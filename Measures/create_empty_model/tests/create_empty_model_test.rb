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

class CreateEmptyModelTest < MiniTest::Test
  # def setup
  # there is no need for any setup
  # end

  def test_number_of_arguments_and_argument_names
    # get arguments with a new instance of the measure
    arguments = GetArguments(CreateEmptyModel.new, OpenStudio::Model::Model.new)

    # check if the number of arguments is correct
    assert_equal(0, arguments.size)
  end

  def test_bad_argument_values
    # create hash of argument values, no arguments defined so there are no bad arguments
    args_hash = {}

    result = TestArguments(CreateEmptyModel.new, OpenStudio::Model::Model.new, args_hash)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
  end

  def test_good_argument_values
    # create hash of argument values
    args_hash = {}

    # create an empty model
    model = OpenStudio::Model::Model.new
    result = TestArguments(CreateEmptyModel.new, model, args_hash)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.empty?)
    assert(result.warnings.empty?)
    assert(result.errors.empty?)
    refute(result.initialCondition.is_initialized)
    assert(result.finalCondition.is_initialized)
    assert_equal("The Model was created.", result.finalCondition.get.logMessage)

    SaveModel(model, File.dirname(__FILE__) + "/output/test_output.osm")
  end

  def teardown
    # nothing to do here for such a simple measure
  end
end
