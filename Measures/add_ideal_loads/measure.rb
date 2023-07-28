require_relative "../NewHelper"

# start the measure
class AddIdealLoads < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "AddIdealLoads"
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

    wrg = OpenStudio::Ruleset::OSArgument::makeStringArgument("wrg",true)
    wrg.setDisplayName("Heat Recocovery Ratio")
    wrg.setDefaultValue("none")
    args << wrg
    latent = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("latent",true)
    latent.setDisplayName("Latent efficiency")
    latent.setDefaultValue(0.65)
    args << latent
    sensible = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("sensible",true)
    sensible.setDisplayName("sensible efficiency")
    sensible.setDefaultValue(0.7)
    args << sensible
    ach = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ach",true)
    ach.setDisplayName("Air changes per hours")
    ach.setDefaultValue(1)
    args << ach
    nfa_gfa_ratio = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("nfa_gfa_ratio",true)
    nfa_gfa_ratio.setDisplayName("Ratio of NFA over GFA")
    nfa_gfa_ratio.setDefaultValue(1)
    args << nfa_gfa_ratio
    floor_height_ratio = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("floor_height_ratio",true)
    floor_height_ratio.setDisplayName("Ratio of conditioned floor height over total floor height")
    floor_height_ratio.setDefaultValue(1)
    args << floor_height_ratio

	args << OpenStudio::Measure::OSArgument.makeStringArgument("hvacSchedWerktag", true)
	args << OpenStudio::Measure::OSArgument.makeStringArgument("hvacSchedSamstag", true)
	args << OpenStudio::Measure::OSArgument.makeStringArgument("hvacSchedSonntag", true)
	args << OpenStudio::Measure::OSArgument.makeStringArgument("hvacSchedFeiertag", false)
	args << OpenStudio::Measure::OSArgument.makeStringArgument("Holidays", false)
	return args

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    ##Abruf der Variablen
	wrg = runner.getStringArgumentValue("wrg", user_arguments)
	latent = runner.getDoubleArgumentValue("latent",user_arguments)
	sensible = runner.getDoubleArgumentValue("sensible",user_arguments)
	ach = runner.getDoubleArgumentValue("ach",user_arguments)
  nfa_gfa_ratio = runner.getDoubleArgumentValue("nfa_gfa_ratio",user_arguments)
  floor_height_ratio = runner.getDoubleArgumentValue("floor_height_ratio",user_arguments)
	hvacSchedWeekday = runner.getStringArgumentValue("hvacSchedWerktag", user_arguments)
	hvacSchedSaturday = runner.getStringArgumentValue("hvacSchedSamstag", user_arguments)
	hvacSchedSunday = runner.getStringArgumentValue("hvacSchedSonntag", user_arguments)
	hvacSchedFeiertag = runner.getStringArgumentValue("hvacSchedFeiertag", user_arguments)
	holidays = runner.getStringArgumentValue("Holidays", user_arguments)

	hvacSched = CreateSchedule(model, "HVACSched", hvacSchedWeekday, hvacSchedSaturday, hvacSchedSunday, hvacSchedFeiertag, holidays)

    # rescale air change rate to conditioned volume and GFA
    ach = ach * nfa_gfa_ratio * floor_height_ratio

    # array of zones initially using ideal air loads
    startingIdealAir = []

    thermalZones = model.getThermalZones
    thermalZones.each do |zone|
      if zone.useIdealAirLoads
        startingIdealAir << zone
      else
        zone.setUseIdealAirLoads(true)
		runner.registerInfo("Setting Ideal loads for zone: #{zone.name}")
        zone.equipment.each do |equipment|
		  runner.registerInfo("Equipment type: " + equipment.iddObjectType )
          if not equipment.setAttribute("Heat Recovery Type", wrg)
			runner.registerError("Heat Revocery Type was not set.")
		  end
          if not equipment.setAttribute("Sensible Heat Recovery Effectiveness", sensible)
			runner.registerError("Sensible Heat Recovery Effectiveness.")
          end
		  if not equipment.setAttribute("Latent Heat Recovery Effectiveness", latent)
			runner.registerError("Latent Heat Recovery Effectiveness.")
		  end
        end  
      end
    end

    #reporting initial condition of model
    runner.registerInitialCondition("In the initial model #{startingIdealAir.size} zones use ideal air loads.")

    #reporting final condition of model
    finalIdealAir = []
    thermalZones.each do |zone|
      if zone.useIdealAirLoads
        finalIdealAir << zone
      end
    end
    runner.registerFinalCondition("In the final model #{finalIdealAir.size} zones use ideal air loads.")

    return true

  end

end

# register the measure to be used by the application
AddIdealLoads.new.registerWithApplication
