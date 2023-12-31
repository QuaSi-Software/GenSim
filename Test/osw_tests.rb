# frozen_string_literal: true

require "test/unit"
require "json"

# Prepare a given path-like string for comparisons.
#
# This replaces backwards with forwards slash and replaces the special string
# "$GENSIM_PATH$" with the path of gensim as derived from the location of this script
# file.
#
# @param raw (String) The string to prepare
# @return (String) The prepared string
def prepare_path(raw)
  prepared = raw.tr("\\", "/")
  prepared = prepared.gsub("$GENSIM_PATH$/", File.join(__dir__, ".."))
  prepared = prepared.gsub("Test/..", "")
  return prepared
end

# Check the given exported measure hashdict against expectations.
#
# Checks are performed with assert_equal within the method and there is no return value.
#
# @param expected (Hash) The expected values
# @param exported (Hash) The exported values
def check_measure(expected, exported)
  assert(exported.key?("measure_dir_name"), "Missing key measure_dir_name\n")
  assert_equal(expected["measure_dir_name"], exported["measure_dir_name"])

  assert(exported.key?("arguments"), "Missing key arguments\n")
  assert_equal(expected["arguments"].length, exported["arguments"].length)

  expected["arguments"].each do |key, value|
    assert(
      exported["arguments"].key?(key),
      "Missing parameter key #{key} in measure #{expected['measure_dir_name']}"
    )

    err_msg = "Value mismatch in measure #{expected['measure_dir_name']}::#{key}"
    if key.include?("Path") || key.include?("path")
      assert_equal(prepare_path(value), prepare_path(exported["arguments"][key]), err_msg)
    else
      assert_equal(value, exported["arguments"][key], err_msg)
    end
  end
end

# Perform tests comparing the two given OSW files.
#
# @param expected_file_path (String) File path to the OSW with expected values
# @param compared_file_path (String) File path to the OSW with values to check
def compare_osw_files(expected_file_path, compared_file_path)
  file_content = File.read(expected_file_path)
  expected = JSON.parse(file_content)

  file_content = File.read(compared_file_path)
  exported = JSON.parse(file_content)

  assert(exported.key?("weather_file"), "Missing key weather_file\n")
  assert_equal(
    prepare_path(expected["weather_file"]),
    prepare_path(exported["weather_file"])
  )

  assert(exported.key?("measure_paths"), "Missing key measure_paths\n")
  expected["measure_paths"].each_with_index do |element, index|
    assert_equal(
      prepare_path(element),
      prepare_path(exported["measure_paths"][index])
    )
  end

  assert(exported.key?("seed_file"), "Missing key seed_file\n")
  assert_equal(expected["seed_file"], exported["seed_file"])

  assert(exported.key?("steps"), "Missing key steps\n")
  expected["steps"].each_with_index do |element, index|
    if index >= exported["steps"].length
      assert(false, "Wanted to check measure at pos #{index} but could not find it\n")
    else
      check_measure(element, exported["steps"][index])
    end
  end
end

# Tests for the export of parameters to an OSW file
class TestExportToOSW < Test::Unit::TestCase
  # check the export of default parameter valuess when nothing has been changed in the GUI
  def test_exported_defaults
    compare_osw_files(
      "./expected/exported_defaults.osw",
      "./../Output/Model.osw"
    )
  end
end

# Tests for the import of parameters from an OSW file
class TestImportedOSW < Test::Unit::TestCase
  # check the export of parameter values after a parameter file has been imported
  # this checks parameters for generic geometry and weather data
  def test_generic_geometry_and_weather
    compare_osw_files(
      "./parameter_sets/env_ii/generic_geometry_and_weather.osw",
      "./../Output/generic_geometry_and_weather.osw"
    )
  end

  # check the export of parameter values after a parameter file has been imported
  # this checks parameters for the hvac system
  def test_hvac_parameters
    compare_osw_files(
      "./parameter_sets/env_ii/hvac_parameters.osw",
      "./../Output/hvac_parameters.osw"
    )
  end

  # check the export of parameter values after a parameter file has been imported
  # this checks parameters for the building standard (envelope and inner masses)
  def test_building_standards
    compare_osw_files(
      "./parameter_sets/env_ii/building_standards.osw",
      "./../Output/building_standards.osw"
    )
  end
end
