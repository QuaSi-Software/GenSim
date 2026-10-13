# frozen_string_literal: true

# Compare two EnergyPlus IDFs (e.g. run/in.idf of two regression runs) object by object, to find
# which inputs cause a difference in the results.
#
# OpenStudio numbers objects in a different order from run to run (Node 12, Lights 3, ...), so a
# plain text diff is useless. Here numbered names are normalized and, per object type, the objects
# are compared as a set, independent of their order. Remaining noise: objects that list zones in a
# different order (e.g. Controller:MechanicalVentilation, WindowShadingControl).
#
#   ruby Test\regression\diff_idf.rb A\in.idf B\in.idf [--max N]
#   (or with C:\openstudio-3.10.0\bin\openstudio.exe instead of ruby)

max_shown = 4
paths = []
args = ARGV.dup
until args.empty?
  case (arg = args.shift)
  when "--max" then max_shown = args.shift.to_i
  else paths << arg
  end
end
abort("usage: diff_idf.rb A.idf B.idf [--max N]") unless paths.size == 2

# object type => { normalized object => count }
def load_idf(path)
  objects = Hash.new { |h, k| h[k] = Hash.new(0) }
  File.read(path, encoding: "ISO-8859-1").gsub(/!.*$/, "").split(";").each do |chunk|
    fields = chunk.split(",").map { |f| f.strip.gsub(/\{[0-9a-f-]+\}/, "").gsub(/ \d+$/, " N") }
    next if fields.empty? || fields[0].empty?

    objects[fields[0]][fields[1..].join(" | ")] += 1
  end
  objects
end

a = load_idf(paths[0])
b = load_idf(paths[1])
differences = 0
(a.keys | b.keys).sort.each do |type|
  only_a = a[type].flat_map { |o, n| [o] * [n - b[type][o], 0].max }
  only_b = b[type].flat_map { |o, n| [o] * [n - a[type][o], 0].max }
  next if only_a.empty? && only_b.empty?

  differences += 1
  puts "== #{type}: #{only_a.size} only in A, #{only_b.size} only in B"
  only_a.first(max_shown).each { |o| puts "  A: #{o[0, 400]}" }
  only_b.first(max_shown).each { |o| puts "  B: #{o[0, 400]}" }
end
puts "No differences." if differences.zero?
