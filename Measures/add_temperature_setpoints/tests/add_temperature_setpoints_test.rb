# frozen_string_literal: true

# author: Tobias Maile <tobias@maileconsulting.de>
########################################################
# This is the test for the measure "AddingTemperatureSetpoints"
########################################################

require "openstudio"
require "openstudio/measure/ShowRunnerOutput"
require "fileutils"

require_relative "../measure.rb"
require_relative "../../TestHelper.rb"
require "minitest/autorun"

class AddTemperatureSetpointsTest < MiniTest::Test
  def test_number_of_arguments_and_argument_names
    # get arguments with a new instance of the measure
    arguments = GetArguments(AddTemperatureSetpoints.new, OpenStudio::Model::Model.new)

    assert_equal(13, arguments.size)
  end

  def test_bad_argument_values
    # create hash of argument values, no arguments defined so there are no bad arguments
    args_hash = {}
    args_hash["space_name"] = ""

    result = TestArguments(AddTemperatureSetpoints.new, OpenStudio::Model::Model.new, args_hash)

    # assert that it ran correctly
    assert_equal("Fail", result.value.valueName)
  end

  def test_good_argument_values
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    defaultSched = " 20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20"
    # create hash of argument values
    args_hash = {}
    args_hash["zone_heating_temp_sched_weekday"] = defaultSched
    args_hash["zone_heating_temp_sched_saturday"] = defaultSched
    args_hash["zone_heating_temp_sched_sunday"] = defaultSched
    args_hash["zone_heating_temp_sched_holiday"] = defaultSched
    args_hash["zone_cooling_temp_sched_weekday"] = defaultSched
    args_hash["zone_cooling_temp_sched_saturday"] = defaultSched
    args_hash["zone_cooling_temp_sched_sunday"] = defaultSched
    args_hash["zone_cooling_temp_sched_holiday"] = defaultSched
    args_hash["holidays"] = defaultSched
    args_hash["heating_temp_selection"] = "Konstant 20°C"
    args_hash["cooling_temp_selection"] = "Konstant 25°C"
    args_hash["is_custom_heating"] = false
    args_hash["is_custom_cooling"] = false

    # load an existing model
    dir = __dir__
    model = OpenModel(dir)
    result = TestArguments(AddTemperatureSetpoints.new, model, args_hash)

    # store the number of spaces in the seed model
    num_spaces_seed = model.getSpaces.size

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.size == 4)
    assert(result.warnings.empty?)
    assert(result.errors.empty?)
    refute(result.initialCondition.is_initialized)
    assert(result.finalCondition.is_initialized)
    assert_equal("Replaced thermostats for 4 thermal zones", result.finalCondition.get.logMessage)
    # save the model to test output directory
    SaveModel(model, dir)
  end

  def teardown
    # nothing to do here for such a simple measure
  end
end
