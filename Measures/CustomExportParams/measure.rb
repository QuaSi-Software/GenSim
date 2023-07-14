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

        has_zone_details = OpenStudio::Measure::OSArgument::makeIntegerArgument("zoneDetails", false)
        has_zone_details.setDisplayName("Has zone details")
        args << has_zone_details

        do_detailed_hvac = OpenStudio::Measure::OSArgument::makeIntegerArgument("detailedHVAC", false)
        do_detailed_hvac.setDisplayName("With detailed HVAC")
        args << do_detailed_hvac

        ventilation_type = OpenStudio::Measure::OSArgument::makeIntegerArgument("ventilation_type", false)
        ventilation_type.setDisplayName("Ventilation type")
        args << ventilation_type

        floor_length = OpenStudio::Measure::OSArgument::makeDoubleArgument("floor_length", false)
        floor_length.setDisplayName("Floor length")
        floor_length.setUnits("m")
        args << floor_length

        floor_width = OpenStudio::Measure::OSArgument::makeDoubleArgument("floor_width", false)
        floor_width.setDisplayName("Floor width")
        floor_width.setUnits("m")
        args << floor_width

        ratio_NRF_BGF_selection = OpenStudio::Measure::OSArgument::makeStringArgument("ratio_NRF_BGF", false)
        ratio_NRF_BGF_selection.setDisplayName("Ratio of NRF over BGF selection")
        args << ratio_NRF_BGF_selection

        ratio_NRF_BGF = OpenStudio::Measure::OSArgument::makeDoubleArgument("NRF_BGF", false)
        ratio_NRF_BGF.setDisplayName("Ratio of NRF over BGF")
        args << ratio_NRF_BGF

        holidays = OpenStudio::Measure::OSArgument::makeStringArgument("Holidays", false)
        holidays.setDisplayName("Definition of holidays")
        args << holidays

        calc_feed_air = OpenStudio::Measure::OSArgument::makeIntegerArgument("vorlauf_Luft", false)
        calc_feed_air.setDisplayName("Vorlauf Luft berechnen")
        args << calc_feed_air

        calc_return_air = OpenStudio::Measure::OSArgument::makeIntegerArgument("nachlauf_Luft", false)
        calc_return_air.setDisplayName("Rücklauf Luft berechnen")
        args << calc_return_air

        calc_shading_control = OpenStudio::Measure::OSArgument::makeIntegerArgument("Shadingcontrol", false)
        calc_shading_control.setDisplayName("Sonnenschutz berechnen")
        args << calc_shading_control

        calc_infiltration = OpenStudio::Measure::OSArgument::makeIntegerArgument("Infiltration", false)
        calc_infiltration.setDisplayName("Infiltration berechnen")
        args << calc_infiltration

        calc_lighting_control = OpenStudio::Measure::OSArgument::makeIntegerArgument("Lightingcontrol", false)
        calc_lighting_control.setDisplayName("Lichtsteuerung berechnen")
        args << calc_lighting_control

        calc_window_vent = OpenStudio::Measure::OSArgument::makeIntegerArgument("Windowvent", false)
        calc_window_vent.setDisplayName("Fensterlüftung berechnen")
        args << calc_window_vent

        is_generic_geom = OpenStudio::Measure::OSArgument::makeIntegerArgument("genGeom", false)
        is_generic_geom.setDisplayName("Generische Geometrie")
        args << is_generic_geom

        cond_floor_height = OpenStudio::Measure::OSArgument::makeDoubleArgument("FloorHeight_kond", false)
        cond_floor_height.setDisplayName("Konditionierte Raumhöhe")
        cond_floor_height.setUnits("m")
        args << cond_floor_height

        imported_floor_height = OpenStudio::Measure::OSArgument::makeDoubleArgument("FloorHeight_import", false)
        imported_floor_height.setDisplayName("Importierte Raumhöhe")
        imported_floor_height.setUnits("m")
        args << imported_floor_height

        air_changes = OpenStudio::Measure::OSArgument::makeDoubleArgument("ACH_Input_Parameter", false)
        air_changes.setDisplayName("Luftwechselrate")
        air_changes.setUnits("h^-1")
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
