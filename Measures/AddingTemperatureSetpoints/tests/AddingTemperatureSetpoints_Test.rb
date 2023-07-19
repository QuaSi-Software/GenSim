# author: Tobias Maile <tobias@maileconsulting.de>
########################################################
# This is the test for the measure "AddingTemperatureSetpoints"
########################################################

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure.rb'
require_relative '../../TestHelper.rb'
require 'minitest/autorun'

class AddingTemperatureSetpoints_Test < MiniTest::Test
    def test_number_of_arguments_and_argument_names
        # get arguments with a new instance of the measure
        arguments = GetArguments(AddingTemperatureSetpoints.new, OpenStudio::Model::Model.new)

        assert_equal(9, arguments.size)
    end

    def test_bad_argument_values
        # create hash of argument values, no arguments defined so there are no bad arguments
        args_hash = {}
        args_hash["space_name"] = ""
 
        result = TestArguments(AddingTemperatureSetpoints.new, OpenStudio::Model::Model.new, args_hash)
 
        # assert that it ran correctly
        assert_equal("Fail", result.value.valueName)
    end

    def test_good_argument_values
        # If the argument has a default that you want to use, you don't need it in the hash
        args_hash = {}
        defaultSched = " 20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20"
        # create hash of argument values
        args_hash = {}
        args_hash["zoneHeatingTempScheduleWerktag"] = defaultSched
        args_hash["zoneHeatingTempScheduleSamstag"] = defaultSched
        args_hash["zoneHeatingTempScheduleSonntag"] = defaultSched
        args_hash["zoneHeatingTempScheduleFeiertag"] = defaultSched
        args_hash["zoneCoolingTempScheduleWerktag"] = defaultSched
        args_hash["zoneCoolingTempScheduleSamstag"] = defaultSched
        args_hash["zoneCoolingTempScheduleSonntag"] = defaultSched
        args_hash["zoneCoolingTempScheduleFeiertag"] = defaultSched
        args_hash["Holidays"] = defaultSched

         # load an existing model
        dir = File.expand_path(File.dirname(__FILE__))
        model = OpenModel(dir)
        result = TestArguments(AddingTemperatureSetpoints.new, model, args_hash)

        # store the number of spaces in the seed model
        num_spaces_seed = model.getSpaces.size

        # assert that it ran correctly
        assert_equal("Success", result.value.valueName)
        assert(result.info.size == 4)
        assert(result.warnings.size == 0)
        assert(result.errors.size == 0)
        refute(result.initialCondition.is_initialized())
        assert(result.finalCondition.is_initialized())
        assert_equal("Replaced thermostats for 4 thermal zones", result.finalCondition.get().logMessage())
        # save the model to test output directory
        SaveModel(model, dir)
    end

    def teardown
        # nothing to do here for such a simple measure
    end
end