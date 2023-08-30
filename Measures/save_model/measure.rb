# start the measure
class SaveModel < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "SaveModel"
  end

  # human readable description
  def description
    return "Just saving the model to an OSM file"
  end

  # human readable description of modeling approach
  def modeler_description
    return ""
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # the name of the space to add to the model
    space_name = OpenStudio::Measure::OSArgument.makeStringArgument("output_path", true)
    space_name.setDisplayName("Path to Save")
    args << space_name
	
	# the name of the space to add to the model
    file_name = OpenStudio::Measure::OSArgument.makeStringArgument("file_name", true)
    file_name.setDisplayName("File Name")
    args << file_name

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
    pathtosave = runner.getStringArgumentValue("output_path", user_arguments)
	file_name = runner.getStringArgumentValue("file_name", user_arguments)

    # report initial condition of model
    runner.registerInitialCondition("Starting to save OSM")
  
	runner.registerInfo("Saving the osm file in the following output dir\n " + pathtosave); 
        
    FileUtils.mkdir pathtosave unless Dir.exist? pathtosave
    model.save("#{pathtosave}/#{file_name}.osm", true)
    
    # report final condition of model
    runner.registerFinalCondition("OSM file saved successfully to: #{pathtosave}/#{file_name}.osm")

    return true
  end
end

# register the measure to be used by the application
SaveModel.new.registerWithApplication
