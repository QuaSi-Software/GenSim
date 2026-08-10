# frozen_string_literal: true

# start the measure
class SetWeatherAxisTimestep < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return "SetWeatherAxisTimestep"
  end

  # general description of measure
  def description
    return "Set axis of building and time step of simulation."
  end

  # description for users of what the measure does and how it works
  def modeler_description
    return "Set axis of building and time step of simulation."
  end

  # define the arguments that the user will input
  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new

    args << OpenStudio::Measure::OSArgument.makeStringArgument("weather_file_path", true)
    args << OpenStudio::Measure::OSArgument.makeIntegerArgument("time_step", true)

    northaxis = OpenStudio::Measure::OSArgument.makeDoubleArgument("north_axis", true)
    northaxis.setDefaultValue(-9999.0)
    args << northaxis

    sizing_method = OpenStudio::Measure::OSArgument.makeChoiceArgument(
      "sizing_method",
      ["use_ddy_file", "manual_design_days", "automatic_design_days"],
      ["Use DDY file", "Manual Design Days", "Automatic Design Days"],
      true
    )
    sizing_method.setDefaultValue("automatic_design_days")
    args << sizing_method

    return args
  end

  # sizing method using the DDY file that is expected to be along the EPW weather file
  def sizing_use_ddy_file(model, runner, epw_file)
    # find the ddy files
    ddy_file = "#{File.join(File.dirname(epw_file.path.to_s), File.basename(epw_file.path.to_s, '.*'))}.ddy"
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
      return false
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
  end

  # sizing method using design days automatically determined from the weather data
  def sizing_automatic_design_days(model, runner)
    # we do add a dummy design day, so the zone sizing get properly generated
    # we remove it later in the EnergyPlus measure and we add the SizingPeriod:WeatherFileConditionType objects then, too
    # in the set_meters_idf measure
    summer_dd = OpenStudio::Model::DesignDay.new(model)
    summer_dd.setName('Dummy Design Day')
    runner.registerInfo("Added dummy design day: #{summer_dd.nameString}")
  end

  # sizing method using manually specified design days
  def sizing_manual_design_days(model, runner)
    # remove existing design days
    model.getDesignDays.each(&:remove)

    # get current version
    current_version = OpenStudio::VersionString.new(OpenStudio.openStudioVersion())

    # summer design day
    summer_dd = OpenStudio::Model::DesignDay.new(model)
    summer_dd.setName('Summer Design Day')
    summer_dd.setMaximumDryBulbTemperature(38.0)
    summer_dd.setDailyDryBulbTemperatureRange(10.0)
    summer_dd.setBarometricPressure(101325.0)
    if current_version >= OpenStudio::VersionString.new(3,2,0)
        summer_dd.setHumidityConditionType('HumidityRatio')
        summer_dd.setHumidityRatioAtMaximumDryBulb(0.012) # mass ratio water / dry_air
    end
    summer_dd.setDayType('SummerDesignDay')
    summer_dd.setMonth(7)
    summer_dd.setDayOfMonth(21)
    summer_dd.setDryBulbTemperatureRangeModifierType('DefaultMultipliers')
    summer_dd.setSkyClearness(1.0)
    summer_dd.setRainIndicator(false)
    summer_dd.setSnowIndicator(false)
    summer_dd.setWindSpeed(1.0)
    summer_dd.setWindDirection(180)
    summer_dd.setSolarModelIndicator('ASHRAEClearSky')

    # winter design day
    winter_dd = OpenStudio::Model::DesignDay.new(model)
    winter_dd.setName('Winter Design Day')
    winter_dd.setMaximumDryBulbTemperature(-13.0)
    winter_dd.setDailyDryBulbTemperatureRange(0.0)
    winter_dd.setBarometricPressure(98675.0)
    if current_version >= OpenStudio::VersionString.new(3,2,0)
        winter_dd.setHumidityConditionType('Wetbulb')
        winter_dd.setWetBulbOrDewPointAtMaximumDryBulb(-15.0)
    end
    winter_dd.setDayType('WinterDesignDay')
    winter_dd.setMonth(1)
    winter_dd.setDayOfMonth(21)
    winter_dd.setDryBulbTemperatureRangeModifierType('DefaultMultipliers')
    winter_dd.setSkyClearness(0.0)
    winter_dd.setRainIndicator(false)
    winter_dd.setSnowIndicator(true)
    winter_dd.setWindSpeed(15.0)
    winter_dd.setWindDirection(0)
    winter_dd.setSolarModelIndicator('ASHRAEClearSky')

    runner.registerInfo("Added design day: #{summer_dd.nameString}")
    runner.registerInfo("Added design day: #{winter_dd.nameString}")
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    weatherFilePath = runner.getStringArgumentValue("weather_file_path", user_arguments)
    northAxis = runner.getDoubleArgumentValue("north_axis", user_arguments)
    timestep = runner.getIntegerArgumentValue("time_step", user_arguments)
    sizing_method = runner.getStringArgumentValue("sizing_method", user_arguments)

    # read weather File and set site data
    epw_file = false
    if File.exist?(weatherFilePath) && weatherFilePath.downcase.include?(".epw")
      epw_file = OpenStudio::EpwFile.new(weatherFilePath)

      weather_name = "#{epw_file.city}_#{epw_file.stateProvinceRegion}_#{epw_file.country}"
      weather_lat = epw_file.latitude
      weather_lon = epw_file.longitude
      weather_time = epw_file.timeZone
      weather_elev = epw_file.elevation

      site = model.getSite
      site.setName(weather_name)
      site.setLatitude(weather_lat)
      site.setLongitude(weather_lon)
      site.setTimeZone(weather_time)
      site.setElevation(weather_elev)
      runner.registerInfo(
        "Set site data as '#{weather_name}' at lat #{weather_lat} lon #{weather_lon} " + 
        "elev #{weather_elev} and timezone #{weather_time}."
      )
    else
      runner.registerInfo("'#{weatherFilePath}' does not exist or is not an .epw file.")
    end

    # perform sizing depending on chosen method
    if epw_file && sizing_method == "use_ddy_file"
      sizing_use_ddy_file(model, runner, epw_file)
    elsif epw_file && sizing_method == "automatic_design_days"
      sizing_automatic_design_days(model, runner)
    elsif sizing_method == "manual_design_days"
      sizing_manual_design_days(model, runner)
    else
      runner.registerError("Required weather file missing or unknown sizing method #{sizing_method}.")
    end

    # set north axis of building
    if northAxis >= -45.0 && northAxis <= 45.0
      building = model.getBuilding
      building.setNorthAxis(northAxis)
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
      next unless space.thermalZone.empty?
      # create zones
      new_zone = OpenStudio::Model::ThermalZone.new(model)
      space.setThermalZone(new_zone)
      zone_name = space.name.get.gsub("Space", "Zone")
      new_zone.setName(zone_name)
    end

    # report final condition of model
    runner.registerFinalCondition("The weather file, axis and timestep set.")

    return true
  end
end

# register the measure to be used by the application
SetWeatherAxisTimestep.new.registerWithApplication
