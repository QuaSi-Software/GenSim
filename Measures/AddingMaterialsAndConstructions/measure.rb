class Material
   def initialize(name, thickness, conductivity, density, specificHeat)
      @cust_name = name
      @cust_thickness = thickness
	  @cust_conductivity = conductivity
      @cust_density = density
	  @cust_specificHeat = specificHeat
   end
   
   def Name
	  return @cust_name
   end
   def Thickness
	  return @cust_thickness
   end
   def Conductivity
	  return @cust_conductivity
   end
   def Density
	  return @cust_density
   end
   def SpecificHeat
	  return @cust_specificHeat
   end
end

# start the measure
class AddingMaterialsAndConstructions < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "AddingMaterialsAndConstructions"
  end

  # human readable description
  def description
    return "Inject materials and constructions into the model"
  end

  # human readable description of modeling approach
  def modeler_description
    return "Inject materials and constructions into the model"
  end
  
  def createMaterial(model, mat)
	#creates a OSMaterial"
		
	if mat.Name.empty?
		return nil
	elsif mat.Density.nil?
		osMat = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
		osMat.setName(mat.Name)
		osMat.setRoughness("Rough")
		# set argument values 
		osMat.setThickness(OpenStudio::Quantity.new(mat.Thickness, OpenStudio::createUnit("m").get))
		osMat.setThermalResistance( mat.Conductivity)
			
		return osMat
	else
		osMat = OpenStudio::Model::StandardOpaqueMaterial.new(model)
		osMat.setName(mat.Name)
		osMat.setRoughness("Rough")
		# set argument values 
		#osMat.setThickness( OpenStudio::Quantity.new(mat.Thickness, OpenStudio::createUnit("m").get))
      osMat.setThickness( mat.Thickness)
		osMat.setConductivity( mat.Conductivity)
		osMat.setDensity( mat.Density)
		osMat.setSpecificHeat( mat.SpecificHeat)
		
		return osMat
	end
  end
  
  def CreateConstruction(model, name, mats)
	constr = OpenStudio::Model::Construction.new(model)
	constr.setName(name)
	
	mats.each do |mat|
		if !mat.Name.empty?
			constr.insertLayer(constr.numLayers, createMaterial(model, mat))
		end
	end
	
	return constr
  end
  
  def CreateWindowConstruction(model, name, matname, uvalue, shgc)
	mat = OpenStudio::Model::SimpleGlazing.new(model)
	# set material properties
	mat.setUFactor( uvalue) 
	mat.setSolarHeatGainCoefficient(shgc)
	# construction
	constr = OpenStudio::Model::Construction.new(model)
	constr.setName(name)
	constr.insertLayer(constr.numLayers, mat)
		
	return constr;
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # External Wall Construction
	argumentName = "ExternalWallMat"
	for i in 1..4
		args << OpenStudio::Measure::OSArgument.makeStringArgument(argumentName + i.to_s + "Name", true)
		args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "Thickness", true)
		args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "Conductivity", true)
		args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "Density", true)
		args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "SpecificHeat", true)
	end
	
	# RoofMat
	argumentName = "RoofMat"
	for i in 1..4
		args << OpenStudio::Measure::OSArgument.makeStringArgument(argumentName + i.to_s + "Name", true)
		args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "Thickness", true)
		args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "Conductivity", true)
		args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "Density", true)
		args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "SpecificHeat", true)
	end
	
	# SlabMat
	argumentName = "SlabMat"
	for i in 1..4
		args << OpenStudio::Measure::OSArgument.makeStringArgument(argumentName + i.to_s + "Name", true)
		args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "Thickness", true)
		args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "Conductivity", true)
		args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "Density", true)
		args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "SpecificHeat", true)
	end
	
	# Massen
	argumentName = "Massen"
	for i in 1..3
		args << OpenStudio::Measure::OSArgument.makeStringArgument(argumentName + i.to_s + "Name", true)
		args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "Thickness", true)
		args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "Conductivity", true)
		args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "Density", true)
		args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "SpecificHeat", true)
	end
	
	# Massen
	argumentName = "InteriorSlabs"
	for i in 1..4
		args << OpenStudio::Measure::OSArgument.makeStringArgument(argumentName + i.to_s + "Name", true)
		args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "Thickness", true)
		args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "Conductivity", true)
		args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "Density", true)
		args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "SpecificHeat", true)
	end
	
	# Internal chilled ceiling
	argumentName = "ChilledCeiling"
    args << OpenStudio::Measure::OSArgument.makeIntegerArgument(argumentName + "SourceLayer", true)
	args << OpenStudio::Measure::OSArgument.makeIntegerArgument(argumentName + "TempCalcLayer", true)
	args << OpenStudio::Measure::OSArgument.makeIntegerArgument(argumentName + "DimCTF", true)
	args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName +  "TubeSpacing", true)
	for i in 1..4
		args << OpenStudio::Measure::OSArgument.makeStringArgument(argumentName + i.to_s + "Name", true)
		args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "Thickness", true)
		args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "Conductivity", true)
		args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "Density", true)
		args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "SpecificHeat", true)
	end
		
	argumentName = "Windows"
	args << OpenStudio::Measure::OSArgument.makeStringArgument(argumentName + "Name", true)
	args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + "UValue", true)
	args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + "SHGC", true)
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
	
	mats = Array.new
	argumentName = "ExternalWallMat"
	# assign the user inputs to variables
	for i in 1..4
		mats << Material.new(runner.getStringArgumentValue(argumentName + i.to_s + "Name", user_arguments), runner.getDoubleArgumentValue(argumentName + i.to_s + "Thickness", user_arguments),  runner.getDoubleArgumentValue(argumentName + i.to_s + "Conductivity", user_arguments), runner.getDoubleArgumentValue(argumentName + i.to_s + "Density", user_arguments), runner.getDoubleArgumentValue(argumentName + i.to_s + "SpecificHeat", user_arguments))
	end
	#external wall
	constrExtWall = CreateConstruction(model, "ExternalWallConstruction", mats)
	 # echo back to the user
	runner.registerInfo("Construction #{constrExtWall.name} was added.")
	
	mats = Array.new
	argumentName = "RoofMat"
	# assign the user inputs to variables
	for i in 1..4
		mats << Material.new(runner.getStringArgumentValue(argumentName + i.to_s + "Name", user_arguments), runner.getDoubleArgumentValue(argumentName + i.to_s + "Thickness", user_arguments),  runner.getDoubleArgumentValue(argumentName + i.to_s + "Conductivity", user_arguments), runner.getDoubleArgumentValue(argumentName + i.to_s + "Density", user_arguments), runner.getDoubleArgumentValue(argumentName + i.to_s + "SpecificHeat", user_arguments))
	end
	#external wall
	constrRoof = CreateConstruction(model, "RoofConstruction", mats)
	 # echo back to the user
	runner.registerInfo("Construction #{constrRoof.name} was added.")
	
	mats = Array.new
	argumentName = "SlabMat"
	# assign the user inputs to variables
	for i in 1..4
		mats << Material.new(runner.getStringArgumentValue(argumentName + i.to_s + "Name", user_arguments), runner.getDoubleArgumentValue(argumentName + i.to_s + "Thickness", user_arguments),  runner.getDoubleArgumentValue(argumentName + i.to_s + "Conductivity", user_arguments), runner.getDoubleArgumentValue(argumentName + i.to_s + "Density", user_arguments), runner.getDoubleArgumentValue(argumentName + i.to_s + "SpecificHeat", user_arguments))
	end
	#external wall
	constrSlab = CreateConstruction(model, "SlabConstruction", mats)
	 # echo back to the user
	runner.registerInfo("Construction #{constrSlab.name} was added.")
	
	mats = Array.new
	argumentName = "Massen"
	# assign the user inputs to variables
	for i in 1..3
		mats << Material.new(runner.getStringArgumentValue(argumentName + i.to_s + "Name", user_arguments), runner.getDoubleArgumentValue(argumentName + i.to_s + "Thickness", user_arguments),  runner.getDoubleArgumentValue(argumentName + i.to_s + "Conductivity", user_arguments), runner.getDoubleArgumentValue(argumentName + i.to_s + "Density", user_arguments), runner.getDoubleArgumentValue(argumentName + i.to_s + "SpecificHeat", user_arguments))
	end
	#external wall
	constrInternal = CreateConstruction(model, "InteriorConstruction", mats)
	 # echo back to the user
	runner.registerInfo("Construction #{constrInternal.name} was added.")
	
	mats = Array.new
	argumentName = "InteriorSlabs"
	# assign the user inputs to variables
	for i in 1..4
		mats << Material.new(runner.getStringArgumentValue(argumentName + i.to_s + "Name", user_arguments), runner.getDoubleArgumentValue(argumentName + i.to_s + "Thickness", user_arguments),  runner.getDoubleArgumentValue(argumentName + i.to_s + "Conductivity", user_arguments), runner.getDoubleArgumentValue(argumentName + i.to_s + "Density", user_arguments), runner.getDoubleArgumentValue(argumentName + i.to_s + "SpecificHeat", user_arguments))
	end
	#external wall
	interiorConstrSlab = CreateConstruction(model, "InteriorSlabConstruction", mats)
	 # echo back to the user
	runner.registerInfo("Construction #{interiorConstrSlab.name} was added.")
	
	argumentName = "Windows"
	constrWindow = CreateWindowConstruction(model, "WindowsConstruction", runner.getStringArgumentValue(argumentName + "Name", user_arguments), runner.getDoubleArgumentValue(argumentName + "UValue", user_arguments), runner.getDoubleArgumentValue(argumentName + "SHGC", user_arguments))
	 # echo back to the user
	runner.registerInfo("Construction #{constrWindow.name} was added.")
	
    model.getSurfaces.each do |surface|
		surfaceType = surface.surfaceType.upcase
		if surface.outsideBoundaryCondition == "Ground" and surfaceType == 'FLOOR'
			surface.setConstruction(constrSlab)
		elsif  surface.outsideBoundaryCondition == "Outdoors" and surfaceType == 'WALL'
			surface.setConstruction(constrExtWall)
		elsif  surface.outsideBoundaryCondition == "Outdoors" and surfaceType == 'ROOFCEILING'
			surface.setConstruction(constrRoof)
		elsif surfaceType == 'FLOOR'
		    surface.setConstruction(interiorConstrSlab)
		elsif surfaceType == 'ROOFCEILING'
		    surface.setConstruction(interiorConstrSlab)
		else
			surface.setConstruction(constrInternal)
		end
		# iterate over the subsurfaces to assign the window construction
		surface.subSurfaces.each do |subSurface|
			subSurface.setConstruction(constrWindow)
		end
	end

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getSurfaces.size} surfaces that have constructions now.")

    return true
  end
end

# register the measure to be used by the application
AddingMaterialsAndConstructions.new.registerWithApplication
