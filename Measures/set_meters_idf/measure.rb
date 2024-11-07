# frozen_string_literal: true
require 'json'

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
    sizingHeatingFactor.setDefaultValue("1.25")
    args << sizingHeatingFactor
    sizingCoolingFactor = OpenStudio::Measure::OSArgument.makeDoubleArgument("cooling_sizing_factor", false)
    sizingCoolingFactor.setDefaultValue("1.15")
    args << sizingCoolingFactor
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
      runner.registerInfo("Procesing schedule #{schedule.name}")
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
      outputvariable.remove
    end

    # read variable and meter definitions from data file and create the objects
    file_content = File.read('../../../Measures/set_meters_idf/output_variables.json')
    variable_definitions = JSON.parse(file_content)

    variable_definitions.each do |var_def|
      if var_def["create_output_variable"]
        if var_def["node_reference"] == ""
          create_variable(var_def["name"], reportingInterval, workspace)
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

    # set diagnostics to display all warnings and report on all variables
    new_diagnostic_string = "
      Output:Diagnostics,
        DisplayAllWarnings,
        DisplayAdvancedReportVariables;    !- Key 1
        "
    idfObject = OpenStudio::IdfObject.load(new_diagnostic_string)
    workspace.addObject(idfObject.get)

    # edit ideal loads objects to set the timestep
    newTimesteps = workspace.getObjectsByType("Timestep".to_IddObjectType)
    newTimesteps.each do |newTimestep|
      newTimestep.setInt(0, timestep)
      workspace.insertObject(newTimestep)
    end

    # set parameters of sizing calculation
    sizingZones = workspace.getObjectsByType("Sizing:Zone".to_IddObjectType)
    sizingZones.each do |sizingZone|
      # sizingZone.setDouble(11, 2) # Zone Cooling Sizing Factor
      sizingZone.setString(23, "Yes") # A ccount for Dedicated Outdoor Air System
      sizingZone.setString(24, "NeutralSupplyAir") # Dedicated Outdoor Air System Control Strategy
      sizingZone.setDouble(25, -12.7) # Dedicated Outdoor Air Low Setpoint Temperature for Design {C}
      sizingZone.setDouble(26, 30) # Dedicated Outdoor Air High Setpoint Temperature for Design {C}
      workspace.insertObject(sizingZone)
    end

    # set reporting for tolerances
    new_reporting_string = "
      OutputControl:ReportingTolerances,
        1,
        1;"
    idfObject = OpenStudio::IdfObject.load(new_reporting_string)
    workspace.addObject(idfObject.get)

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
