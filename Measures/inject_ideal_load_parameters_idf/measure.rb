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

    args << OpenStudio::Measure::OSArgument::makeStringArgument("heat_recovery_type", true)
    args << OpenStudio::Measure::OSArgument::makeDoubleArgument("sensible_efficiency", true)
    args << OpenStudio::Measure::OSArgument::makeDoubleArgument("latent_efficiency", true)
    args << OpenStudio::Measure::OSArgument::makeDoubleArgument("air_changes", true)
    nfa_gfa_ratio = OpenStudio::Measure::OSArgument::makeDoubleArgument("nfa_gfa_ratio", true)
    nfa_gfa_ratio.setDisplayName("Ratio of NFA over GFA")
    nfa_gfa_ratio.setDefaultValue(1)
    args << nfa_gfa_ratio
    floor_height_ratio = OpenStudio::Measure::OSArgument::makeDoubleArgument("floor_height_ratio", true)
    floor_height_ratio.setDisplayName("Ratio of conditioned floor height over total floor height")
    floor_height_ratio.setDefaultValue(1)
    args << floor_height_ratio

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
    heatRecoveryType = runner.getStringArgumentValue("heat_recovery_type", user_arguments)
    sensibleEffectiveness = runner.getDoubleArgumentValue("sensible_efficiency", user_arguments)
    latentEffectiveness = runner.getDoubleArgumentValue("latent_efficiency", user_arguments)
    ach = runner.getDoubleArgumentValue("air_changes", user_arguments)
    nfa_gfa_ratio = runner.getDoubleArgumentValue("nfa_gfa_ratio", user_arguments)
    floor_height_ratio = runner.getDoubleArgumentValue("floor_height_ratio", user_arguments)

    # rescale air change rate to conditioned volume and GFA
    ach = ach * nfa_gfa_ratio * floor_height_ratio

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
      idealLoadObject_name = idealLoadObject.getString(0) # Name
      idealLoadObject.setString(27, heatRecoveryType) # Heat Recovery Type
      idealLoadObject.setDouble(28, sensibleEffectiveness) # Sensible Heat Recovery Effectiveness
      idealLoadObject.setDouble(29, latentEffectiveness) # Latent Heat Recovery Effectiveness
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
