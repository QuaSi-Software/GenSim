# start the measure
class InjectIdealLoadParametersIDF < OpenStudio::Measure::EnergyPlusMeasure

  # human readable name
  def name
    return "InjectIdealLoadParametersIDF"
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

    args << OpenStudio::Measure::OSArgument::makeStringArgument("HeatRecoveryType",true)
	args << OpenStudio::Measure::OSArgument::makeDoubleArgument("SensibleEffectiveness",true)
	args << OpenStudio::Measure::OSArgument::makeDoubleArgument("LatentEffectiveness",true)
	args << OpenStudio::Measure::OSArgument::makeDoubleArgument("ACH",true)
	
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
    heatRecoveryType = runner.getStringArgumentValue("HeatRecoveryType", user_arguments)
	sensibleEffectiveness = runner.getDoubleArgumentValue("SensibleEffectiveness", user_arguments)
	latentEffectiveness = runner.getDoubleArgumentValue("LatentEffectiveness", user_arguments)
	ach = runner.getDoubleArgumentValue("ACH", user_arguments)
	
    #get all IdealLoadsObjects in model
    idealLoadObjects = workspace.getObjectsByType("HVACTemplate:Zone:IdealLoadsAirSystem".to_IddObjectType)
	
	# reporting initial condition of model
    runner.registerInitialCondition("The building started with #{idealLoadObjects.size} IdealLoad objects.")
	
	#create designspecification object
	desSpecOA = OpenStudio::IdfObject.new("DesignSpecification:OutdoorAir".to_IddObjectType)
	desSpecOA.setString(0, "DesignSpecs")
	desSpecOA.setString(1, "AirChanges/Hour")
	desSpecOA.setDouble(5, ach)
	workspace.addObject(desSpecOA)
	
   #edit ideal loads objects
   idealLoadObjects.each do |idealLoadObject|
     idealLoadObject_name =  idealLoadObject.getString(0) # Name
     idealLoadObject.setString(27,heatRecoveryType) # Heat Recovery Type
     idealLoadObject.setDouble(28,sensibleEffectiveness) # Sensible Heat Recovery Effectiveness
	   idealLoadObject.setDouble(29,latentEffectiveness) # Latent Heat Recovery Effectiveness
	   idealLoadObject.setString(24, "DesignSpecs")
	   idealLoadObject.setString(20, "DetailedSpecification")
	   idealLoadObject.setString(2, "HVACSched")
	   #workspace.removeObject(idealLoadObject.handle())
	   workspace.insertObject(idealLoadObject)
	 end
	 
    idealloads = workspace.getObjectsByType("HVACTemplate:Zone:IdealLoadsAirSystem".to_IddObjectType)
	  runner.registerFinalCondition("The building finished with #{idealloads.size} IdealLoads objects.")

    return true
  end
end

# register the measure to be used by the application
InjectIdealLoadParametersIDF.new.registerWithApplication
