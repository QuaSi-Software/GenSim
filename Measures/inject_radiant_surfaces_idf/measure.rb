# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class InjectRadiantSurfacesIDF < OpenStudio::Measure::EnergyPlusMeasure
  # human readable name
  def name
    return "InjectRadiantSurfacesIDF"
  end

  # general description of measure
  def description
    return "Inject radiant surfaces."
  end

  # description for users of what the measure does and how it works
  def modeler_description
    return "Inject radiant surfaces."
  end

  # define the arguments that the user will input
  def arguments(_workspace)
    args = OpenStudio::Measure::OSArgumentVector.new
    return args
  end

  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # use the built-in error checking
    return false unless runner.validateUserArguments(arguments(workspace), user_arguments)

    # get all low temp radiant equipment in model
    lowTempRadiants = workspace.getObjectsByType("ZoneHVAC:LowTemperatureRadiant:VariableFlow".to_IddObjectType)

    # get all internal mass objects in model
    internalMasses = workspace.getObjectsByType("InternalMass".to_IddObjectType)

    # get all zone objects in model
    zones = workspace.getObjectsByType("Zone".to_IddObjectType)

    # get all zone objects in model
    zoneEquipConnections = workspace.getObjectsByType("ZoneHVAC:EquipmentConnections".to_IddObjectType)

    # get all zone objects in model
    zoneEquipLists = workspace.getObjectsByType("ZoneHVAC:EquipmentList".to_IddObjectType)
    
    # fix strange issue with SAT schedule
    weekSchedules = workspace.getObjectsByType("Schedule:Week:Daily".to_IddObjectType)
    yearSchedules = workspace.getObjectsByType("Schedule:Year".to_IddObjectType)
    yearSchedules.each do |yearSchedule|
      if yearSchedule.getString(0).get == "SAT Year Schedule"
        weekSchedules.each do |weekSchedule|
          if weekSchedule.getString(0).get == "SAT Week Schedule 10 deg C"
            yearSchedule.setString(2, "SAT Week Schedule 10 deg C")
            yearSchedule.setDouble(3, 1)
            yearSchedule.setDouble(4, 1)
            yearSchedule.setDouble(5, 12)
            yearSchedule.setDouble(6, 31)
          end
        end
      end
    end

    counter = 0
    # reporting initial condition of model
    runner.registerInitialCondition("The building started with #{lowTempRadiants.size} Low Temp Radiant objects and #{internalMasses.size} Internal Masses.")
    # Get the OpenStudio version
    version = OpenStudio.openStudioVersion.to_s

    # Split the version into major, minor, and patch components
    version_parts = version.split('.')

    # Extract the major, minor, and patch components
    major = version_parts[0].to_i
    minor = version_parts[1].to_i
    patch = version_parts[2].to_i

    # Combine the components into a double number
    # We can use the formula major + (minor / 100.0) + (patch / 10000.0)
    # This ensures the minor and patch components are correctly represented as fractional parts of the version
    version_double = major + (minor / 100.0) + (patch / 10000.0)
    if version_double > 3.01
      # since version 3.2 the low temp radiant object do not get propertly converted into IDF so this code will fix it
      # init the dictionary
      list_branches_chilled = []
      list_branches_hot = []
      # first we would iterate over the branches to find the ones with missing components
      branches = workspace.getObjectsByType("Branch".to_IddObjectType)
      branches.each do |branch|
        branch_name = branch.getString(0).get
        runner.registerInfo("Branch: #{branch_name} Comp type: #{branch.getString(2)}")
        if branch.getString(2).get.empty?
          runner.registerInfo("Empty Branch Component found: #{branch_name}")
          if branch_name.start_with?("Chilled Water Loop")
            runner.registerInfo("Starts with chilled water")
            comp_name = "LowTempRad " + branch_name.sub("Chilled Water Loop", "").strip
            list_branches_chilled << branch
          elsif branch_name.start_with?("Hot Water Loop")
            runner.registerInfo("Starts with hot water")
            comp_name = "LowTempRad " + branch_name.sub("Hot Water Loop", "").strip
            list_branches_hot << branch
          end
        end
      end

      design_obj = OpenStudio::IdfObject.new("ZoneHVAC:LowTemperatureRadiant:VariableFlow:Design".to_IddObjectType)
      design_obj.setString(0, "Zone HVAC Low Temperature Radiant Variable Flow Design Object")
      design_obj.setString(1, "ConvectionOnly")
      design_obj.setDouble(2, 0.013)
      design_obj.setDouble(3, 0.016)
      design_obj.setDouble(4, 0.35)
      design_obj.setString(5, "MeanAirTemperature")
      design_obj.setString(6, "HalfFlowPower")
      design_obj.setString(7, "HeatingDesignCapacity")
      

      design_obj.setDouble(10, 0.5)
      design_obj.setString(11, "ZoneHeatingTempSched")
      design_obj.setString(12, "CoolingDesignCapacity")
      

      design_obj.setDouble(15, 0.5)
      design_obj.setString(16, "ZoneCoolingTempSched")
      design_obj.setString(17, "SimpleOff")
      design_obj.setDouble(18, 2)
      workspace.addObject(design_obj)

      i = 0
      zones.each do |zone|
        zone_name = zone.getString(0).get
        comp_name = "#{zone_name} - LowTempRad"

        related_internal_mass = nil
        internalMasses.each do |internalMass|
          runner.registerInfo("InternalMass ZoneName: #{internalMass.getString(2)}")
          runner.registerInfo("are equal? #{internalMass.getString(2).to_s == zone_name}")
          if internalMass.getString(2).to_s == zone_name
            related_internal_mass = internalMass.getString(0).get
          end
        end

        

        comp = OpenStudio::IdfObject.new("ZoneHVAC:LowTemperatureRadiant:VariableFlow".to_IddObjectType)
        comp.setString(0, comp_name)
        comp.setString(1, design_obj.getString(0).get)
        comp.setString(2, "Always On Discrete")
        comp.setString(3, zone_name)
        comp.setString(4, related_internal_mass)
        #comp.setDouble(5, 0.013)
        comp.setDouble(6, 0)
        comp.setDouble(7, 0)
        comp.setString(8, "#{comp_name} - Heating Water Inlet")
        comp.setString(9, "#{comp_name} - Heating Water Outlet")
        comp.setString(10, "Autosize")
        #comp.setString(11, "Autosize")
        comp.setString(12, "#{comp_name} - Cooling Water Inlet")
        comp.setString(13, "#{comp_name} - Cooling Water Outlet")
        #comp.setString(14, "CalculateFromCircuitLength")
        #comp.setDouble(15, 106.7)
        workspace.addObject(comp)

        # update the branch
        branch_chilled = list_branches_chilled[i]
        branch_chilled.setString(2, "ZoneHVAC:LowTemperatureRadiant:VariableFlow")
        branch_chilled.setString(3, comp_name)
        branch_chilled.setString(4, "#{comp_name} - Cooling Water Inlet")
        branch_chilled.setString(5, "#{comp_name} - Cooling Water Outlet")
        runner.registerInfo("Adding #{comp_name} to the chilled water branch")

        # update the branch
        branch_hot = list_branches_hot[i]
        branch_hot.setString(2, "ZoneHVAC:LowTemperatureRadiant:VariableFlow")
        branch_hot.setString(3, comp_name)
        branch_hot.setString(4, "#{comp_name} - Heating Water Inlet")
        branch_hot.setString(5, "#{comp_name} - Heating Water Outlet")
        runner.registerInfo("Adding #{comp_name} to the hot water branch")

        zoneEquipConnections.each do |zoneEquipConnection|
          if zoneEquipConnection.getString(0).to_s == zone_name
            equiplist = zoneEquipConnection.getString(1).to_s
            zoneEquipLists.each do |zoneEquipList|
              if zoneEquipList.getString(0).to_s == equiplist
                zoneEquipList.setString(14, "ZoneHVAC:LowTemperatureRadiant:VariableFlow")
                zoneEquipList.setString(15, comp_name)
                zoneEquipList.setDouble(16, 2)
                zoneEquipList.setDouble(17, 3)
              end
            end
          end
        end

        i = i + 1
      end
    

      '''
      ZoneHVAC:LowTemperatureRadiant:VariableFlow,
       0  Zone HVAC Low Temperature Radiant Variable Flow 1, !- Name
       1  Always On Discrete,                     !- Availability Schedule Name
       2  EXT-Story 1 Core Zone,                  !- Zone Name
       3  Internal Mass 1,                        !- Surface Name or Radiant Surface Group Name
       4  0.013,                                  !- Hydronic Tubing Inside Diameter {m}
       5  Autosize,                               !- Hydronic Tubing Length {m}
       6  MeanAirTemperature,                     !- Temperature Control Type
       7  HeatingDesignCapacity,                  !- Heating Design Capacity Method
       8  Autosize,                               !- Heating Design Capacity {W}
       9  ,                                       !- Heating Design Capacity Per Floor Area {W/m2}
      10  ,                                       !- Fraction of Autosized Heating Design Capacity
      11  0,                                      !- Maximum Hot Water Flow {m3/s}
      12  Node 33,                                !- Heating Water Inlet Node Name
      13  Node 34,                                !- Heating Water Outlet Node Name
      14  0.5,                                    !- Heating Control Throttling Range {deltaC}
      15  ZoneHeatingTempSched,                   !- Heating Control Temperature Schedule Name
      16  CoolingDesignCapacity,                  !- Cooling Design Capacity Method
      17  Autosize,                               !- Cooling Design Capacity {W}
      18  ,                                       !- Cooling Design Capacity Per Floor Area {W/m2}
      19  ,                                       !- Fraction of Autosized Cooling Design Capacity
      20  Autosize,                               !- Maximum Cold Water Flow {m3/s}
      21  Node 26,                                !- Cooling Water Inlet Node Name
      22  Node 35,                                !- Cooling Water Outlet Node Name
      23  0.5,                                    !- Cooling Control Throttling Range {deltaC}
      24  ZoneCoolingTempSched,                   !- Cooling Control Temperature Schedule Name
      25  SimpleOff,                              !- Condensation Control Type
      26  1,                                      !- Condensation Control Dewpoint Offset {C}
      27  CalculateFromCircuitLength,             !- Number of Circuits
      28  106.7;                                  !- Circuit Length {m}
'''

    else
      # this is the old way of adjusting the low temperature components, by just adding the related internal mass object
      lowTempRadiants.each do |lowTempRadiant|
        runner.registerInfo("LowTempZoneName: #{lowTempRadiant.getString(2)}")
        internalMasses.each do |internalMass|
          runner.registerInfo("InternalMass ZoneName: #{internalMass.getString(2)}")
          runner.registerInfo("are equal? #{internalMass.getString(2).to_s == lowTempRadiant.getString(2).to_s}")
          if internalMass.getString(2).to_s == lowTempRadiant.getString(2).to_s
            lowTempRadiant.setString(3, internalMass.getString(0).to_s)
            counter = counter + 1
            workspace.insertObject(lowTempRadiant)
          end
        end
      end
    end

    lowTempRadSurfaceGroups = workspace.getObjectsByType("ZoneHVAC:LowTemperatureRadiant:SurfaceGroup".to_IddObjectType)
    lowTempRadSurfaceGroups.each do |surfGroup|
      surfGroup.remove()
    end

	  runner.registerFinalCondition("The building finished with #{counter}/#{lowTempRadiants.size} updated low temperature rediant objects objects.")

    return true
  end
end

# register the measure to be used by the application
InjectRadiantSurfacesIDF.new.registerWithApplication

