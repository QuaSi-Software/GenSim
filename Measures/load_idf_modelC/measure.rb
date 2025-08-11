# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class LoadIDFModelC < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'LoadIDFModel'
  end

  # human readable description
  def description
    return 'Load an existing IDF Model'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Load an existing IDF Model'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # the name of the space to add to the model
    args << OpenStudio::Measure::OSArgument.makeStringArgument('idf_file_path', true)

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # report initial condition of model
    runner.registerInitialCondition("The model started with #{model.objects.count} objects.")

    # assign the user inputs to variables
    idf_file_path = runner.getStringArgumentValue('idf_file_path', user_arguments)

    if idf_file_path.empty?
      runner.registerError("No IDF file path provided.")
      return false
    end

    unless File.exist?(idf_file_path)
      runner.registerError("The specified IDF file does not exist: #{idf_file_path}")
      return false
    end

    runner.registerInfo("IDF file path: #{idf_file_path}")
    if idf_file_path.to_s != ""
        idf_file_path = idf_file_path.to_s

        # Load the IDF file
        idf_file = OpenStudio::IdfFile.load(OpenStudio::Path.new(idf_file_path))
        if idf_file.empty?
          runner.registerError("Failed to load IDF file at #{idf_file_path}")
          return false
        end
        idf_file = idf_file.get

        # Create a ModelTranslator to convert IDF to OSM
        translator = OpenStudio::EnergyPlus::ReverseTranslator.new
        model_idf = translator.loadModel(OpenStudio::Path.new(idf_file_path))
        if model_idf.empty?
          runner.registerError("Failed to convert IDF file to OpenStudio model.")
          return false
        end
        model = model_idf.get
        #model.addObjects(model_idf.get.objects)
    end

    schedules = workspace.getObjectsByType("Schedule:Year".to_IddObjectType)
    schedules.each do |schedule|
        if(schedule.getString(1).to_s.nil?)
            runner.registerInfo("Schedule removed: " + schedule.getString(0).to_s)
            workspace.removeObject(schedule.idfObject.handle)
            schedule.remove
        end
    end

    #runner.registerInfo("Weather file status: #{model.getWeatherFile.empty? ? 'Not Found' : 'Found'}")
    # report initial condition of model
    runner.registerInfo("The building has #{model.getSpaces.size} spaces now.")
    runner.registerInfo("The building has #{model.getSurfaces.size} surfaces now.")
    # report final condition of model
    runner.registerFinalCondition("The model finished with #{model.objects.count} objects.")

    osm_file_path = idf_file_path.sub(/\.idf$/i, '.osm')
    model.save(osm_file_path, true)

    # report final condition of model
    runner.registerFinalCondition("OSM file saved successfully to: #{idf_file_path}.osm")
    return true
  end
end

# register the measure to be used by the application
LoadIDFModelC.new.registerWithApplication
