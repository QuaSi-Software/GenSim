# *******************************************************************************
# OpenStudio(R), Copyright (c) Alliance for Sustainable Energy, LLC.
# See also https://openstudio.net/license
# *******************************************************************************

# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

require 'erb'

# start the measure
class Results < OpenStudio::Measure::ReportingMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Results'
  end

  # human readable description
  def description
    return 'Create CSV output from SQL file'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Create CSV output from SQL file'
  end

  # define the arguments that the user will input
  def arguments(model = nil)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make an argument for the reporting frequency
    args << OpenStudio::Measure::OSArgument::makeIntegerArgument("Timestep",true)
    gross = OpenStudio::Measure::OSArgument::makeBoolArgument("IntensityResultsGross",true)
    gross.setDefaultValue(false)
    args << gross
    gross_area = OpenStudio::Measure::OSArgument::makeDoubleArgument("GrossArea",true)
    gross_area.setDefaultValue(1)
    args << gross_area
    netto = OpenStudio::Measure::OSArgument::makeBoolArgument("IntensityResultsNet",true)
    netto.setDefaultValue(false)
    args << netto
    gross_net = OpenStudio::Measure::OSArgument::makeDoubleArgument("NetArea",true)
    gross_net.setDefaultValue(1)
    args << gross_net
    debug = OpenStudio::Measure::OSArgument::makeBoolArgument("Debug",false)
    debug.setDefaultValue(false)
    args << debug

    return args
  end

  def getSQLFile(runner)
    sqlFile = runner.lastEnergyPlusSqlFile
    if sqlFile.empty?
      runner.registerError("Cannot find last sql file.")
      return false
    end
    sqlFile = sqlFile.get
    runner.registerInfo("SQL file found")
    return sqlFile
  end

  def getEnvPeriod(runner, sqlFile)
    # get the weather file run period (as opposed to design day run period)
    ann_env_pd = nil
    sqlFile.availableEnvPeriods.each do |env_pd|
      env_type = sqlFile.environmentType(env_pd)
      if env_type.is_initialized
        if env_type.get == OpenStudio::EnvironmentType.new("WeatherRunPeriod")
          ann_env_pd = env_pd
          runner.registerInfo("Found weather run period #{env_pd}")
          break
        end
      end
    end
    return ann_env_pd
  end

  def saveToCSVFile(runner, output_timeseries, headers, conversion_factors, area, csvFileName)
    csv_array = []
    csv_array << headers.uniq

    csv_array_annual = []
    csv_array_annual << headers.drop(1).uniq

    date_times = output_timeseries[output_timeseries.keys[0]][0].dateTimes

    values = {}

    for key in output_timeseries.keys
      if output_timeseries.count > 1
        value = nil
        for timeseries in output_timeseries[key]
          if value.nil?
            value = timeseries.values
          else
            value += timeseries.values
          end
        end
        values[key] = value 
      else
        values[key] = output_timeseries[key].values
      end
    end

    num_times = date_times.size - 1
    for i in 0..num_times
      date_time = date_times[i]
      row = []
      row << date_time
      last_key = ""
      for key in headers[1..-1]
        if last_key != key
          last_key = key
          runner.registerInfo("key (#{key})")
          value = values[key][i]
          if value.kind_of?(Array)
            runner.registerInfo("Value is an array #{value}")
          else
            converted_value = value * conversion_factors[key] / area
            row << converted_value
          end
        end
      end
      csv_array << row
    end

    row_annual = []
    for key in headers[1..-1]
      sum = 0
      for i in 0..num_times
        sum += values[key][i]
      end
      row_annual << sum * conversion_factors[key] / area
    end
    csv_array_annual << row_annual

    File.open("./report_variables_#{csvFileName}.csv", 'wb') do |file|
      csv_array.each do |elem|
        file.puts elem.join(',')
      end
    end

    File.open("./report_variables_#{csvFileName}-Sum.csv", 'wb') do |file|
      csv_array_annual.each do |elem|
        file.puts elem.join(',')
      end
    end

    runner.registerInfo("Output file written to #{File.expand_path('.')}")
    return csv_array_annual
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(), user_arguments)
      return false
    end

    #assign the user inputs to variables
    timestep = runner.getIntegerArgumentValue("Timestep",user_arguments)
    gross = runner.getBoolArgumentValue("IntensityResultsGross",user_arguments)
    net = runner.getBoolArgumentValue("IntensityResultsNet",user_arguments)
    gross_area = runner.getDoubleArgumentValue("GrossArea",user_arguments)
    net_area = runner.getDoubleArgumentValue("NetArea",user_arguments)
    debug = runner.getBoolArgumentValue("Debug",user_arguments)

    reporting_frequency = "All"

    list_of_variables = []
    list_of_variables << "DistrictCooling:Facility"
    list_of_variables << "DistrictHeating:Facility"

    # HEAT LOSS
    list_of_variables << "METER SURFACE AVERAGE FACE CONDUCTION HEAT TRANSFER ENERGY"
    list_of_variables << "METER SURFACE AVERAGE FACE CONDUCTION HEAT LOSS RATE"
    list_of_variables << "METER SURFACE WINDOW HEAT LOSS ENERGY"
    # NEW VARIABLES
    list_of_variables << "METER SURFACE OUTSIDE FACE CONDUCTION HEAT LOSS RATE"
    list_of_variables << "Surface Outside Face Conduction Heat Loss Rate"
    list_of_variables << "Surface Average Face Conduction Heat Loss Rate"
    list_of_variables << "Surface Inside Face Conduction Heat Loss Rate"

    # INFILTRATION AND VENTILATION
    list_of_variables << "METER ZONE INFILTRATION HEAT LOSS"
    list_of_variables << "METER ZONE INFILTRATION HEAT GAIN"
    list_of_variables << "METER ZONE VENTILATION HEAT LOSS"
    list_of_variables << "METER ZONE VENTILATION HEAT GAIN"

    # MECH LOSS
    list_of_variables << "METER MECHANICAL VENTILATION LOSS"

    # HEAT GAIN
    list_of_variables << "METER SURFACE AVERAGE FACE CONDUCTION HEAT GAIN RATE"
    list_of_variables << "METER SURFACE WINDOW HEAT GAIN ENERGY"
    # INFILTRATION AND VENTILATION
    list_of_variables << "METER ZONE ELECTRIC EQUIPMENT TOTAL HEATING ENERGY"
    list_of_variables << "METER ZONE LIGHTS TOTAL HEATING ENERGY"
    list_of_variables << "METER PEOPLE TOTAL HEATING ENERGY"
    # new variables
    list_of_variables << "METER SURFACE OUTSIDE FACE CONDUCTION HEAT GAIN RATE"
    list_of_variables << "METER MECHANICAL VENTILATION GAIN'"
    list_of_variables << "METER ZONE WINDOWS TOTAL TRANSMITTED SOLAR RADIATION ENERGY"
    list_of_variables << "Surface Outside Face Conduction Heat Gain Rate"
    list_of_variables << "Surface Average Face Conduction Heat Gain Rate"
    list_of_variables << "Surface Inside Face Conduction Heat Gain Rate"

    # electricty
    list_of_variables << "InteriorLights:Electricity"
    list_of_variables << "InteriorEquipment:Electricity"
    list_of_variables << "Fans:Electricity"
    list_of_variables << "Pumps:Electricity"

    # internal loads
    list_of_variables << "METER INTERNAL LOADS HEATING ENERGY"
    list_of_variables << "METER MECHANICAL VENTILATION GAIN"

    list_of_variables << "Facility Heating Setpoint Not Met Time"
    list_of_variables << "Facility Heating Setpoint Not Met While Occupied Time"
    list_of_variables << "Facility Cooling Setpoint Not Met Time"
    list_of_variables << "Facility Cooling Setpoint Not Met While Occupied Time"

    sqlFile = getSQLFile(runner)

    ann_env_pd = getEnvPeriod(runner, sqlFile)

    runner.registerInfo("reporting frequency is #{reporting_frequency}")

    reporting_frequencies = {}
    if reporting_frequency == "All"
      reporting_frequencies = ["Hourly","Zone Timestep","HVAC System Timestep"]
    else
      reporting_frequencies << reporting_frequency
    end

    reporting_frequencies.each do |reporting_frequency|
      puts "***********************************************"
      puts "***********************************************"
      puts "Reporting Frequency = #{reporting_frequency}"

      headers = ["#{reporting_frequency}"]
      headers_filtered = ["#{reporting_frequency}"]
      output_timeseries = {}
      output_timeseries_filtered = {}
      conversion_factors = {}
      conversion_factors_filtered = {}

      variable_names = sqlFile.availableVariableNames(ann_env_pd, reporting_frequency)
      variable_names.each do |variable_name|
        puts "****************************"
        puts "Variable Name = #{variable_name}"
        key_values = sqlFile.availableKeyValues(ann_env_pd, reporting_frequency, variable_name.to_s)
        if key_values.size == 0
          runner.registerError("Timeseries for #{variable_name} did not have any key values. No timeseries available.")
        end

        bInit = true
        key_values.each do |key_value|
          puts "Key = #{key_value}"
          timeseries = sqlFile.timeSeries(ann_env_pd, reporting_frequency, variable_name.to_s, key_value.to_s)
          if !timeseries.empty?
            timeseries = timeseries.get
            units = timeseries.units
            headerunits = units
            if (units == "J") or (units == "W")
              headerunits = "Wh"
            end
            headers << "#{variable_name.to_s}[#{headerunits}]"
            if bInit
              output_timeseries[headers[-1]] = []
            end
            output_timeseries[headers[-1]] << timeseries
            if units == "J"
              conversion_factors[headers[-1]] = 1.0 / 3600
            elsif units == "W"
              conversion_factors[headers[-1]] = 1.0 / timestep
            else
              conversion_factors[headers[-1]] = 1.0
            end
            if list_of_variables.include? variable_name.to_s
              headers_filtered << "#{variable_name.to_s}[#{headerunits}]"
              if bInit
                output_timeseries_filtered[headers_filtered[-1]] = []
              end
              output_timeseries_filtered[headers_filtered[-1]] << timeseries
              if units == "J"
                conversion_factors_filtered[headers_filtered[-1]] = 1.0 / 3600
              elsif units == "W"
                conversion_factors_filtered[headers_filtered[-1]] = 1.0 / timestep
              else
                conversion_factors_filtered[headers_filtered[-1]] = 1.0
              end
            end
            bInit = false
          else
            runner.registerWarning("Timeseries for #{key_value} #{variable_name} is empty.")
          end
        end
      end

      if output_timeseries.empty?
        puts "No output variables found at reporting frequency = #{reporting_frequency}"
        next
      end

      csvFileName = reporting_frequency.delete(' ')
      if debug
        data = saveToCSVFile(runner, output_timeseries, headers, conversion_factors, 1, csvFileName + "Debug")
        if gross
          data = saveToCSVFile(runner, output_timeseries, headers, conversion_factors, gross_area, csvFileName + "Debug-gross")
        end
        if net
          data = saveToCSVFile(runner, output_timeseries, headers, conversion_factors, net_area, csvFileName + "Debug-net")
        end
      end

      if output_timeseries_filtered.empty?
        puts "No filtered output variables found at reporting frequency = #{reporting_frequency}"
        next
      end

      data_annual = saveToCSVFile(runner, output_timeseries_filtered, headers_filtered, conversion_factors_filtered, 1, csvFileName)
      if gross
        data = saveToCSVFile(runner, output_timeseries_filtered, headers_filtered, conversion_factors_filtered, gross_area, csvFileName + "-gross")
      end
      if net
        data = saveToCSVFile(runner, output_timeseries_filtered, headers_filtered, conversion_factors_filtered, net_area, csvFileName + "-net")
      end
    end

    # close the sql file
    sqlFile.close()
    runner.registerInfo("Closing the SQL file.")

    return true
  end
end

# register the measure to be used by the application
Results.new.registerWithApplication
