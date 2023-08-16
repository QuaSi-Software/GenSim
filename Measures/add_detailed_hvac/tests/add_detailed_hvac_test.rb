# frozen_string_literal: true

# author: Tobias Maile <tobias@maileconsulting.de>
########################################################
# This is the test for the measure "AddDetailedHVAC"
########################################################

require "openstudio"
require "openstudio/measure/ShowRunnerOutput"
require "fileutils"

require_relative "../measure.rb"
require_relative "../../TestHelper.rb"
require "minitest/autorun"

class AddDetailedHVAC_Test < MiniTest::Test
  # def setup
  # there is no need for any setup
  # end

  def test_number_of_arguments_and_argument_names
    # get arguments with a new instance of the measure
    arguments = GetArguments(AddDetailedHVAC.new, OpenStudio::Model::Model.new)

    assert_equal(28, arguments.size)
  end

  def test_bad_argument_values
    # create hash of argument values, no arguments defined so there are no bad arguments
    args_hash = {}
    args_hash["space_name"] = ""

    result = TestArguments(AddDetailedHVAC.new, OpenStudio::Model::Model.new, args_hash)

    # assert that it ran correctly
    assert_equal("Fail", result.value.valueName)
  end

  def test_good_argument_values
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    hvacSched = " 0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0"
    heatingSched = " 20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20"
    coolingSched = " 25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25"
    args_hash["heat_recovery_method"] = "Sensible"
    args_hash["latent_efficiency"] = 1
    args_hash["sensible_efficiency"] = 0.75
    args_hash["ach_per_hour"] = 2.0
    args_hash["nfg_gfa_ratio"] = 0.8
    args_hash["floor_height_ratio"] = 0.8
    args_hash["hvac_schedule"] = "DIN 18599: Einzel-/Gruppen-/Großraumbüro"
    args_hash["is_custom_hvac"] = true
    args_hash["hvac_sched_weekday"] = hvacSched
    args_hash["hvac_sched_saturday"] = hvacSched
    args_hash["hvac_sched_sunday"] = hvacSched
    args_hash["hvac_sched_holiday"] = hvacSched
    args_hash["holidays"] = "-"
    args_hash["zone_heating_temp_sched_weekday"] = heatingSched
    args_hash["zone_heating_temp_sched_saturday"] = heatingSched
    args_hash["zone_heating_temp_sched_sunday"] = heatingSched
    args_hash["zone_heating_temp_sched_holiday"] = heatingSched
    args_hash["zone_cooling_temp_sched_weekday"] = coolingSched
    args_hash["zone_cooling_temp_sched_saturday"] = coolingSched
    args_hash["zone_cooling_temp_sched_sunday"] = coolingSched
    args_hash["zone_cooling_temp_sched_holiday"] = coolingSched
    args_hash["hot_water_temp_setpoint"] = 82
    args_hash["hot_water_temp_diff"] = 11
    args_hash["cold_water_temp_setpoint"] = 10
    args_hash["cold_water_temp_diff"] = 5
    args_hash["supply_fan_pressure_rise"] = 75
    args_hash["return_fan_pressure_rise"] = 750
    args_hash["system_type"] = 2

    # load an existing model
    dir = __dir__
    model = OpenModel(dir)
    result = TestArguments(AddDetailedHVAC.new, model, args_hash)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.size == 12)
    assert(result.warnings.empty?)
    assert(result.errors.empty?)
    refute(result.initialCondition.is_initialized)
    assert(result.finalCondition.is_initialized)
    assert_equal("In the final model 4 zones are connected to the DOAS air loop.", result.finalCondition.get.logMessage)
    # save the model to test output directory
    SaveModel(model, dir)
  end

  def teardown
    # nothing to do here for such a simple measure
  end
end
