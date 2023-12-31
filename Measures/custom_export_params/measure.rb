# frozen_string_literal: true

#########################################################
# This is a dummy measure to contain custom export params
#########################################################

# start the measure
class CustomExportParams < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return "CustomExportParams"
  end

  # general description of measure
  def description
    return "A dummy measure to contain custom parameters"
  end

  # description for users of what the measure does and how it works
  def modeler_description
    return "A dummy measure to contain custom parameters"
  end

  # define the arguments that the user will input
  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new

    has_zone_details = OpenStudio::Measure::OSArgument.makeIntegerArgument("include_zone_details", false)
    has_zone_details.setDisplayName("Has zone details")
    args << has_zone_details

    do_detailed_hvac = OpenStudio::Measure::OSArgument.makeIntegerArgument("include_detailed_hvac", false)
    do_detailed_hvac.setDisplayName("With detailed HVAC")
    args << do_detailed_hvac

    ventilation_type = OpenStudio::Measure::OSArgument.makeIntegerArgument("ventilation_type", false)
    ventilation_type.setDisplayName("Ventilation type")
    args << ventilation_type

    holidays = OpenStudio::Measure::OSArgument.makeStringArgument("holidays", false)
    holidays.setDisplayName("Definition of holidays")
    args << holidays

    calc_feed_air = OpenStudio::Measure::OSArgument.makeIntegerArgument("ventilation_lead_time", false)
    calc_feed_air.setDisplayName("Lead time of ventilation")
    args << calc_feed_air

    calc_return_air = OpenStudio::Measure::OSArgument.makeIntegerArgument("ventilation_follow_up_time", false)
    calc_return_air.setDisplayName("Follow-up time of ventilation")
    args << calc_return_air

    calc_shading_control = OpenStudio::Measure::OSArgument.makeIntegerArgument("include_shading_control", false)
    calc_shading_control.setDisplayName("Calculate shading")
    args << calc_shading_control

    calc_infiltration = OpenStudio::Measure::OSArgument.makeIntegerArgument("include_infiltration", false)
    calc_infiltration.setDisplayName("Calculate infiltration")
    args << calc_infiltration

    calc_lighting_control = OpenStudio::Measure::OSArgument.makeIntegerArgument("include_lighting_control", false)
    calc_lighting_control.setDisplayName("Calculate lighting")
    args << calc_lighting_control

    calc_window_vent = OpenStudio::Measure::OSArgument.makeIntegerArgument("include_window_ventilation", false)
    calc_window_vent.setDisplayName("Calculate window ventilation")
    args << calc_window_vent

    is_generic_geom = OpenStudio::Measure::OSArgument.makeIntegerArgument("generate_geometry_selection", false)
    is_generic_geom.setDisplayName("Generic geometry selection value")
    args << is_generic_geom

    cond_floor_height = OpenStudio::Measure::OSArgument.makeDoubleArgument("conditioned_floor_height", false)
    cond_floor_height.setDisplayName("Conditioned floor height")
    cond_floor_height.setUnits("m")
    args << cond_floor_height

    imported_floor_height = OpenStudio::Measure::OSArgument.makeDoubleArgument("imported_floor_height", false)
    imported_floor_height.setDisplayName("Imported floor height")
    imported_floor_height.setUnits("m")
    args << imported_floor_height

    air_changes = OpenStudio::Measure::OSArgument.makeDoubleArgument("air_changes_input", false)
    air_changes.setDisplayName("Air changes input parameter")
    air_changes.setUnits("h^-1")
    args << air_changes

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    return true
  end
end

# register the measure to be used by the application
CustomExportParams.new.registerWithApplication
