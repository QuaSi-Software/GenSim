# frozen_string_literal: true

# Compare the results of two or more regression runs (see run_regression.rb). The first
# directory is the reference, every further one is compared against it.
#
#   ruby Test\regression\compare_results.rb Output\regression\main Output\regression\varFanTest [options]
#   (or with C:\openstudio-3.10.0\bin\openstudio.exe instead of ruby)
#
# Options:
#   --tolerance PCT   relative change below which a value counts as unchanged (default: 1)
#   --all             list all metrics, not only the changed ones
#   --csv FILE        also write every value and change to a CSV file

require "json"

dirs = []
tolerance = 1.0
show_all = false
csv_path = nil
args = ARGV.dup
until args.empty?
  case (arg = args.shift)
  when "--tolerance" then tolerance = args.shift.to_f
  when "--all" then show_all = true
  when "--csv" then csv_path = args.shift
  else dirs << arg
  end
end
abort("usage: compare_results.rb REFERENCE_DIR OTHER_DIR [...] [--tolerance PCT] [--all] [--csv FILE]") if dirs.size < 2

runs = dirs.map do |dir|
  path = File.join(dir, "summary.json")
  abort("#{path} not found - run run_regression.rb first") unless File.exist?(path)
  JSON.parse(File.read(path))
end
labels = runs.map { |r| "#{r['branch']}@#{r['commit']}#{r['uncommitted_measure_changes'] ? '*' : ''}" }

def change_pct(reference, value)
  return nil if reference.nil? || value.nil?
  return(value.zero? ? 0.0 : Float::INFINITY) if reference.zero?

  (value - reference).to_f / reference.abs * 100.0
end

def format_value(value)
  return "-" if value.nil?

  value.abs >= 100 ? value.round.to_s : format("%.2f", value)
end

def format_change(pct)
  return "" if pct.nil?
  return "new" if pct.infinite?

  format("%+.1f %%", pct)
end

puts "# Regression comparison"
puts
runs.each_with_index { |r, i| puts "- #{i.zero? ? 'reference' : "run #{i}"}: #{labels[i]} (#{r['created']})" }
puts "- tolerance: #{tolerance} %#{show_all ? '' : ', only changed values are listed'}"
puts

csv_rows = [["case", "metric"] + labels + labels.drop(1).map { |l| "change % #{l}" }]
changed_cases = 0
case_ids = runs.flat_map { |r| r["cases"].keys }.uniq.sort
case_ids.each do |id|
  results = runs.map { |r| r["cases"][id] }
  status = results.map { |r| r.nil? ? "missing" : r["energyplus"] }
  metrics = results.compact.flat_map { |r| r["metrics"].keys }.uniq
  # absolute energies are listed per m2 only, unless everything is requested
  metrics.reject! { |m| m.end_with?("_kWh") && metrics.include?("#{m}_per_m2") } unless show_all

  rows = metrics.map do |metric|
    values = results.map { |r| r&.dig("metrics", metric) }
    changes = values.drop(1).map { |v| change_pct(values[0], v) }
    csv_rows << [id, metric] + values + changes.map { |c| c&.finite? ? c.round(3) : c }
    changed = changes.any? { |c| c.nil? || c.abs > tolerance } || values.any?(&:nil?)
    [metric, values, changes, changed]
  end
  status_changed = status.uniq.size > 1 || status.first != "completed"
  shown = show_all ? rows : rows.select { |row| row[3] }
  next if shown.empty? && !status_changed

  changed_cases += 1
  puts "## #{id}"
  puts
  puts "status: #{status.each_with_index.map { |s, i| "#{labels[i]} #{s}" }.join(', ')}" if status_changed
  results.each_with_index do |r, i|
    (r&.fetch("errors", []) || []).each { |e| puts "- #{labels[i]}: #{e}" }
    (r&.fetch("workflow_error", []) || []).each { |e| puts "- #{labels[i]}: #{e}" }
  end
  unless shown.empty?
    puts
    puts "| metric | #{labels.join(' | ')} | #{labels.drop(1).map { |l| "change #{l}" }.join(' | ')} |"
    puts "|---|#{'---:|' * (labels.size * 2 - 1)}"
    shown.each do |metric, values, changes, _|
      puts "| #{metric} | #{values.map { |v| format_value(v) }.join(' | ')} | #{changes.map { |c| format_change(c) }.join(' | ')} |"
    end
  end
  puts
end
puts "No changes above #{tolerance} % in #{case_ids.size} cases." if changed_cases.zero?

if csv_path
  File.write(csv_path, csv_rows.map { |row| row.map { |v| v.to_s.include?(";") ? "\"#{v}\"" : v.to_s }.join(";") }.join("\n") + "\n")
  puts "CSV written to #{csv_path}"
end
