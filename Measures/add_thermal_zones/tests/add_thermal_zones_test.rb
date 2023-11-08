# frozen_string_literal: true

# author: Tobias Maile <tobias@maileconsulting.de>
########################################################
# This is the test for the measure "AddThermalZones"
########################################################

require "openstudio"
require "openstudio/measure/ShowRunnerOutput"
require "fileutils"

require_relative "../measure.rb"
require_relative "../../TestHelper.rb"
require "minitest/autorun"

class AddThermalZonesTest < MiniTest::Test
  # def setup
  # there is no need for any setup
  # end

  def test_number_of_arguments_and_argument_names
    # get arguments with a new instance of the measure
    arguments = GetArguments(AddThermalZones.new, OpenStudio::Model::Model.new)

    assert_equal(0, arguments.size)
  end

  def test_bad_argument_values
    # create hash of argument values, no arguments defined so there are no bad arguments
    args_hash = {}
    args_hash["space_name"] = ""

    result = TestArguments(AddThermalZones.new, OpenStudio::Model::Model.new, args_hash)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
  end

  def test_good_argument_values
    # create hash of argument values
    args_hash = {}

    # load an existing model
    dir = __dir__
    model = OpenModel(dir)
    result = TestArguments(AddThermalZones.new, model, args_hash)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    assert(result.info.size == 523)
    assert(result.warnings.empty?)
    assert(result.errors.empty?)
    assert(result.initialCondition.is_initialized)
    assert(result.finalCondition.is_initialized)
    assert_equal(" Added 4 ThermalZones, removed 311 objects, so 518 objects remain", result.finalCondition.get.logMessage)
    # save the model to test output directory
    SaveModel(model, dir)
  end

  def teardown
    # nothing to do here for such a simple measure
  end
end
