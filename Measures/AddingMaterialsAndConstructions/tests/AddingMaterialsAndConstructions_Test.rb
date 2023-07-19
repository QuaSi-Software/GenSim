require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require_relative '../../TestHelper.rb'
require 'fileutils'

class AddingMaterialsAndConstructions_Test < MiniTest::Unit::TestCase

  # def setup
  # end

  # def teardown
  # end

  def test_number_of_arguments_and_argument_names
    # get arguments with a new instance of the measure
    arguments = GetArguments(AddingMaterialsAndConstructions.new, OpenStudio::Model::Model.new)

    assert_equal(122, arguments.size)
    assert_equal("ExternalWallMat1Name", arguments[0].name)
  end

  def test_bad_argument_values
    # create hash of argument values, no arguments defined so there are no bad arguments
    args_hash = {}
    args_hash["space_name"] = ""

    result = TestArguments(AddingMaterialsAndConstructions.new, OpenStudio::Model::Model.new, args_hash)

    # assert that it ran correctly
    assert_equal("Fail", result.value.valueName)
  end

  def test_good_argument_values
    # create hash of argument values
    args_hash = {}
    # create hash of argument values.
    # If the argument has a default that you want to use, you don't need it in the hash
    args_hash = {}
    ["ExternalWallMat", "RoofMat",  "SlabMat", "Massen", "InteriorSlabs", "ChilledCeiling"].each do |s|
      if s == "ChilledCeiling"
        args_hash[s + "SourceLayer"] = 1
        args_hash[s + "TempCalcLayer"] = 2
        args_hash[s + "DimCTF"] = 3
        args_hash[s +  "TubeSpacing"] = 0.1
      end
      for i in 1..4
        args_hash[s + i.to_s + "Name"] = s + i.to_s + "Name"
        args_hash[s + i.to_s + "Thickness"] = 1.0
        args_hash[s + i.to_s + "Conductivity"] = 2.0
        args_hash[s + i.to_s + "Density"] = 3.0
        args_hash[s + i.to_s + "SpecificHeat"] = 4.0
      end
    end
		
    s = "Windows"
    args_hash[s + "Name"] = s + "Name"
    args_hash[s + "UValue"] = 2
    args_hash[s + "SHGC"] = 1
        
    # load an existing model
    dir = File.expand_path(File.dirname(__FILE__))
    model = OpenModel(dir)
    # store the number of spaces in the seed model
    num_spaces_seed = model.getSpaces.size

    result = TestArguments(AddingMaterialsAndConstructions.new, model, args_hash)

    # assert that it ran correctly
    assert_equal("Success", result.value.valueName)
    #print(result.info.size)
    assert(result.info.size == 6)
    assert(result.warnings.size == 0)

    # check that there is now 1 space
    assert_equal(0, model.getSpaces.size - num_spaces_seed)

    assert_equal("The building finished with 24 surfaces that have constructions now.", result.finalCondition.get().logMessage())

    SaveModel(model, dir)
  end

end
