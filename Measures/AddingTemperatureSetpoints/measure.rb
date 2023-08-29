require_relative '../NewHelper.rb'

# start the measure
class AddingTemperatureSetpoints < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "AddingTemperatureSetpoints"
  end

  # human readable description
  def description
    return ""
  end

  # human readable description of modeling approach
  def modeler_description
    return ""
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    args << OpenStudio::Measure::OSArgument.makeStringArgument("heatingTemp", false)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("coolingTemp", false)
    args << OpenStudio::Measure::OSArgument.makeBoolArgument("is_custom_heating", false)
    args << OpenStudio::Measure::OSArgument.makeBoolArgument("is_custom_cooling", false)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zoneHeatingTempScheduleWerktag", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zoneHeatingTempScheduleSamstag", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zoneHeatingTempScheduleSonntag", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zoneHeatingTempScheduleFeiertag", false)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zoneCoolingTempScheduleWerktag", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zoneCoolingTempScheduleSamstag", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zoneCoolingTempScheduleSonntag", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zoneCoolingTempScheduleFeiertag", false)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("Holidays", false)
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    holidays = runner.getStringArgumentValue("Holidays", user_arguments)
    zoneHeatingTempSchedWeekday = runner.getStringArgumentValue("zoneHeatingTempScheduleWerktag", user_arguments)
    zoneHeatingTempSchedSaturday = runner.getStringArgumentValue("zoneHeatingTempScheduleSamstag", user_arguments)
    zoneHeatingTempSchedSunday = runner.getStringArgumentValue("zoneHeatingTempScheduleSonntag", user_arguments)
    zoneHeatingTempSchedFeiertag = runner.getStringArgumentValue("zoneHeatingTempScheduleFeiertag", user_arguments)
    zoneCoolingTempSchedWeekday = runner.getStringArgumentValue("zoneCoolingTempScheduleWerktag", user_arguments)
    zoneCoolingTempSchedSaturday = runner.getStringArgumentValue("zoneCoolingTempScheduleSamstag", user_arguments)
    zoneCoolingTempSchedSunday = runner.getStringArgumentValue("zoneCoolingTempScheduleSonntag", user_arguments)
    zoneCoolingTempSchedFeiertag = runner.getStringArgumentValue("zoneCoolingTempScheduleFeiertag", user_arguments)

    zoneHeatingTempSched = CreateSchedule(model, "ZoneHeatingTempSched", zoneHeatingTempSchedWeekday, zoneHeatingTempSchedSaturday, zoneHeatingTempSchedSunday, zoneHeatingTempSchedFeiertag, holidays, false, true)
    zoneCoolingTempSched = CreateSchedule(model, "ZoneCoolingTempSched", zoneCoolingTempSchedWeekday, zoneCoolingTempSchedSaturday, zoneCoolingTempSchedSunday, zoneCoolingTempSchedFeiertag, holidays)

    number_zones_modified = 0
    total_cost = 0
    if zoneHeatingTempSched or zoneCoolingTempSched
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
            if not oldThermostat.heatingSetpointTemperatureSchedule.empty?
              thermostatSetpointDualSetpoint.setHeatingSetpointTemperatureSchedule(oldThermostat.heatingSetpointTemperatureSchedule.get)
            end
            if not oldThermostat.coolingSetpointTemperatureSchedule.empty?
              thermostatSetpointDualSetpoint.setCoolingSetpointTemperatureSchedule(oldThermostat.coolingSetpointTemperatureSchedule.get)
            end
            zone.setThermostatSetpointDualSetpoint(thermostatSetpointDualSetpoint)
          end
        end
        
        if zoneHeatingTempSched
          if not thermostatSetpointDualSetpoint.setHeatingSetpointTemperatureSchedule(zoneHeatingTempSched)
            runner.registerError("Script Error - cannot set heating schedule for thermal zone '#{zone.name}'.")
            return false
          end
        end
        
        if zoneCoolingTempSched
          if not thermostatSetpointDualSetpoint.setCoolingSetpointTemperatureSchedule(zoneCoolingTempSched)
            runner.registerError("Script Error - cannot set cooling schedule for thermal zone '#{zone.name}'.")
            return false
          end
        end
        
        number_zones_modified += 1
      end
    end
    
    runner.registerFinalCondition("Replaced thermostats for #{number_zones_modified} thermal zones")                   

    if number_zones_modified == 0
      runner.registerAsNotApplicable("No thermostats altered")
    end
    
    return true
  end
end

# register the measure to be used by the application
AddingTemperatureSetpoints.new.registerWithApplication
