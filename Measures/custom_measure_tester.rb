# frozen_string_literal: true

require "openstudio_measure_tester"

# Custom runner class shadowing OpenStudioMeasureTester
# This was required to overwrite the default rubocop config file with the
# project-wide config.
class CustomRunner < OpenStudioMeasureTester::Runner
  def pre_process_rubocop
    result = super

    source = File.expand_path("../.rubocop.yml")
    target = File.expand_path("./.rubocop.yml")
    FileUtils.copy(source, target)

    return result
  end
end
