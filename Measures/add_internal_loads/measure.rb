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
	args << OpenStudio::Measure::OSArgument.makeDoubleArgument("NRF/BGF", true)
    args << OpenStudio::Measure::OSArgument.makeDoubleArgument("ElectricEquipmentPowerPerFloorArea", true)
    args << OpenStudio::Measure::OSArgument.makeDoubleArgument("LightingPowerPerFloorArea", true)
    args << OpenStudio::Measure::OSArgument.makeDoubleArgument("FloorAreaPerPerson", true)
	args << OpenStudio::Measure::OSArgument.makeStringArgument("ElectricEquipmentScheduleWerktag", true)
	args << OpenStudio::Measure::OSArgument.makeStringArgument("ElectricEquipmentScheduleSamstag", true)
	args << OpenStudio::Measure::OSArgument.makeStringArgument("ElectricEquipmentScheduleSonntag", true)
	args << OpenStudio::Measure::OSArgument.makeStringArgument("ElectricEquipmentScheduleFeiertag", true)
	args << OpenStudio::Measure::OSArgument.makeStringArgument("LightScheduleWerktag", true)
	args << OpenStudio::Measure::OSArgument.makeStringArgument("LightScheduleSamstag", true)
	args << OpenStudio::Measure::OSArgument.makeStringArgument("LightScheduleSonntag", true)
	args << OpenStudio::Measure::OSArgument.makeStringArgument("LightScheduleFeiertag", true)
	args << OpenStudio::Measure::OSArgument.makeStringArgument("PeopleScheduleWerktag", true)
	args << OpenStudio::Measure::OSArgument.makeStringArgument("PeopleScheduleSamstag", true)
	args << OpenStudio::Measure::OSArgument.makeStringArgument("PeopleScheduleSonntag", true)
	args << OpenStudio::Measure::OSArgument.makeStringArgument("PeopleScheduleFeiertag", true)
	args << OpenStudio::Measure::OSArgument.makeStringArgument("PeopleActivityScheduleWerktag", true)
	args << OpenStudio::Measure::OSArgument.makeStringArgument("PeopleActivityScheduleSamstag", true)
	args << OpenStudio::Measure::OSArgument.makeStringArgument("PeopleActivityScheduleSonntag", true)
	args << OpenStudio::Measure::OSArgument.makeStringArgument("PeopleActivityScheduleFeiertag", true)
	args << OpenStudio::Measure::OSArgument.makeStringArgument("Holidays", false)

	# custom parameters for loading from OSW
	args << OpenStudio::Measure::OSArgument.makeDoubleArgument("area_bgf_import", false)
	args << OpenStudio::Measure::OSArgument.makeStringArgument("selected_ratio", false)
	args << OpenStudio::Measure::OSArgument.makeBoolArgument("is_custom_ratio", false)
	args << OpenStudio::Measure::OSArgument.makeBoolArgument("is_imported", false)
	args << OpenStudio::Measure::OSArgument.makeStringArgument("ElectricEquipmentSchedule", false)
	args << OpenStudio::Measure::OSArgument.makeStringArgument("LightSchedule", false)
	args << OpenStudio::Measure::OSArgument.makeStringArgument("PeopleSchedule", false)
	args << OpenStudio::Measure::OSArgument.makeStringArgument("PeopleActivitySchedule", false)
	args << OpenStudio::Measure::OSArgument.makeBoolArgument("is_custom_ElectricEquipment", false)
	args << OpenStudio::Measure::OSArgument.makeBoolArgument("is_custom_Light", false)
	args << OpenStudio::Measure::OSArgument.makeBoolArgument("is_custom_People", false)
	args << OpenStudio::Measure::OSArgument.makeBoolArgument("is_custom_PeopleActivity", false)
    
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
    nfa_gfa_ratio = runner.getDoubleArgumentValue("NRF/BGF", user_arguments)
    electricEquipmentPowerPerFloorArea = runner.getDoubleArgumentValue("ElectricEquipmentPowerPerFloorArea", user_arguments)
	lightingPowerPerFloorArea = runner.getDoubleArgumentValue("LightingPowerPerFloorArea", user_arguments)
	floorAreaPerPerson = runner.getDoubleArgumentValue("FloorAreaPerPerson", user_arguments)
	electricEquipmentScheduleWerktag = runner.getStringArgumentValue("ElectricEquipmentScheduleWerktag", user_arguments)
	electricEquipmentScheduleSamstag = runner.getStringArgumentValue("ElectricEquipmentScheduleSamstag", user_arguments)
	electricEquipmentScheduleSonntag = runner.getStringArgumentValue("ElectricEquipmentScheduleSonntag", user_arguments)
	electricEquipmentScheduleFeiertag = runner.getStringArgumentValue("ElectricEquipmentScheduleFeiertag", user_arguments)
	lightScheduleWerktag = runner.getStringArgumentValue("LightScheduleWerktag", user_arguments)
	lightScheduleSamstag = runner.getStringArgumentValue("LightScheduleSamstag", user_arguments)
	lightScheduleSonntag = runner.getStringArgumentValue("LightScheduleSonntag", user_arguments)
	lightScheduleFeiertag = runner.getStringArgumentValue("LightScheduleFeiertag", user_arguments)
	peopleScheduleWerktag = runner.getStringArgumentValue("PeopleScheduleWerktag", user_arguments)
	peopleScheduleSamstag = runner.getStringArgumentValue("PeopleScheduleSamstag", user_arguments)
	peopleScheduleSonntag = runner.getStringArgumentValue("PeopleScheduleSonntag", user_arguments)
	peopleScheduleFeiertag = runner.getStringArgumentValue("PeopleScheduleFeiertag", user_arguments)
	peopleActivityScheduleWerktag = runner.getStringArgumentValue("PeopleActivityScheduleWerktag", user_arguments)
	peopleActivityScheduleSamstag = runner.getStringArgumentValue("PeopleActivityScheduleSamstag", user_arguments)
	peopleActivityScheduleSonntag = runner.getStringArgumentValue("PeopleActivityScheduleSonntag", user_arguments)
	peopleActivityScheduleFeiertag = runner.getStringArgumentValue("PeopleActivityScheduleFeiertag", user_arguments)
	holidays = runner.getStringArgumentValue("Holidays", user_arguments)

	# set power densities relative to net floor area
	electricEquipmentPowerPerFloorArea *= nfa_gfa_ratio
	lightingPowerPerFloorArea *= nfa_gfa_ratio
	peoplePerFloorArea = nfa_gfa_ratio / floorAreaPerPerson

    # report initial condition of model
    runner.registerInitialCondition("The building has #{model.getSpaces.size} spaces.")
	
	electricSched = CreateSchedule(model, "ElectricEquipmentSched", electricEquipmentScheduleWerktag, electricEquipmentScheduleSamstag, electricEquipmentScheduleSonntag, electricEquipmentScheduleFeiertag, holidays, true)
	lightSched = CreateSchedule(model, "LightSchedule", lightScheduleWerktag, lightScheduleSamstag, lightScheduleSonntag, lightScheduleFeiertag, holidays, true)
	peopleSched = CreateSchedule(model, "PeopleSchedule", peopleScheduleWerktag, peopleScheduleSamstag, peopleScheduleSonntag, peopleScheduleFeiertag, holidays, true)
	activitySched = CreateSchedule(model, "PeopleActivitySchedule", peopleActivityScheduleWerktag, peopleActivityScheduleSamstag, peopleActivityScheduleSonntag, peopleActivityScheduleFeiertag, holidays)
	
	defSchedules = OpenStudio::Model::DefaultScheduleSet.new(model)
	defSchedules.setElectricEquipmentSchedule(electricSched)
	defSchedules.setNumberofPeopleSchedule(peopleSched)
	defSchedules.setPeopleActivityLevelSchedule(activitySched)
	defSchedules.setLightingSchedule(lightSched)
	
	model.getSpaces.each do |space|
		# electric equipment
		space.setElectricEquipmentPowerPerFloorArea(electricEquipmentPowerPerFloorArea)
		space.setLightingPowerPerFloorArea(lightingPowerPerFloorArea)
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
