# frozen_string_literal: true

# author: Tobias Maile <tobias@maileconsulting.de>
########################################################
# This is the test for the measure "AddingLightingControls"
########################################################

require "openstudio"
require "openstudio/measure/ShowRunnerOutput"
require "fileutils"

require_relative "../measure.rb"
require_relative "../../TestHelper.rb"
require "minitest/autorun"

class AddLightingControlsTest < MiniTest::Test
  def test_number_of_arguments_and_argument_names
    # get arguments with a new instance of the measure
    arguments = GetArguments(AddLightingControls.new, OpenStudio::Model::Model.new)

    assert_equal(1, arguments.size)
  end

  def test_bad_argument_values
    # create hash of argument values, no arguments defined so there are no bad arguments
    args_hash = {}
    args_hash["space_name"] = ""

    result = TestArguments(AddLightingControls.new, OpenStudio::Model::Model.new, args_hash)

    # assert that it ran correctly
    assert_equal("NA", result.value.valueName)
  end

  def test_good_argument_values
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash["daylighting_setpoint"] = 500

    # load an existing model
    dir = __dir__
    model = OpenModel(dir)
    result = TestArguments(AddLightingControls.new, model, args_hash)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.size == 1)
    assert(result.warnings.empty?)
    assert(result.errors.empty?)
    assert(result.initialCondition.is_initialized)
    assert(result.finalCondition.is_initialized)
    assert_equal("4 sensors added on a total effected sensor area of 37.161216 square meters", result.finalCondition.get.logMessage)
    # save the model to test output directory
    SaveModel(model, dir)
  end
end
