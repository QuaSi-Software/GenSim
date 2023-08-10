# start the measure
class SetWeatherAxisTimestep < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "SetWeatherAxisTimestep"
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

    args << OpenStudio::Measure::OSArgument.makeStringArgument("weather_file_path", true)
    args << OpenStudio::Measure::OSArgument.makeIntegerArgument("time_step", true)
    northaxis = OpenStudio::Measure::OSArgument.makeDoubleArgument("north_axis", true)
    northaxis.setDefaultValue(-9999)
    args << northaxis
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    weatherFilePath = runner.getStringArgumentValue("weather_file_path", user_arguments)
    northAxis = runner.getDoubleArgumentValue("north_axis", user_arguments)
    timestep = runner.getIntegerArgumentValue("time_step", user_arguments)

    #Add Weather File
    if File.exists?(weatherFilePath) and weatherFilePath.downcase.include? ".epw"
      epw_file = OpenStudio::EpwFile.new(weatherFilePath)

      weather_name = "#{epw_file.city}_#{epw_file.stateProvinceRegion}_#{epw_file.country}"
      weather_lat = epw_file.latitude
      weather_lon = epw_file.longitude
      weather_time = epw_file.timeZone
      weather_elev = epw_file.elevation

      # Add or update site data
      site = model.getSite
      site.setName(weather_name)
      site.setLatitude(weather_lat)
      site.setLongitude(weather_lon)
      site.setTimeZone(weather_time)
      site.setElevation(weather_elev)

      runner.registerInfo("Setting site data.")

      # find the ddy files
      ddy_file = "#{File.join(File.dirname(epw_file.path.to_s), File.basename(epw_file.path.to_s, ".*"))}.ddy"
      runner.registerInfo("Looking for ddy file. #{ddy_file}")
      unless File.exist? ddy_file
        ddy_files = Dir["#{File.dirname(epw_file.path.to_s)}/*.ddy"]
        if ddy_files.size > 1
          runner.registerError("More than one ddy file in the EPW directory")
          return false
        end
        if ddy_files.empty?
          runner.registerError("could not find the ddy file in the EPW directory")
          return false
        end

        ddy_file = ddy_files.first
      end

      unless ddy_file
        runner.registerError "Could not find DDY file for #{ddy_file}"
        return error
      end

      ddy_model = OpenStudio::EnergyPlus.loadAndTranslateIdf(ddy_file).get
      ddy_model.getObjectsByType("OS:SizingPeriod:DesignDay".to_IddObjectType).each do |d|
        # grab only the ones that matter
        ddy_list = /(Htg 99.6)|(Clg .4)/
        if d.name.get =~ ddy_list
          runner.registerInfo("Adding object #{d.name}")

          # add the object to the existing model
          model.addObject(d.clone)
          runner.registerInfo("Adding design day #{d.name}.")
        end
      end
    else
      runner.registerInfo("'#{weatherFilePath}' does not exist or is not an .epw file.")
    end

    if !northAxis == -9999
      building = model.getBuilding
      building.setNorthAxis(northAxis)
    end
    repfrequency = "Hourly"
    if (timestep >= 60)
      repfrequency = "Hourly"
    else
      repfrequency = "Timestep"
    end

    meters = Array.new
    meters << "DistrictHeating:Facility"
    meters << "DistrictCooling:Facility"
    meters << "InteriorLights:Electricity"
    meters << "InteriorEquipment:Electricity"
    meters << "ElectricityProduced:Plant"
    meters << "Electricity:Facility"
    meters << "Photovoltaic:ElectricityProduced"
    #add meters
    meters.each do |meter|
      newMeter = OpenStudio::Model::OutputMeter.new(model)
      newMeter.setName(meter)
      newMeter.setReportingFrequency(repfrequency)
    end

    # create the timestep object
    osTimestep = model.getTimestep
    osTimestep.setNumberOfTimestepsPerHour(timestep)

    # ===== reporting initial condition of model
    spaces = model.getSpaces
    runner.registerInitialCondition("#{spaces.size} spaces")

    desSpec = OpenStudio::Model::DesignSpecificationOutdoorAir.new(model)
    desSpec.setName("DesSpecName")

    # ===== loop through all spaces and add a daylighting sensor with dimming to each
    spaces.each do |space|
      if space.thermalZone.empty?
        #create zones
        new_zone = OpenStudio::Model::ThermalZone.new(model)
        space.setThermalZone(new_zone)
        zone_name = space.name.get.gsub("Space", "Zone")
        new_zone.setName(zone_name)
      end
    end

    # report final condition of model
    runner.registerFinalCondition("The weather file, axis and timestep set.")

    return true
  end
end

# register the measure to be used by the application
SetWeatherAxisTimestep.new.registerWithApplication
