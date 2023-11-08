# frozen_string_literal: true

require_relative "../NewHelper"

# start the measure
class AddInfiltration < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return "AddInfiltration"
  end

  # general description of measure
  def description
    return "Add infiltration."
  end

  # description for users of what the measure does and how it works
  def modeler_description
    return "Add infiltration objects."
  end

  # define the arguments that the user will input
  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for infiltration
    infiltration_ach = OpenStudio::Measure::OSArgument.makeDoubleArgument("air_changes", true)
    infiltration_ach.setDisplayName("Space Infiltration Air Changes")
    infiltration_ach.setUnits("1/h")
    infiltration_ach.setDefaultValue(0.1)
    args << infiltration_ach
    nfa_gfa_ratio = OpenStudio::Measure::OSArgument.makeDoubleArgument("nfa_gfa_ratio", true)
    nfa_gfa_ratio.setDisplayName("Ratio of NFA over GFA")
    nfa_gfa_ratio.setDefaultValue(1)
    args << nfa_gfa_ratio
    floor_height_ratio = OpenStudio::Measure::OSArgument.makeDoubleArgument("floor_height_ratio", true)
    floor_height_ratio.setDisplayName("Ratio of conditioned floor height over total floor height")
    floor_height_ratio.setDefaultValue(1)
    args << floor_height_ratio

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    # assign the user inputs to variables
    infiltration_ach = runner.getDoubleArgumentValue("air_changes", user_arguments)
    nfa_gfa_ratio = runner.getDoubleArgumentValue("nfa_gfa_ratio", user_arguments)
    floor_height_ratio = runner.getDoubleArgumentValue("floor_height_ratio", user_arguments)

    # rescale air change rate to conditioned volume and GFA
    infiltration_ach = infiltration_ach * nfa_gfa_ratio * floor_height_ratio

    # check infiltration for reasonableness
    if infiltration_ach < 0
      runner.registerError("The requested space infiltration Air Changes Per Hour #{infiltration_ach} 1/h was below the measure limit. Choose a positive number.")
      return false
    elsif infiltration_ach > 10.0
      runner.registerWarning("The requested space infiltration Air Changes Per Hour  #{infiltration_ach} 1/h seems abnormally high.")
    end

    constSchedule = CreateConstSchedule(model, "AlwaysOnInfitration", 1)

    # loop through spaces used in the model adding space infiltration objects
    spaces = model.getSpaces
    spaces.each do |space|
      next if spaces.empty?
      new_space_type_infil = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
      new_space_type_infil.setAirChangesperHour(infiltration_ach)
      new_space_type_infil.setSpace(space)
      new_space_type_infil.setSchedule(constSchedule)
    end # end .each do

    # report final condition of model
    runner.registerFinalCondition("Infiltration added to #{model.getSpaces.size} spaces.")

    return true
  end
end

# register the measure to be used by the application
AddInfiltration.new.registerWithApplication
