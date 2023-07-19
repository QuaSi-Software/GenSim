  def ConvertToDouble(argument)
	double_arg = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("double_arg",true)
	double_arg.setValue(argument)
	return double_arg.valueAsDouble
  end
  
  # create a ruleset schedule with a basic profile
  def CreateSchedule(model, name, valuesWeekday, valuesSaturday, valuesSunday, valuesHoliday, holidays, internalLoad = false, heatingTemperatureSetpoints = false)
	#ScheduleRuleset
	sch_ruleset = OpenStudio::Model::ScheduleRuleset.new(model)
	if name
		sch_ruleset.setName(name)
	end
	
	#All Days
	default_day = sch_ruleset.defaultDaySchedule
	default_day.setName("#{sch_ruleset.name} Schedule Holiday Day")
	hour = 0
	minutes = 0
	valuesHoliday.split(";").each do |v|
		minutes = minutes + 15
		if minutes >= 60
			minutes = 0
			hour = hour + 1
		end
		default_day.addValue(OpenStudio::Time.new(0, hour, minutes, 0),ConvertToDouble(v.tr(",",".")))
	end
	
	# Winter Design Day
	winter_dsn_day = OpenStudio::Model::ScheduleDay.new(model)
	sch_ruleset.setWinterDesignDaySchedule(winter_dsn_day)
	winter_dsn_day = sch_ruleset.winterDesignDaySchedule
	winter_dsn_day.setName("#{sch_ruleset.name} Winter Design Day")
	hour = 0
	minutes = 0
	values = []
	if internalLoad
		values = ["0.0"]
	elsif heatingTemperatureSetpoints
		values = valuesWeekday.split(";")
	else
		values = valuesHoliday.split(";")
	end
	values.each do |v|
		minutes = minutes + 15
		if minutes >= 60
			minutes = 0
			hour = hour + 1
		end
		winter_dsn_day.addValue(OpenStudio::Time.new(0, hour, minutes, 0),ConvertToDouble(v.tr(",",".")))
	end

	#Summer Design Day
	summer_dsn_day = OpenStudio::Model::ScheduleDay.new(model)
	sch_ruleset.setSummerDesignDaySchedule(summer_dsn_day)
	summer_dsn_day = sch_ruleset.summerDesignDaySchedule
	summer_dsn_day.setName("#{sch_ruleset.name} Summer Design Day")
	hour = 0
	minutes = 0
	valuesWeekday.split(";").each do |v|
		minutes = minutes + 15
		if minutes >= 60
			minutes = 0
			hour = hour + 1
		end
		summer_dsn_day.addValue(OpenStudio::Time.new(0, hour, minutes, 0),ConvertToDouble(v.tr(",",".")))
	end
	
	#Saturday
	sch_rule_Sat = OpenStudio::Model::ScheduleRule.new(sch_ruleset)
    day_sch = sch_rule_Sat.daySchedule
    day_sch.setName("#{sch_ruleset.name} Schedule Saturday Day")
	sch_rule_Sat.setApplySaturday(true)
	hour = 0
	minutes = 0
	valuesSaturday.split(";").each do |v|
		minutes = minutes + 15
		if minutes >= 60
			minutes = 0
			hour = hour + 1
		end
		day_sch.addValue(OpenStudio::Time.new(0, hour, minutes, 0),ConvertToDouble(v.tr(",",".")))
	end
		
	#Sunday
	sch_rule_Sun = OpenStudio::Model::ScheduleRule.new(sch_ruleset)
    day_sch = sch_rule_Sun.daySchedule
    day_sch.setName("#{sch_ruleset.name} Schedule Sunday Day")
	sch_rule_Sun.setApplySunday(true)
	hour = 0
	minutes = 0
	valuesSunday.split(";").each do |v|
		minutes = minutes + 15
		if minutes >= 60
			minutes = 0
			hour = hour + 1
		end
		day_sch.addValue(OpenStudio::Time.new(0, hour, minutes, 0),ConvertToDouble(v.tr(",",".")))
	end
	
	#Weekdays
	sch_rule_WD = OpenStudio::Model::ScheduleRule.new(sch_ruleset)
    day_sch = sch_rule_WD.daySchedule
    day_sch.setName("#{sch_ruleset.name} Schedule WeekDay")
	sch_rule_WD.setApplyMonday(true)
	sch_rule_WD.setApplyTuesday(true)
	sch_rule_WD.setApplyWednesday(true)
	sch_rule_WD.setApplyThursday(true)
	sch_rule_WD.setApplyFriday(true)
	hour = 0
	minutes = 0
	valuesWeekday.split(";").each do |v|
		minutes = minutes + 15
		if minutes >= 60
			minutes = 0
			hour = hour + 1
		end
		day_sch.addValue(OpenStudio::Time.new(0, hour, minutes, 0),ConvertToDouble(v.tr(",",".")))
	end

	return sch_ruleset
  end #end of create schedule
  
  
  # create a ruleset schedule with a basic profile
  def CreateScheduleOld(model, name, valuesWeekday, valuesSaturday, valuesSunday, valuesHoliday, holidays)
	#ScheduleRuleset
	sch_ruleset = OpenStudio::Model::ScheduleRuleset.new(model)
	if name
		sch_ruleset.setName(name)
	end

	#Winter Design Day
	winter_dsn_day = OpenStudio::Model::ScheduleDay.new(model)
	sch_ruleset.setWinterDesignDaySchedule(winter_dsn_day)
	winter_dsn_day = sch_ruleset.winterDesignDaySchedule
	winter_dsn_day.setName("#{sch_ruleset.name} Winter Design Day")
	hour = 0
	minutes = 0
	valuesSaturday.split(";").each do |v|
		minutes = minutes + 15
		if minutes >= 60
			minutes = 0
			hour = hour + 1
		end
		winter_dsn_day.addValue(OpenStudio::Time.new(0, hour, minutes, 0),0.0)
	end

	#Summer Design Day
	summer_dsn_day = OpenStudio::Model::ScheduleDay.new(model)
	sch_ruleset.setSummerDesignDaySchedule(summer_dsn_day)
	summer_dsn_day = sch_ruleset.summerDesignDaySchedule
	summer_dsn_day.setName("#{sch_ruleset.name} Summer Design Day")
	hour = 0
	minutes = 0
	valuesWeekday.split(";").each do |v|
		minutes = minutes + 15
		if minutes >= 60
			minutes = 0
			hour = hour + 1
		end
		summer_dsn_day.addValue(OpenStudio::Time.new(0, hour, minutes, 0),ConvertToDouble(v.tr(",",".")))
	end

	#All Days
	default_day = sch_ruleset.defaultDaySchedule
	default_day.setName("#{sch_ruleset.name} Schedule Week Day")
	hour = 0
	minutes = 0
	valuesWeekday.split(";").each do |v|
		minutes = minutes + 15
		if minutes >= 60
			minutes = 0
			hour = hour + 1
		end
		default_day.addValue(OpenStudio::Time.new(0, hour, minutes, 0),ConvertToDouble(v.tr(",",".")))
	end
		
	iCounter = 1
	# split the timeframes into single timeframes of format 1.1.-2.1.
	holidays.split(";").each do |timeframe|
		#Holiday
		startdate = timeframe.split("-").first
		enddate = timeframe.split("-").last
		startday = startdate.split(".").first
		startmonth = startdate.split(".").last
		endday = enddate.split(".").first
		endmonth = enddate.split(".").last
		hol_rule = OpenStudio::Model::ScheduleRule.new(sch_ruleset)
		hol_rule.setStartDate(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(startmonth.to_i), startday.to_i))
		hol_rule.setEndDate(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(endmonth.to_i), endday.to_i))
		day_sch = hol_rule.daySchedule
		day_sch.setName("#{sch_ruleset.name} Schedule Holiday Day #{iCounter}")
		hol_rule.setApplyMonday(true)
		hol_rule.setApplyTuesday(true)
		hol_rule.setApplyWednesday(true)
		hol_rule.setApplyThursday(true)
		hol_rule.setApplyFriday(true)
		hol_rule.setApplySaturday(true)
		hol_rule.setApplySunday(true)
		#hol_rule.setApplySaturday(true)
		hour = 0
		minutes = 0
		valuesHoliday.split(";").each do |v|
			minutes = minutes + 15
			if minutes >= 60
				minutes = 0
				hour = hour + 1
			end
			day_sch.addValue(OpenStudio::Time.new(0, hour, minutes, 0),ConvertToDouble(v.tr(",",".")))
		end
		
		sch_ruleset.setScheduleRuleIndex(hol_rule, iCounter)
		iCounter = iCounter + 1
	end
	
	#Saturday
	sch_rule = OpenStudio::Model::ScheduleRule.new(sch_ruleset)
    day_sch = sch_rule.daySchedule
    day_sch.setName("#{sch_ruleset.name} Schedule Saturday Day")
	sch_rule.setApplySaturday(true)
	hour = 0
	minutes = 0
	valuesSaturday.split(";").each do |v|
		minutes = minutes + 15
		if minutes >= 60
			minutes = 0
			hour = hour + 1
		end
		day_sch.addValue(OpenStudio::Time.new(0, hour, minutes, 0),ConvertToDouble(v.tr(",",".")))
	end
	sch_ruleset.setScheduleRuleIndex(sch_rule, iCounter)
	iCounter = iCounter + 1
		
	#Sunday
	sch_rule2 = OpenStudio::Model::ScheduleRule.new(sch_ruleset)
    day_sch = sch_rule2.daySchedule
    day_sch.setName("#{sch_ruleset.name} Schedule Sunday Day")
	sch_rule2.setApplySunday(true)
	hour = 0
	minutes = 0
	valuesSunday.split(";").each do |v|
		minutes = minutes + 15
		if minutes >= 60
			minutes = 0
			hour = hour + 1
		end
		day_sch.addValue(OpenStudio::Time.new(0, hour, minutes, 0),ConvertToDouble(v.tr(",",".")))
	end
	sch_ruleset.setScheduleRuleIndex(sch_rule2, iCounter)
	iCounter = iCounter + 1
		
	return sch_ruleset
  end #end of create schedule
  
  # create a ruleset schedule with a basic profile
  def CreateConstSchedule(model, name, constantValue)
	#ScheduleRuleset
	sch_ruleset = OpenStudio::Model::ScheduleRuleset.new(model)
	if name
		sch_ruleset.setName(name)
	end

	#Winter Design Day
	winter_dsn_day = OpenStudio::Model::ScheduleDay.new(model)
	sch_ruleset.setWinterDesignDaySchedule(winter_dsn_day)
	winter_dsn_day = sch_ruleset.winterDesignDaySchedule
	winter_dsn_day.setName("#{sch_ruleset.name} Winter Design Day")
	for hour in 0..24
		winter_dsn_day.addValue(OpenStudio::Time.new(0, hour, 0, 0),ConvertToDouble(constantValue))
	end

	#Summer Design Day
	summer_dsn_day = OpenStudio::Model::ScheduleDay.new(model)
	sch_ruleset.setSummerDesignDaySchedule(summer_dsn_day)
	summer_dsn_day = sch_ruleset.summerDesignDaySchedule
	summer_dsn_day.setName("#{sch_ruleset.name} Summer Design Day")
	for hour in 0..24
		summer_dsn_day.addValue(OpenStudio::Time.new(0, hour, 0, 0),ConvertToDouble(constantValue))
	end

	#All Days
	default_day = sch_ruleset.defaultDaySchedule
	default_day.setName("#{sch_ruleset.name} Schedule Week Day")
	for hour in 0..24
		default_day.addValue(OpenStudio::Time.new(0, hour, 0, 0),ConvertToDouble(constantValue))
	end
	
	result = sch_ruleset
	return result
  end #end of create schedule
