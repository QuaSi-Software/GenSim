require "#{File.dirname(__FILE__)}/resources/os_lib_schedules"

# start the measure
class AddingPhotovoltaic < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "AddingPhotovoltaic"
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

    # set azimut
    azimuth = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("Azimuth", true)
    azimuth.setDisplayName("Azimuth angle of the PV")
    azimuth.setDefaultValue(0)
    args << azimuth
	
    # set slope
    slope = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("Slope", true)
    slope.setDisplayName("Slope angle of the PV")
    slope.setDefaultValue(0)
    args << slope

    # set cell_efficiency
    cell_efficiency = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("CellEfficiency", true)
    cell_efficiency.setDisplayName("Cell Efficiency")
    cell_efficiency.setUnits("fraction")
    cell_efficiency.setDefaultValue(0.18)
    args << cell_efficiency

    # set inverter_efficiency
    inverter_efficiency = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("InverterEfficiency", true)
    inverter_efficiency.setDisplayName("Inverter Efficiency")
    inverter_efficiency.setUnits("fraction")
    inverter_efficiency.setDefaultValue(0.98)
    args << inverter_efficiency

    # set Fraction Of Surface Area With Active Solar Cells
    fractionAreaWithActivePV = OpenStudio::Ruleset::OSArgument.makeDoubleArgument("FractionActiveSurfaceArea", true)
    fractionAreaWithActivePV.setDisplayName("Fraction Of Surface Area With Active Solar Cells")
    fractionAreaWithActivePV.setUnits("fraction")
    fractionAreaWithActivePV.setDefaultValue(0.9)
    args << fractionAreaWithActivePV

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
    azimuth = runner.getDoubleArgumentValue("Azimuth",user_arguments)
    slope = runner.getDoubleArgumentValue("Slope",user_arguments)
    cell_efficiency = runner.getDoubleArgumentValue("CellEfficiency",user_arguments)
    inverter_efficiency = runner.getDoubleArgumentValue("InverterEfficiency",user_arguments)
    fractionAreaWithActivePV = runner.getDoubleArgumentValue("FractionActiveSurfaceArea",user_arguments)

    # create the inverter
    inverter = OpenStudio::Model::ElectricLoadCenterInverterSimple.new(model)
    inverter.setInverterEfficiency(inverter_efficiency)
    runner.registerInfo("Created inverter with efficiency of #{inverter.inverterEfficiency}")

    # create the distribution system
    elcd = OpenStudio::Model::ElectricLoadCenterDistribution.new(model)
    elcd.setInverter(inverter)

    # create shared shading transmittance schedule
    target_transmittance = 1.0
    inputs = {
        'name' => "PV Shading Transmittance Schedule",
        'winterTimeValuePairs' => { 24.0 => target_transmittance },
        'summerTimeValuePairs' => { 24.0 => target_transmittance },
        'defaultTimeValuePairs' => { 24.0 => target_transmittance }
    }
    pv_shading_transmittance_schedule = OsLib_Schedules.createSimpleSchedule(model,inputs)
    runner.registerInfo("Created transmittance schedule for PV shading surfaces with constant value of #{target_transmittance}")
	
	####Creating Geometrie of the PV
	##########
	
	#Convert angels from deg to rad
	slope_rad = 0
	slope_rad = OpenStudio::convert(slope,"deg","rad").get
	azimuth_rad = 0
	azimuth_rad = OpenStudio::convert(azimuth,"deg","rad").get 
	
	#### Create a PV with 1 m² and the user given slope	and azimuth
   	
	#vertices with slope
	a_point = OpenStudio::Point3d.new(0,0,0)
    b_point = OpenStudio::Point3d.new(1,0,0)
    c_point = OpenStudio::Point3d.new(1,Math.cos(slope_rad),Math.sin(slope_rad))
    d_point = OpenStudio::Point3d.new(0,Math.cos(slope_rad),Math.sin(slope_rad))
	
	#rotation with azimuth
	z_axis = OpenStudio::Vector3d.new(0,0,1)
	origin = OpenStudio::Point3d.new(0,0,0)
	trans = OpenStudio::Transformation::rotation(origin, z_axis, azimuth_rad)
	
	#Generate rotated points
	b_point = trans*b_point
	c_point = trans*c_point
	d_point = trans*d_point
	
	#Create the vertices
	polygon = OpenStudio::Point3dVector.new
	polygon << a_point
	polygon << b_point
	polygon << c_point
	polygon << d_point
	
	####Create PV Objects
	##########
	
    # make shading surface group and set origin
	shading_surface_group = OpenStudio::Model::ShadingSurfaceGroup.new(model)
	shading_surface_group.setXOrigin(500)
	shading_surface_group.setYOrigin(0)
	shading_surface_group.setZOrigin(0)

	# make shading surface for new group
	shading_surface = OpenStudio::Model::ShadingSurface.new(polygon,model)
	shading_surface.setShadingSurfaceGroup(shading_surface_group)
	shading_surface.setName("Photovoltaic System")
	shading_surface.setTransmittanceSchedule(pv_shading_transmittance_schedule)

	# create the panel
	panel = OpenStudio::Model::GeneratorPhotovoltaic::simple(model)
	panel.setSurface(shading_surface)
	performance = panel.photovoltaicPerformance.to_PhotovoltaicPerformanceSimple.get
	performance.setFractionOfSurfaceAreaWithActiveSolarCells(fractionAreaWithActivePV)
	performance.setFixedEfficiency(cell_efficiency)

	# connect panel to electric load center distribution
	elcd.addGenerator(panel)

    runner.registerFinalCondition("PV successfully added with inverter efficieny of #{inverter.inverterEfficiency} and a transmittance of the shading surfeaces of #{target_transmittance}." )
	  return true
  end
end

# register the measure to be used by the application
AddingPhotovoltaic.new.registerWithApplication
