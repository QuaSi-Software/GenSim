# frozen_string_literal: true

require "date"

# start the measure
class InjectHolidaysIDF < OpenStudio::Measure::EnergyPlusMeasure
  # human readable name
  def name
    return "InjectHolidaysIDF"
  end

  # general description of measure
  def description
    return "Inject holidays."
  end

  # description for users of what the measure does and how it works
  def modeler_description
    return "Inject holidays."
  end

  # define the arguments that the user will input
  def arguments(_workspace)
    args = OpenStudio::Measure::OSArgumentVector.new

    args << OpenStudio::Measure::OSArgument.makeStringArgument("holidays", true)

    return args
  end

  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # use the built-in error checking
    return false unless runner.validateUserArguments(arguments(workspace), user_arguments)

    # assign the user inputs to variables
    holidays = runner.getStringArgumentValue("holidays", user_arguments)

    # report final condition of model
    idfHolidays = workspace.getObjectsByType("RunPeriodControl:SpecialDays".to_IddObjectType)
    runner.registerInitialCondition("The building started with #{idfHolidays.size} Holiday objects.")

    number = 1
    # split the timeframes into single timeframes of format 1.1.-2.1.
    holidays.split(";").each do |timeframe|
      # Holiday
      startdate = timeframe.split("-").first
      enddate = timeframe.split("-").last
      startday = startdate.split(".").first
      startmonth = startdate.split(".").last
      endday = enddate.split(".").first
      endmonth = enddate.split(".").last

      fullstartdate = "#{startday}/#{startmonth}/2018"
      runner.registerInfo("Startdate: #{fullstartdate} ")
      fullenddate = "#{endday}/#{endmonth}/2018"
      runner.registerInfo("Enddate: #{fullenddate} ")
      diff = Date.parse(fullenddate) - Date.parse(fullstartdate)
      if diff < 0
        diff = Date.parse("#{endday}/#{endmonth}/2019") - Date.parse(fullstartdate)
      end
      runner.registerInfo("Diff: #{diff} to_i: #{diff.to_i} to_i+1: #{diff.to_i + 1}")

      idfHoliday = OpenStudio::IdfObject.new("RunPeriodControl:SpecialDays".to_IddObjectType)
      idfHoliday.setString(0, "Holiday #{number}")
      idfHoliday.setString(1, "#{startmonth}/#{startday}")
      idfHoliday.setDouble(2, diff.to_i + 1)
      idfHoliday.setString(3, "Holiday")
      workspace.addObject(idfHoliday)

      number += 1
    end

    # report final condition of model
    idfHolidays = workspace.getObjectsByType("RunPeriodControl:SpecialDays".to_IddObjectType)
    runner.registerFinalCondition("The building finished with #{idfHolidays.size} Holiday objects.")

    return true
  end
end

# register the measure to be used by the application
InjectHolidaysIDF.new.registerWithApplication
