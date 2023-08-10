require "openstudio"
require "openstudio/measure/ShowRunnerOutput"
require "fileutils"

require_relative "../measure.rb"
require_relative "../../TestHelper.rb"
require "minitest/autorun"

class CustomExportParamsTest < MiniTest::Test
  def test_number_of_arguments_and_argument_names
    arguments = GetArguments(CustomExportParams.new, OpenStudio::Model::Model.new)

    assert_equal(18, arguments.size)
  end

  def test_bad_argument_values
    args_hash = {}

    result = TestArguments(CustomExportParams.new, OpenStudio::Model::Model.new, args_hash)

    # as the measure does nothing, even "bad" argument values do not cause the measure
    # to fail
    assert_equal("Success", result.value.valueName)
  end

  def test_good_argument_values
    args_hash = {}

    model = OpenStudio::Model::Model.new
    result = TestArguments(CustomExportParams.new, model, args_hash)

    assert_equal("Success", result.value.valueName)
    assert(result.info.empty?)
    assert(result.warnings.empty?)
    assert(result.errors.empty?)
  end
end
