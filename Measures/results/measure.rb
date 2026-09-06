require 'erb'
require_relative '../output_variables'

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
  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new

    args << OpenStudio::Measure::OSArgument::makeIntegerArgument("timestep", true)

    as_gross = OpenStudio::Measure::OSArgument::makeBoolArgument("calculate_relative_gross", true)
    as_gross.setDefaultValue(false)
    args << as_gross

    gross_area = OpenStudio::Measure::OSArgument::makeDoubleArgument("gross_area", true)
    gross_area.setDefaultValue(1)
    args << gross_area

    as_net = OpenStudio::Measure::OSArgument::makeBoolArgument("calculate_relative_net", true)
    as_net.setDefaultValue(false)
    args << as_net

    net_area = OpenStudio::Measure::OSArgument::makeDoubleArgument("net_area", true)
    net_area.setDefaultValue(1)
    args << net_area

    output_level = OpenStudio::Measure::OSArgument::makeStringArgument("output_level", false)
    output_level.setDefaultValue("Normal")

    args << output_level

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

    factors = {}
    values = {}

    for key in output_timeseries.keys
      value = nil
      for timeseries in output_timeseries[key]
        if value.nil?
          value = timeseries.values
        else
          value += timeseries.values
        end
      end
      values[key] = value

      if key.include?("[Wh]")
        factors[key] = conversion_factors[key] / area
      else
        factors[key] = conversion_factors[key]
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
          value = values[key][i]
          if value.kind_of?(Array)
            converted_value = sum(value) * factors[key]
          else
            converted_value = value * factors[key]
          end
          row << converted_value
        end
      end
      csv_array << row
    end

    row_annual = []
    for key in headers.uniq[1..-1]
      sum = 0
      for i in 0..num_times
        value = values[key][i]
        if value.kind_of?(Array)
          sum += sum(value) / value.length
        else
          sum += value
        end
      end
      row_annual << sum * factors[key]
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
    if !runner.validateUserArguments(arguments("dummy"), user_arguments)
      return false
    end

    # read parameter values
    timestep = runner.getIntegerArgumentValue("timestep", user_arguments)
    gross = runner.getBoolArgumentValue("calculate_relative_gross", user_arguments)
    net = runner.getBoolArgumentValue("calculate_relative_net", user_arguments)
    gross_area = runner.getDoubleArgumentValue("gross_area", user_arguments)
    net_area = runner.getDoubleArgumentValue("net_area", user_arguments)
    output_level = runner.getStringArgumentValue("output_level", user_arguments)

    # reporting frequencies should probably be a parameter, but there is little reason to
    # not check all channels. however only "Zone Timestep" seems to contain any data at all
    reporting_frequency = "All"
    runner.registerInfo("Reporting frequency is #{reporting_frequency}")

    if reporting_frequency == "All"
      reporting_frequencies = ["Hourly", "Zone Timestep", "HVAC System Timestep"]
    else
      reporting_frequencies = [reporting_frequency]
    end

    # read list of output variables and meters and set names (meters are all upper case
    # for unknown reasons)
    list_of_variables = {}
    get_output_variables(output_level).each do |var_def|
      if var_def["create_output_variable"]
        list_of_variables[var_def["name"]] = true
      end
      if var_def["create_output_meter"]
        list_of_variables[("Meter " + var_def["name"]).upcase] = true
      end
    end

    # now read the data from the SQLite database
    sqlFile = getSQLFile(runner)
    return false unless sqlFile

    ann_env_pd = getEnvPeriod(runner, sqlFile)

    reporting_frequencies.each do |rep_freq|
      runner.registerInfo("***********************************************")
      runner.registerInfo("***********************************************")
      runner.registerInfo("Reporting Frequency = #{rep_freq}")
      runner.registerInfo("Environmental Period = #{ann_env_pd}")

      headers = ["#{rep_freq}"]
      output_timeseries = {}
      conversion_factors = {}

      variable_names = sqlFile.availableVariableNames(ann_env_pd, rep_freq)
      variable_names.each do |variable_name|
        runner.registerInfo("****************************")
        runner.registerInfo("Variable Name = #{variable_name}")

        if !list_of_variables.include? variable_name.to_s
          runner.registerInfo("Skipping variable due to output filtering")
          next
        end

        time_series_vec = sqlFile.timeSeries(ann_env_pd, rep_freq, variable_name.to_s)
        if time_series_vec.empty?
          runner.registerWarning("Time series for #{variable_name} is empty.")
          next
        end

        time_series_vec.each do |time_series|
          units = time_series.units
          headerunits = units
          if (units == "J") or (units == "W")
            headerunits = "Wh"
          end
          header = "#{variable_name}[#{headerunits}]"
          headers << header

          if !output_timeseries.include?(header)
            output_timeseries[header] = []
          end
          output_timeseries[header] << time_series

          if units == "J"
            conversion_factors[header] = 1.0 / 3600
          elsif units == "W"
            conversion_factors[header] = 1.0 / timestep
          else
            conversion_factors[header] = 1.0
          end
        end
      end

      if output_timeseries.empty?
        runner.registerInfo("No output variables found at reporting frequency = #{rep_freq}")
        next
      end

      # write output for absolute values, and optionally relative to gross and net area
      csvFileName = rep_freq.delete(' ')
      saveToCSVFile(runner, output_timeseries, headers, conversion_factors, 1, csvFileName)
      if gross
        saveToCSVFile(
          runner, output_timeseries, headers, conversion_factors,
          gross_area, csvFileName + "-gross"
        )
      end
      if net
        saveToCSVFile(
          runner, output_timeseries, headers, conversion_factors,
          net_area, csvFileName + "-net"
        )
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
