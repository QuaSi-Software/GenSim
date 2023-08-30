# frozen_string_literal: true

# Helper tool to automatically update the measure.xml files of all measures in the measure
# directory (where this file is placed). It takes one argument, which must be the
# executable of OpenStudio. For example on Windows this might look like this:
#
# ruby ./update_measure_xml.rb C:\openstudio-2.7.0\bin\openstudio.exe
#
# Please take caution when copying any path into this command as there is no validation
# of inputs!

base_directory = __dir__
command_to_run = ARGV[0]

unless command_to_run
  puts "Usage: ruby update_measure_xml.rb <open_studio_exe_path>"
  exit
end

# get a list of immediate subdirectories in the base directory
subdirectories = Dir.glob(File.join(base_directory, "*")).select do |path|
  File.directory?(path)
end

subdirectories.each do |path|
  dir_name = path.tr("\\", "/").split("/")[-1]
  next if %w[test test_results].include?(dir_name)

  Dir.chdir(path) do
    system("#{command_to_run} measure --update .")
  end
end
