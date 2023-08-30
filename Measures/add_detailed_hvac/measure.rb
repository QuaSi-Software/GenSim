# frozen_string_literal: true

require_relative "../NewHelper"

# start the measure
class AddDetailedHVAC < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return "AddDetailedHVAC"
  end

  # general description of measure
  def description
    return "This measure adds a DOAS air loop and a radiant ceiling heating and cooling component that connects to a hot and chilled water loop with district heating and cooling."
  end

  # description for users of what the measure does and how it works
  def modeler_description
    return "Add geometry from simple inputs."
  end

  # define the arguments that the user will input
  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new
    heat_recovery_method = OpenStudio::Measure::OSArgument.makeStringArgument("heat_recovery_method", true)
    heat_recovery_method.setDisplayName("Heat recovery method")
    heat_recovery_method.setDefaultValue("none")
    args << heat_recovery_method
    latent_efficiency = OpenStudio::Measure::OSArgument.makeDoubleArgument("latent_efficiency", true)
    latent_efficiency.setDisplayName("Latent efficiency")
    latent_efficiency.setDefaultValue(0.65)
    args << latent_efficiency
    sensible_efficiency = OpenStudio::Measure::OSArgument.makeDoubleArgument("sensible_efficiency", true)
    sensible_efficiency.setDisplayName("Sensible efficiency")
    sensible_efficiency.setDefaultValue(0.7)
    args << sensible_efficiency
    ach_per_hour = OpenStudio::Measure::OSArgument.makeDoubleArgument("ach_per_hour", true)
    ach_per_hour.setDisplayName("Air changes per hour")
    ach_per_hour.setDefaultValue(1)
    args << ach_per_hour
    nfa_gfa_ratio = OpenStudio::Measure::OSArgument.makeDoubleArgument("nfa_gfa_ratio", true)
    nfa_gfa_ratio.setDisplayName("Ratio of NFA over GFA")
    nfa_gfa_ratio.setDefaultValue(1)
    args << nfa_gfa_ratio
    floor_height_ratio = OpenStudio::Measure::OSArgument.makeDoubleArgument("floor_height_ratio", true)
    floor_height_ratio.setDisplayName("Ratio of conditioned floor height over total floor height")
    floor_height_ratio.setDefaultValue(1)
    args << floor_height_ratio

    args << OpenStudio::Measure::OSArgument.makeStringArgument("hvac_schedule", false)
    args << OpenStudio::Measure::OSArgument.makeBoolArgument("is_custom_hvac", false)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("hvac_sched_weekday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("hvac_sched_saturday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("hvac_sched_sunday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("hvac_sched_holiday", false)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("holidays", false)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zone_heating_temp_sched_weekday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zone_heating_temp_sched_saturday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zone_heating_temp_sched_sunday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zone_heating_temp_sched_holiday", false)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zone_cooling_temp_sched_weekday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zone_cooling_temp_sched_saturday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zone_cooling_temp_sched_sunday", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zone_cooling_temp_sched_holiday", false)
    hot_water_temp_setpoint = OpenStudio::Measure::OSArgument.makeDoubleArgument("hot_water_temp_setpoint", true)
    hot_water_temp_setpoint.setDisplayName("Hot water temperature setpoint")
    hot_water_temp_setpoint.setDefaultValue(50)
    args << hot_water_temp_setpoint
    hot_water_temp_diff = OpenStudio::Measure::OSArgument.makeDoubleArgument("hot_water_temp_diff", true)
    hot_water_temp_diff.setDisplayName("Hot water temperature difference")
    hot_water_temp_diff.setDefaultValue(5)
    args << hot_water_temp_diff
    cold_water_temp_setpoint = OpenStudio::Measure::OSArgument.makeDoubleArgument("cold_water_temp_setpoint", true)
    cold_water_temp_setpoint.setDisplayName("Cold water temperature setpoint")
    cold_water_temp_setpoint.setDefaultValue(15)
    args << cold_water_temp_setpoint
    cold_water_temp_diff = OpenStudio::Measure::OSArgument.makeDoubleArgument("cold_water_temp_diff", true)
    cold_water_temp_diff.setDisplayName("Cold water temperature difference")
    cold_water_temp_diff.setDefaultValue(5)
    args << cold_water_temp_diff
    supply_fan_pressure_rise = OpenStudio::Measure::OSArgument.makeDoubleArgument("supply_fan_pressure_rise", true)
    supply_fan_pressure_rise.setDisplayName("Supply fan pressure rise")
    supply_fan_pressure_rise.setDefaultValue(250)
    args << supply_fan_pressure_rise
    return_fan_pressure_rise = OpenStudio::Measure::OSArgument.makeDoubleArgument("return_fan_pressure_rise", true)
    return_fan_pressure_rise.setDisplayName("Return fan pressure rise")
    return_fan_pressure_rise.setDefaultValue(250)
    args << return_fan_pressure_rise
    system_type = OpenStudio::Measure::OSArgument.makeDoubleArgument("system_type", true)
    system_type.setDisplayName("Type of ventilation system")
    system_type.setDefaultValue(1)
    args << system_type

    # hot water temperature schedule use default of 67??
    # pressure rise
    # hot water loop exit temperature
    # hot water loop temp difference
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    # Abruf der Variablen
    heat_recovery_method = runner.getStringArgumentValue("heat_recovery_method", user_arguments)
    latent_efficiency = runner.getDoubleArgumentValue("latent_efficiency", user_arguments)
    sensible_efficiency = runner.getDoubleArgumentValue("sensible_efficiency", user_arguments)
    ach_per_hour = runner.getDoubleArgumentValue("ach_per_hour", user_arguments)
    nfa_gfa_ratio = runner.getDoubleArgumentValue("nfa_gfa_ratio", user_arguments)
    floor_height_ratio = runner.getDoubleArgumentValue("floor_height_ratio", user_arguments)

    hvac_sched_weekday = runner.getStringArgumentValue("hvac_sched_weekday", user_arguments)
    hvac_sched_saturday = runner.getStringArgumentValue("hvac_sched_saturday", user_arguments)
    hvac_sched_sunday = runner.getStringArgumentValue("hvac_sched_sunday", user_arguments)
    hvac_sched_holiday = runner.getStringArgumentValue("hvac_sched_holiday", user_arguments)
    holidays = runner.getStringArgumentValue("holidays", user_arguments)
    zone_heating_temp_sched_weekday = runner.getStringArgumentValue("zone_heating_temp_sched_weekday", user_arguments)
    zone_heating_temp_sched_saturday = runner.getStringArgumentValue("zone_heating_temp_sched_saturday", user_arguments)
    zone_heating_temp_sched_sunday = runner.getStringArgumentValue("zone_heating_temp_sched_sunday", user_arguments)
    zone_heating_temp_sched_holiday = runner.getStringArgumentValue("zone_heating_temp_sched_holiday", user_arguments)
    zone_cooling_temp_sched_weekday = runner.getStringArgumentValue("zone_cooling_temp_sched_weekday", user_arguments)
    zone_cooling_temp_sched_saturday = runner.getStringArgumentValue("zone_cooling_temp_sched_saturday", user_arguments)
    zone_cooling_temp_sched_sunday = runner.getStringArgumentValue("zone_cooling_temp_sched_sunday", user_arguments)
    zone_cooling_temp_sched_holiday = runner.getStringArgumentValue("zone_cooling_temp_sched_holiday", user_arguments)
    hot_water_temp_setpoint = runner.getDoubleArgumentValue("hot_water_temp_setpoint", user_arguments)
    hot_water_temp_diff = runner.getDoubleArgumentValue("hot_water_temp_diff", user_arguments)
    cold_water_temp_setpoint = runner.getDoubleArgumentValue("cold_water_temp_setpoint", user_arguments)
    cold_water_temp_diff = runner.getDoubleArgumentValue("cold_water_temp_diff", user_arguments)
    supply_fan_pressure_rise = runner.getDoubleArgumentValue("supply_fan_pressure_rise", user_arguments)
    return_fan_pressure_rise = runner.getDoubleArgumentValue("return_fan_pressure_rise", user_arguments)
    system_type = runner.getDoubleArgumentValue("system_type", user_arguments)

    hvacSched = CreateSchedule(model, "HVACSched", hvac_sched_weekday, hvac_sched_saturday, hvac_sched_sunday, hvac_sched_holiday, holidays)
    zoneHeatingTempSched = CreateSchedule(model, "ZoneHeatingTempSched", zone_heating_temp_sched_weekday, zone_heating_temp_sched_saturday, zone_heating_temp_sched_sunday, zone_heating_temp_sched_holiday, holidays, false, true)
    zoneCoolingTempSched = CreateSchedule(model, "ZoneCoolingTempSched", zone_cooling_temp_sched_weekday, zone_cooling_temp_sched_saturday, zone_cooling_temp_sched_sunday, zone_cooling_temp_sched_holiday, holidays)

    # rescale air change rate to conditioned volume and GFA
    ach_per_hour = ach_per_hour * nfa_gfa_ratio * floor_height_ratio

    air_loop_comps = []
    # creating the DOAS air loop
    airLoopHVAC = OpenStudio::Model::AirLoopHVAC.new(model)
    airLoopHVAC.setName("DOAS Air Loop")
    sizingSystem = airLoopHVAC.sizingSystem()
    sizingSystem.setTypeofLoadtoSizeOn("VentilationRequirement")

    if system_type == 2
      # if we do not have heat recovery we add only a return fan
      supplyFan = OpenStudio::Model::FanConstantVolume.new(model, hvacSched)
      supplyFan.setName("Supply Fan")
      supplyFan.setPressureRise(supply_fan_pressure_rise)
      supplyFan.setFanEfficiency(1)
      air_loop_comps << supplyFan
    end

    controller_OA = OpenStudio::Model::ControllerOutdoorAir.new(model)
    controller_OA.autosizeMinimumOutdoorAirFlowRate
    controller_OA.autosizeMaximumOutdoorAirFlowRate
    controller_OA.setMinimumFractionofOutdoorAirSchedule(model.alwaysOnDiscreteSchedule)
    controller_OA.setMaximumFractionofOutdoorAirSchedule(model.alwaysOnDiscreteSchedule)

    system_OA = OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model, controller_OA)
    air_loop_comps << system_OA
    # for now no heating or cooling coils

    returnFan = OpenStudio::Model::FanConstantVolume.new(model, hvacSched)
    returnFan.setName("Return Fan")
    returnFan.setPressureRise(return_fan_pressure_rise)
    returnFan.setFanEfficiency(1)
    air_loop_comps << returnFan

    if (heat_recovery_method == "Sensible") || (heat_recovery_method == "Enthalpy")
      runner.registerInfo("system_OA.outboardOANode:  #{system_OA.outboardOANode.get}")
      runner.registerInfo("system_OA.outboardReliefNode:  #{system_OA.outboardReliefNode.get}")

      heat_exchanger = OpenStudio::Model::HeatExchangerAirToAirSensibleAndLatent.new(model)
      heat_exchanger.setAvailabilitySchedule(hvacSched)
      heat_exchanger.setSensibleEffectivenessat100CoolingAirFlow(sensible_efficiency)
      heat_exchanger.setSensibleEffectivenessat100HeatingAirFlow(sensible_efficiency)
      heat_exchanger.setSensibleEffectivenessat75CoolingAirFlow(sensible_efficiency)
      heat_exchanger.setSensibleEffectivenessat75HeatingAirFlow(sensible_efficiency)
      if heat_recovery_method == "Enthalpy"
        heat_exchanger.setLatentEffectivenessat100CoolingAirFlow(latent_efficiency)
        heat_exchanger.setLatentEffectivenessat100HeatingAirFlow(latent_efficiency)
        heat_exchanger.setLatentEffectivenessat75CoolingAirFlow(latent_efficiency)
        heat_exchanger.setLatentEffectivenessat75HeatingAirFlow(latent_efficiency)
      else
        heat_exchanger.setLatentEffectivenessat100CoolingAirFlow(0)
        heat_exchanger.setLatentEffectivenessat100HeatingAirFlow(0)
        heat_exchanger.setLatentEffectivenessat75CoolingAirFlow(0)
        heat_exchanger.setLatentEffectivenessat75HeatingAirFlow(0)
      end
      heat_exchanger.setSupplyAirOutletTemperatureControl(true)
      heat_exchanger.addToNode(system_OA.outboardOANode.get)

      runner.registerInfo("heat_exchanger.primaryAirInletPort:  #{heat_exchanger.primaryAirInletPort}")
      runner.registerInfo("heat_exchanger.primaryAirOutletPort:  #{heat_exchanger.primaryAirOutletPort}")
      runner.registerInfo("heat_exchanger.secondaryAirInletPort:  #{heat_exchanger.secondaryAirInletPort}")
      runner.registerInfo("heat_exchanger.secondaryAirOutletPort:  #{heat_exchanger.secondaryAirOutletPort}")

      day_sched_30 = OpenStudio::Model::ScheduleDay.new(model, 27)
      day_sched_30.setName("SAT Day Schedule 30 deg C")
      day_sched_10 = OpenStudio::Model::ScheduleDay.new(model, 18)
      day_sched_30.setName("SAT Day Schedule 10 deg C")

      week_sched_30 = OpenStudio::Model::ScheduleWeek.new(model)
      week_sched_30.setAllSchedules(day_sched_30)
      week_sched_30.setName("SAT Week Schedule 30 deg C")

      week_sched_10 = OpenStudio::Model::ScheduleWeek.new(model)
      week_sched_10.setAllSchedules(day_sched_10)
      week_sched_10.setName("SAT Week Schedule 10 deg C")

      sat_sched = OpenStudio::Model::ScheduleYear.new(model)
      sat_sched.setName("SAT Year Schedule")
      # for now we check the latitude and if it is possitive then summer is in the middle of the calendar year
      if model.getSite.latitude > 0
        runner.registerInfo("latitude is:  #{model.getSite.latitude} -> summer is in the middle of the calendar year")
        sat_sched.addScheduleWeek(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(5), 1), week_sched_30)
        sat_sched.addScheduleWeek(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(10), 1), week_sched_10)
        sat_sched.addScheduleWeek(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(12), 31), week_sched_30)
      else
        runner.registerInfo("latitude is:  #{model.getSite.latitude} -> summer is at the beginning and end of the calendar year")
        sat_sched.addScheduleWeek(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(5), 1), week_sched_10)
        sat_sched.addScheduleWeek(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(10), 1), week_sched_30)
        sat_sched.addScheduleWeek(OpenStudio::Date.new(OpenStudio::MonthOfYear.new(12), 31), week_sched_10)
      end

      setpoint_scheduled = OpenStudio::Model::SetpointManagerScheduled.new(model, "Temperature", sat_sched)
      erv_outlet = heat_exchanger.primaryAirOutletModelObject.get.to_Node.get
      setpoint_scheduled.addToNode(erv_outlet)

      # Add setpoint manager, normally this would be a
      # SetpointManagerOutdoorAirPretreat, but you can use any
    end

    # add the components to the airloop
    air_loop_comps.each do |comp|
      comp.addToNode(airLoopHVAC.supplyInletNode)
      if comp.to_CoilHeatingWater.is_initialized
        options["hot_water_plant"].addDemandBranchForComponent(comp)
        comp.controllerWaterCoil.get.setMinimumActuatedFlow(0)
      elsif comp.to_CoilCoolingWater.is_initialized
        options["chilled_water_plant"].addDemandBranchForComponent(comp)
        comp.controllerWaterCoil.get.setMinimumActuatedFlow(0)
      end
    end

    # add thermal zones to airloop
    thermalZones = model.getThermalZones
    thermalZones.each do |zone|
      # make an air terminal for the zone
      air_terminal = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(model, hvacSched)
      air_terminal.autosizeMaximumAirFlowRate
      # attach new terminal to the zone and to the airloop
      airLoopHVAC.addBranchForZone(zone, air_terminal.to_StraightComponent)
      # zone sizing
      zoneSizing = zone.sizingZone
      zoneSizing.setName(" #{zone.name} Sizing")

      designSpecOA = OpenStudio::Model::DesignSpecificationOutdoorAir.new(model)
      designSpecOA.setOutdoorAirMethod("AirChanges/Hour") # Flow/Person  Flow/Area Flow/Zone AirChanges/Hour Sum Maximum
      # designSpecOA.setOutdoorAirFlowperPerson()
      # designSpecOA.setOutdoorAirFlowperFloorArea()
      # designSpecOA.setOutdoorAirFlowRate()
      designSpecOA.setOutdoorAirFlowAirChangesperHour(ach_per_hour)

      zone.spaces.each do |space|
        space.setDesignSpecificationOutdoorAir(designSpecOA)
      end
    end

    # we are looking for the ChilledCeilingConstruction
    chilledCeilingConstruction = nil
    constructions = model.getConstructionWithInternalSources
    constructions.each do |construction|
      runner.registerInfo("#{construction.name} contruction found.")
      if construction.name.to_s == "ChilledCeilingConstruction"
        chilledCeilingConstruction = construction
      end
    end
    if chilledCeilingConstruction.nil?
      # now we create the default chilled ceiling construction
      metalMaterial = OpenStudio::Model::StandardOpaqueMaterial.new(model, "Smooth", 0.01, 45, 7824, 800)
      metalMaterial.setName("F08 Metal surface")

      insBoardMaterial = OpenStudio::Model::StandardOpaqueMaterial.new(model, "Smooth", 0.0254, 0.03, 43, 1210)
      insBoardMaterial.setName("I01 25mm insulation board")

      # construction with internal source
      chilledCeilingConstruction = OpenStudio::Model::ConstructionWithInternalSource.new(model)
      chilledCeilingConstruction.setSourcePresentAfterLayerNumber(1)
      chilledCeilingConstruction.setTemperatureCalculationRequestedAfterLayerNumber(1)
      chilledCeilingConstruction.setDimensionsForTheCTFCalculation(1)
      chilledCeilingConstruction.setTubeSpacing(0.15)
      chilledCeilingConstruction.insertLayer(chilledCeilingConstruction.numLayers, insBoardMaterial)
      chilledCeilingConstruction.insertLayer(chilledCeilingConstruction.numLayers, metalMaterial)
    end

    # internal mass
    intMassDef = OpenStudio::Model::InternalMassDefinition.new(model)
    intMassDef.setSurfaceAreaperSpaceFloorArea(0.8)
    intMassDef.setConstruction(chilledCeilingConstruction)

    thermalZones.each do |zone|
      zone.spaces.each do |space|
        intMass = OpenStudio::Model::InternalMass.new(intMassDef)
        intMass.setSpace(space)
      end
    end

    ####################################################################################
    # adding the hot water loop
    hotWaterPlant = OpenStudio::Model::PlantLoop.new(model)
    hotWaterPlant.setName("Hot Water Loop")

    sizingPlantHW = hotWaterPlant.sizingPlant
    sizingPlantHW.setLoopType("Heating")
    sizingPlantHW.setDesignLoopExitTemperature(hot_water_temp_setpoint)
    sizingPlantHW.setLoopDesignTemperatureDifference(hot_water_temp_diff)

    districtHeating = OpenStudio::Model::DistrictHeating.new(model)
    hotWaterPlant.addSupplyBranchForComponent(districtHeating)

    pumpHW = OpenStudio::Model::PumpVariableSpeed.new(model)
    pumpHW.addToNode(hotWaterPlant.supplyInletNode)

    pipeHW = OpenStudio::Model::PipeAdiabatic.new(model)
    hotWaterPlant.addSupplyBranchForComponent(pipeHW)

    pipe2HW = OpenStudio::Model::PipeAdiabatic.new(model)
    pipe2HW.addToNode(hotWaterPlant.supplyOutletNode)

    hotWaterSchedule = CreateConstSchedule(model, "HotWaterTempSched", hot_water_temp_setpoint)

    hotWaterSPM = OpenStudio::Model::SetpointManagerScheduled.new(model, hotWaterSchedule)
    hotWaterSPM.addToNode(hotWaterPlant.supplyOutletNode)

    ####################################################################################
    # adding the chilled water loop
    chilledWaterPlant = OpenStudio::Model::PlantLoop.new(model)
    chilledWaterPlant.setName("Chilled Water Loop")

    sizingPlantCHW = chilledWaterPlant.sizingPlant
    sizingPlantCHW.setLoopType("Cooling")
    sizingPlantCHW.setDesignLoopExitTemperature(cold_water_temp_setpoint)
    sizingPlantCHW.setLoopDesignTemperatureDifference(cold_water_temp_diff)

    districtCooling = OpenStudio::Model::DistrictCooling.new(model)
    # districtCooling.setNominalCapacity(5000000)
    chilledWaterPlant.addSupplyBranchForComponent(districtCooling)

    pumpCHW = OpenStudio::Model::PumpVariableSpeed.new(model)
    pumpCHW.addToNode(chilledWaterPlant.supplyInletNode)

    pipeCHW = OpenStudio::Model::PipeAdiabatic.new(model)
    chilledWaterPlant.addSupplyBranchForComponent(pipeCHW)

    pipe2CHW = OpenStudio::Model::PipeAdiabatic.new(model)
    pipe2CHW.addToNode(chilledWaterPlant.supplyOutletNode)

    chilledWaterSchedule = CreateConstSchedule(model, "ChilledWaterTempSched", cold_water_temp_setpoint)

    chilledWaterSPM = OpenStudio::Model::SetpointManagerScheduled.new(model, chilledWaterSchedule)
    chilledWaterSPM.addToNode(chilledWaterPlant.supplyOutletNode)

    # add thermal zones to hot water plant loop
    thermalZones = model.getThermalZones
    thermalZones.each do |zone|
      # add baseboard heaters first
      heatingCoilBaseboard = OpenStudio::Model::CoilHeatingWaterBaseboard.new(model)
      # make an air terminal for the zone
      baseboard = OpenStudio::Model::ZoneHVACBaseboardConvectiveWater.new(model, model.alwaysOnDiscreteSchedule, heatingCoilBaseboard)
      # attach the zone to the baseboard
      baseboard.addToThermalZone(zone)
      # add the baseboard to the plant loop
      hotWaterPlant.addDemandBranchForComponent(baseboard.heatingCoil)

      heatingCoilRadiant = OpenStudio::Model::CoilHeatingLowTempRadiantVarFlow.new(model, zoneHeatingTempSched)
      heatingCoilRadiant.setMaximumHotWaterFlow(0)
      # heatingCoilRadiant.setHeatingDesignCapacity(0)
      coolingCoilRadiant = OpenStudio::Model::CoilCoolingLowTempRadiantVarFlow.new(model, zoneCoolingTempSched)
      #      coolingCoilRadiant.setMaximumColdWaterFlow(coldWaterFlowPerArea * zone.floorArea())
      # coolingCoilRadiant.setCoolingDesignCapacityMethod("CapacityPerFloorArea")
      # coolingCoilRadiant.setCoolingDesignCapacityPerFloorArea(100)
      # make an air terminal for the zone
      radiantLowTVarFlow = OpenStudio::Model::ZoneHVACLowTempRadiantVarFlow.new(model, model.alwaysOnDiscreteSchedule, heatingCoilRadiant, coolingCoilRadiant)
      radiantLowTVarFlow.setNumberofCircuits("CalculateFromCircuitLength")
      # radiantLowTVarFlow.setHydronicTubingLength(100)
      # attach the zone to the baseboard
      radiantLowTVarFlow.addToThermalZone(zone)
      # add the baseboard to the plant loop
      hotWaterPlant.addDemandBranchForComponent(radiantLowTVarFlow.heatingCoil)
      chilledWaterPlant.addDemandBranchForComponent(radiantLowTVarFlow.coolingCoil)

      # automatically sets all surfaces with internal construction to the radiat device
      radiantLowTVarFlow.setRadiantSurfaceType("Ceiling"); # Floors or Ceiling

      # we need to set the DOAS first, so the other components can react to the cooling/heating loads initiated by the DOAS
      zone.setCoolingPriority(baseboard, 3)
      zone.setHeatingPriority(baseboard, 2)
      zone.setCoolingPriority(radiantLowTVarFlow, 2)
      zone.setHeatingPriority(radiantLowTVarFlow, 3)

      runner.registerInfo("#{zone.name} zone has #{radiantLowTVarFlow.surfaces.size} ceiling surfaces with internal contructions.")
    end

    simulationControl = model.getSimulationControl
    simulationControl.setDoZoneSizingCalculation(true)
    simulationControl.setDoSystemSizingCalculation(true)
    simulationControl.setDoPlantSizingCalculation(true)
    simulationControl.setRunSimulationforSizingPeriods(false)

    runner.registerFinalCondition("In the final model #{thermalZones.size} zones are connected to the DOAS air loop.")

    return true
  end
end

# register the measure to be used by the application
AddDetailedHVAC.new.registerWithApplication
