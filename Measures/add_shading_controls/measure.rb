# start the measure
class AddShadingControls < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "AddShadingControls"
  end

  # human readable description
  def description
    return ""
  end

  # human readable description of modeling approach
  def modeler_description
    return ""
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    #make an argument for infiltration
    setpoint = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("solar_setpoint", true)
    setpoint.setDisplayName("Solar Irradiation [W/m²] on window above which the ShadingControl is activated")
    setpoint.setDefaultValue(180)
    args << setpoint

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    setpoint = runner.getDoubleArgumentValue("solar_setpoint", user_arguments)

    #check infiltration for reasonableness
    if setpoint < 0
      runner.registerError("The requested Solar Irradiation of #{setpoint} W/m² was below the measure limit. Choose a positive number.")
      return false
    elsif setpoint > 5000
      runner.registerWarning("The requested Solar Irradiation of  #{setpoint} W/m² seems abnormally high.")
    end

    # Add Window Material Blind for ShadingControl
    new_shading_material = OpenStudio::Model::Blind.new(model)

    #loop through subsurfaces in the model adding ShadingControl objects to all windows
    sub_surfaces = model.getSubSurfaces
    window_count = 0

    # report initial condition of model
    runner.registerInitialCondition("Adding shading controls to potentially #{model.getSubSurfaces.size} windows wiht a setpoint of: #{setpoint}")

    sub_surfaces.each do |sub_surface|

      #If Subsurface is not a window "next"
      next if not sub_surface.subSurfaceType == "FixedWindow"

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
