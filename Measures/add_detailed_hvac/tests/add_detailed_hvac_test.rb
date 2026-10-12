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

    assert_equal(30, arguments.size)
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
    assert(result.info.size >= 1)
    assert(result.warnings.empty?)
    assert(result.errors.empty?)
    refute(result.initialCondition.is_initialized)
    assert(result.finalCondition.is_initialized)
    assert_equal("In the final model 4 zones are connected to the DOAS air loop.", result.finalCondition.get.logMessage)
    # save the model to test output directory
    SaveModel(model, dir)
  end

  def test_doas_heating_and_cooling_coils
    args_hash = {}
    hvacSched = " 0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0"
    heatingSched = " 20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20"
    coolingSched = " 25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25"
    args_hash["heat_recovery_method"] = "none"
    args_hash["latent_efficiency"] = 1
    args_hash["sensible_efficiency"] = 0.75
    args_hash["ach_per_hour"] = 2.0
    args_hash["nfg_gfa_ratio"] = 0.8
    args_hash["floor_height_ratio"] = 0.8
    args_hash["hvac_sched_weekday"] = hvacSched
    args_hash["hvac_sched_saturday"] = hvacSched
    args_hash["hvac_sched_sunday"] = hvacSched
    args_hash["hvac_sched_holiday"] = hvacSched
    args_hash["holidays"] = "-"
    args_hash["zone_heating_temp_sched_weekday"] = heatingSched
    # night setback on Saturdays, to check that every day of the setpoint schedule gets offset
    args_hash["zone_heating_temp_sched_saturday"] = ((["16"] * 24) + (["20"] * 72)).join(";")
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
    args_hash["add_doas_heating_coil"] = true
    args_hash["add_doas_cooling_coil"] = true

    # load an existing model
    dir = __dir__
    model = OpenModel(dir)
    # the example model has no site location (latitude 0) - place it in Augsburg (northern hemisphere)
    model.getSite.setLatitude(48.4)
    result = TestArguments(AddDetailedHVAC.new, model, args_hash)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.errors.empty?)

    # verify the DOAS heating and cooling coils were added and connected to the plant loops
    air_loop = model.getAirLoopHVACByName("DOAS Air Loop").get
    heating_coils = air_loop.supplyComponents.select { |c| c.to_CoilHeatingWater.is_initialized }
    cooling_coils = air_loop.supplyComponents.select { |c| c.to_CoilCoolingWater.is_initialized }
    assert_equal(1, heating_coils.size)
    assert_equal(1, cooling_coils.size)

    hot_water_plant = model.getPlantLoopByName("Hot Water Loop").get
    chilled_water_plant = model.getPlantLoopByName("Chilled Water Loop").get
    assert(hot_water_plant.demandComponents.any? { |c| c.to_CoilHeatingWater.is_initialized })
    assert(chilled_water_plant.demandComponents.any? { |c| c.to_CoilCoolingWater.is_initialized })

    # both coils share the seasonal "SAT Year Schedule": heating season = zone heating setpoint - 2 K,
    # cooling season = zone cooling setpoint + 2 K (northern hemisphere)
    heating_coil_spm = heating_coils[0].to_CoilHeatingWater.get.airOutletModelObject.get.to_Node.get.setpointManagers[0].to_SetpointManagerScheduled.get
    cooling_coil_spm = cooling_coils[0].to_CoilCoolingWater.get.airOutletModelObject.get.to_Node.get.setpointManagers[0].to_SetpointManagerScheduled.get
    assert_equal("SAT Year Schedule", heating_coil_spm.schedule.name.to_s)
    assert_equal(heating_coil_spm.schedule, cooling_coil_spm.schedule)

    sat_sched = heating_coil_spm.schedule.to_ScheduleYear.get
    weeks = sat_sched.scheduleWeeks
    assert_equal(["SAT Week Schedule Low", "SAT Week Schedule High", "SAT Week Schedule Low"], weeks.map { |w| w.name.to_s })
    winter_week = weeks[0]
    summer_week = weeks[1]
    assert_equal([18.0], winter_week.mondaySchedule.get.values.uniq)
    assert_equal(([14.0] * 24) + ([18.0] * 72), winter_week.saturdaySchedule.get.values)
    assert_equal([18.0], winter_week.winterDesignDaySchedule.get.values.uniq)
    assert_equal([27.0], summer_week.mondaySchedule.get.values.uniq)
    assert_equal([27.0], summer_week.summerDesignDaySchedule.get.values.uniq)

    # in the southern hemisphere the seasons are swapped
    southern_model = OpenModel(dir)
    southern_model.getSite.setLatitude(-33.9)
    TestArguments(AddDetailedHVAC.new, southern_model, args_hash)
    southern_weeks = southern_model.getScheduleYearByName("SAT Year Schedule").get.scheduleWeeks
    assert_equal(["SAT Week Schedule High", "SAT Week Schedule Low", "SAT Week Schedule High"], southern_weeks.map { |w| w.name.to_s })

    # the zone setpoint schedules themselves stay untouched
    zone_heating_sched = model.getScheduleRulesetByName("ZoneHeatingTempSched").get
    assert_equal([20.0], zone_heating_sched.scheduleRules.find(&:applyMonday).daySchedule.values.uniq)
  end

  def test_fan_flow_fraction_schedule_applied
    args_hash = {}
    # fractional Betriebszeiten: off at night, 30 % flow in the morning, full flow during the day
    hvacSched = ((["0"] * 20) + (["0.3"] * 12) + (["1"] * 40) + (["0"] * 24)).join(";")
    heatingSched = " 20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20"
    coolingSched = " 25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25"
    args_hash["heat_recovery_method"] = "none"
    args_hash["ach_per_hour"] = 2.0
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
    args_hash["system_type"] = 2

    dir = __dir__
    model = OpenModel(dir)
    result = TestArguments(AddDetailedHVAC.new, model, args_hash)

    assert_equal("Success", result.value.valueName)
    assert(result.errors.empty?)

    # both the supply fan and the return fan get an EMS override for system_type 2
    actuators = model.getEnergyManagementSystemActuators
    assert_equal(2, actuators.size)
    actuators.each do |actuator|
      assert_equal("Fan", actuator.actuatedComponentType)
      assert_equal("Fan Air Mass Flow Rate", actuator.actuatedComponentControlType)
    end

    assert_equal(2, model.getEnergyManagementSystemPrograms.size)
    assert_equal(2, model.getEnergyManagementSystemProgramCallingManagers.size)
    assert_equal(2, model.getEnergyManagementSystemSensors.size) # one HVACSched sensor per fan
    assert_equal(2, model.getEnergyManagementSystemInternalVariables.size)

    # the fractional schedule must still be accepted as the fans' availability schedule,
    # and the EMS sensors read that same schedule as the flow fraction
    hvac_sched = model.getFanConstantVolumeByName("Supply Fan").get.availabilitySchedule.to_ScheduleRuleset.get
    assert_equal(hvac_sched.handle, model.getFanConstantVolumeByName("Return Fan").get.availabilitySchedule.handle)
    assert_equal("HVAC Operation Fraction", hvac_sched.scheduleTypeLimits.get.name.to_s)
    model.getEnergyManagementSystemSensors.each do |sensor|
      assert_equal(hvac_sched.name.to_s, sensor.keyName)
    end
    weekday_rule = hvac_sched.scheduleRules.find { |r| r.applyMonday }
    assert(weekday_rule.daySchedule.values.include?(0.3))

    SaveModel(model, dir)
  end

  def test_fan_flow_fraction_schedule_return_fan_only
    args_hash = {}
    hvacSched = " 0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0"
    heatingSched = " 20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20"
    coolingSched = " 25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25"
    args_hash["heat_recovery_method"] = "none"
    args_hash["ach_per_hour"] = 2.0
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
    args_hash["system_type"] = 1

    dir = __dir__
    model = OpenModel(dir)
    result = TestArguments(AddDetailedHVAC.new, model, args_hash)

    assert_equal("Success", result.value.valueName)
    assert(result.errors.empty?)

    # only the return/exhaust fan exists for system_type 1
    assert_equal(1, model.getEnergyManagementSystemActuators.size)
    assert_equal(1, model.getEnergyManagementSystemPrograms.size)

    SaveModel(model, dir)
  end

  def teardown
    # nothing to do here for such a simple measure
  end
end
