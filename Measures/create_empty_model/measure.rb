# frozen_string_literal: true

########################################################
# This is just a simple measure to create an empty model
########################################################

# start the measure
class CreateEmptyModel < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return "CreateEmptyModel"
  end

  # general description of measure
  def description
    return "This just creates an empty model"
  end

  # description for users of what the measure does and how it works
  def modeler_description
    return "This just creates an empty model"
  end

  # define the arguments that the user will input
  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    # report final condition of model
    runner.registerFinalCondition("The Model was created.")

    return true
  end
end

# register the measure to be used by the application
CreateEmptyModel.new.registerWithApplication
