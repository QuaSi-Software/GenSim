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

    # assign the user inputs to variables
    timestep = runner.getIntegerArgumentValue("time_step", user_arguments)
    heatingSizingFactor = runner.getDoubleArgumentValue("heating_sizing_factor", user_arguments)
    coolingSizingFactor = runner.getDoubleArgumentValue("cooling_sizing_factor", user_arguments)
    dayToStartSimulation = runner.getStringArgumentValue("day_to_start_simulation", user_arguments)

    customMeters = workspace.getObjectsByType("Meter:Custom".to_IddObjectType)
    runner.registerInitialCondition("The building started with #{customMeters.size} Custom Meters with version #{workspace.version.str}.")

    sizingParams = workspace.getObjectsByType("Sizing:Parameters".to_IddObjectType)
    sizingParams.each do |sizingParam|
      sizingParam.setDouble(0, heatingSizingFactor)
      sizingParam.setDouble(1, coolingSizingFactor)
    end

    # fix the schedule bug!!!
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

    #----------custom meters
    #-------------------------------------------------------

    reportingInterval = "Hourly"
    reportingInterval = "Timestep" if timestep < 60

    runner.registerInfo("Trying to remove variables")
    # delete the output:variables we do not need them and did not ask for them!!!
    outputvariables = workspace.getObjectsByType("Output:Variable".to_IddObjectType)
    outputvariables.each do |outputvariable|
      runner.registerInfo("The following variable was removed: " + outputvariable.getString(0).to_s)
      workspace.removeObject(outputvariable.idfObject.handle)
      outputvariable.remove
    end

    file_content = File.read('../../../Measures/set_meters_idf/output_variables.json')
    variable_definitions = JSON.parse(file_content)

    variable_definitions.each do |var_def|
      if var_def["create_custom_meter"]
        create_custom_meter(var_def["name"], var_def["eplus_variables"], workspace)
      end
      if var_def["create_output_meter"]
        create_output_meter(var_def["name"], reportingInterval, workspace)
      end
    end

    eplusVariables = [
      "Zone Mechanical Ventilation No Load Heat Removal Energy",
      "Zone Mechanical Ventilation Cooling Load Increase Energy",
      "Zone Mechanical Ventilation Cooling Load Increase Due to Overheating Energy",
      "Zone Mechanical Ventilation Cooling Load Decrease Energy" ,
      "Zone Mechanical Ventilation No Load Heat Addition Energy",
      "Zone Mechanical Ventilation Heating Load Increase Energy",
      "Zone Mechanical Ventilation Heating Load Increase Due to Overcooling Energy",
      "Zone Mechanical Ventilation Heating Load Decrease Energy" ,
      "Air System Heat Exchanger Total Heating Energy",
      "Air System Heat Exchanger Total Cooling Energy",
      "Zone Windows Total Transmitted Solar Radiation Energy",
      "Zone Windows Total Heat Gain Energy",
      "Zone Windows Total Heat Loss Energy",
      "Surface Average Face Conduction Heat Gain Rate",
      "Surface Average Face Conduction Heat Loss Rate",
      "Surface Outside Face Conduction Heat Gain Rate",
      "Surface Outside Face Conduction Heat Loss Rate",
      "Surface Inside Face Conduction Heat Gain Rate",
      "Surface Inside Face Conduction Heat Loss Rate",
      "Surface Outside Face Convection Heat Gain Rate",
      "Surface Inside Face Convection Heat Gain Rate",
      "Zone Air Heat Balance Internal Convective Heat Gain Rate",
      "Zone Air Heat Balance Surface Convection Rate",
      "Zone Air Heat Balance Interzone Air Transfer Rate",
      "Zone Air Heat Balance Outdoor Air Transfer Rate",
      "Zone Air Heat Balance System Air Transfer Rate",
      "Zone Air Heat Balance System Convective Heat Gain Rate",
      "Zone Air Heat Balance Air Energy Storage Rate",
      "Zone Air Heat Balance Deviation Rate"
    ]
    eplusVariables.each{ |name|
      create_variable(name, reportingInterval, workspace)
      create_custom_meter(name, [name], workspace)
      create_output_meter(name, reportingInterval, workspace)
    }

    create_variable_with_key("Outside Air Node", "System Node Temperature", reportingInterval, workspace)
    create_variable_with_key("Outside Air Node", "System Node Mass Flow Rate", reportingInterval, workspace)
    create_variable_with_key("Outside Air Node", "System Node Specific Heat", reportingInterval, workspace)
    create_variable_with_key("Outside Air Node", "System Node Enthalpy", reportingInterval, workspace)
    create_variable_with_key("Outside Relief Node", "System Node Temperature", reportingInterval, workspace)
    create_variable_with_key("Outside Relief Node", "System Node Mass Flow Rate", reportingInterval, workspace)
    create_variable_with_key("Outside Relief Node", "System Node Specific Heat", reportingInterval, workspace)
    create_variable_with_key("Outside Relief Node", "System Node Enthalpy", reportingInterval, workspace)

    create_variable("Zone Mechanical Ventilation Mass Flow Rate", reportingInterval, workspace)

    # make new string
    new_diagnostic_string = "
      Output:Diagnostics,
        DisplayAllWarnings,
        DisplayAdvancedReportVariables;    !- Key 1
        "

    # adding here the meters again, not sure why this is not working from the CreateEmptyModel Measure
    meters = []
    meters << "DistrictHeating:Facility"
    meters << "DistrictCooling:Facility"
    meters << "InteriorLights:Electricity"
    meters << "InteriorEquipment:Electricity"
    meters << "ElectricityProduced:Plant"
    meters << "Electricity:Facility"
    meters << "Photovoltaic:ElectricityProduced"
    meters << "Fans:Electricity"
    meters << "Pumps:Electricity"
    # add meters
    meters.each do |meter|
      newMeter = OpenStudio::IdfObject.new("Output:Meter".to_IddObjectType)
      newMeter.setString(0, meter)
      newMeter.setString(1, reportingInterval)
      workspace.insertObject(newMeter)
    end

    # Report Variable "Zone Mean Air Temperature"
    varZoneMeanAirTemp = OpenStudio::IdfObject.new("Output:Variable".to_IddObjectType)
    varZoneMeanAirTemp.setString(0, "*")
    varZoneMeanAirTemp.setString(1, "Zone Mean Air Temperature")
    varZoneMeanAirTemp.setString(2, reportingInterval)
    workspace.insertObject(varZoneMeanAirTemp)

    # Report Variable "Zone Heating Setpoint Not Met Time"
    varZoneMeanAirTemp = OpenStudio::IdfObject.new("Output:Variable".to_IddObjectType)
    varZoneMeanAirTemp.setString(0, "*")
    varZoneMeanAirTemp.setString(1, "Zone Heating Setpoint Not Met Time")
    varZoneMeanAirTemp.setString(2, reportingInterval)
    workspace.insertObject(varZoneMeanAirTemp)

    # Report Variable "Zone Heating Setpoint Not Met While Occupied Time"
    varZoneMeanAirTemp = OpenStudio::IdfObject.new("Output:Variable".to_IddObjectType)
    varZoneMeanAirTemp.setString(0, "*")
    varZoneMeanAirTemp.setString(1, "Zone Heating Setpoint Not Met While Occupied Time")
    varZoneMeanAirTemp.setString(2, reportingInterval)
    workspace.insertObject(varZoneMeanAirTemp)

    # Report Variable "Zone Cooling Setpoint Not Met Time"
    varZoneMeanAirTemp = OpenStudio::IdfObject.new("Output:Variable".to_IddObjectType)
    varZoneMeanAirTemp.setString(0, "*")
    varZoneMeanAirTemp.setString(1, "Zone Cooling Setpoint Not Met Time")
    varZoneMeanAirTemp.setString(2, reportingInterval)
    workspace.insertObject(varZoneMeanAirTemp)

    # Report Variable "Zone Cooling Setpoint Not Met While Occupied Time"
    varZoneMeanAirTemp = OpenStudio::IdfObject.new("Output:Variable".to_IddObjectType)
    varZoneMeanAirTemp.setString(0, "*")
    varZoneMeanAirTemp.setString(1, "Zone Cooling Setpoint Not Met While Occupied Time")
    varZoneMeanAirTemp.setString(2, reportingInterval)
    workspace.insertObject(varZoneMeanAirTemp)

    # Report Variable "Facility Heating Setpoint Not Met Time"
    varZoneMeanAirTemp = OpenStudio::IdfObject.new("Output:Variable".to_IddObjectType)
    varZoneMeanAirTemp.setString(0, "*")
    varZoneMeanAirTemp.setString(1, "Facility Heating Setpoint Not Met Time")
    varZoneMeanAirTemp.setString(2, reportingInterval)
    workspace.insertObject(varZoneMeanAirTemp)

    # Report Variable "Facility Heating Setpoint Not Met While Occupied Time"
    varZoneMeanAirTemp = OpenStudio::IdfObject.new("Output:Variable".to_IddObjectType)
    varZoneMeanAirTemp.setString(0, "*")
    varZoneMeanAirTemp.setString(1, "Facility Heating Setpoint Not Met While Occupied Time")
    varZoneMeanAirTemp.setString(2, reportingInterval)
    workspace.insertObject(varZoneMeanAirTemp)

    # Report Variable "Facility Cooling Setpoint Not Met Time"
    varZoneMeanAirTemp = OpenStudio::IdfObject.new("Output:Variable".to_IddObjectType)
    varZoneMeanAirTemp.setString(0, "*")
    varZoneMeanAirTemp.setString(1, "Facility Cooling Setpoint Not Met Time")
    varZoneMeanAirTemp.setString(2, reportingInterval)
    workspace.insertObject(varZoneMeanAirTemp)

    # Report Variable "Facility Cooling Setpoint Not Met While Occupied Time"
    varZoneMeanAirTemp = OpenStudio::IdfObject.new("Output:Variable".to_IddObjectType)
    varZoneMeanAirTemp.setString(0, "*")
    varZoneMeanAirTemp.setString(1, "Facility Cooling Setpoint Not Met While Occupied Time")
    varZoneMeanAirTemp.setString(2, reportingInterval)
    workspace.insertObject(varZoneMeanAirTemp)

    newTimesteps = workspace.getObjectsByType("Timestep".to_IddObjectType)
    # edit ideal loads objects
    newTimesteps.each do |newTimestep|
      newTimestep.setInt(0, timestep)
      workspace.insertObject(newTimestep)
    end

    # sizingParams = workspace.getObjectsByType("Sizing:Parameters".to_IddObjectType)
    # sizingParams.each do |sizingParam|
    #  sizingParam.setDouble(0,2)
    #  workspace.insertObject(sizingParam)
    # end

    sizingZones = workspace.getObjectsByType("Sizing:Zone".to_IddObjectType)
    sizingZones.each do |sizingZone|
      # sizingZone.setDouble(11, 2) # Zone Cooling Sizing Factor
      sizingZone.setString(23, "Yes") # A ccount for Dedicated Outdoor Air System
      sizingZone.setString(24, "NeutralSupplyAir") # Dedicated Outdoor Air System Control Strategy
      sizingZone.setDouble(25, -12.7) # Dedicated Outdoor Air Low Setpoint Temperature for Design {C}
      sizingZone.setDouble(26, 30) # Dedicated Outdoor Air High Setpoint Temperature for Design {C}
      workspace.insertObject(sizingZone)
    end

    # make new string
    new_reporting_string = "
      OutputControl:ReportingTolerances,
        1,
        1;"

    # make new object from string
    idfObject = OpenStudio::IdfObject.load(new_reporting_string)
    object = idfObject.get
    workspace.addObject(object)

    newRunPeriods = workspace.getObjectsByType("RunPeriod".to_IddObjectType)
    # edit ideal loads objects
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

    # make new object from string
    idfObject = OpenStudio::IdfObject.load(new_diagnostic_string)
    object = idfObject.get
    workspace.addObject(object)

    # idealloads = workspace.getObjectsByType("HVACTemplate:Zone:IdealLoadsAirSystem".to_IddObjectType)
    customMeters = workspace.getObjectsByType("Meter:Custom".to_IddObjectType)
    runner.registerFinalCondition("The building finished with #{customMeters.size} Custom Meters with version #{workspace.version.str}.")

    return true
  end
end

# register the measure to be used by the application
SetMetersIDF.new.registerWithApplication
