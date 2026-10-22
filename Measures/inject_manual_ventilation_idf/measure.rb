# frozen_string_literal: true

# start the measure
class InjectManualVentilationIDF < OpenStudio::Measure::EnergyPlusMeasure
  # human readable name
  def name
    return "InjectManualVentilationIDF"
  end

  # general description of measure
  def description
    return "Inject manual window ventilation."
  end

  # description for users of what the measure does and how it works
  def modeler_description
    return "Inject manual window ventilation."
  end

  # define the arguments that the user will input
  def arguments(_workspace)
    args = OpenStudio::Measure::OSArgumentVector.new

    args << OpenStudio::Measure::OSArgument.makeDoubleArgument("air_changes", true)

    dtsS = OpenStudio::Measure::OSArgument.makeStringArgument("infiltration_type", false)
    dtsS.setDefaultValue("BLAST")
    args << dtsS

    return args
  end

  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # use the built-in error checking
    return false unless runner.validateUserArguments(arguments(workspace), user_arguments)

    # assign the user inputs to variables
    ventilationACH = runner.getDoubleArgumentValue("air_changes", user_arguments)
    infiltration_type = runner.getStringArgumentValue("infiltration_type", user_arguments)

    # get all thermal zones in the starting model
    zones = workspace.getObjectsByType("Zone".to_IddObjectType)

    # reporting initial condition of model
    runner.registerInitialCondition("The building started with #{zones.size} zones.")

    # first we built a list of perimeter zones
    perimeterZones = []
    bPerimeterZonesFound = false
    zones.each do |zone|
      if zone.name.to_s.include? "Perimeter"
        perimeterZones << zone
        bPerimeterZonesFound = true
      end
    end

    unless bPerimeterZonesFound
      zones.each do |zone|
        if zone.name.to_s.include? "EXT-"
          perimeterZones << zone
          bPerimeterZonesFound = true
        end
      end
    end

    runner.registerInfo("We found #{perimeterZones.size} perimeter zones")
    unless bPerimeterZonesFound
      perimeterZones = zones
      runner.registerInfo("Using all zones since we did not find any perimeter zones.")
    end

    perimeterZones.each do |zone|
      zoneVent = OpenStudio::IdfObject.new("ZoneVentilation:DesignFlowRate".to_IddObjectType)
      zoneVent.setString(0, "#{zone.name} - Manual Ventilation")
      zoneVent.setString(1, zone.name.to_s)
      zoneVent.setString(2, "ManualVentilationSchedule")
      zoneVent.setString(3, "AirChanges/Hour")
      zoneVent.setDouble(7, ventilationACH)
      zoneVent.setString(8, "Natural")
      if infiltration_type == "BLAST"
          zoneVent.setDouble(11, 0.606)
          zoneVent.setDouble(12, 0.03636)
          zoneVent.setDouble(13, 0.1177)
          zoneVent.setDouble(14, 0)
      elsif infiltration_type == "DOE2"
          zoneVent.setDouble(11, 0)
          zoneVent.setDouble(12, 0)
          zoneVent.setDouble(13, 0.224)
          zoneVent.setDouble(14, 0)
      else
          zoneVent.setDouble(11, 1)
          zoneVent.setDouble(12, 0)
          zoneVent.setDouble(13, 0)
          zoneVent.setDouble(14, 0)
      end
      zoneVent.setDouble(15, -100)
      zoneVent.setDouble(19, -100)
      workspace.addObject(zoneVent)
    end

    # report final condition of model
    zoneVentilation = workspace.getObjectsByType("ZoneVentilation:DesignFlowRate".to_IddObjectType)
    runner.registerFinalCondition("The building finished with #{zoneVentilation.size} Manual ZoneVentilation objects.")

    return true
  end
end

# register the measure to be used by the application
InjectManualVentilationIDF.new.registerWithApplication
