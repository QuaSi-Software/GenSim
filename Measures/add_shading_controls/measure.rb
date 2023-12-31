# frozen_string_literal: true

# start the measure
class AddShadingControls < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return "AddShadingControls"
  end

  # general description of measure
  def description
    return "Add shading controls."
  end

  # description for users of what the measure does and how it works
  def modeler_description
    return "Add shading controls."
  end

  # define the arguments that the user will input
  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # make an argument for infiltration
    setpoint = OpenStudio::Measure::OSArgument.makeDoubleArgument("solar_setpoint", true)
    setpoint.setDisplayName("Solar Irradiation [W/m²] on window above which the ShadingControl is activated")
    setpoint.setDefaultValue(180)
    args << setpoint

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    # assign the user inputs to variables
    setpoint = runner.getDoubleArgumentValue("solar_setpoint", user_arguments)

    # check infiltration for reasonableness
    if setpoint < 0
      runner.registerError("The requested Solar Irradiation of #{setpoint} W/m² was below the measure limit. Choose a positive number.")
      return false
    elsif setpoint > 5000
      runner.registerWarning("The requested Solar Irradiation of  #{setpoint} W/m² seems abnormally high.")
    end

    # Add Window Material Blind for ShadingControl
    new_shading_material = OpenStudio::Model::Blind.new(model)

    # loop through subsurfaces in the model adding ShadingControl objects to all windows
    sub_surfaces = model.getSubSurfaces
    window_count = 0

    # report initial condition of model
    runner.registerInitialCondition("Adding shading controls to potentially #{model.getSubSurfaces.size} windows wiht a setpoint of: #{setpoint}")

    sub_surfaces.each do |sub_surface|
      # If Subsurface is not a window "next"
      next if sub_surface.subSurfaceType != "FixedWindow"

      window_count += 1
      runner.registerInfo("ShadingControl added for window #{sub_surface.name}")

      new_shading_control = OpenStudio::Model::ShadingControl.new(new_shading_material)
      new_shading_control.setName("#{sub_surface.name} shading control")
      new_shading_control.setShadingControlType("OnIfHighSolarOnWindow")
      new_shading_control.setShadingType("ExteriorBlind")
      new_shading_control.setSetpoint(setpoint)
      sub_surface.setShadingControl(new_shading_control)
    end # end subsurfaces.each do

    runner.registerFinalCondition("#{window_count} shading controls added to windows in total")

    return true
  end
end

# register the measure to be used by the application
AddShadingControls.new.registerWithApplication
