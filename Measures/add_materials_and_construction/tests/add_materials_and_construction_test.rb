# frozen_string_literal: true

require "openstudio"
require "openstudio/measure/ShowRunnerOutput"
require "minitest/autorun"
require_relative "../measure.rb"
require_relative "../../TestHelper.rb"
require "fileutils"

class AddMaterialsAndConstructionTest < MiniTest::Unit::TestCase
  # def setup
  # end

  # def teardown
  # end

  def test_number_of_arguments_and_argument_names
    # get arguments with a new instance of the measure
    arguments = GetArguments(AddMaterialsAndConstruction.new, OpenStudio::Model::Model.new)

    assert_equal(125, arguments.size)
    assert_equal("external_wall_1_name", arguments[0].name)
  end

  def test_bad_argument_values
    # create hash of argument values, no arguments defined so there are no bad arguments
    args_hash = {}
    args_hash["space_name"] = ""

    result = TestArguments(AddMaterialsAndConstruction.new, OpenStudio::Model::Model.new, args_hash)

    # assert that it ran correctly
    assert_equal("Fail", result.value.valueName)
  end

  def test_good_argument_values
    # create hash of argument values
    args_hash = {}
    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    %w[external_wall_ roof_ base_plate_ inner_masses_ interior_slab_ chilled_ceiling_].each do |s|
      if s == "chilled_ceiling_"
        args_hash[s + "source_layer"] = 1
        args_hash[s + "temp_calc_layer"] = 2
        args_hash[s + "dim_ctf"] = 3
        args_hash[s + "tube_spacing"] = 0.1
      end
      for i in 1..4
        args_hash[s + i.to_s + "_name"] = s + i.to_s + "_name"
        args_hash[s + i.to_s + "_thickness"] = 1.0
        args_hash[s + i.to_s + "_conductivity"] = 2.0
        args_hash[s + i.to_s + "_density"] = 3.0
        args_hash[s + i.to_s + "_heat_capacity"] = 4.0
      end
    end

    s = "windows_"
    args_hash[s + "name"] = s + "name"
    args_hash[s + "u_value"] = 2
    args_hash[s + "shgc"] = 1

    args_hash["is_custom_standard"] = false
    args_hash["construction_standard_selection"] = "Neubau: EH 55"
    args_hash["inner_masses_selection"] = "Mittel"

    # load an existing model
    dir = __dir__
    model = OpenModel(dir)
    # store the number of spaces in the seed model
    num_spaces_seed = model.getSpaces.size

    result = TestArguments(AddMaterialsAndConstruction.new, model, args_hash)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    # print(result.info.size)
    assert(result.info.size == 6)
    assert(result.warnings.empty?)

    # check that there is now 1 space
    assert_equal(0, model.getSpaces.size - num_spaces_seed)

    assert_equal("The building finished with 24 surfaces that have constructions now.", result.finalCondition.get.logMessage)

    SaveModel(model, dir)
  end
end
