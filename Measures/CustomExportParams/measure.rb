#########################################################
# This is a dummy measure to contain custom export params
#########################################################

# start the measure
class CustomExportParams < OpenStudio::Measure::ModelMeasure

    # human readable name
    def name
        return "CustomExportParams"
    end

    # human readable description
    def description
        return "A dummy measure to contain custom parameters"
    end

    # human readable description of modeling approach
    def modeler_description
        return "A dummy measure to contain custom parameters"
    end

    # define the arguments that the user will input
    def arguments(model)
        args = OpenStudio::Measure::OSArgumentVector.new

        has_zone_details = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("zoneDetails", true)
        has_zone_details.setDisplayName("Has zone details?")
        args << has_zone_details

        do_detailed_hvac = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("detailedHVAC", true)
        do_detailed_hvac.setDisplayName("With detailed HVAC?")
        args << do_detailed_hvac

        ventilation_type = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("ventilation_type", true)
        ventilation_type.setDisplayName("Ventilation type")
        args << ventilation_type

        floor_length = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("floor_length", true)
        floor_length.setDisplayName("Floor length")
        floor_length.setUnits("m")
        args << floor_length

        floor_width = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("floor_width", true)
        floor_width.setDisplayName("Floor width")
        floor_width.setUnits("m")
        args << floor_width

        ratio_NRF_BGF_selection = OpenStudio::Ruleset::OSArgument::makeStringArgument("ratio_NRF_BGF", true)
        ratio_NRF_BGF_selection.setDisplayName("Ratio of NRF over BGF (selection)")
        args << ratio_NRF_BGF_selection

        ratio_NRF_BGF = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("NRF_BGF", true)
        ratio_NRF_BGF.setDisplayName("Ratio of NRF over BGF")
        args << ratio_NRF_BGF

        holidays = OpenStudio::Ruleset::OSArgument::makeStringArgument("Holidays", true)
        holidays.setDisplayName("Definition of holidays")
        args << holidays

        calc_feed_air = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("vorlauf_Luft", true)
        calc_feed_air.setDisplayName("Vorlauf Luft berechnen?")
        args << calc_feed_air

        calc_return_air = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("nachlauf_Luft", true)
        calc_return_air.setDisplayName("Rücklauf Luft berechnen?")
        args << calc_return_air

        calc_shading_control = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("Shadingcontrol", true)
        calc_shading_control.setDisplayName("Sonnenschutz berechnen?")
        args << calc_shading_control

        calc_infiltration = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("Infiltration", true)
        calc_infiltration.setDisplayName("Infiltration berechnen?")
        args << calc_infiltration

        calc_lighting_control = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("Lightingcontrol", true)
        calc_lighting_control.setDisplayName("Lichtsteuerung berechnen?")
        args << calc_lighting_control

        calc_window_vent = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("Windowvent", true)
        calc_window_vent.setDisplayName("Fensterlüftung berechnen?")
        args << calc_window_vent

        is_generic_geom = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("genGeom", true)
        is_generic_geom.setDisplayName("Generische Geometrie?")
        args << is_generic_geom

        cond_floor_height = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("FloorHeight_kond", true)
        cond_floor_height.setDisplayName("Konditionierte Raumhöhe")
        cond_floor_height.setUnits("m")
        args << cond_floor_height

        imported_floor_height = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("FloorHeight_import", true)
        imported_floor_height.setDisplayName("Importierte Raumhöhe")
        imported_floor_height.setUnits("m")
        args << imported_floor_height

        air_changes = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("ACH_Input_Parameter", true)
        air_changes.setDisplayName("Luftwechselrate")
        air_changes.setUnits("m^-1")
        args << air_changes

        return args
    end

    # define what happens when the measure is run
    def run(model, runner, user_arguments)
        super(model, runner, user_arguments)

        # use the built-in error checking
        if !runner.validateUserArguments(arguments(model), user_arguments)
            return false
        end

        return true
    end
end

# register the measure to be used by the application
CustomExportParams.new.registerWithApplication
