# frozen_string_literal: true

# author: Tobias Maile <tobias@maileconsulting.de>
########################################################
# This is the test for the measure "AddingInfiltration"
########################################################

require "openstudio"
require "openstudio/measure/ShowRunnerOutput"
require "fileutils"

require_relative "../measure.rb"
require_relative "../../TestHelper.rb"
require "minitest/autorun"

class AddInfiltrationTest < MiniTest::Test
  def test_number_of_arguments_and_argument_names
    # get arguments with a new instance of the measure
    arguments = GetArguments(AddInfiltration.new, OpenStudio::Model::Model.new)

    assert_equal(3, arguments.size)
  end

  def test_bad_argument_values
    # create hash of argument values, no arguments defined so there are no bad arguments
    args_hash = {}
    args_hash["space_name"] = ""

    result = TestArguments(AddInfiltration.new, OpenStudio::Model::Model.new, args_hash)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
  end

  def test_good_argument_values
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash["air_changes"] = 0.07
    args_hash["nfa_gfa_ratio"] = 0.8
    args_hash["floor_height_ratio"] = 0.8

    # load an existing model
    dir = __dir__
    model = OpenModel(dir)
    result = TestArguments(AddInfiltration.new, model, args_hash)

    # store the number of spaces in the seed model
    num_spaces_seed = model.getSpaces.size

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.empty?)
    assert(result.warnings.empty?)
    assert(result.errors.empty?)
    refute(result.initialCondition.is_initialized)
    assert(result.finalCondition.is_initialized)
    assert_equal("Infiltration added to 4 spaces.", result.finalCondition.get.logMessage)
    # save the model to test output directory
    SaveModel(model, dir)
  end

  def teardown
    # nothing to do here for such a simple measure
  end
end
