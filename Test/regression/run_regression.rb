# frozen_string_literal: true

# Regression runs of the building typologies (building_typologies/*.osw) without Excel.
#
# Each typology only holds the parameters that differ from the GenSim defaults, so it is laid
# over a complete exported workflow (base_workflow.osw) per measure step, the same way the Excel
# import would overwrite the corresponding input cells. Every typology is run with ideal loads
# and/or the detailed HVAC (DOAS + radiant surfaces), against the measures of the repository the
# script lives in (or --repo). Arguments and steps the measures of that repository do not know
# are dropped, so the same inputs can be run on older and newer branches and compared with
# compare_results.rb.
#
# Run with the OpenStudio CLI (needs the OpenStudio SDK for reading the SQL output):
#   C:\openstudio-3.10.0\bin\openstudio.exe Test\regression\run_regression.rb [options]
#
# Options:
#   --repo DIR       repository whose measures are run (default: the one containing this script);
#                    typologies and weather files always come from this script's checkout
#   --out DIR        result directory (default: <repo>/Output/regression/<branch>)
#   --cases REGEX    only run typologies whose name matches (case insensitive)
#   --modes LIST     ideal,detailed (default: both)
#   --variants REGEX feature variants of variants.json to run in addition to the plain typologies:
#                    all (default), none, or a regex on the variant names
#   --only-variants  run only the variants, not the plain typologies
#   --jobs N         simulations run in parallel (default: 6)
#   --os PATH        openstudio executable (default: C:/openstudio-3.10.0/bin/openstudio.exe)
#   --set M.ARG=VAL  override a measure argument in every case (repeatable), e.g.
#                    --set add_infiltration.infiltration_type=EnergyPlus
#   --keep-runs      keep the complete simulation output (about 0.5 GB per run)
#   --prepare-only   only write the workflows, do not simulate

require "json"
require "fileutils"
require "rexml/document"

SCRIPT_DIR = File.expand_path(__dir__)
# typologies and weather always come from the checkout of this script, so every tested
# repository gets identical inputs
INPUT_ROOT = File.expand_path("../..", SCRIPT_DIR)

options = {
  repo: INPUT_ROOT,
  out: nil,
  cases: nil,
  modes: %w[ideal detailed],
  jobs: 6,
  os: "C:/openstudio-3.10.0/bin/openstudio.exe",
  keep_runs: false,
  overrides: [],
  variants: /./,
  only_variants: false,
  prepare_only: false
}
args = ARGV.dup
until args.empty?
  case (arg = args.shift)
  when "--repo" then options[:repo] = File.expand_path(args.shift)
  when "--out" then options[:out] = File.expand_path(args.shift)
  when "--cases" then options[:cases] = Regexp.new(args.shift, Regexp::IGNORECASE)
  when "--modes" then options[:modes] = args.shift.split(",").map(&:strip)
  when "--jobs" then options[:jobs] = args.shift.to_i
  when "--os" then options[:os] = args.shift
  when "--set"
    abort("--set expects MEASURE.ARGUMENT=VALUE") unless (m = args.shift.to_s.match(/\A([^.=]+)\.([^=]+)=(.*)\z/))
    options[:overrides] << m.captures
  when "--variants"
    value = args.shift.to_s
    options[:variants] = case value
                         when "all" then /./
                         when "none" then nil
                         else Regexp.new(value, Regexp::IGNORECASE)
                         end
  when "--only-variants" then options[:only_variants] = true
  when "--keep-runs" then options[:keep_runs] = true
  when "--prepare-only" then options[:prepare_only] = true
  else abort("unknown option #{arg}")
  end
end
unless (options[:modes] - %w[ideal detailed]).empty?
  abort("--modes accepts ideal and/or detailed")
end

repo = options[:repo]
measures_dir = File.join(repo, "Measures")
branch = `git -C "#{repo}" rev-parse --abbrev-ref HEAD`.strip
commit = `git -C "#{repo}" rev-parse --short HEAD`.strip
dirty = !`git -C "#{repo}" status --porcelain -- Measures`.strip.empty?
out_dir = options[:out] || File.join(repo, "Output", "regression", branch.empty? ? "current" : branch)
FileUtils.mkdir_p(out_dir)

# argument names, required flags and defaults of a measure, from its measure.xml
def measure_arguments(measures_dir, measure_name)
  xml_path = File.join(measures_dir, measure_name, "measure.xml")
  return nil unless File.exist?(xml_path)

  doc = REXML::Document.new(File.read(xml_path))
  doc.get_elements("//arguments/argument").to_h do |arg|
    name = arg.elements["name"].text
    [name, { required: arg.elements["required"]&.text == "true", default: arg.elements["default_value"]&.text }]
  end
end

# step name => arguments of an OSW
def step_arguments(osw)
  osw["steps"].to_h { |s| [s["measure_dir_name"], s["arguments"] || {}] }
end

# a variant value: a string, or [[value, count], ...] expanded to a ';'-separated schedule
def variant_value(value)
  return value.to_s unless value.is_a?(Array)

  value.flat_map { |v, count| [v.to_s] * count }.join(";")
end

# Build the complete workflow of one typology and HVAC mode, optionally with a feature variant
# laid over the typology; returns [osw, notes, errors]
def build_workflow(base, typology, mode, measures_dir, run_dir, overrides = [], variant = nil)
  notes = []
  errors = []
  typology_args = step_arguments(typology)
  (variant&.fetch("set", {}) || {}).each do |key, value|
    measure, name = key.split(".", 2)
    typology_args[measure] = (typology_args[measure] || {}).merge(name => variant_value(value))
  end
  steps = base["steps"].map do |step|
    args = (step["arguments"] || {}).merge(typology_args.fetch(step["measure_dir_name"], {}))
    { "measure_dir_name" => step["measure_dir_name"], "arguments" => args }
  end
  (typology_args.keys - steps.map { |s| s["measure_dir_name"] }).each do |name|
    notes << "typology step #{name} is not part of the base workflow - ignored"
  end
  step = ->(name) { steps.find { |s| s["measure_dir_name"] == name } }

  flags = step.call("custom_export_params")["arguments"]
  # the typologies predate manual window ventilation - keep it off unless they set it
  flags["include_manual_ventilation"] = typology_args.dig("custom_export_params", "include_manual_ventilation") || "0"
  flags["include_detailed_hvac"] = mode == "detailed" ? "1" : "0"
  { "add_infiltration" => "include_infiltration",
    "inject_zone_ventilation_idf" => "include_window_ventilation",
    "inject_manual_ventilation_idf" => "include_manual_ventilation",
    "add_shading_controls" => "include_shading_control",
    "add_lighting_controls" => "include_lighting_control" }.each do |measure, flag|
    steps.reject! { |s| s["measure_dir_name"] == measure } if flags[flag].to_s == "0"
  end

  # ideal loads replace the DOAS + radiant surfaces; both take the same HVAC inputs (see the
  # Excel export: ExportAddIdealLoads vs. ExportAddDetailedHVAC)
  if mode == "ideal"
    step.call("add_detailed_hvac")["measure_dir_name"] = "add_ideal_loads"
    steps.reject! { |s| s["measure_dir_name"] == "inject_radiant_surfaces_idf" }
  end

  weather = File.join(INPUT_ROOT, "Wetter", variant&.fetch("weather", nil) || File.basename(base["weather_file"].tr("\\", "/")))
  errors << "weather file #{weather} not found" unless File.exist?(weather)
  step.call("set_weather_axis_timestep")["arguments"]["weather_file_path"] = weather
  step.call("save_model")["arguments"]["output_path"] = run_dir
  if (results = step.call("results"))
    gross_area = step.call("add_geometry")["arguments"]["floor_area"].to_f
    nfa_gfa = step.call("add_internal_loads")["arguments"]["nfa_gfa_ratio"].to_f
    results["arguments"]["gross_area"] = gross_area.to_s
    results["arguments"]["net_area"] = (gross_area * nfa_gfa).round.to_s
  end

  overrides.each do |measure, name, value|
    if (s = step.call(measure))
      s["arguments"][name] = value
      notes << "override #{measure}.#{name} = #{value}"
    else
      notes << "override #{measure}.#{name}: step not in this case - ignored"
    end
  end

  # adapt to the measures of the repository under test; explicit overrides and variant inputs are
  # always passed on, since a measure.xml can lag behind its measure.rb
  explicit = overrides.map { |measure, name, _| [measure, name] } +
             (variant&.fetch("set", {}) || {}).keys.map { |key| key.split(".", 2) }
  steps.select! do |s|
    known = measure_arguments(measures_dir, s["measure_dir_name"])
    if known.nil?
      notes << "measure #{s['measure_dir_name']} does not exist in this repository - step skipped"
      next false
    end
    overridden = explicit.select { |measure, _| measure == s["measure_dir_name"] }.map(&:last)
    (overridden - known.keys).each do |name|
      notes << "#{s['measure_dir_name']}: explicit input #{name} is not in measure.xml - passed on anyway"
      known[name] = { required: false, default: nil }
    end
    unknown = s["arguments"].keys - known.keys
    notes << "#{s['measure_dir_name']}: unknown arguments dropped: #{unknown.join(', ')}" unless unknown.empty?
    s["arguments"].select! { |k, _| known.key?(k) }
    missing = known.select { |k, v| v[:required] && v[:default].nil? && !s["arguments"].key?(k) }.keys
    errors << "#{s['measure_dir_name']}: required arguments missing: #{missing.join(', ')}" unless missing.empty?
    true
  end

  osw = { "measure_paths" => [measures_dir], "seed_file" => "Model.osm", "weather_file" => weather, "steps" => steps }
  [osw, notes, errors]
end

def table_value(sql, report, table, row, column)
  value = sql.execAndReturnFirstDouble(
    "SELECT CAST(Value AS REAL) FROM TabularDataWithStrings WHERE ReportName='#{report}' AND TableName='#{table}' " \
    "AND RowName='#{row}' AND ColumnName='#{column}'"
  )
  value.is_initialized ? value.get : nil
end

def table_rows(sql, report, table, column_filter)
  rows = sql.execAndReturnVectorOfString(
    "SELECT RowName || '|' || ColumnName || '|' || Value FROM TabularDataWithStrings WHERE ReportName='#{report}' " \
    "AND TableName='#{table}' AND #{column_filter}"
  )
  rows.is_initialized ? rows.get.map { |r| r.split("|", 3) } : []
end

# key results of one finished run; energies in kWh, peak demands in kW
def extract_results(run_dir)
  result = { "metrics" => {} }
  err_path = File.join(run_dir, "run", "eplusout.err")
  if File.exist?(err_path)
    summary = File.readlines(err_path, encoding: "ISO-8859-1").grep(/EnergyPlus (Completed|Terminated)/).last.to_s
    result["energyplus"] = summary.include?("Completed Successfully") ? "completed" : "failed"
    result["metrics"]["warnings"] = summary[/(\d+) Warning/, 1].to_i
    result["metrics"]["severe_errors"] = summary[/(\d+) Severe Error/, 1].to_i
  else
    result["energyplus"] = "not run"
  end
  log_path = File.join(run_dir, "run.log")
  if result["energyplus"] != "completed" && File.exist?(log_path)
    result["workflow_error"] = File.readlines(log_path, encoding: "ISO-8859-1").grep(/error/i).last(3).map(&:strip)
  end
  sql_path = File.join(run_dir, "run", "eplusout.sql")
  return result unless result["energyplus"] == "completed" && File.exist?(sql_path)

  sql = OpenStudio::SqlFile.new(OpenStudio::Path.new(sql_path))
  m = result["metrics"]
  area = table_value(sql, "AnnualBuildingUtilityPerformanceSummary", "Building Area", "Net Conditioned Building Area", "Area")
  m["net_conditioned_area_m2"] = area

  # end uses, summed over all fuels (water excluded), GJ -> kWh
  end_uses = Hash.new(0.0)
  fuels = Hash.new(0.0)
  table_rows(sql, "AnnualBuildingUtilityPerformanceSummary", "End Uses", "ColumnName <> 'Water'").each do |row, column, value|
    next if row.empty?

    kwh = value.to_f / 0.0036
    if row == "Total End Uses"
      fuels[column] += kwh
    else
      end_uses[row] += kwh
    end
  end
  end_uses.each do |use, kwh|
    next if kwh.zero?

    key = use.downcase.tr(" ", "_")
    m["#{key}_kWh"] = kwh
    m["#{key}_kWh_per_m2"] = kwh / area if area&.positive?
  end
  fuels.each { |fuel, kwh| m["total_#{fuel.downcase.tr(' ', '_')}_kWh"] = kwh unless kwh.zero? }

  table_rows(sql, "DemandEndUseComponentsSummary", "End Uses", "RowName = 'Total End Uses' AND ColumnName <> 'Water'").each do |_, column, value|
    m["peak_#{column.downcase.tr(' ', '_')}_kW"] = value.to_f / 1000.0 unless value.to_f.zero?
  end

  { "unmet_hours_heating" => "Time Setpoint Not Met During Occupied Heating",
    "unmet_hours_cooling" => "Time Setpoint Not Met During Occupied Cooling",
    "not_comfortable_hours_ashrae55" => "Time Not Comfortable Based on Simple ASHRAE 55-2004" }.each do |key, row|
    m[key] = table_value(sql, "AnnualBuildingUtilityPerformanceSummary", "Comfort and Setpoint Not Met Summary", row, "Facility")
  end
  sql.close
  result
end

# collect the cases
base = JSON.parse(File.read(File.join(SCRIPT_DIR, "base_workflow.osw"), encoding: "UTF-8"))
typology_files = Dir[File.join(INPUT_ROOT, "building_typologies", "*.osw")].sort
typology_files.select! { |f| File.basename(f, ".osw") =~ options[:cases] } if options[:cases]
abort("no typologies found") if typology_files.empty?

variants = JSON.parse(File.read(File.join(SCRIPT_DIR, "variants.json"), encoding: "UTF-8"))["variants"]
variants = options[:variants] ? variants.select { |v| v["name"] =~ options[:variants] } : []
all_typologies = Dir[File.join(INPUT_ROOT, "building_typologies", "*.osw")].map { |f| File.basename(f, ".osw").sub(/ \(Germany\)$/, "") }
variants.each do |v|
  (v["typologies"] - all_typologies).each { |t| warn "variant #{v['name']}: unknown typology #{t}" }
end

cases = []
typology_files.each do |file|
  typology = JSON.parse(File.read(file, encoding: "UTF-8"))
  name = File.basename(file, ".osw").sub(/ \(Germany\)$/, "")
  # the plain typology (variant nil) and every variant listed for it, per mode
  runs = options[:only_variants] ? [] : options[:modes].map { |mode| [mode, nil] }
  variants.each do |v|
    next unless v["typologies"].include?(name)

    (v["modes"] & options[:modes]).each { |mode| runs << [mode, v] }
  end
  runs.each do |mode, variant|
    id = "#{name.tr(' ', '_')}__#{mode}#{variant ? "__#{variant['name']}" : ''}"
    run_dir = File.join(out_dir, id)
    FileUtils.rm_rf(run_dir)
    FileUtils.mkdir_p(run_dir)
    osw, notes, errors = build_workflow(base, typology, mode, measures_dir, run_dir, options[:overrides], variant)
    notes.unshift("variant #{variant['name']}: #{variant['description']}") if variant
    File.write(File.join(run_dir, "Model.osw"), JSON.pretty_generate(osw))
    OpenStudio::Model::Model.new.save(OpenStudio::Path.new(File.join(run_dir, "Model.osm")), true)
    cases << { "id" => id, "typology" => name, "mode" => mode, "variant" => variant&.fetch("name"),
               "run_dir" => run_dir, "notes" => notes, "errors" => errors }
  end
end
puts "#{cases.size} cases for #{branch} (#{commit}#{dirty ? ', uncommitted measure changes' : ''}) -> #{out_dir}"
exit if options[:prepare_only]

# simulate in parallel
queue = Queue.new
cases.each { |c| queue << c }
workers = Array.new([options[:jobs], 1].max) do
  Thread.new do
    until (c = (queue.pop(true) rescue nil)).nil?
      if c["errors"].empty?
        started = Time.now
        system(options[:os], "run", "-w", "Model.osw", chdir: c["run_dir"],
               out: File.join(c["run_dir"], "run.log"), err: [:child, :out])
        c["runtime_s"] = (Time.now - started).round
      end
      puts "  #{c['id']}: #{c['errors'].empty? ? "#{c['runtime_s']} s" : "skipped (#{c['errors'].join('; ')})"}"
    end
  end
end
workers.each(&:join)

# extract and summarize
summary = { "branch" => branch, "commit" => commit, "uncommitted_measure_changes" => dirty,
            "overrides" => options[:overrides].map { |m, a, v| "#{m}.#{a}=#{v}" },
            "created" => Time.now.strftime("%Y-%m-%d %H:%M"), "cases" => {} }
cases.each do |c|
  result = c["errors"].empty? ? extract_results(c["run_dir"]) : { "energyplus" => "not run", "metrics" => {} }
  result["runtime_s"] = c["runtime_s"]
  result["notes"] = c["notes"]
  result["errors"] = c["errors"]
  summary["cases"][c["id"]] = result
  File.write(File.join(c["run_dir"], "summary.json"), JSON.pretty_generate(result))
  next if options[:keep_runs]

  # keep the error file, the tabular report and the workflow log, drop the bulky outputs
  run = File.join(c["run_dir"], "run")
  next unless Dir.exist?(run)

  Dir.children(run).each do |f|
    next if %w[eplusout.err eplustbl.htm in.idf out.osw run.log].include?(f)

    FileUtils.rm_rf(File.join(run, f))
  end
  %w[reports generated_files].each { |d| FileUtils.rm_rf(File.join(c["run_dir"], d)) }
end
File.write(File.join(out_dir, "summary.json"), JSON.pretty_generate(summary))

failed = summary["cases"].reject { |_, r| r["energyplus"] == "completed" }
puts "#{summary['cases'].size - failed.size} of #{summary['cases'].size} cases completed, summary: #{File.join(out_dir, 'summary.json')}"
failed.each { |id, r| puts "  FAILED #{id}: #{r['energyplus']} #{r['errors'].join('; ')}" }
