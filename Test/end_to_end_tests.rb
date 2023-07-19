require 'test/unit'
require 'json'

# Calculate the absolute tolerance from the given string and, if required the
# reference value. This method is somewhat brittle in terms of accepted inputs
# and parsing numbers from the string, however this was traded in exchange for
# fast calculations, which is useful given that the method is used for tests
# with known inputs.
#
# @param str_tolerance (String) The string defining the tolerance, e.g. "0.3"
#   or "5%".
# @param expected_value (Float) The reference value. Optional, defaults to 0.
# @return (Float) The absolute value of the tolerance as parsed and calculated
#   from given inputs
def absolute_tolerance(str_tolerance, expected_value=0.0)
    if str_tolerance[-1] == "%"
        tolerance = str_tolerance[0..-2].to_f() * 0.01
        return (tolerance * expected_value).abs
    else
        tolerance = str_tolerance.to_f()
        return (tolerance).abs
    end
end

# Compare values within a given range of the expected value.
#
# @param expected (Float) The expected value
# @param actual (Float) The value to test
# @param tolerance (Float) The absolute delta that defines the range
# @param message (String) (Optional) A message to be added to the message list
#   if the check fails
# @param messages (List) (Optional) The list to which append messages
# @return (Bool) True if the actual value is within the expected range
def check_approximates(expected, actual, tolerance, message=nil, messages=nil)
    evaluated = (expected - tolerance <= actual) & (expected + tolerance >= actual)
    if (!evaluated & !message.nil? & !messages.nil?)
        messages.append(message)
    end
    return evaluated
end

# Tests on the file handling functionality and the KPI data file format.
class TestKPIFile < Test::Unit::TestCase

    # Test if JSON files can be read. This test is fairly superfluous given that
    # the json module has its own tests, however can be useful to test if the
    # json module is installed as the test will fail if it is not.
    def test_read_json_file
        file_content = File.read('./expected/json_test_file.json')
        kpis = JSON.parse(file_content)
        expected = {
            "foo" => "bar",
            "bar" => "baz"
        }
        assert_equal expected, kpis
    end

    # Tests if the KPI data file can be parsed by checking for samples of values
    # in the file. This test should be adapted to changes in the file format, so
    # that file "expected/kpis_test_file.json" always matches the current version
    # of the file format and this test passes.
    def test_read_kpis_data_file
        file_content = File.read('./expected/kpis_test_file.json')
        kpis = JSON.parse(file_content)

        assert_equal 56.2189371637002, kpis["KPIs"]["Heizbedarf"]["Value"]
        assert_equal "[kWh/m^2NRF*a]", kpis["KPIs"]["Nutzerstrom_Elektrische_Geraete"]["Unit"]
        assert_equal 16611.5315739942, kpis["Profiles"]["Kuehlenergie"]["Sum_yearly"]
        assert_equal 24.3153397310774, kpis["Profiles"]["Kuehlenergie"]["Sum_monthly"]["March"]
    end

    # Tests for method absolute_tolerance
    def test_absolute_tolerance
        assert_equal 0.0, absolute_tolerance("0")
        assert_equal 0.0, absolute_tolerance("0%")
        assert_equal 0.0, absolute_tolerance("0.0")
        assert_equal 3.14, absolute_tolerance("3.14")
        assert_equal 5.0, absolute_tolerance("5%", 100.0)
        assert_equal 0.0, absolute_tolerance("5%", 0.0)
        assert_equal 0.0, absolute_tolerance("0%", 100.0)
        assert_equal 5.0, absolute_tolerance("5%", -100.0)
        assert_equal 5.0, absolute_tolerance("-5%", 100.0)
        assert_equal 5.0, absolute_tolerance("-5%", -100.0)

        # oridinarily we would expect additional characters to cause parsing
        # errors, but ruby is fairly robust in its parsing, so this works too
        assert_equal 5.0, absolute_tolerance("5% ", 100.0)
        assert_equal 5.0, absolute_tolerance("5$", 100.0)
        assert_equal 5.0, absolute_tolerance("5&", 100.0)
    end

    # Tests for check_approximates without using message
    def test_check_approximates
        assert(check_approximates(0.0, 0.0, 0.0))
        assert(check_approximates(0.0, 0.05, 0.1))
        assert(check_approximates(0.0, 0.1, 0.1))
        assert(check_approximates(-1.0, -1.05, 0.1))
        assert(!check_approximates(0.0, 0.15, 0.1))
        assert(!check_approximates(0.0, 0.05, 0.0))
        assert(!check_approximates(-1.0, -1.1, 0.05))
    end

    # Tests for check_approximates using a message
    def test_check_approximates_with_message
        # check succeeded, message should not appear
        messages = []
        result = check_approximates(
            0.0, 0.0, 0.0, "Message should not appear", messages
        )
        assert_equal(messages, [])
        assert(result)

        # check failed, message should appear
        messages = []
        result = check_approximates(
            0.0, 1.0, 0.5, "Message should appear", messages
        )
        assert_equal(messages, ["Message should appear"])
        assert(!result)

        # should default to not using message
        result = check_approximates(0.0, 0.0, 0.0, nil, nil)
        assert(result)
    end
end

# Compare the values of monthly sums between expected values and run results.
#
# @param expected [Hash] The expected monthly sums in String->Float pairs of
#   the month's name and the corresponding value
# @param run_results [Hash] The monthly sums of the run results in String->Float
#   pairs of the month's name and the corresponding value
# @param str_tolerance [String] The string defining the tolerance for comparisons
# @param messages (List) List for messages from failed checks
# @return (Bool) True if all tests were successful, false otherwise
def compare_monthly_sum(expected, run_results, str_tolerance, messages)
    accumulator = true

    expected.each do |month, value|
        if month == "_note"
            # nothing to do
        else
            assert(run_results.key?(month), "Missing month " + name + "\n")
            tolerance = absolute_tolerance(str_tolerance, value)
            result = check_approximates(
                value, run_results[month], tolerance,
                "Month " + month + " does not match expectations\n",
                messages
            )
            accumulator = accumulator & result
        end
    end

    return accumulator
end

# Compare the parsed contents of a result file with the corresponding expected values.
#
# @param expected [Hash] The contents of the KPI data file with the expected
#   values.
# @param run_results [Hash] The contents of the KPI data with the run results.
def compare_result_files(expected, run_results)
    messages = []
    accumulator = true

    # for KPIs we check the value and unit for each named KPI in the expected
    # input against the run results
    expected["KPIs"].each do |name, entries|
        assert(run_results["KPIs"].key?(name), "Missing KPI " + name + "\n")

        tolerance = absolute_tolerance(entries["Tolerance"], entries["Value"])
        accumulator = accumulator & check_approximates(
            entries["Value"],
            run_results["KPIs"][name]["Value"],
            tolerance,
            "KPI " + name + " does not match expectations\n",
            messages
        )

        assert_equal(
            entries["Unit"],
            run_results["KPIs"][name]["Unit"],
            "Unit of KPI " + name + " does not match expectations\n"
        )
    end

    # for profiles we check the values and units for each profile and month
    # plus certain year-based KPIs
    expected["Profiles"].each do |profile_name, entries|
        assert(
            run_results["Profiles"].key?(profile_name),
            "Missing profile " + profile_name + "\n"
        )

        tolerance = absolute_tolerance(entries["Tolerance"], entries["Sum_yearly"])
        accumulator = accumulator & check_approximates(
            entries["Sum_yearly"],
            run_results["Profiles"][profile_name]["Sum_yearly"],
            tolerance,
            "Yearly sum of profile " + profile_name + " does not match\n",
            messages
        )

        tolerance = absolute_tolerance(entries["Tolerance"], entries["Max_yearly"])
        accumulator = accumulator & check_approximates(
            entries["Max_yearly"],
            run_results["Profiles"][profile_name]["Max_yearly"],
            tolerance,
            "Max Yearly of profile " + profile_name + " does not match\n",
            messages
        )

        tolerance = absolute_tolerance(entries["Tolerance"], entries["Min_yearly"])
        accumulator = accumulator & check_approximates(
            entries["Min_yearly"],
            run_results["Profiles"][profile_name]["Min_yearly"],
            tolerance,
            "Min Yearly of profile " + profile_name + " does not match\n",
            messages
        )

        tolerance = absolute_tolerance(entries["Tolerance"], entries["Mean_yearly"])
        accumulator = accumulator & check_approximates(
            entries["Mean_yearly"],
            run_results["Profiles"][profile_name]["Mean_yearly"],
            tolerance,
            "Mean Yearly of profile " + profile_name + " does not match\n",
            messages
        )

        assert_equal(
            entries["Unit"],
            run_results["Profiles"][profile_name]["Unit"],
            "Unit of profile" + profile_name + " does not match\n"
        )

        accumulator = accumulator & compare_monthly_sum(
            entries["Sum_monthly"],
            run_results["Profiles"][profile_name]["Sum_monthly"],
            entries["Tolerance"],
            messages
        )
    end

    if !accumulator
        messages.each do |message|
            print(message)
        end
    end
    assert(accumulator, "Output does not match expectations\n")
end

# Tests for the various defined test cases. The accompanying documentation lists
# the tests cases and which parameters each one encompasses. For convenience of
# running the tests they are only numbered in this code. Check the documentation
# for details on each test.
class TestEndToEnd < Test::Unit::TestCase

    # Test case 1: MFH Bestand saniert
    def test_case_01
        run_results = JSON.parse(File.read(
            '../Output/end2end/test_01.json'
        ))
        expected = JSON.parse(File.read(
            './expected/end2end/test_01.json'
        ))
        compare_result_files(expected, run_results)
    end

    # Test case 2: Büro EH55
    def test_case_02
        run_results = JSON.parse(File.read(
            '../Output/end2end/test_02.json'
        ))
        expected = JSON.parse(File.read(
            './expected/end2end/test_02.json'
        ))
        compare_result_files(expected, run_results)
    end

    # Test case 3: Schule EH55
    def test_case_03
        run_results = JSON.parse(File.read(
            '../Output/end2end/test_03.json'
        ))
        expected = JSON.parse(File.read(
            './expected/end2end/test_03.json'
        ))
        compare_result_files(expected, run_results)
    end
end