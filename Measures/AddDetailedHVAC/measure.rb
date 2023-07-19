require_relative "../NewHelper"

# start the measure
class AddDetailedHVAC < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'AddDetailedHVAC'
  end

  # human readable description
  def description
    return 'This measure adds a DOAS air loop and a radiant ceiling heating and cooling component that connects to a hot and chilled water loop with district heating and cooling.'
  end

  # human readable description of modeling approach
  def modeler_description
    return ''
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    wrg = OpenStudio::Ruleset::OSArgument::makeStringArgument("wrg",true)
    wrg.setDisplayName("Heat Recocovery Ratio")
    wrg.setDefaultValue("none")
    args << wrg
    latent = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("latent",true)
    latent.setDisplayName("Latent efficiency")
    latent.setDefaultValue(0.65)
    args << latent
    sensible = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("sensible",true)
    sensible.setDisplayName("sensible efficiency")
    sensible.setDefaultValue(0.7)
    args << sensible
    ach = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ach",true)
    ach.setDisplayName("Air changes per hours")
    ach.setDefaultValue(1)
    args << ach
    args << OpenStudio::Measure::OSArgument.makeStringArgument("hvacSchedWerktag", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("hvacSchedSamstag", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("hvacSchedSonntag", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("hvacSchedFeiertag", false)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("Holidays", false)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zoneHeatingTempSchedWerktag", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zoneHeatingTempSchedSamstag", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zoneHeatingTempSchedSonntag", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zoneHeatingTempSchedFeiertag", false)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zoneCoolingTempSchedWerktag", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zoneCoolingTempSchedSamstag", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zoneCoolingTempSchedSonntag", true)
    args << OpenStudio::Measure::OSArgument.makeStringArgument("zoneCoolingTempSchedFeiertag", false)
    hotWaterTempSetpoint = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("hotWaterTempSetpoint",true)
    hotWaterTempSetpoint.setDisplayName("Hot Water Temp Setpoint")
    hotWaterTempSetpoint.setDefaultValue(50)
    args << hotWaterTempSetpoint
    hotWaterDeltaT = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("hotWaterDeltaT",true)
    hotWaterDeltaT.setDisplayName("Hot Water Delta T")
    hotWaterDeltaT.setDefaultValue(5)
    args << hotWaterDeltaT
    coldWaterTempSetpoint = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("coldWaterTempSetpoint",true)
    coldWaterTempSetpoint.setDisplayName("Cold Water Temp Setpoint")
    coldWaterTempSetpoint.setDefaultValue(15)
    args << coldWaterTempSetpoint
    coldWaterDeltaT = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("coldWaterDeltaT",true)
    coldWaterDeltaT.setDisplayName("Cold Water Delta T")
    coldWaterDeltaT.setDefaultValue(5)
    args << coldWaterDeltaT
    fanPressureRiseSupply = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fanPressureRiseSupply",true)
    fanPressureRiseSupply.setDisplayName("Supply Fan Pressure Rise")
    fanPressureRiseSupply.setDefaultValue(250)
    args << fanPressureRiseSupply
    fanPressureRiseReturn = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fanPressureRiseReturn",true)
    fanPressureRiseReturn.setDisplayName("Return Fan Pressure Rise")
    fanPressureRiseReturn.setDefaultValue(250)
    args << fanPressureRiseReturn
	system_type = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("system_type",true)
    system_type.setDisplayName("Type of Ventilation System")
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
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # Abruf der Variablen
    wrg = runner.getStringArgumentValue("wrg", user_arguments)
    latent = runner.getDoubleArgumentValue("latent",user_arguments)
    sensible = runner.getDoubleArgumentValue("sensible",user_arguments)
    ach = runner.getDoubleArgumentValue("ach",user_arguments)
	
    hvacSchedWeekday = runner.getStringArgumentValue("hvacSchedWerktag", user_arguments)
    hvacSchedSaturday = runner.getStringArgumentValue("hvacSchedSamstag", user_arguments)
    hvacSchedSunday = runner.getStringArgumentValue("hvacSchedSonntag", user_arguments)
    hvacSchedFeiertag = runner.getStringArgumentValue("hvacSchedFeiertag", user_arguments)
    holidays = runner.getStringArgumentValue("Holidays", user_arguments)
    zoneHeatingTempSchedWeekday = runner.getStringArgumentValue("zoneHeatingTempSchedWerktag", user_arguments)
    zoneHeatingTempSchedSaturday = runner.getStringArgumentValue("zoneHeatingTempSchedSamstag", user_arguments)
    zoneHeatingTempSchedSunday = runner.getStringArgumentValue("zoneHeatingTempSchedSonntag", user_arguments)
    zoneHeatingTempSchedFeiertag = runner.getStringArgumentValue("zoneHeatingTempSchedFeiertag", user_arguments)
    zoneCoolingTempSchedWeekday = runner.getStringArgumentValue("zoneCoolingTempSchedWerktag", user_arguments)
    zoneCoolingTempSchedSaturday = runner.getStringArgumentValue("zoneCoolingTempSchedSamstag", user_arguments)
    zoneCoolingTempSchedSunday = runner.getStringArgumentValue("zoneCoolingTempSchedSonntag", user_arguments)
    zoneCoolingTempSchedFeiertag = runner.getStringArgumentValue("zoneCoolingTempSchedFeiertag", user_arguments)
    hotWaterTempSetpoint = runner.getDoubleArgumentValue("hotWaterTempSetpoint", user_arguments)
    hotWaterDeltaT = runner.getDoubleArgumentValue("hotWaterDeltaT", user_arguments)
    coldWaterTempSetpoint = runner.getDoubleArgumentValue("coldWaterTempSetpoint", user_arguments)
    coldWaterDeltaT = runner.getDoubleArgumentValue("coldWaterDeltaT", user_arguments)
    fanPressureRiseSupply = runner.getDoubleArgumentValue("fanPressureRiseSupply", user_arguments)
    fanPressureRiseReturn = runner.getDoubleArgumentValue("fanPressureRiseReturn", user_arguments)
    system_type = runner.getDoubleArgumentValue("system_type", user_arguments)

    hvacSched = CreateSchedule(model, "HVACSched", hvacSchedWeekday, hvacSchedSaturday, hvacSchedSunday, hvacSchedFeiertag, holidays)
    zoneHeatingTempSched = CreateSchedule(model, "ZoneHeatingTempSched", zoneHeatingTempSchedWeekday, zoneHeatingTempSchedSaturday, zoneHeatingTempSchedSunday, zoneHeatingTempSchedFeiertag, holidays, false, true)
    zoneCoolingTempSched = CreateSchedule(model, "ZoneCoolingTempSched", zoneCoolingTempSchedWeekday, zoneCoolingTempSchedSaturday, zoneCoolingTempSchedSunday, zoneCoolingTempSchedFeiertag, holidays)

    air_loop_comps = []
    # creating the DOAS air loop
    airLoopHVAC = OpenStudio::Model::AirLoopHVAC::new(model)
    airLoopHVAC.setName("DOAS Air Loop");
    sizingSystem = airLoopHVAC.sizingSystem()
    sizingSystem.setTypeofLoadtoSizeOn("VentilationRequirement")

    if system_type == 2 
      # if we do not have heat recovery we add only a return fan
      supplyFan = OpenStudio::Model::FanConstantVolume::new(model, hvacSched)
      supplyFan.setName("Supply Fan");
      supplyFan.setPressureRise(fanPressureRiseSupply)
      supplyFan.setFanEfficiency(1)
      air_loop_comps << supplyFan
    end

    controller_OA = OpenStudio::Model::ControllerOutdoorAir.new(model)
    controller_OA.autosizeMinimumOutdoorAirFlowRate()
    controller_OA.autosizeMaximumOutdoorAirFlowRate()
    controller_OA.setMinimumFractionofOutdoorAirSchedule(model.alwaysOnDiscreteSchedule())
    controller_OA.setMaximumFractionofOutdoorAirSchedule(model.alwaysOnDiscreteSchedule())

    system_OA = OpenStudio::Model::AirLoopHVACOutdoorAirSystem.new(model, controller_OA)
    air_loop_comps << system_OA
    # for now no heating or cooling coils

    returnFan = OpenStudio::Model::FanConstantVolume::new(model, hvacSched)
    returnFan.setName("Return Fan");
    returnFan.setPressureRise(fanPressureRiseReturn)
	returnFan.setFanEfficiency(1)
    air_loop_comps << returnFan

    if wrg == "Sensible" or wrg == "Enthalpy"
      runner.registerInfo("system_OA.outboardOANode:  #{system_OA.outboardOANode.get}")
      runner.registerInfo("system_OA.outboardReliefNode:  #{system_OA.outboardReliefNode.get}")

      heat_exchanger = OpenStudio::Model::HeatExchangerAirToAirSensibleAndLatent.new(model)
      heat_exchanger.setAvailabilitySchedule(hvacSched)
      heat_exchanger.setSensibleEffectivenessat100CoolingAirFlow(sensible)
      heat_exchanger.setSensibleEffectivenessat100HeatingAirFlow(sensible)
      heat_exchanger.setSensibleEffectivenessat75CoolingAirFlow(sensible)
      heat_exchanger.setSensibleEffectivenessat75HeatingAirFlow(sensible)
      if wrg == "Enthalpy"
        heat_exchanger.setLatentEffectivenessat100CoolingAirFlow(latent)
        heat_exchanger.setLatentEffectivenessat100HeatingAirFlow(latent)
        heat_exchanger.setLatentEffectivenessat75CoolingAirFlow(latent)
        heat_exchanger.setLatentEffectivenessat75HeatingAirFlow(latent)
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
      comp.addToNode(airLoopHVAC.supplyInletNode())
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
      air_terminal.autosizeMaximumAirFlowRate()
      # attach new terminal to the zone and to the airloop
      airLoopHVAC.addBranchForZone(zone, air_terminal.to_StraightComponent)
      #zone sizing
      zoneSizing = zone.sizingZone()
      zoneSizing.setName(" #{zone.name()} Sizing")

      designSpecOA = OpenStudio::Model::DesignSpecificationOutdoorAir.new(model)
      designSpecOA.setOutdoorAirMethod("AirChanges/Hour") # Flow/Person  Flow/Area Flow/Zone AirChanges/Hour Sum Maximum
      #designSpecOA.setOutdoorAirFlowperPerson()
      #designSpecOA.setOutdoorAirFlowperFloorArea()
      #designSpecOA.setOutdoorAirFlowRate()
      designSpecOA.setOutdoorAirFlowAirChangesperHour(ach)

      zone.spaces().each do |space|
        space.setDesignSpecificationOutdoorAir(designSpecOA)
      end
    end

    # we are looking for the ChilledCeilingConstruction
    chilledCeilingConstruction = nil
    constructions = model.getConstructionWithInternalSources()
    constructions.each do |construction|
      runner.registerInfo("#{construction.name.to_s} contruction found.")
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
      zone.spaces().each do |space|
        intMass = OpenStudio::Model::InternalMass.new(intMassDef)
        intMass.setSpace(space)
      end
    end

    ####################################################################################
    # adding the hot water loop
    hotWaterPlant = OpenStudio::Model::PlantLoop::new(model)
    hotWaterPlant.setName("Hot Water Loop");

    sizingPlantHW = hotWaterPlant.sizingPlant();
    sizingPlantHW.setLoopType("Heating");
    sizingPlantHW.setDesignLoopExitTemperature(hotWaterTempSetpoint);
    sizingPlantHW.setLoopDesignTemperatureDifference(hotWaterDeltaT);

    districtHeating = OpenStudio::Model::DistrictHeating::new(model);
    hotWaterPlant.addSupplyBranchForComponent(districtHeating)

    pumpHW = OpenStudio::Model::PumpVariableSpeed::new(model);
    pumpHW.addToNode(hotWaterPlant.supplyInletNode());

    pipeHW = OpenStudio::Model::PipeAdiabatic::new(model);
    hotWaterPlant.addSupplyBranchForComponent(pipeHW);

    pipe2HW  = OpenStudio::Model::PipeAdiabatic::new(model);
    pipe2HW.addToNode(hotWaterPlant.supplyOutletNode());

    hotWaterSchedule = CreateConstSchedule(model, "HotWaterTempSched", hotWaterTempSetpoint)

    hotWaterSPM = OpenStudio::Model::SetpointManagerScheduled::new(model,hotWaterSchedule);
    hotWaterSPM.addToNode(hotWaterPlant.supplyOutletNode());

    ####################################################################################
    # adding the chilled water loop
    chilledWaterPlant = OpenStudio::Model::PlantLoop::new(model)
    chilledWaterPlant.setName("Chilled Water Loop");

    sizingPlantCHW = chilledWaterPlant.sizingPlant();
    sizingPlantCHW.setLoopType("Cooling");
    sizingPlantCHW.setDesignLoopExitTemperature(coldWaterTempSetpoint);
    sizingPlantCHW.setLoopDesignTemperatureDifference(coldWaterDeltaT);

    districtCooling = OpenStudio::Model::DistrictCooling::new(model);
    #districtCooling.setNominalCapacity(5000000)
    chilledWaterPlant.addSupplyBranchForComponent(districtCooling)

    pumpCHW = OpenStudio::Model::PumpVariableSpeed::new(model);
    pumpCHW.addToNode(chilledWaterPlant.supplyInletNode());

    pipeCHW = OpenStudio::Model::PipeAdiabatic::new(model);
    chilledWaterPlant.addSupplyBranchForComponent(pipeCHW);

    pipe2CHW  = OpenStudio::Model::PipeAdiabatic::new(model);
    pipe2CHW.addToNode(chilledWaterPlant.supplyOutletNode());

    chilledWaterSchedule = CreateConstSchedule(model, "ChilledWaterTempSched", coldWaterTempSetpoint)

    chilledWaterSPM = OpenStudio::Model::SetpointManagerScheduled::new(model,chilledWaterSchedule);
    chilledWaterSPM.addToNode(chilledWaterPlant.supplyOutletNode());

    # add thermal zones to hot water plant loop
    thermalZones = model.getThermalZones
    thermalZones.each do |zone|
      # add baseboard heaters first
      heatingCoilBaseboard= OpenStudio::Model::CoilHeatingWaterBaseboard::new(model);
      # make an air terminal for the zone
      baseboard = OpenStudio::Model::ZoneHVACBaseboardConvectiveWater.new(model, model.alwaysOnDiscreteSchedule(), heatingCoilBaseboard)
      # attach the zone to the baseboard
      baseboard.addToThermalZone(zone)
      # add the baseboard to the plant loop
      hotWaterPlant.addDemandBranchForComponent(baseboard.heatingCoil());

      heatingCoilRadiant = OpenStudio::Model::CoilHeatingLowTempRadiantVarFlow::new(model, zoneHeatingTempSched);
      heatingCoilRadiant.setMaximumHotWaterFlow(0)
      #heatingCoilRadiant.setHeatingDesignCapacity(0)
      coolingCoilRadiant = OpenStudio::Model::CoilCoolingLowTempRadiantVarFlow::new(model, zoneCoolingTempSched);
#      coolingCoilRadiant.setMaximumColdWaterFlow(coldWaterFlowPerArea * zone.floorArea())
      #coolingCoilRadiant.setCoolingDesignCapacityMethod("CapacityPerFloorArea")
      #coolingCoilRadiant.setCoolingDesignCapacityPerFloorArea(100)
      # make an air terminal for the zone
      radiantLowTVarFlow = OpenStudio::Model::ZoneHVACLowTempRadiantVarFlow.new(model, model.alwaysOnDiscreteSchedule(), heatingCoilRadiant, coolingCoilRadiant)
      radiantLowTVarFlow.setNumberofCircuits("CalculateFromCircuitLength")
      #radiantLowTVarFlow.setHydronicTubingLength(100)
      # attach the zone to the baseboard 
      radiantLowTVarFlow.addToThermalZone(zone)
      # add the baseboard to the plant loop
      hotWaterPlant.addDemandBranchForComponent(radiantLowTVarFlow.heatingCoil());
      chilledWaterPlant.addDemandBranchForComponent(radiantLowTVarFlow.coolingCoil());

      # automatically sets all surfaces with internal construction to the radiat device
      radiantLowTVarFlow.setRadiantSurfaceType("Ceiling");  # Floors or Ceiling

      # we need to set the DOAS first, so the other components can react to the cooling/heating loads initiated by the DOAS
      zone.setCoolingPriority(baseboard, 3)
      zone.setHeatingPriority(baseboard, 2)
      zone.setCoolingPriority(radiantLowTVarFlow, 2)
      zone.setHeatingPriority(radiantLowTVarFlow, 3)

      runner.registerInfo("#{zone.name()} zone has #{radiantLowTVarFlow.surfaces().size()} ceiling surfaces with internal contructions.")
    end

    simulationControl = model.getSimulationControl()
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

