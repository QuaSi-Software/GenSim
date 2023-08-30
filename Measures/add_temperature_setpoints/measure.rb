# frozen_string_literal: true

require_relative "../NewHelper.rb"

# start the measure
class AddTemperatureSetpoints < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return "AddTemperatureSetpoints"
  end

  # general description of measure
  def description
    return "Add temperature setpoints."
  end

  # description for users of what the measure does and how it works
  def modeler_description
    return "Add temperature setpoints."
  end

  # define the arguments that the user will input
  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new
    args << OpenStudio::Measure::OSArgument.makeStringArgument("heating_temp_selection", false)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("cooling_temp_selection", false)
    args << OpenStudio::Measure::OSArgument.makeBoolArgument("is_custom_heating", false)
    args << OpenStudio::Measure::OSArgument.makeBoolArgument("is_custom_cooling", false)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zone_heating_temp_sched_weekday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zone_heating_temp_sched_saturday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zone_heating_temp_sched_sunday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zone_heating_temp_sched_holiday", false)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zone_cooling_temp_sched_weekday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zone_cooling_temp_sched_saturday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zone_cooling_temp_sched_sunday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zone_cooling_temp_sched_holiday", false)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("holidays", false)
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    holidays = runner.getStringArgumentValue("holidays", user_arguments)
    zone_heating_temp_sched_weekday = runner.getStringArgumentValue("zone_heating_temp_sched_weekday", user_arguments)
    zone_heating_temp_sched_saturday = runner.getStringArgumentValue("zone_heating_temp_sched_saturday", user_arguments)
    zone_heating_temp_sched_sunday = runner.getStringArgumentValue("zone_heating_temp_sched_sunday", user_arguments)
    zone_heating_temp_sched_holiday = runner.getStringArgumentValue("zone_heating_temp_sched_holiday", user_arguments)
    zone_cooling_temp_sched_weekday = runner.getStringArgumentValue("zone_cooling_temp_sched_weekday", user_arguments)
    zone_cooling_temp_sched_saturday = runner.getStringArgumentValue("zone_cooling_temp_sched_saturday", user_arguments)
    zone_cooling_temp_sched_sunday = runner.getStringArgumentValue("zone_cooling_temp_sched_sunday", user_arguments)
    zone_cooling_temp_sched_holiday = runner.getStringArgumentValue("zone_cooling_temp_sched_holiday", user_arguments)

    zoneHeatingTempSched = CreateSchedule(model, "ZoneHeatingTempSched", zone_heating_temp_sched_weekday, zone_heating_temp_sched_saturday, zone_heating_temp_sched_sunday, zone_heating_temp_sched_holiday, holidays, false, true)
    zoneCoolingTempSched = CreateSchedule(model, "ZoneCoolingTempSched", zone_cooling_temp_sched_weekday, zone_cooling_temp_sched_saturday, zone_cooling_temp_sched_sunday, zone_cooling_temp_sched_holiday, holidays)

    number_zones_modified = 0
    if zoneHeatingTempSched || zoneCoolingTempSched
      model.getThermalZones.each do |zone|
        thermostatSetpointDualSetpoint = zone.thermostatSetpointDualSetpoint
        if thermostatSetpointDualSetpoint.empty?
          runner.registerInfo("Creating thermostat for thermal zone '#{zone.name}'.")

          thermostatSetpointDualSetpoint = OpenStudio::Model::ThermostatSetpointDualSetpoint.new(model)
          zone.setThermostatSetpointDualSetpoint(thermostatSetpointDualSetpoint)
        else
          thermostatSetpointDualSetpoint = thermostatSetpointDualSetpoint.get

          # make sure this thermostat is unique to this zone
          if thermostatSetpointDualSetpoint.getSources("OS_ThermalZone".to_IddObjectType).size > 1
            # if not create a new copy
            runner.registerInfo("Copying thermostat for thermal zone '#{zone.name}'.")

            oldThermostat = thermostatSetpointDualSetpoint
            thermostatSetpointDualSetpoint = OpenStudio::Model::ThermostatSetpointDualSetpoint.new(model)
            unless oldThermostat.heatingSetpointTemperatureSchedule.empty?
              thermostatSetpointDualSetpoint.setHeatingSetpointTemperatureSchedule(oldThermostat.heatingSetpointTemperatureSchedule.get)
            end
            unless oldThermostat.coolingSetpointTemperatureSchedule.empty?
              thermostatSetpointDualSetpoint.setCoolingSetpointTemperatureSchedule(oldThermostat.coolingSetpointTemperatureSchedule.get)
            end
            zone.setThermostatSetpointDualSetpoint(thermostatSetpointDualSetpoint)
          end
        end

        if zoneHeatingTempSched
          unless thermostatSetpointDualSetpoint.setHeatingSetpointTemperatureSchedule(zoneHeatingTempSched)
            runner.registerError("Script Error - cannot set heating schedule for thermal zone '#{zone.name}'.")
            return false
          end
        end

        if zoneCoolingTempSched
          unless thermostatSetpointDualSetpoint.setCoolingSetpointTemperatureSchedule(zoneCoolingTempSched)
            runner.registerError("Script Error - cannot set cooling schedule for thermal zone '#{zone.name}'.")
            return false
          end
        end

        number_zones_modified += 1
      end
    end

    runner.registerFinalCondition("Replaced thermostats for #{number_zones_modified} thermal zones")

    runner.registerAsNotApplicable("No thermostats altered") if number_zones_modified == 0

    return true
  end
end

# register the measure to be used by the application
AddTemperatureSetpoints.new.registerWithApplication
