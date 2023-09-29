require "thor"

PROFILES = """DistrictHeating:Facility
DistrictCooling:Facility
InteriorLights:Electricity
InteriorEquipment:Electricity
Fans:Electricity
Pumps:Electricity
METER ZONE ELECTRIC EQUIPMENT TOTAL HEATING ENERGY
METER ZONE LIGHTS TOTAL HEATING ENERGY
METER PEOPLE TOTAL HEATING ENERGY
METER SURFACE WINDOW HEAT GAIN ENERGY
METER SURFACE WINDOW HEAT LOSS ENERGY
METER INTERNAL LOADS HEATING ENERGY
METER SURFACE AVERAGE FACE CONDUCTION HEAT TRANSFER ENERGY
METER ZONE INFILTRATION HEAT LOSS
METER ZONE INFILTRATION HEAT GAIN
METER ZONE VENTILATION HEAT LOSS
METER ZONE VENTILATION HEAT GAIN
METER MECHANICAL VENTILATION GAIN
METER MECHANICAL VENTILATION LOSS
Facility Heating Setpoint Not Met Time
Facility Heating Setpoint Not Met While Occupied Time
Facility Cooling Setpoint Not Met Time
Facility Cooling Setpoint Not Met While Occupied Time
"""

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

  # Command to create an empty OSM file.
  #
  # @param file_name (String) The name of the OSM file to create
  option :output_folder, :required => true, :default => "./Output"
  desc "create_empty_osm --output_path=./Output FILE_NAME", "Create an empty OSM file"
  def create_empty_osm(file_name="Model.osm")
    File.open(File.join(options["output_folder"], file_name), "w") do |file|
      file.write("OS:Version,\n")
      file.write("  {0f20289d-c9f3-4775-8548-e6b6a77e899a}, !- Handle\n")
      file.write("  2.5.0;                                  !- Version Identifier\n")
      file.write("\n")
    end
  end

  # Command to convert an ESO to CSV file.
  #
  # The profiles, which are being extracted from the ESO, are hardcoded.
  # The CSV file will have the same base name as the given ESO file.
  #
  # @param file_name (String) The name of the ESP file to convert
  desc "convert_eso_to_csv --output_path=./Output FILE_NAME", "Convert an ESO file to CSV"
  option :output_folder, :required => true, :default => "./Output/run"
  option :converter_exe, :required => true, :default => "./ReadVarsEso/ReadVarsESO.exe"
  def convert_eso_to_csv(file_name="eplusout.eso")
    # prepare definition of profiles to be exported
    File.open(File.join(options["output_folder"], "Rvi.rvi"), "w") do |file|
      file.write(File.join(options["output_folder"], file_name) + "\n")
      file.write(File.join(options["output_folder"], file_name.sub("eso", "csv")) + "\n")
      file.write(PROFILES)
      file.write("0\n")
    end

    # execute converter
    arguments = [
      options["converter_exe"],
      File.join(options["output_folder"], "Rvi.rvi"),
      "unlimited"
    ]
    system(arguments.join(" "))
  end
end

GenSimCLI.start(ARGV)
