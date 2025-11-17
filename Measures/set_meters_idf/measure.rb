# frozen_string_literal: true
require_relative '../output_variables'

# start the measure
class SetMetersIDF < OpenStudio::Measure::EnergyPlusMeasure
  # human readable name
  def name
    return "SetMetersIDF"
  end

  # general description of measure
  def description
    return "Adds meter objects for outputting."
  end

  # description for users of what the measure does and how it works
  def modeler_description
    return "Adds meter objects for outputting."
  end

  # define the arguments that the user will input
  def arguments(_workspace)
    args = OpenStudio::Measure::OSArgumentVector.new

    args << OpenStudio::Measure::OSArgument.makeIntegerArgument("time_step", true)
    dtsS = OpenStudio::Measure::OSArgument.makeStringArgument("day_to_start_simulation", false)
    dtsS.setDefaultValue("UseWeatherFile")

    args << dtsS
    sizingHeatingFactor = OpenStudio::Measure::OSArgument.makeDoubleArgument("heating_sizing_factor", false)
    sizingHeatingFactor.setDefaultValue(1.25)
    args << sizingHeatingFactor

    sizingCoolingFactor = OpenStudio::Measure::OSArgument.makeDoubleArgument("cooling_sizing_factor", false)
    sizingCoolingFactor.setDefaultValue(1.15)
    args << sizingCoolingFactor

    outputLevel = OpenStudio::Measure::OSArgument.makeStringArgument("output_level", false)
    outputLevel.setDefaultValue("Normal")
    args << outputLevel

    return args
  end

  def create_variable(variable_name, reportingInterval, workspace)
    var = OpenStudio::IdfObject.new("Output:Variable".to_IddObjectType)
    var.setString(0, "*")
    var.setString(1, variable_name)
    var.setString(2, reportingInterval)
    workspace.insertObject(var)
  end

  def create_variable_with_key(key_name, variable_name, reportingInterval, workspace)
    var = OpenStudio::IdfObject.new("Output:Variable".to_IddObjectType)
    var.setString(0, key_name)
    var.setString(1, variable_name)
    var.setString(2, reportingInterval)
    workspace.insertObject(var)
  end

  def create_custom_meter(name, constituents, workspace)
    meter = OpenStudio::IdfObject.new("Meter:Custom".to_IddObjectType)
    meter.setString(0, "Meter " + name)
    meter.setString(1, "Generic")

    nr = 2
    idx = 0
    while idx < constituents.length
      meter.setString(nr, "*")
      nr += 1
      meter.setString(nr, constituents[idx])
      nr += 1
      idx += 1
    end

    workspace.insertObject(meter)
  end

  def create_output_meter(name, reporting_interval, workspace)
    meter = OpenStudio::IdfObject.new("Output:Meter".to_IddObjectType)
    meter.setString(0, "Meter " + name)
    meter.setString(1, reporting_interval)
    workspace.insertObject(meter)
  end

  def find_references(workspace, target_schedule)
    refs = []
    workspace.objects.each do |obj|
        obj.numFields.times do |i|
        field = obj.getString(i, true)
        if field.is_initialized && field.get == target_schedule.nameString
            refs << obj
            break
        end
        end
    end
    return refs
  end

  def find_references_by_handle(workspace, target_schedule)
      refs = []
      workspace.objects.each do |obj|
        obj.numFields.times do |i|
          ref = obj.getTarget(i)
          if ref.is_initialized && ref.get.handle == target_schedule.handle
            refs << obj
            break
          end
        end
      end
      return refs
  end




  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # use the built-in error checking
    return false unless runner.validateUserArguments(arguments(workspace), user_arguments)

    # read parameters
    timestep = runner.getIntegerArgumentValue("time_step", user_arguments)
    heatingSizingFactor = runner.getDoubleArgumentValue("heating_sizing_factor", user_arguments)
    coolingSizingFactor = runner.getDoubleArgumentValue("cooling_sizing_factor", user_arguments)
    dayToStartSimulation = runner.getStringArgumentValue("day_to_start_simulation", user_arguments)
    outputLevel = runner.getStringArgumentValue("output_level", user_arguments)

    customMeters = workspace.getObjectsByType("Meter:Custom".to_IddObjectType)
    runner.registerInitialCondition("The building started with #{customMeters.size} Custom Meters with version #{workspace.version.str}.")

    # set sizing factors from input parameters
    sizingParams = workspace.getObjectsByType("Sizing:Parameters".to_IddObjectType)
    sizingParams.each do |sizingParam|
      sizingParam.setDouble(0, heatingSizingFactor)
      sizingParam.setDouble(1, coolingSizingFactor)
    end

    # fixes a bug with schedules
    schedules = workspace.getObjectsByType("Schedule:Year".to_IddObjectType)
    schedules.each do |schedule|
      runner.registerInfo("Procesing schedule #{schedule.name} Number of fields: #{schedule.numFields}")
      refs = find_references_by_handle(workspace, schedule)
      if refs.empty?
        runner.registerInfo("Schedule #{schedule.nameString} is not used anywhere => delete it!")
        workspace.removeObject(schedule.idfObject.handle)
      else
        runner.registerInfo("Schedule #{schedule.nameString} is used by:")
        refs.each { |r| runner.registerInfo( "  #{r.nameString}") }
      end
      #if schedule.name.to_s == "SAT Year Schedule"
      #  schedule.setString(2, "SAT Week Schedule 10 deg C") # Correct schedule ref
      #  schedule.setDouble(3, 1)
      #  schedule.setDouble(4, 1)
      #  schedule.setDouble(5, 12)
      #  schedule.setDouble(6, 31)
      #  runner.registerInfo("Procesing schedule #{schedule.name}")
      #  workspace.insertObject(schedule)
      #end
      next unless schedule.name.to_s != "SAT Year Schedule"
      next unless schedule.numFields > 7
      runner.registerInfo("  Replacing week schedule #{schedule.getString(3)} with  #{schedule.getString(7)}")
      schedule.setString(2, schedule.getString(7).to_s) # Correct schedule ref
      runner.registerInfo("Procesing schedule #{schedule.name}")
      workspace.insertObject(schedule)
    end

    reportingInterval = "Hourly"
    reportingInterval = "Timestep" if timestep < 60

    # delete existing Output:Variable objects
    runner.registerInfo("Trying to remove variables")
    outputvariables = workspace.getObjectsByType("Output:Variable".to_IddObjectType)
    outputvariables.each do |outputvariable|
      runner.registerInfo("The following variable was removed: " + outputvariable.getString(0).to_s)
      workspace.removeObject(outputvariable.idfObject.handle)
    end

    # create the output meters and variables from definitions
    get_output_variables(outputLevel).each do |var_def|
      if var_def["create_output_variable"]
        if var_def["node_reference"] == ""
          var_def["eplus_variables"].each do |var_name|
            create_variable(var_name, reportingInterval, workspace)
          end
        else
          create_variable_with_key(
            var_def["node_reference"],
            var_def["name"],
            reportingInterval,
            workspace
          )
        end
      end
      if var_def["create_custom_meter"]
        create_custom_meter(var_def["name"], var_def["eplus_variables"], workspace)
      end
      if var_def["create_output_meter"]
        create_output_meter(var_def["name"], reportingInterval, workspace)
      end
    end


    # first let's delete any diagnostics objects, since somewhere around 3.9.0 we get errors if we have two of them
    # Find all Output:Diagnostics objects
    diagnostics_objects = workspace.getObjectsByType("Output:Diagnostics".to_IddObjectType)

    # Delete each one
    diagnostics_objects.each do |obj|
        workspace.removeObject(obj.handle)
    end

    # set diagnostics to display all warnings and report on all variables
    new_diagnostic_string = "
      Output:Diagnostics,
        DisplayAllWarnings,
        DisplayAdvancedReportVariables;    !- Key 1
        "
    idfObject = OpenStudio::IdfObject.load(new_diagnostic_string)
    if idfObject.is_initialized
      workspace.addObject(idfObject.get)
    else
      runner.registerError("Failed to load IDF snippet with string : #{new_diagnostic_string}")
    end

    design_days = workspace.getObjectsByType("SizingPeriod:DesignDay".to_IddObjectType)
    if design_days.size <= 1
        # first remove the dummy design day
        design_days.each do |design_day|
            workspace.removeObject(design_day.handle)
        end
        # we get here, when we do not define any design days, hence we want to define the weather file condition type objects here
        idf_snippet = "
            SizingPeriod:WeatherFileConditionType,
            Extreme Summer Weather Period,     !- Name
            SummerExtreme;"

        idfObject = OpenStudio::IdfObject.load(idf_snippet)
        if idfObject.is_initialized
          workspace.addObject(idfObject.get)
        else
          runner.registerError("Failed to load IDF snippet with string : #{new_diagnostic_string}")
        end

         idf_snippet = "
            SizingPeriod:WeatherFileConditionType,
            Extreme Winter Weather Period,     !- Name
            WinterTypical; "

        idfObject = OpenStudio::IdfObject.load(idf_snippet)
        if idfObject.is_initialized
          workspace.addObject(idfObject.get)
        else
          runner.registerError("Failed to load IDF snippet with string : #{new_diagnostic_string}")
        end
    end

    # edit ideal loads objects to set the timestep
    newTimesteps = workspace.getObjectsByType("Timestep".to_IddObjectType)
    newTimesteps.each do |newTimestep|
      newTimestep.setInt(0, timestep)
      workspace.insertObject(newTimestep)
    end

    # get all air loops in model
    airLoopList = workspace.getObjectsByType("AirLoopHVAC".to_IddObjectType)

    # set parameters of sizing calculation
    sizingZones = workspace.getObjectsByType("Sizing:Zone".to_IddObjectType)
    sizingZones.each do |sizingZone|
        if airLoopList.size == 0
            runner.registerInfo("No vent type, no updates to the sizing zones")
        else
            runner.registerWarning("For all other system types.")
            # sizingZone.setDouble(11, 2) # Zone Cooling Sizing Factor
            sizingZone.setString(23, "Yes") # A ccount for Dedicated Outdoor Air System
            sizingZone.setString(24, "NeutralSupplyAir") # Dedicated Outdoor Air System Control Strategy
            sizingZone.setDouble(25, -12.7) # Dedicated Outdoor Air Low Setpoint Temperature for Design {C}
            sizingZone.setDouble(26, 30) # Dedicated Outdoor Air High Setpoint Temperature for Design {C}
            workspace.insertObject(sizingZone)
        end
    end

    # set reporting for tolerances
    new_reporting_string = "
      OutputControl:ReportingTolerances,
        1,
        1;"
    idfObject = OpenStudio::IdfObject.load(new_reporting_string)
    if idfObject.is_initialized
      workspace.addObject(idfObject.get)
    else
      runner.registerError("Failed to load IDF snippet with string : #{new_diagnostic_string}")
    end

    # edit ideal loads objects to set starting day of simulation
    newRunPeriods = workspace.getObjectsByType("RunPeriod".to_IddObjectType)
    newRunPeriods.each do |newRunPeriod|
      if workspace.version >= OpenStudio::VersionString.new(9, 0, 0)
        newRunPeriod.setString(7, dayToStartSimulation)
        newRunPeriod.setString(3, "")
        newRunPeriod.setString(6, "")
      else
        newRunPeriod.setString(5, dayToStartSimulation)
      end
      workspace.insertObject(newRunPeriod)
    end

    customMeters = workspace.getObjectsByType("Meter:Custom".to_IddObjectType)
    runner.registerFinalCondition("The building finished with #{customMeters.size} Custom Meters with version #{workspace.version.str}.")

    return true
  end
end

# register the measure to be used by the application
SetMetersIDF.new.registerWithApplication
