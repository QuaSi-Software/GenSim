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

    wrg = OpenStudio::Measure::OSArgument::makeStringArgument("heat_recovery_method", true)
    wrg.setDisplayName("Heat Recocovery Method")
    wrg.setDefaultValue("none")
    args << wrg
    latent = OpenStudio::Measure::OSArgument::makeDoubleArgument("latent_efficiency", true)
    latent.setDisplayName("Latent efficiency")
    latent.setDefaultValue(0.65)
    args << latent
    sensible = OpenStudio::Measure::OSArgument::makeDoubleArgument("sensible_efficiency", true)
    sensible.setDisplayName("sensible efficiency")
    sensible.setDefaultValue(0.7)
    args << sensible
    ach = OpenStudio::Measure::OSArgument::makeDoubleArgument("ach_per_hour", true)
    ach.setDisplayName("Air changes per hours")
    ach.setDefaultValue(1)
    args << ach
    nfa_gfa_ratio = OpenStudio::Measure::OSArgument::makeDoubleArgument("nfa_gfa_ratio", true)
    nfa_gfa_ratio.setDisplayName("Ratio of NFA over GFA")
    nfa_gfa_ratio.setDefaultValue(1)
    args << nfa_gfa_ratio
    floor_height_ratio = OpenStudio::Measure::OSArgument::makeDoubleArgument("floor_height_ratio", true)
    floor_height_ratio.setDisplayName("Ratio of conditioned floor height over total floor height")
    floor_height_ratio.setDefaultValue(1)
    args << floor_height_ratio

    args << OpenStudio::Measure::OSArgument.makeStringArgument("hvac_sched_weekday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("hvac_sched_saturday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("hvac_sched_sunday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("hvac_sched_holiday", false)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("holidays", false)
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
    heat_recovery_method = runner.getStringArgumentValue("heat_recovery_method", user_arguments)
    latent_efficiency = runner.getDoubleArgumentValue("latent_efficiency", user_arguments)
    sensible_efficiency = runner.getDoubleArgumentValue("sensible_efficiency", user_arguments)
    ach = runner.getDoubleArgumentValue("ach_per_hour", user_arguments)
    nfa_gfa_ratio = runner.getDoubleArgumentValue("nfa_gfa_ratio", user_arguments)
    floor_height_ratio = runner.getDoubleArgumentValue("floor_height_ratio", user_arguments)
    hvac_sched_weekday = runner.getStringArgumentValue("hvac_sched_weekday", user_arguments)
    hvac_sched_saturday = runner.getStringArgumentValue("hvac_sched_saturday", user_arguments)
    hvac_sched_sunday = runner.getStringArgumentValue("hvac_sched_sunday", user_arguments)
    hvac_sched_holiday = runner.getStringArgumentValue("hvac_sched_holiday", user_arguments)
    holidays = runner.getStringArgumentValue("holidays", user_arguments)

    hvacSched = CreateSchedule(model, "HVACSched", hvac_sched_weekday, hvac_sched_saturday, hvac_sched_sunday, hvac_sched_holiday, holidays)

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
          runner.registerInfo("Equipment type: " + equipment.iddObjectType)
          if not equipment.setAttribute("Heat Recovery Type", heat_recovery_method)
            runner.registerError("Heat Revocery Type was not set.")
          end
          if not equipment.setAttribute("Sensible Heat Recovery Effectiveness", sensible_efficiency)
            runner.registerError("Sensible Heat Recovery Effectiveness.")
          end
          if not equipment.setAttribute("Latent Heat Recovery Effectiveness", latent_efficiency)
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
