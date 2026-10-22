# frozen_string_literal: true

# author: Tobias Maile <tobias@maileconsulting.de>
########################################################
# This is the test for the measure "Results"
########################################################

require "openstudio"
require "openstudio/measure/ShowRunnerOutput"
require "fileutils"

require_relative "../measure.rb"
require_relative "../../TestHelper.rb"
require "minitest/autorun"

class ResultsTest < MiniTest::Test
  # Results is a ReportingMeasure. Its run() signature is (runner, user_arguments) with no
  # model/workspace argument, unlike ModelMeasure/EnergyPlusMeasure - so the shared
  # TestArguments helper (which always calls measure.run(model_or_workspace, runner, map))
  # does not apply here, and this measure needs its own thin runner.
  def run_results_measure(args_hash)
    measure = Results.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    arguments = GetArguments(measure, OpenStudio::Model::Model.new)
    argument_map = GetArgumentMap(arguments, args_hash)

    measure.run(runner, argument_map)
    result = runner.result

    show_output(result)
    return result
  end

  def test_number_of_arguments_and_argument_names
    # get arguments with a new instance of the measure
    arguments = GetArguments(Results.new, OpenStudio::Model::Model.new)

    assert_equal(6, arguments.size)
  end

  def test_bad_argument_values
    # timestep is required with no default, so an empty argument hash must fail validation
    args_hash = {}

    result = run_results_measure(args_hash)

    # assert that it failed as expected
    assert_equal("Fail", result.value.valueName)
  end

  def test_no_sql_file_available
    # with otherwise valid arguments but no EnergyPlus simulation having been run against
    # this runner, lastEnergyPlusSqlFile is empty and the measure must fail gracefully
    # rather than raise, since there is no sql output to read variables from.
    args_hash = {}
    args_hash["timestep"] = 60

    result = run_results_measure(args_hash)

    # assert that it failed as expected
    assert_equal("Fail", result.value.valueName)
    assert_equal(1, result.errors.size)
    assert_equal("Cannot find last sql file.", result.errors[0].logMessage)
  end

  def test_good_argument_values
    # example_model.sql is a real EnergyPlus SQL output from a minimal 3-day, single-zone
    # simulation (see example_model_generator.idf for the input that produced it, run via
    # `energyplus -w <a TMY3 epw> -d <outdir> -r example_model_generator.idf`), reporting
    # "Zone Infiltration Sensible Heat Loss Energy" hourly - one of the "Normal"-level
    # output variables this measure looks for.
    args_hash = {}
    args_hash["timestep"] = 60

    measure = Results.new
    runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

    arguments = GetArguments(measure, OpenStudio::Model::Model.new)
    argument_map = GetArgumentMap(arguments, args_hash)

    sql_path = OpenStudio::Path.new("#{__dir__}/example_model.sql")
    runner.setLastEnergyPlusSqlFilePath(sql_path)

    output_dir = "#{__dir__}/output"
    FileUtils.mkdir_p(output_dir)

    result = nil
    # the measure writes its CSV output relative to the current working directory
    Dir.chdir(output_dir) do
      measure.run(runner, argument_map)
      result = runner.result
    end

    show_output(result)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.errors.empty?)

    hourly_csv = "#{output_dir}/report_variables_Hourly.csv"
    hourly_sum_csv = "#{output_dir}/report_variables_Hourly-Sum.csv"
    assert(File.exist?(hourly_csv))
    assert(File.exist?(hourly_sum_csv))

    csv_lines = File.readlines(hourly_csv)
    assert_equal("Hourly,Zone Infiltration Sensible Heat Loss Energy[Wh]\n", csv_lines[0])
    # 3 simulated days at hourly reporting = 72 data rows plus the header row
    assert_equal(73, csv_lines.size)

    sum_lines = File.readlines(hourly_sum_csv)
    assert_equal("Zone Infiltration Sensible Heat Loss Energy[Wh]\n", sum_lines[0])
  end
end
