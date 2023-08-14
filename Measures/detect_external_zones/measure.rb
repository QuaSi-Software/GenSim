# frozen_string_literal: true

########################################################
# This is a measure to detect external zones by looping through space surfaces and finding window subsurfaces
########################################################

# start the measure
class DetectExternalZones < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return "DetectExternalZones"
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
  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    # check if the mode is null
    if model.nil?
      runner.registerFinalCondition("The model is null!")
      return false
    end

    # ===== reporting initial condition of model
    spaces = model.getSpaces
    runner.registerInitialCondition("#{spaces.size} spaces")

    externalSpaces = []
    externalZones = []

    # ===== loop through all spaces finding zones with windows and mark them with zone name extension "EXT"
    spaces.each do |space|
      has_ext_nat_light = false
      space.surfaces.each do |surface|
        next if surface.outsideBoundaryCondition != "Outdoors"
        surface.subSurfaces.each do |sub_surface|
          next if sub_surface.subSurfaceType == "Door"
          next if sub_surface.subSurfaceType == "OverheadDoor"
          has_ext_nat_light = true
        end
      end
      if has_ext_nat_light == false
        runner.registerWarning("Space '#{space.name}' has no exterior window")
      else
        temp_zone = space.thermalZone.get
        temp_zone.setName("EXT-#{temp_zone.name}")
        space.setName("EXT-#{space.name}")
        externalSpaces << space
        externalZones << temp_zone
      end
    end # end spaces.each de_sensors == true

    runner.registerFinalCondition("'#{externalSpaces.size}' external spaces and '#{externalZones.size}' external zones found.")
    return true
  end
end

# register the measure to be used by the application
DetectExternalZones.new.registerWithApplication
