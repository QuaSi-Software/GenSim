require 'openstudio_measure_tester'
measures_dir = Dir.pwd
# all measures (recursively) from measures_dir will be tested

runner = OpenStudioMeasureTester::Runner.new(measures_dir)

# base_dir is needed for coverage results as they are written to disk on the at_exit calls
base_dir = Dir.pwd

result = runner.run_all(base_dir)
puts result
# result will be 0 or 1, 0=success, 1=failure

# runner.run_style(false)

runner.run_test(false, base_dir)

# runner.run_rubocop(false)
