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

class SetMetersIDFTest < MiniTest::Test
  def test_number_of_arguments_and_argument_names
    # get arguments with a new instance of the measure
    arguments = GetArguments(SetMetersIDF.new, OpenStudio::Model::Model.new)

    assert_equal(4, arguments.size)
  end

  def test_bad_argument_values
    # create hash of argument values, no arguments defined so there are no bad arguments
    args_hash = {}

    result = TestArguments(SetMetersIDF.new, OpenStudio::Model::Model.new, args_hash)

    # assert that it ran correctly
    assert_equal("Fail", result.value.valueName)
  end

  def test_good_argument_values
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    args_hash["time_step"] = "6"

    # load an existing model
    dir = __dir__
    workspace = OpenIDFModel(dir)
    result = TestArguments(SetMetersIDF.new, workspace, args_hash)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.size == 36)
    assert(result.warnings.empty?)
    assert(result.errors.empty?)
    assert(result.initialCondition.is_initialized)
    assert(result.finalCondition.is_initialized)
    assert_equal("The building finished with 14 Custom Meters with version 9.3.0.", result.finalCondition.get.logMessage)
    # save the model to test output directory
    SaveIDFModel(workspace, dir)
  end
end
