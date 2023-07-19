# author: Tobias Maile <tobias@maileconsulting.de>
########################################################
# This is the test for the measure "AddingInternalLoads"
########################################################

require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'fileutils'

require_relative '../measure.rb'
require_relative '../../TestHelper.rb'
require 'minitest/autorun'

class AddingInternalLoads_Test < MiniTest::Test

    #def setup
        # there is no need for any setup
    #end

    def test_number_of_arguments_and_argument_names
        # get arguments with a new instance of the measure
        arguments = GetArguments(AddingInternalLoads.new, OpenStudio::Model::Model.new)

        assert_equal(20, arguments.size)
    end

    def test_bad_argument_values
         # create hash of argument values, no arguments defined so there are no bad arguments
         args_hash = {}
         args_hash["space_name"] = ""
 
         result = TestArguments(AddingInternalLoads.new, OpenStudio::Model::Model.new, args_hash)
 
         # assert that it ran correctly
         assert_equal("Fail", result.value.valueName)
    end

    def test_good_argument_values
        # create hash of argument values
        # If the argument has a default that you want to use, you don't need it in the hash
        args_hash = {}
        defaultSched = " 20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20;20"
        
        # using defaults values from measure.rb for other arguments
        args_hash["ElectricEquipmentPowerPerFloorArea"] = 1
        args_hash["LightingPowerPerFloorArea"] = 2
        args_hash["PeoplePerFloorArea"] = 3
        args_hash["ElectricEquipmentScheduleWerktag"] = defaultSched
        args_hash["ElectricEquipmentScheduleSamstag"] = defaultSched
        args_hash["ElectricEquipmentScheduleSonntag"] = defaultSched
        args_hash["ElectricEquipmentScheduleFeiertag"] = defaultSched
        args_hash["LightScheduleWerktag"] = defaultSched
        args_hash["LightScheduleSamstag"] = defaultSched
        args_hash["LightScheduleSonntag"] = defaultSched
        args_hash["LightScheduleFeiertag"] = defaultSched
        args_hash["PeopleScheduleWerktag"] = defaultSched
        args_hash["PeopleScheduleSamstag"] = defaultSched
        args_hash["PeopleScheduleSonntag"] = defaultSched
        args_hash["PeopleScheduleFeiertag"] = defaultSched
        args_hash["PeopleActivityScheduleWerktag"] = defaultSched
        args_hash["PeopleActivityScheduleSamstag"] = defaultSched
        args_hash["PeopleActivityScheduleSonntag"] = defaultSched
        args_hash["PeopleActivityScheduleFeiertag"] = defaultSched
        args_hash["Holidays"] = defaultSched
        args_hash["hvacSchedWerktag"] = defaultSched
        args_hash["hvacSchedSamstag"] = defaultSched
        args_hash["hvacSchedSonntag"] = defaultSched
        
        # load an existing model
        dir = File.expand_path(File.dirname(__FILE__))
        model = OpenModel(dir)
        result = TestArguments(AddingInternalLoads.new, model, args_hash)

        # store the number of spaces in the seed model
        num_spaces_seed = model.getSpaces.size

        # assert that it ran correctly
        assert_equal("Success", result.value.valueName)
        assert(result.info.size == 4)
        assert(result.warnings.size == 0)
        assert(result.errors.size == 0)
        assert(result.initialCondition.is_initialized())
        assert(result.finalCondition.is_initialized())
        assert_equal("Internal loads added to 4 spaces.", result.finalCondition.get().logMessage())

        # save the model to test output directory
        SaveModel(model, dir)
    end

    def teardown
        # nothing to do here for such a simple measure
    end
end