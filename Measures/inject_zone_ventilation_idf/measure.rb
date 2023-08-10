# start the measure
class InjectZoneVentilationIDF < OpenStudio::Measure::EnergyPlusMeasure

  # human readable name
  def name
    return "InjectZoneVentilationIDF"
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
  def arguments(workspace)
    args = OpenStudio::Measure::OSArgumentVector.new

    args << OpenStudio::Measure::OSArgument.makeDoubleArgument("air_changes", true)
    args << OpenStudio::Measure::OSArgument.makeDoubleArgument("min_indoor_temperature", true)
    args << OpenStudio::Measure::OSArgument.makeDoubleArgument("temperature_difference", true)

    return args
  end

  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end

    # assign the user inputs to variables
    ventilationACH = runner.getDoubleArgumentValue("air_changes", user_arguments)
    minIndoorTemperature = runner.getDoubleArgumentValue("min_indoor_temperature", user_arguments)
    deltaT = runner.getDoubleArgumentValue("temperature_difference", user_arguments)

    # get all thermal zones in the starting model
    zones = workspace.getObjectsByType("Zone".to_IddObjectType)

    # reporting initial condition of model
    runner.registerInitialCondition("The building started with #{zones.size} zones.")

    # first we built a list of perimeter zones
    perimeterZones = Array.new
    bPerimeterZonesFound = false
    zones.each do |zone|
      if zone.name.to_s.include? "Perimeter"
        perimeterZones << zone
        bPerimeterZonesFound = true
      end
    end

    if !bPerimeterZonesFound
      zones.each do |zone|
        if zone.name.to_s.include? "EXT-"
          perimeterZones << zone
          bPerimeterZonesFound = true
        end
      end
    end

    runner.registerInfo("We found #{perimeterZones.size} perimeter zones")
    if !bPerimeterZonesFound
      perimeterZones = zones
      runner.registerInfo("Using all zones since we did not find any perimeter zones.")
    end

    perimeterZones.each do |zone|
      zoneVent = OpenStudio::IdfObject.new("ZoneVentilation:DesignFlowRate".to_IddObjectType)
      zoneVent.setString(0, "#{zone.name} - Window Ventilation")
      zoneVent.setString(1, zone.name.to_s)
      zoneVent.setString(2, "PeopleSchedule")
      zoneVent.setString(3, "AirChanges/Hour")
      zoneVent.setDouble(7, ventilationACH)
      zoneVent.setString(8, "Natural")
      zoneVent.setDouble(11, 1)
      zoneVent.setDouble(12, 0)
      zoneVent.setDouble(13, 0)
      zoneVent.setDouble(14, 0)
      zoneVent.setDouble(15, minIndoorTemperature)
      zoneVent.setDouble(19, deltaT)
      workspace.addObject(zoneVent)
    end

    # report final condition of model
    zoneVentilation = workspace.getObjectsByType("ZoneVentilation:DesignFlowRate".to_IddObjectType)
    runner.registerFinalCondition("The building finished with #{zoneVentilation.size} ZoneVentilation objects.")

    return true
  end
end

# register the measure to be used by the application
InjectZoneVentilationIDF.new.registerWithApplication
