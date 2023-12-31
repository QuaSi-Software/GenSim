# frozen_string_literal: true

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class InjectRadiantSurfacesIDF < OpenStudio::Measure::EnergyPlusMeasure
  # human readable name
  def name
    return "InjectRadiantSurfacesIDF"
  end

  # general description of measure
  def description
    return "Inject radiant surfaces."
  end

  # description for users of what the measure does and how it works
  def modeler_description
    return "Inject radiant surfaces."
  end

  # define the arguments that the user will input
  def arguments(_workspace)
    args = OpenStudio::Measure::OSArgumentVector.new
    return args
  end

  # define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    # use the built-in error checking
    return false unless runner.validateUserArguments(arguments(workspace), user_arguments)

    # get all low temp radiant equipment in model
    lowTempRadiants = workspace.getObjectsByType("ZoneHVAC:LowTemperatureRadiant:VariableFlow".to_IddObjectType)

    # get all internal mass objects in model
    internalMasses = workspace.getObjectsByType("InternalMass".to_IddObjectType)

    counter = 0
    # reporting initial condition of model
    runner.registerInitialCondition("The building started with #{lowTempRadiants.size} Low Temp Radiant objects and #{internalMasses.size} Internal Masses.")
    lowTempRadiants.each do |lowTempRadiant|
      runner.registerInfo("LowTempZoneName: #{lowTempRadiant.getString(2)}")
      internalMasses.each do |internalMass|
        runner.registerInfo("InternalMass ZoneName: #{internalMass.getString(2)}")
        runner.registerInfo("are equal? #{internalMass.getString(2).to_s == lowTempRadiant.getString(2).to_s}")
        next unless internalMass.getString(2).to_s == lowTempRadiant.getString(2).to_s
        lowTempRadiant.setString(3, internalMass.getString(0).to_s)
        counter += 1
        workspace.insertObject(lowTempRadiant)
      end
    end

    lowTempRadSurfaceGroups = workspace.getObjectsByType("ZoneHVAC:LowTemperatureRadiant:SurfaceGroup".to_IddObjectType)
    lowTempRadSurfaceGroups.each(&:remove)

    runner.registerFinalCondition("The building finished with #{counter}/#{lowTempRadiants.size} updated low temperature rediant objects objects.")

    return true
  end
end

# register the measure to be used by the application
InjectRadiantSurfacesIDF.new.registerWithApplication
