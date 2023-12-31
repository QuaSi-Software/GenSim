# frozen_string_literal: true

# start the measure
class AddThermalZones < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return "AddThermalZones"
  end

  # general description of measure
  def description
    return "Add thermal zones."
  end

  # description for users of what the measure does and how it works
  def modeler_description
    return "Add thermal zones."
  end

  # define the arguments that the user will input
  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    # ===== reporting initial condition of model
    spaces = model.getSpaces
    runner.registerInitialCondition("#{spaces.size} spaces")
    numberOfZonesAdded = 0

    # loop through spaces
    spaces.each do |space|
      next unless space.thermalZone.empty?
      newthermalzone = OpenStudio::Model::ThermalZone.new(model)
      space.setThermalZone(newthermalzone)
      runner.registerInfo("Created " + newthermalzone.briefDescription + " and assigned " + space.briefDescription + " to it.")
      numberOfZonesAdded += 1
    end # loop

    # remove other stuff that may be in the OSM file but we don't need or want!!
    modelObjects = model.getModelObjects
    runner.registerInfo("#{modelObjects.size} Model Objects found.")
    numberOfObjectsRemoved = 0
    numberOfObjectsRemaining = 0
    modelObjects.each do |modelObject|
      if modelObject.iddObjectType == "OS_SpaceType".to_IddObjectType
        modelObject.remove
        numberOfObjectsRemoved += 1
      elsif modelObject.iddObjectType == "OS:Rendering:Color".to_IddObjectType
        modelObject.remove
        numberOfObjectsRemoved += 1
      elsif modelObject.iddObjectType == "OS:DefaultScheduleSet".to_IddObjectType
        modelObject.remove
        numberOfObjectsRemoved += 1
      elsif modelObject.iddObjectType == "OS:Lights:Definition".to_IddObjectType
        modelObject.remove
        numberOfObjectsRemoved += 1
      elsif modelObject.iddObjectType == "OS:Lights:Definition".to_IddObjectType
        modelObject.remove
        numberOfObjectsRemoved += 1
      elsif modelObject.iddObjectType == "OS:Schedule:Ruleset".to_IddObjectType
        modelObject.remove
        numberOfObjectsRemoved += 1
      elsif modelObject.iddObjectType == "OS:ScheduleTypeLimits".to_IddObjectType
        modelObject.remove
        numberOfObjectsRemoved += 1
      elsif modelObject.iddObjectType == "OS:DesignSpecification:OutdoorAir".to_IddObjectType
        modelObject.remove
        numberOfObjectsRemoved += 1
      elsif modelObject.iddObjectType == "OS:People:Definition".to_IddObjectType
        modelObject.remove
        numberOfObjectsRemoved += 1
      elsif modelObject.iddObjectType == "OS:ElectricEquipment:Definition".to_IddObjectType
        modelObject.remove
        numberOfObjectsRemoved += 1
      elsif modelObject.iddObjectType == "OS:ThermostatSetpoint:DualSetpoint".to_IddObjectType
        modelObject.remove
        numberOfObjectsRemoved += 1
      elsif modelObject.iddObjectType == "OS:OutputControl:ReportingTolerances".to_IddObjectType
        modelObject.remove
        numberOfObjectsRemoved += 1
      else
        runner.registerInfo("#{modelObject.iddObjectType.valueName} Model Object Type found.")
        numberOfObjectsRemaining += 1
      end
    end # loop

    modelObjects = model.getModelObjects
    modelObjects.each do |modelObject|
      next unless modelObject.iddObjectType == "OS:SpaceInfiltration:DesignFlowRate".to_IddObjectType
      modelObject.remove
      numberOfObjectsRemoved += 1
      numberOfObjectsRemaining -= 1
    end # loop

    runner.registerFinalCondition(" Added #{numberOfZonesAdded} ThermalZones, removed #{numberOfObjectsRemoved} objects, so #{numberOfObjectsRemaining} objects remain")
    return true
  end
end

# register the measure to be used by the application
AddThermalZones.new.registerWithApplication
