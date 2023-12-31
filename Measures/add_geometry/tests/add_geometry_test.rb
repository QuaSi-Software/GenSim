# frozen_string_literal: true

require "openstudio"
require "openstudio/ruleset/ShowRunnerOutput"

require_relative "../measure.rb"
require_relative "../../TestHelper.rb"
require "minitest/autorun"

class AddGeometryTest < MiniTest::Test
  def test_number_of_arguments_and_argument_names
    # get arguments with a new instance of the measure
    arguments = GetArguments(AddGeometry.new, OpenStudio::Model::Model.new)

    # check if the number of arguments is correct
    assert_equal(18, arguments.size)
  end

  def test_bad_argument_values
    # create hash of argument values, no arguments defined so there are no bad arguments
    args_hash = {}

    result = TestArguments(AddGeometry.new, OpenStudio::Model::Model.new, args_hash)

    # assert that it ran correctly
    assert_equal("Fail", result.value.valueName)
  end

  def test_good_argument_values
    # create hash of argument values
    args_hash = {}
    args_hash["floor_area"] = 400

    # create an empty model
    model = OpenStudio::Model::Model.new
    result = TestArguments(AddGeometry.new, model, args_hash)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.empty?)
    assert(result.warnings.size == 1)
    assert(result.errors.empty?)
    refute(result.initialCondition.is_initialized)
    assert(result.finalCondition.is_initialized)
    print(result.finalCondition.get.logMessage)
    assert_equal("The building finished with 2 spaces.", result.finalCondition.get.logMessage)

    SaveModel(model, File.dirname(__FILE__) + "/output/test_output.osm")
  end

  def teardown
    # nothing to do here for such a simple measure
  end
end
