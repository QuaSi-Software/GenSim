# frozen_string_literal: true

# function to get arguments of a measure
def GetArguments(measure, model)
  # get arguments and return
  return measure.arguments(model)
end

def GetArguments(measure, workspace)
  # get arguments and return
  return measure.arguments(workspace)
end

# builds and returns the argument map based on the arg hash
def GetArgumentMap(arguments, args_hash)
  argument_map = OpenStudio::Measure.convertOSArgumentVectorToMap(arguments)

  # populate argument with specified hash value if specified
  arguments.each do |arg|
    temp_arg_var = arg.clone
    assert(temp_arg_var.setValue(args_hash[arg.name])) if args_hash[arg.name]
    argument_map[arg.name] = temp_arg_var
  end
  return argument_map
end

# function to run the measure with the given argument hash and return the results
def TestArguments(measure, model, args_hash)
  # create an instance of a runner
  runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

  # get arguments
  arguments = GetArguments(measure, model)

  # get arguments map
  argument_map = GetArgumentMap(arguments, args_hash)

  # run the measure
  measure.run(model, runner, argument_map)
  result = runner.result

  # show the output
  show_output(result)
  return result
end

# function to run the measure with the given argument hash and return the results
def TestArguments(measure, workspace, args_hash)
  # create an instance of a runner
  runner = OpenStudio::Measure::OSRunner.new(OpenStudio::WorkflowJSON.new)

  # get arguments
  arguments = GetArguments(measure, workspace)

  # get arguments map
  argument_map = GetArgumentMap(arguments, args_hash)

  # run the measure
  measure.run(workspace, runner, argument_map)
  result = runner.result

  # show the output
  show_output(result)
  return result
end

# function to save the model
def SaveModel(model, dir)
  # save the model to test output directory
  output_file_path = OpenStudio::Path.new(dir + "/output/test_output.osm")
  model.save(output_file_path, true)

  # forward translate OSM file to IDF file
  ft = OpenStudio::EnergyPlus::ForwardTranslator.new
  workspace = ft.translateModel(model)
  SaveIDFModel(workspace, dir)
end

def SaveIDFModel(workspace, dir)
  idf_file_path = OpenStudio::Path.new(dir + "/output/test_output.idf")
  workspace.save(idf_file_path)
end

# function to open a model
def OpenModel(dir)
  translator = OpenStudio::OSVersion::VersionTranslator.new
  puts "Dir verify"
  puts(dir)

  # load an model
  path = OpenStudio::Path.new("#{dir}/example_model.osm")
  puts "Path to verify"
  puts(path)
  print path
  model = translator.loadModel(path)
  assert(!model.empty?)
  return model.get
end

def OpenIDFModel(dir)
  path = OpenStudio::Path.new("#{dir}/example_model.idf")
  puts "IDF Path to load"
  puts(path)
  workspace = OpenStudio::Workspace.load(path)
  assert(!workspace.empty?)
  return workspace.get
end
