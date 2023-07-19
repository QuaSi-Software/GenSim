require_relative "../NewHelper"

# start the measure
class AddingInfiltration < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "AddingInfiltration"
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

    #make an argument for infiltration
    infiltration_ach = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("AirChangesPerHour",true)
    infiltration_ach.setDisplayName("Space Infiltration Air Changes Per Hour (1/h).")
    infiltration_ach.setDefaultValue(0.1)
    args << infiltration_ach


    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    infiltration_ach = runner.getDoubleArgumentValue("AirChangesPerHour",user_arguments)

    #check infiltration for reasonableness
    if infiltration_ach < 0
      runner.registerError("The requested space infiltration Air Changes Per Hour #{infiltration_ach} 1/h was below the measure limit. Choose a positive number.")
      return false
    elsif infiltration_ach > 10.0 
      runner.registerWarning("The requested space infiltration Air Changes Per Hour  #{infiltration_ach} 1/h seems abnormally high.")
    end
	
	constSchedule = CreateConstSchedule(model, "AlwaysOnInfitration", 1)
		 
    #loop through spaces used in the model adding space infiltration objects
    spaces = model.getSpaces
    spaces.each do |space|
      if spaces.size > 0
        new_space_type_infil = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
        new_space_type_infil.setAirChangesperHour(infiltration_ach)
        new_space_type_infil.setSpace(space)
		new_space_type_infil.setSchedule(constSchedule)
      end
    end # end .each do

    # report final condition of model
    runner.registerFinalCondition("Infiltration added to #{model.getSpaces.size} spaces.")

    return true

  end

end

# register the measure to be used by the application
AddingInfiltration.new.registerWithApplication
