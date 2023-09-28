require "thor"

class GenSimCLI < Thor

  # Command to run the workflow defined in an OSW file
  #
  # @param workflow_file (String) The name of the workflow file
  desc "run_workflow --os_bin_path=/os/openstudio.exe WORKFLOW_FILE", "Execute the given workflow"
  option :os_bin_path, :required => true
  option :output_folder, :required => true, :default => "./Output"
  def run_workflow(workflow_file="Model.osw")
    arguments = [
      options["os_bin_path"],
      "--verbose", "run", "--workflow",
      File.join(options["output_folder"], workflow_file)
    ]
    system(arguments.join(" "))
  end
end

GenSimCLI.start(ARGV)
