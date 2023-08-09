# author: Tobias Maile <tobias@maileconsulting.de>
########################################################
# This is the test for the measure "CreateAnEmptyModel"
########################################################

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure.rb'
require_relative '../../TestHelper.rb'
require 'minitest/autorun'

class InjectZoneVentilationIDFTest < MiniTest::Test
    def test_number_of_arguments_and_argument_names
        # get arguments with a new instance of the measure
        arguments = GetArguments(InjectZoneVentilationIDF.new, OpenStudio::Model::Model.new)

        assert_equal(3, arguments.size)
    end

    def test_bad_argument_values
        # create hash of argument values, no arguments defined so there are no bad arguments
        args_hash = {}
        args_hash["space_name"] = ""
        
        result = TestArguments(InjectZoneVentilationIDF.new, OpenStudio::Model::Model.new, args_hash)

        # assert that it ran correctly
        assert_equal("Fail", result.value.valueName)
    end

    def test_good_argument_values
        # If the argument has a default that you want to use, you don't need it in the hash
        args_hash = {}
        args_hash["air_changes"] = "2"
        args_hash["min_indoor_temperature"] = "15"
        args_hash["temperature_difference"] = "3"

        # load an existing model
        dir = File.expand_path(File.dirname(__FILE__))
        workspace = OpenIDFModel(dir)
        result = TestArguments(InjectZoneVentilationIDF.new, workspace, args_hash)

        # assert that it ran correctly
        assert_equal("Success", result.value.valueName)
        assert(result.info.size == 1)
        assert(result.warnings.size == 0)
        assert(result.errors.size == 0)
        assert(result.initialCondition.is_initialized())
        assert(result.finalCondition.is_initialized())
        assert_equal("The building finished with 4 ZoneVentilation objects.", result.finalCondition.get().logMessage())
        # save the model to test output directory
        SaveIDFModel(workspace, dir)
    end
end