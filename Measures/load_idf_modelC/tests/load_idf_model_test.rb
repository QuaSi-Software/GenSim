require 'openstudio'
require 'openstudio/measure/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'

class LoadIDFModelTest < Minitest::Test
  # def setup
  # end

  # def teardown
  # end

  def test_number_of_arguments_and_argument_names
    # create an instance of the measure
    measure = LoadIDFModelC.new

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(1, arguments.size)
    assert_equal('idf_file_path', arguments[0].name)
  end

  def test_bad_argument_values
    # create an instance of the measure
    measure = LoadIDFModelC.new

    # create runner with empty OSW
    osw = OpenStudio::WorkflowJSON.new
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values, an empty idf_file_path should fail validation
    args_hash = {}
    args_hash['idf_file_path'] = ''

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    show_output(result)

    # assert that it ran correctly
    assert_equal('Fail', result.value.valueName)
  end

  def test_good_argument_values
    # create an instance of the measure
    measure = LoadIDFModelC.new

    # create runner with empty OSW
    osw = OpenStudio::WorkflowJSON.new
    runner = OpenStudio::Measure::OSRunner.new(osw)

    # start from an empty model, the measure loads the IDF file itself
    model = OpenStudio::Model::Model.new

    # get arguments
    arguments = measure.arguments(model)
    argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

    # create hash of argument values.
    args_hash = {}
    args_hash['idf_file_path'] = "#{File.dirname(__FILE__)}/example_model.idf"

    # populate argument with specified hash value if specified
    arguments.each do |arg|
      temp_arg_var = arg.clone
      if args_hash.key?(arg.name)
        assert(temp_arg_var.setValue(args_hash[arg.name]))
      end
      argument_map[arg.name] = temp_arg_var
    end

    # run the measure
    measure.run(model, runner, argument_map)
    result = runner.result

    # show the output
    show_output(result)

    # assert that it ran correctly
    assert_equal('Success', result.value.valueName)
    assert(result.warnings.empty?)
    assert(result.errors.empty?)
    assert(result.initialCondition.is_initialized)
    assert(result.finalCondition.is_initialized)

    # the measure reassigns its own local `model` variable rather than mutating
    # the one passed in, so that reference never reflects the converted content -
    # check the saved OSM file instead, which is what the measure actually wrote
    output_osm_path = args_hash['idf_file_path'].sub(/\.idf$/i, '.osm')
    assert(File.exist?(output_osm_path))

    translator = OpenStudio::OSVersion::VersionTranslator.new
    saved_model = translator.loadModel(output_osm_path)
    assert(!saved_model.empty?)
    assert(saved_model.get.getSpaces.size > 0)

    File.delete(output_osm_path) if File.exist?(output_osm_path)
  end
end
