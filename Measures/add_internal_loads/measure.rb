require_relative "../NewHelper"

# start the measure
class AddInternalLoads < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "AddInternalLoads"
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

    # the name of the space to add to the model
    args << OpenStudio::Measure::OSArgument.makeDoubleArgument("nfa_gfa_ratio", true)
    args << OpenStudio::Measure::OSArgument.makeDoubleArgument("electric_equipment_power_per_floor_area", true)
    args << OpenStudio::Measure::OSArgument.makeDoubleArgument("lighting_power_per_floor_area", true)
    args << OpenStudio::Measure::OSArgument.makeDoubleArgument("floor_area_per_person", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("electric_equipment_sched_weekday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("electric_equipment_sched_saturday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("electric_equipment_sched_sunday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("electric_equipment_sched_holiday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("lighting_sched_weekday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("lighting_sched_saturday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("lighting_sched_sunday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("lighting_sched_holiday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("people_sched_weekday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("people_sched_saturday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("people_sched_sunday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("people_sched_holiday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("people_activity_sched_weekday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("people_activity_sched_saturday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("people_activity_sched_sunday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("people_activity_sched_holiday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("holidays", false)

    # custom parameters for loading from OSW
    args << OpenStudio::Measure::OSArgument.makeDoubleArgument("area_gfa_import", false)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("nfa_gfa_ratio_selection", false)
    args << OpenStudio::Measure::OSArgument.makeBoolArgument("is_custom_ratio", false)
    args << OpenStudio::Measure::OSArgument.makeBoolArgument("is_imported_model", false)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("electric_equipment_sched_selection", false)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("lighting_sched_selection", false)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("people_sched_selection", false)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("people_activity_sched_selection", false)
    args << OpenStudio::Measure::OSArgument.makeBoolArgument("is_custom_electric_equipment", false)
    args << OpenStudio::Measure::OSArgument.makeBoolArgument("is_custom_lighting", false)
    args << OpenStudio::Measure::OSArgument.makeBoolArgument("is_custom_people", false)
    args << OpenStudio::Measure::OSArgument.makeBoolArgument("is_custom_people_activity", false)

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    nfa_gfa_ratio = runner.getDoubleArgumentValue("nfa_gfa_ratio", user_arguments)
    electric_equipment_power_per_floor_area = runner.getDoubleArgumentValue("electric_equipment_power_per_floor_area", user_arguments)
    lighting_power_per_floor_area = runner.getDoubleArgumentValue("lighting_power_per_floor_area", user_arguments)
    floor_area_per_person = runner.getDoubleArgumentValue("floor_area_per_person", user_arguments)
    electric_equipment_sched_weekday = runner.getStringArgumentValue("electric_equipment_sched_weekday", user_arguments)
    electric_equipment_sched_saturday = runner.getStringArgumentValue("electric_equipment_sched_saturday", user_arguments)
    electric_equipment_sched_sunday = runner.getStringArgumentValue("electric_equipment_sched_sunday", user_arguments)
    electric_equipment_sched_holiday = runner.getStringArgumentValue("electric_equipment_sched_holiday", user_arguments)
    lighting_sched_weekday = runner.getStringArgumentValue("lighting_sched_weekday", user_arguments)
    lighting_sched_saturday = runner.getStringArgumentValue("lighting_sched_saturday", user_arguments)
    lighting_sched_sunday = runner.getStringArgumentValue("lighting_sched_sunday", user_arguments)
    lighting_sched_holiday = runner.getStringArgumentValue("lighting_sched_holiday", user_arguments)
    people_sched_weekday = runner.getStringArgumentValue("people_sched_weekday", user_arguments)
    people_sched_saturday = runner.getStringArgumentValue("people_sched_saturday", user_arguments)
    people_sched_sunday = runner.getStringArgumentValue("people_sched_sunday", user_arguments)
    people_sched_holiday = runner.getStringArgumentValue("people_sched_holiday", user_arguments)
    people_activity_sched_weekday = runner.getStringArgumentValue("people_activity_sched_weekday", user_arguments)
    people_activity_sched_saturday = runner.getStringArgumentValue("people_activity_sched_saturday", user_arguments)
    people_activity_sched_sunday = runner.getStringArgumentValue("people_activity_sched_sunday", user_arguments)
    people_activity_sched_holiday = runner.getStringArgumentValue("people_activity_sched_holiday", user_arguments)
    holidays = runner.getStringArgumentValue("holidays", user_arguments)

    # set power densities relative to net floor area
    electric_equipment_power_per_floor_area *= nfa_gfa_ratio
    lighting_power_per_floor_area *= nfa_gfa_ratio
    peoplePerFloorArea = nfa_gfa_ratio / floor_area_per_person

    # report initial condition of model
    runner.registerInitialCondition("The building has #{model.getSpaces.size} spaces.")

    electricSched = CreateSchedule(model, "ElectricEquipmentSched", electric_equipment_sched_weekday, electric_equipment_sched_saturday, electric_equipment_sched_sunday, electric_equipment_sched_holiday, holidays, true)
    lightSched = CreateSchedule(model, "LightSchedule", lighting_sched_weekday, lighting_sched_saturday, lighting_sched_sunday, lighting_sched_holiday, holidays, true)
    peopleSched = CreateSchedule(model, "PeopleSchedule", people_sched_weekday, people_sched_saturday, people_sched_sunday, people_sched_holiday, holidays, true)
    activitySched = CreateSchedule(model, "PeopleActivitySchedule", people_activity_sched_weekday, people_activity_sched_saturday, people_activity_sched_sunday, people_activity_sched_holiday, holidays)

    defSchedules = OpenStudio::Model::DefaultScheduleSet.new(model)
    defSchedules.setElectricEquipmentSchedule(electricSched)
    defSchedules.setNumberofPeopleSchedule(peopleSched)
    defSchedules.setPeopleActivityLevelSchedule(activitySched)
    defSchedules.setLightingSchedule(lightSched)

    model.getSpaces.each do |space|
      # electric equipment
      space.setElectricEquipmentPowerPerFloorArea(electric_equipment_power_per_floor_area)
      space.setLightingPowerPerFloorArea(lighting_power_per_floor_area)
      space.setPeoplePerFloorArea(peoplePerFloorArea)
      space.setDefaultScheduleSet(defSchedules)
      runner.registerInfo("Adding internal loads for space: #{space.name}")
    end

    # report final condition of model
    runner.registerFinalCondition("Internal loads added to #{model.getSpaces.size} spaces.")

    return true
  end
end

# register the measure to be used by the application
AddInternalLoads.new.registerWithApplication
