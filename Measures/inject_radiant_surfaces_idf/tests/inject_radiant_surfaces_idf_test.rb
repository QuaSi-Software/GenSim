# frozen_string_literal: true

########################################################
# This is the test for the measure "CreateAnEmptyModel"
########################################################

require "openstudio"
require "openstudio/measure/ShowRunnerOutput"
require "fileutils"

require_relative "../measure.rb"
require_relative "../../TestHelper.rb"
require "minitest/autorun"

class InjectRadiantSurfacesIDFTest < MiniTest::Test
  def test_number_of_arguments_and_argument_names
    # get arguments with a new instance of the measure
    arguments = GetArguments(InjectRadiantSurfacesIDF.new, OpenStudio::Model::Model.new)

    assert_equal(0, arguments.size)
  end

  def test_bad_argument_values
    # create hash of argument values, no arguments defined so there are no bad arguments
    args_hash = {}
    args_hash["space_name"] = ""

    result = TestArguments(InjectRadiantSurfacesIDF.new, OpenStudio::Model::Model.new, args_hash)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
  end

  def test_good_argument_values
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}

    # load an existing model
    dir = __dir__
    workspace = OpenIDFModel(dir)
    result = TestArguments(InjectRadiantSurfacesIDF.new, workspace, args_hash)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.size >= 1)
    assert(result.warnings.empty?)
    assert(result.errors.empty?)
    assert(result.initialCondition.is_initialized)
    assert(result.finalCondition.is_initialized)

    # TODO: the problem here is that the used IDF model doesn't actually test the code we
    # want to test because it has no branches with empty components, hence the code doesn't
    # update anything. the model needs to be updated from the old behaviour to the new one
    assert_equal(
      "The building finished with 0/4 updated zones for 0 chilled branches and 0 hot " +
      "branches and 4 low temperature radiant objects.",
      result.finalCondition.get.logMessage
    )

    # save the model to test output directory
    SaveIDFModel(workspace, dir)
  end
end
