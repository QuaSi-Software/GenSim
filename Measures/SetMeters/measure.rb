# start the measure
class SetMeters < OpenStudio::Measure::EnergyPlusMeasure

  # human readable name
  def name
    return "SetMeters"
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

    args << OpenStudio::Measure::OSArgument::makeIntegerArgument("Timestep",true)
		dtsS = OpenStudio::Measure::OSArgument::makeStringArgument("DayToStartSimulation",false)
		dtsS.setDefaultValue("UseWeatherFile")
    args << dtsS
		sizingHeatingFactor = OpenStudio::Measure::OSArgument::makeDoubleArgument("HeatingSizingFactor",false)
		sizingHeatingFactor.setDefaultValue("1.25")
		args << sizingHeatingFactor
		sizingCoolingFactor = OpenStudio::Measure::OSArgument::makeDoubleArgument("CoolingSizingFactor",false)
		sizingCoolingFactor.setDefaultValue("1.15")
		args << sizingCoolingFactor
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
    timestep = runner.getIntegerArgumentValue("Timestep", user_arguments)
	heatingSizingFactor = runner.getDoubleArgumentValue("HeatingSizingFactor", user_arguments)
	coolingSizingFactor = runner.getDoubleArgumentValue("CoolingSizingFactor", user_arguments)
	dayToStartSimulation = runner.getStringArgumentValue("DayToStartSimulation", user_arguments)

	customMeters = workspace.getObjectsByType("Meter:Custom".to_IddObjectType)
 	runner.registerInitialCondition("The building started with #{customMeters.size} Custom Meters with version #{workspace.version().str()}.")

		sizingParams = workspace.getObjectsByType("Sizing:Parameters".to_IddObjectType)
		sizingParams.each do |sizingParam|
			sizingParam.setDouble(0, heatingSizingFactor)
			sizingParam.setDouble(1, coolingSizingFactor)
		end

   	#fix the schedule bug!!!
	 	schedules = workspace.getObjectsByType("Schedule:Year".to_IddObjectType)
	 	schedules.each do |schedule|
			runner.registerInfo("Procesing schedule #{schedule.name.to_s}")
			if(schedule.name.to_s != "SAT Year Schedule")
				if(schedule.numFields() > 7)
					runner.registerInfo("  Replacing week schedule #{schedule.getString(3).to_s} with  #{schedule.getString(7).to_s}")
					schedule.setString(2, schedule.getString(7).to_s) # Correct schedule ref
					runner.registerInfo("Procesing schedule #{schedule.name}")
					workspace.insertObject(schedule)
				end
			end
	 	end
	
		#----------custom meters
	 	#-------------------------------------------------------
	 
	 	reportingInterval = "Hourly"
	 	if timestep < 60
			reportingInterval = "Timestep"
	 	end
	 
	 runner.registerInfo("Trying to remove variables")
	 # delete the output:variables we do not need them and did not ask for them!!!
	 outputvariables = workspace.getObjectsByType("Output:Variable".to_IddObjectType)
	 outputvariables.each do |outputvariable|
		runner.registerInfo("The following variable was removed: " + outputvariable.getString(0).to_s)
		workspace.removeObject(outputvariable.idfObject().handle())	
		outputvariable.remove()
	 end
	 #-----conduction exterial walls (Total)
	 customMeterConductionExtSurf = OpenStudio::IdfObject.new("Meter:Custom".to_IddObjectType)
	 customMeterConductionExtSurf.setString(0, "Meter Surface Average Face Conduction Heat Transfer Energy")
	 customMeterConductionExtSurf.setString(1, "Generic")
	 customMeterConductionExtSurf.setString(2, "*")
	 customMeterConductionExtSurf.setString(3, "Surface Average Face Conduction Heat Transfer Energy")
	 workspace.insertObject(customMeterConductionExtSurf)
	 meterConductionExtSurf = OpenStudio::IdfObject.new("Output:Meter".to_IddObjectType)
	 meterConductionExtSurf.setString(0, "Meter Surface Average Face Conduction Heat Transfer Energy")
	 meterConductionExtSurf.setString(1, reportingInterval)
	 workspace.insertObject(meterConductionExtSurf)
	 
	 #customMeterConductionExtSurfGainRATE = OpenStudio::IdfObject.new("Meter:Custom".to_IddObjectType)
	 #customMeterConductionExtSurfGainRATE.setString(0, "Meter Surface Average Face Conduction Heat Gain Rate")
	 #customMeterConductionExtSurfGainRATE.setString(1, "Generic")
	 #customMeterConductionExtSurfGainRATE.setString(2, "*")
	 #customMeterConductionExtSurfGainRATE.setString(3, "Surface Average Face Conduction Heat Gain Rate")
	 #workspace.insertObject(customMeterConductionExtSurfGainRATE)
	 #meterConductionExtSurfGainRATE = OpenStudio::IdfObject.new("Output:Meter".to_IddObjectType)
	 #meterConductionExtSurfGainRATE.setString(0, "Meter Surface Average Face Conduction Heat Gain Rate")
	 #meterConductionExtSurfGainRATE.setString(1, reportingInterval)
	 #workspace.insertObject(meterConductionExtSurfGainRATE)
	 
	 #customMeterConductionExtSurfLOSSRATE = OpenStudio::IdfObject.new("Meter:Custom".to_IddObjectType)
	 #customMeterConductionExtSurfLOSSRATE.setString(0, "Meter Surface Average Face Conduction Heat Loss Rate")
	 #customMeterConductionExtSurfLOSSRATE.setString(1, "Generic")
	 #customMeterConductionExtSurfLOSSRATE.setString(2, "*")
	 #customMeterConductionExtSurfLOSSRATE.setString(3, "Surface Average Face Conduction Heat Loss Rate")
	 #workspace.insertObject(customMeterConductionExtSurfLOSSRATE)
	 #meterConductionExtSurfLOSSRATE = OpenStudio::IdfObject.new("Output:Meter".to_IddObjectType)
	 #meterConductionExtSurfLOSSRATE.setString(0, "Meter Surface Average Face Conduction Heat Loss Rate")
	 #meterConductionExtSurfLOSSRATE.setString(1, reportingInterval)
	 #workspace.insertObject(meterConductionExtSurfLOSSRATE)
	 
	 #-----conduction windows (losses)
	 # Const METER_TRANSMISSION_HEAT_LOSS = "SURFACE WINDOW HEAT LOSS ENERGY"
	 customMeterConductionWindowsLoss = OpenStudio::IdfObject.new("Meter:Custom".to_IddObjectType)
	 customMeterConductionWindowsLoss.setString(0, "Meter Surface Window Heat Loss Energy")
	 customMeterConductionWindowsLoss.setString(1, "Generic")
	 customMeterConductionWindowsLoss.setString(2, "*")
	 customMeterConductionWindowsLoss.setString(3, "Surface Window Heat Loss Energy")
	 workspace.insertObject(customMeterConductionWindowsLoss)
	 meterConductionWindowsLoss = OpenStudio::IdfObject.new("Output:Meter".to_IddObjectType)
	 meterConductionWindowsLoss.setString(0, "Meter Surface Window Heat Loss Energy")
	 meterConductionWindowsLoss.setString(1, reportingInterval)
	 workspace.insertObject(meterConductionWindowsLoss)
	 
	 #-----windows (solar gains)
	 # Const METER_WINDOW_HEAT_GAIN = "ZONE WINDOWS TOTAL HEAT GAIN ENERGY"
	 customMeterConductionWindowsGain = OpenStudio::IdfObject.new("Meter:Custom".to_IddObjectType)
	 customMeterConductionWindowsGain.setString(0, "Meter Zone Windows Total Heat Gain Energy")
	 customMeterConductionWindowsGain.setString(1, "Generic")
	 customMeterConductionWindowsGain.setString(2, "*")
	 customMeterConductionWindowsGain.setString(3, "Zone Windows Total Heat Gain Energy")
	 workspace.insertObject(customMeterConductionWindowsGain)
	 meterConductionWindowsGain = OpenStudio::IdfObject.new("Output:Meter".to_IddObjectType)
	 meterConductionWindowsGain.setString(0, "Meter Zone Windows Total Heat Gain Energy")
	 meterConductionWindowsGain.setString(1, reportingInterval)
	 workspace.insertObject(meterConductionWindowsGain)
	 
	 # Const METER_WINDOW_SURFACE_HEAT_GAIN = "SURFACE WINDOW HEAT GAIN ENERGY"
	 customMeterSolarGain = OpenStudio::IdfObject.new("Meter:Custom".to_IddObjectType)
	 customMeterSolarGain.setString(0, "Meter Surface Window Heat Gain Energy")
	 customMeterSolarGain.setString(1, "Generic")
	 customMeterSolarGain.setString(2, "*")
	 customMeterSolarGain.setString(3, "Surface Window Heat Gain Energy")
	 workspace.insertObject(customMeterSolarGain)
	 meterSolarGain = OpenStudio::IdfObject.new("Output:Meter".to_IddObjectType)
	 meterSolarGain.setString(0, "Meter Surface Window Heat Gain Energy")
	 meterSolarGain.setString(1, reportingInterval)
	 workspace.insertObject(meterSolarGain)
	 	 
	 #-----ventilation - windows (gains and losses)
	# Const METER_VENTILATION_HEAT_LOSS = "ZONE VENTILATION HEAT GAIN"
	 customMeterVentilationGain = OpenStudio::IdfObject.new("Meter:Custom".to_IddObjectType)
	 customMeterVentilationGain.setString(0, "Meter Zone Ventilation Heat Gain")
	 customMeterVentilationGain.setString(1, "Generic")
	 customMeterVentilationGain.setString(2, "*")
	 customMeterVentilationGain.setString(3, "Zone Ventilation Total Heat Gain Energy")
	 workspace.insertObject(customMeterVentilationGain)
	 meterVentilationGain = OpenStudio::IdfObject.new("Output:Meter".to_IddObjectType)
	 meterVentilationGain.setString(0, "Meter Zone Ventilation Heat Gain")
	 meterVentilationGain.setString(1, reportingInterval)
	 workspace.insertObject(meterVentilationGain)
	 
	 # Const METER_VENTILATION_HEAT_GAIN = "ZONE VENTILATION HEAT LOSS"
	 customMeterVentilationLoss = OpenStudio::IdfObject.new("Meter:Custom".to_IddObjectType)
	 customMeterVentilationLoss.setString(0, "Meter Zone Ventilation Heat Loss")
	 customMeterVentilationLoss.setString(1, "Generic")
	 customMeterVentilationLoss.setString(2, "*")
	 customMeterVentilationLoss.setString(3, "Zone Ventilation Total Heat Loss Energy")
	 workspace.insertObject(customMeterVentilationLoss)
	 meterVentilationLoss = OpenStudio::IdfObject.new("Output:Meter".to_IddObjectType)
	 meterVentilationLoss.setString(0, "Meter Zone Ventilation Heat Loss")
	 meterVentilationLoss.setString(1, reportingInterval)
	 workspace.insertObject(meterVentilationLoss)
	 	 	 
	 #-----infiltration (gains and losses)
	 # Const METER_INFILTRATION_HEAT_LOSS = "ZONE INFILTRATION HEAT GAIN"
	 customMeterInfiltrationGain = OpenStudio::IdfObject.new("Meter:Custom".to_IddObjectType)
	 customMeterInfiltrationGain.setString(0, "Meter Zone Infiltration Heat Gain")
	 customMeterInfiltrationGain.setString(1, "Generic")
	 customMeterInfiltrationGain.setString(2, "*")
	 customMeterInfiltrationGain.setString(3, "Zone Infiltration Total Heat Gain Energy")
	 workspace.insertObject(customMeterInfiltrationGain)
	 meterInfiltrationGain = OpenStudio::IdfObject.new("Output:Meter".to_IddObjectType)
	 meterInfiltrationGain.setString(0, "Meter Zone Infiltration Heat Gain")
	 meterInfiltrationGain.setString(1, reportingInterval)
	 workspace.insertObject(meterInfiltrationGain)
	 
	 # Const METER_INFILTRATION_HEAT_GAIN = "ZONE INFILTRATION HEAT LOSS"
	 customMeterInfiltrationLoss = OpenStudio::IdfObject.new("Meter:Custom".to_IddObjectType)
	 customMeterInfiltrationLoss.setString(0, "Meter Zone Infiltration Heat Loss")
	 customMeterInfiltrationLoss.setString(1, "Generic")
	 customMeterInfiltrationLoss.setString(2, "*")
	 customMeterInfiltrationLoss.setString(3, "Zone Infiltration Total Heat Loss Energy")
	 workspace.insertObject(customMeterInfiltrationLoss)
	 meterInfiltrationLoss = OpenStudio::IdfObject.new("Output:Meter".to_IddObjectType)
	 meterInfiltrationLoss.setString(0, "Meter Zone Infiltration Heat Loss")
	 meterInfiltrationLoss.setString(1, reportingInterval)
	 workspace.insertObject(meterInfiltrationLoss)
	 
	 #-----internal loads (Equipment, Lights People)
	 # Const METER_INTERNAL_LOADS = "INTERNAL LOADS HEATING ENERGY"
	 customMeterInternalLoads = OpenStudio::IdfObject.new("Meter:Custom".to_IddObjectType)
	 customMeterInternalLoads.setString(0, "Meter Internal Loads Heating Energy")
	 customMeterInternalLoads.setString(1, "Generic")
	 customMeterInternalLoads.setString(2, "*")
	 customMeterInternalLoads.setString(3, "Zone Electric Equipment Total Heating Energy")
	 customMeterInternalLoads.setString(4, "*")
	 customMeterInternalLoads.setString(5, "Zone Lights Total Heating Energy")
	 customMeterInternalLoads.setString(6, "*")
	 customMeterInternalLoads.setString(7, "People Total Heating Energy")
	 workspace.insertObject(customMeterInternalLoads)
	 meterInternalLoads = OpenStudio::IdfObject.new("Output:Meter".to_IddObjectType)
	 meterInternalLoads.setString(0, "Meter Internal Loads Heating Energy")
	 meterInternalLoads.setString(1, reportingInterval)
	 workspace.insertObject(meterInternalLoads)
	 
	 # Const METER_ZONE_PLUGS = "ZONE ELECTRIC EQUIPMENT TOTAL HEATING ENERGY"
	 customMeterInternalLoadsElectric = OpenStudio::IdfObject.new("Meter:Custom".to_IddObjectType)
	 customMeterInternalLoadsElectric.setString(0, "Meter Zone Electric Equipment Total Heating Energy")
	 customMeterInternalLoadsElectric.setString(1, "Generic")
	 customMeterInternalLoadsElectric.setString(2, "*")
	 customMeterInternalLoadsElectric.setString(3, "Zone Electric Equipment Total Heating Energy")
	 workspace.insertObject(customMeterInternalLoadsElectric)
	 meterInternalLoadsElectric = OpenStudio::IdfObject.new("Output:Meter".to_IddObjectType)
	 meterInternalLoadsElectric.setString(0, "Meter Zone Electric Equipment Total Heating Energy")
	 meterInternalLoadsElectric.setString(1, reportingInterval)
	 workspace.insertObject(meterInternalLoadsElectric)
	 
	 # Const METER_ZONE_LIGHTS = "ZONE LIGHTS TOTAL HEATING ENERGY"
	 customMeterInternalLoadsLights = OpenStudio::IdfObject.new("Meter:Custom".to_IddObjectType)
	 customMeterInternalLoadsLights.setString(0, "Meter Zone Lights Total Heating Energy")
	 customMeterInternalLoadsLights.setString(1, "Generic")
	 customMeterInternalLoadsLights.setString(2, "*")
	 customMeterInternalLoadsLights.setString(3, "Zone Lights Total Heating Energy")
	 workspace.insertObject(customMeterInternalLoadsLights)
	 meterInternalLoadsLights = OpenStudio::IdfObject.new("Output:Meter".to_IddObjectType)
	 meterInternalLoadsLights.setString(0, "Meter Zone Lights Total Heating Energy")
	 meterInternalLoadsLights.setString(1, reportingInterval)
	 workspace.insertObject(meterInternalLoadsLights)
	 
	 # Const METER_ZONE_PEOPLE = "PEOPLE TOTAL HEATING ENERGY"
	 customMeterInternalLoadsPeople = OpenStudio::IdfObject.new("Meter:Custom".to_IddObjectType)
	 customMeterInternalLoadsPeople.setString(0, "Meter People Total Heating Energy")
	 customMeterInternalLoadsPeople.setString(1, "Generic")
	 customMeterInternalLoadsPeople.setString(2, "*")
	 customMeterInternalLoadsPeople.setString(3, "People Total Heating Energy")
	 workspace.insertObject(customMeterInternalLoadsPeople)
	 meterInternalLoadsPeople = OpenStudio::IdfObject.new("Output:Meter".to_IddObjectType)
	 meterInternalLoadsPeople.setString(0, "Meter People Total Heating Energy")
	 meterInternalLoadsPeople.setString(1, reportingInterval)
	 workspace.insertObject(meterInternalLoadsPeople)

	 #-----Mechanical Ventilation (gains and losses)
	 # Const Zone_Mechanical_Ventilation_Cooling_Load_Increase_Energy = "METER MECHANICAL VENTILATION GAIN"
	 customMeterMechVentGain = OpenStudio::IdfObject.new("Meter:Custom".to_IddObjectType)
	 customMeterMechVentGain.setString(0, "Meter Mechanical Ventilation Gain")
	 customMeterMechVentGain.setString(1, "Generic")
	 customMeterMechVentGain.setString(2, "*")
	 customMeterMechVentGain.setString(3, "Zone Mechanical Ventilation Cooling Load Increase Energy")
	 workspace.insertObject(customMeterMechVentGain)
	 meterMechVentGain = OpenStudio::IdfObject.new("Output:Meter".to_IddObjectType)
	 meterMechVentGain.setString(0, "Meter Mechanical Ventilation Gain")
	 meterMechVentGain.setString(1, reportingInterval)
	 workspace.insertObject(meterMechVentGain)
	 
	 # Const Zone_Mechanical_Ventilation_No_Load_Heat_Removal_Energy = "METER MECHANICAL VENTILATION LOSS"
	 customMeterMechVentLoss = OpenStudio::IdfObject.new("Meter:Custom".to_IddObjectType)
	 customMeterMechVentLoss.setString(0, "Meter Mechanical Ventilation Loss")
	 customMeterMechVentLoss.setString(1, "Generic")
	 customMeterMechVentLoss.setString(2, "*")
	 customMeterMechVentLoss.setString(3, "Zone Mechanical Ventilation No Load Heat Removal Energy")
	 workspace.insertObject(customMeterMechVentLoss)
	 meterMechVentLoss = OpenStudio::IdfObject.new("Output:Meter".to_IddObjectType)
	 meterMechVentLoss.setString(0, "Meter Mechanical Ventilation Loss")
	 meterMechVentLoss.setString(1, reportingInterval)
	 workspace.insertObject(meterMechVentLoss)
	 
	 #make new string
      new_diagnostic_string = "
      Output:Diagnostics,
        DisplayAllWarnings;    !- Key 1
        "
		
	 #adding here the meters again, not sure why this is not working from the CreateEmptyModel Measure
	 meters = Array.new
	 meters << "DistrictHeating:Facility"
	 meters << "DistrictCooling:Facility"
	 meters << "InteriorLights:Electricity"
	 meters << "InteriorEquipment:Electricity"
	 meters << "ElectricityProduced:Plant"
	 meters << "Electricity:Facility"
	 meters << "Photovoltaic:ElectricityProduced"
	 meters << "Fans:Electricity"
	 meters << "Pumps:Electricity"
	 #add meters
	 meters.each do |meter|
		newMeter = OpenStudio::IdfObject.new("Output:Meter".to_IddObjectType)
		newMeter.setString(0,meter)
		newMeter.setString(1,reportingInterval)
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
		#edit ideal loads objects
		newTimesteps.each do |newTimestep|
			newTimestep.setInt(0,timestep)
			workspace.insertObject(newTimestep)
		end

		#sizingParams = workspace.getObjectsByType("Sizing:Parameters".to_IddObjectType)
		#sizingParams.each do |sizingParam|
		#	sizingParam.setDouble(0,2)
		#	workspace.insertObject(sizingParam)
		#end

		sizingZones = workspace.getObjectsByType("Sizing:Zone".to_IddObjectType)
		sizingZones.each do |sizingZone|
			#sizingZone.setDouble(11, 2) # Zone Cooling Sizing Factor
			sizingZone.setString(23,"Yes") #A ccount for Dedicated Outdoor Air System
			sizingZone.setString(24,"NeutralSupplyAir")  # Dedicated Outdoor Air System Control Strategy
			sizingZone.setDouble(25, -12.7) # Dedicated Outdoor Air Low Setpoint Temperature for Design {C}
			sizingZone.setDouble(26, 30) # Dedicated Outdoor Air High Setpoint Temperature for Design {C}
			workspace.insertObject(sizingZone)
		end

		#make new string
		new_reporting_string = "
    	OutputControl:ReportingTolerances,
      	1,
				1;"

		#make new object from string
		idfObject = OpenStudio::IdfObject::load(new_reporting_string)
		object = idfObject.get
		wsObject = workspace.addObject(object)

		newRunPeriods = workspace.getObjectsByType("RunPeriod".to_IddObjectType)
		#edit ideal loads objects
		newRunPeriods.each do |newRunPeriod|
			if workspace.version() >= OpenStudio::VersionString.new(9, 0, 0)
				newRunPeriod.setString(7,dayToStartSimulation)
				newRunPeriod.setString(3,"")
				newRunPeriod.setString(6,"")
			else
				newRunPeriod.setString(5,dayToStartSimulation)
			end
			workspace.insertObject(newRunPeriod)
		end

     #make new object from string
     idfObject = OpenStudio::IdfObject::load(new_diagnostic_string)
     object = idfObject.get
     wsObject = workspace.addObject(object)

     idealloads = workspace.getObjectsByType("HVACTemplate:Zone:IdealLoadsAirSystem".to_IddObjectType)
     customMeters = workspace.getObjectsByType("Meter:Custom".to_IddObjectType)
	 	runner.registerFinalCondition("The building finished with #{customMeters.size} Custom Meters with version #{workspace.version().str()}.")

    return true
  end
end

# register the measure to be used by the application
SetMeters.new.registerWithApplication
