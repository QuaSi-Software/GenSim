# frozen_string_literal: true

# author: Tobias Maile <tobias@maileconsulting.de>
########################################################
# This is the test for the measure "CreateAnEmptyModel"
########################################################

require "openstudio"
require "openstudio/measure/ShowRunnerOutput"
require "fileutils"

require_relative "../measure.rb"
require_relative "../../TestHelper.rb"
require "minitest/autorun"

class SaveModelTest < MiniTest::Test
  def test_number_of_arguments_and_argument_names
    # get arguments with a new instance of the measure
    arguments = GetArguments(SaveModel.new, OpenStudio::Model::Model.new)

    assert_equal(2, arguments.size)
  end

  def test_bad_argument_values
    # create hash of argument values, no arguments defined so there are no bad arguments
    args_hash = {}
    args_hash["space_name"] = ""

    result = TestArguments(SaveModel.new, OpenStudio::Model::Model.new, args_hash)

    # assert that it ran correctly
    assert_equal("Fail", result.value.valueName)
  end

  def test_good_argument_values
    # load an existing model
    dir = __dir__
    model = OpenModel(dir)

    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash["output_path"] = dir
    args_hash["file_name"] = "Test"

    result = TestArguments(SaveModel.new, model, args_hash)

    # store the number of spaces in the seed model
    num_spaces_seed = model.getSpaces.size

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.size == 1)
    assert(result.warnings.empty?)
    assert(result.errors.empty?)
    assert(result.initialCondition.is_initialized)
    assert(result.finalCondition.is_initialized)
    assert_equal("OSM file saved successfully to: #{args_hash['output_path']}/#{args_hash['file_name']}.osm", result.finalCondition.get.logMessage)
    # save the model to test output directory
    SaveModel(model, dir)
  end
end
