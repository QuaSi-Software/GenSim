require "thor"

# CLI for running the necessary steps of a GenSim simulation.
#
# This CLI is intended to be used both by the GUI and other processes in the future. It
# can also be used manually over a command line, however this is only useful for
# debugging purposes.
class GenSimCLI < Thor

  # Command to run the workflow defined in an OSW file.
  #
  # @param workflow_file (String) The name of the workflow file
  desc "run_workflow --os_bin_path=/os/openstudio.exe WORKFLOW_FILE", "Execute the given workflow"
  option :os_bin_path, :required => true
  option :output_folder, :required => true, :default => "./Output"
  option :debug, :type => :boolean, :required => false, :default => false
  def run_workflow(workflow_file="Model.osw")
    arguments = [
      options["os_bin_path"],
      "--verbose", "run"
    ]

    if options["debug"]
      arguments << "--debug"
    end

    arguments << "--workflow"
    arguments << File.join(options["output_folder"], workflow_file)

    system(arguments.join(" "))
  end

  # Command to create an empty OSM file.
  #
  # @param file_name (String) The name of the OSM file to create
  option :output_folder, :required => true, :default => "./Output"
  desc "create_empty_osm --output_folder=./Output FILE_NAME", "Create an empty OSM file"
  def create_empty_osm(file_name="Model.osm")
    File.open(File.join(options["output_folder"], file_name), "w") do |file|
      file.write("OS:Version,\n")
      file.write("  {0f20289d-c9f3-4775-8548-e6b6a77e899a}, !- Handle\n")
      file.write("  3.0.0;                                  !- Version Identifier\n")
      file.write("\n")
    end
  end
end

GenSimCLI.start(ARGV)
