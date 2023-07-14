# author: Tobias Maile <tobias@maileconsulting.de>
########################################################
# This is the test for the measure "AddDetailedHVAC"
########################################################

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure.rb'
require_relative '../../TestHelper.rb'
require 'minitest/autorun'

class AddDetailedHVAC_Test < MiniTest::Test

    #def setup
        # there is no need for any setup
    #end

    def test_number_of_arguments_and_argument_names
        # get arguments with a new instance of the measure
        arguments = GetArguments(AddDetailedHVAC.new, OpenStudio::Model::Model.new)

        assert_equal(26, arguments.size)
    end

    def test_bad_argument_values
        # create hash of argument values, no arguments defined so there are no bad arguments
        args_hash = {}
        args_hash["space_name"] = ""
 
        result = TestArguments(AddDetailedHVAC.new, OpenStudio::Model::Model.new, args_hash)
 
        # assert that it ran correctly
        assert_equal("Fail", result.value.valueName)
    end

    def test_good_argument_values
        # If the argument has a default that you want to use, you don't need it in the hash
        args_hash = {}
        hvacSched = " 0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0"
        heatingSched = " 20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20"
        coolingSched = " 25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25;25"
        args_hash["wrg"] = "Sensible"
        args_hash["latent"] = 1
        args_hash["sensible"] = 0.75
        args_hash["ach"] = 1.5
        args_hash["hvacSchedule"] = "DIN 18599: Einzel-/Gruppen-/Großraumbüro"
        args_hash["is_custom_hvac"] = true
        args_hash["hvacSchedWerktag"] = hvacSched
        args_hash["hvacSchedSamstag"] = hvacSched
        args_hash["hvacSchedSonntag"] = hvacSched
        args_hash["hvacSchedFeiertag"] = hvacSched
        args_hash["Holidays"] = "-"
        args_hash["zoneHeatingTempSchedWerktag"] = heatingSched
        args_hash["zoneHeatingTempSchedSamstag"] = heatingSched
        args_hash["zoneHeatingTempSchedSonntag"] = heatingSched
        args_hash["zoneHeatingTempSchedFeiertag"] = heatingSched
        args_hash["zoneCoolingTempSchedWerktag"] = coolingSched
        args_hash["zoneCoolingTempSchedSamstag"] = coolingSched
        args_hash["zoneCoolingTempSchedSonntag"] = coolingSched
        args_hash["zoneCoolingTempSchedFeiertag"] = coolingSched
        args_hash["hotWaterTempSetpoint"] = 82
        args_hash["hotWaterDeltaT"] = 11
        args_hash["coldWaterTempSetpoint"] = 10
        args_hash["coldWaterDeltaT"] = 5
        args_hash["fanPressureRiseSupply"] = 75
        args_hash["fanPressureRiseReturn"] = 750
        args_hash["system_type"] = 2


         # load an existing model
        dir = File.expand_path(File.dirname(__FILE__))
        model = OpenModel(dir)
        result = TestArguments(AddDetailedHVAC.new, model, args_hash)

        # store the number of spaces in the seed model
        num_spaces_seed = model.getSpaces.size

        # assert that it ran correctly
        assert_equal("Success", result.value.valueName)
        assert(result.info.size == 12)
        assert(result.warnings.size == 0)
        assert(result.errors.size == 0)
        refute(result.initialCondition.is_initialized())
        assert(result.finalCondition.is_initialized())
        assert_equal("In the final model 4 zones are connected to the DOAS air loop.", result.finalCondition.get().logMessage())
        # save the model to test output directory
        SaveModel(model, dir)
    end

    def teardown
        # nothing to do here for such a simple measure
    end
end