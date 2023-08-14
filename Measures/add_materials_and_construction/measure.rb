# frozen_string_literal: true

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
class AddMaterialsAndConstruction < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    return "AddMaterialsAndConstruction"
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
    # creates a OSMaterial"

    if mat.Name.empty?
      return nil
    elsif mat.Density.nil?
      osMat = OpenStudio::Model::MasslessOpaqueMaterial.new(model)
      osMat.setName(mat.Name)
      osMat.setRoughness("Rough")
      # set argument values
      osMat.setThickness(OpenStudio::Quantity.new(mat.Thickness, OpenStudio.createUnit("m").get))
      osMat.setThermalResistance(mat.Conductivity)

      return osMat
    else
      osMat = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      osMat.setName(mat.Name)
      osMat.setRoughness("Rough")
      # set argument values
      # osMat.setThickness( OpenStudio::Quantity.new(mat.Thickness, OpenStudio::createUnit("m").get))
      osMat.setThickness(mat.Thickness)
      osMat.setConductivity(mat.Conductivity)
      osMat.setDensity(mat.Density)
      osMat.setSpecificHeat(mat.SpecificHeat)

      return osMat
    end
  end

  def CreateConstruction(model, name, mats)
    constr = OpenStudio::Model::Construction.new(model)
    constr.setName(name)

    mats.each do |mat|
      constr.insertLayer(constr.numLayers, createMaterial(model, mat)) unless mat.Name.empty?
    end

    return constr
  end

  def CreateWindowConstruction(model, name, _matname, uvalue, shgc)
    mat = OpenStudio::Model::SimpleGlazing.new(model)
    # set material properties
    mat.setUFactor(uvalue)
    mat.setSolarHeatGainCoefficient(shgc)
    # construction
    constr = OpenStudio::Model::Construction.new(model)
    constr.setName(name)
    constr.insertLayer(constr.numLayers, mat)

    return constr
  end

  # define the arguments that the user will input
  def arguments(_model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # External Wall Construction
    argumentName = "external_wall_"
    for i in 1..4
      args << OpenStudio::Measure::OSArgument.makeStringArgument(argumentName + i.to_s + "_name", true)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_thickness", true)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_conductivity", true)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_density", true)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_heat_capacity", true)
    end

    # RoofMat
    argumentName = "roof_"
    for i in 1..4
      args << OpenStudio::Measure::OSArgument.makeStringArgument(argumentName + i.to_s + "_name", true)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_thickness", true)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_conductivity", true)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_density", true)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_heat_capacity", true)
    end

    # SlabMat
    argumentName = "base_plate_"
    for i in 1..4
      args << OpenStudio::Measure::OSArgument.makeStringArgument(argumentName + i.to_s + "_name", true)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_thickness", true)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_conductivity", true)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_density", true)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_heat_capacity", true)
    end

    # Massen
    argumentName = "inner_masses_"
    for i in 1..3
      args << OpenStudio::Measure::OSArgument.makeStringArgument(argumentName + i.to_s + "_name", true)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_thickness", true)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_conductivity", true)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_density", true)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_heat_capacity", true)
    end

    # Massen
    argumentName = "interior_slab_"
    for i in 1..4
      args << OpenStudio::Measure::OSArgument.makeStringArgument(argumentName + i.to_s + "_name", true)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_thickness", true)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_conductivity", true)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_density", true)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_heat_capacity", true)
    end

    # Internal chilled ceiling
    argumentName = "chilled_ceiling_"
    args << OpenStudio::Measure::OSArgument.makeIntegerArgument(argumentName + "source_layer", true)
    args << OpenStudio::Measure::OSArgument.makeIntegerArgument(argumentName + "temp_calc_layer", true)
    args << OpenStudio::Measure::OSArgument.makeIntegerArgument(argumentName + "dim_ctf", true)
    args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + "tube_spacing", true)
    for i in 1..4
      args << OpenStudio::Measure::OSArgument.makeStringArgument(argumentName + i.to_s + "_name", true)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_thickness", true)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_conductivity", true)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_density", true)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_heat_capacity", true)
    end

    argumentName = "windows_"
    args << OpenStudio::Measure::OSArgument.makeStringArgument(argumentName + "name", true)
    args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + "u_value", true)
    args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + "shgc", true)

    # checkbox value for custom standard
    args << OpenStudio::Measure::OSArgument.makeBoolArgument("is_custom_standard", false)

    # selection value for building standard
    args << OpenStudio::Measure::OSArgument.makeStringArgument("construction_standard_selection", false)

    # selection value for inner masses
    args << OpenStudio::Measure::OSArgument.makeStringArgument("inner_masses_selection", false)

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    mats = []
    argumentName = "external_wall_"
    # assign the user inputs to variables
    for i in 1..4
      mats << Material.new(
        runner.getStringArgumentValue(argumentName + i.to_s + "_name", user_arguments),
        runner.getDoubleArgumentValue(argumentName + i.to_s + "_thickness", user_arguments),
        runner.getDoubleArgumentValue(argumentName + i.to_s + "_conductivity", user_arguments),
        runner.getDoubleArgumentValue(argumentName + i.to_s + "_density", user_arguments),
        runner.getDoubleArgumentValue(argumentName + i.to_s + "_heat_capacity", user_arguments)
      )
    end
    # external wall
    constrExtWall = CreateConstruction(model, "ExternalWallConstruction", mats)
    # echo back to the user
    runner.registerInfo("Construction #{constrExtWall.name} was added.")

    mats = []
    argumentName = "roof_"
    # assign the user inputs to variables
    for i in 1..4
      mats << Material.new(
        runner.getStringArgumentValue(argumentName + i.to_s + "_name", user_arguments),
        runner.getDoubleArgumentValue(argumentName + i.to_s + "_thickness", user_arguments),
        runner.getDoubleArgumentValue(argumentName + i.to_s + "_conductivity", user_arguments),
        runner.getDoubleArgumentValue(argumentName + i.to_s + "_density", user_arguments),
        runner.getDoubleArgumentValue(argumentName + i.to_s + "_heat_capacity", user_arguments)
      )
    end
    # external wall
    constrRoof = CreateConstruction(model, "RoofConstruction", mats)
    # echo back to the user
    runner.registerInfo("Construction #{constrRoof.name} was added.")

    mats = []
    argumentName = "base_plate_"
    # assign the user inputs to variables
    for i in 1..4
      mats << Material.new(
        runner.getStringArgumentValue(argumentName + i.to_s + "_name", user_arguments),
        runner.getDoubleArgumentValue(argumentName + i.to_s + "_thickness", user_arguments),
        runner.getDoubleArgumentValue(argumentName + i.to_s + "_conductivity", user_arguments),
        runner.getDoubleArgumentValue(argumentName + i.to_s + "_density", user_arguments),
        runner.getDoubleArgumentValue(argumentName + i.to_s + "_heat_capacity", user_arguments)
      )
    end
    # external wall
    constrSlab = CreateConstruction(model, "SlabConstruction", mats)
    # echo back to the user
    runner.registerInfo("Construction #{constrSlab.name} was added.")

    mats = []
    argumentName = "inner_masses_"
    # assign the user inputs to variables
    for i in 1..3
      mats << Material.new(
        runner.getStringArgumentValue(argumentName + i.to_s + "_name", user_arguments),
        runner.getDoubleArgumentValue(argumentName + i.to_s + "_thickness", user_arguments),
        runner.getDoubleArgumentValue(argumentName + i.to_s + "_conductivity", user_arguments),
        runner.getDoubleArgumentValue(argumentName + i.to_s + "_density", user_arguments),
        runner.getDoubleArgumentValue(argumentName + i.to_s + "_heat_capacity", user_arguments)
      )
    end
    # external wall
    constrInternal = CreateConstruction(model, "InteriorConstruction", mats)
    # echo back to the user
    runner.registerInfo("Construction #{constrInternal.name} was added.")

    mats = []
    argumentName = "interior_slab_"
    # assign the user inputs to variables
    for i in 1..4
      mats << Material.new(
        runner.getStringArgumentValue(argumentName + i.to_s + "_name", user_arguments),
        runner.getDoubleArgumentValue(argumentName + i.to_s + "_thickness", user_arguments),
        runner.getDoubleArgumentValue(argumentName + i.to_s + "_conductivity", user_arguments),
        runner.getDoubleArgumentValue(argumentName + i.to_s + "_density", user_arguments),
        runner.getDoubleArgumentValue(argumentName + i.to_s + "_heat_capacity", user_arguments)
      )
    end
    # external wall
    interiorConstrSlab = CreateConstruction(model, "InteriorSlabConstruction", mats)
    # echo back to the user
    runner.registerInfo("Construction #{interiorConstrSlab.name} was added.")

    argumentName = "windows_"
    constrWindow = CreateWindowConstruction(
      model,
      "WindowsConstruction",
      runner.getStringArgumentValue(argumentName + "name", user_arguments),
      runner.getDoubleArgumentValue(argumentName + "u_value", user_arguments),
      runner.getDoubleArgumentValue(argumentName + "shgc", user_arguments)
    )
    # echo back to the user
    runner.registerInfo("Construction #{constrWindow.name} was added.")

    model.getSurfaces.each do |surface|
      surfaceType = surface.surfaceType.upcase
      if (surface.outsideBoundaryCondition == "Ground") && (surfaceType == "FLOOR")
        surface.setConstruction(constrSlab)
      elsif (surface.outsideBoundaryCondition == "Outdoors") && (surfaceType == "WALL")
        surface.setConstruction(constrExtWall)
      elsif (surface.outsideBoundaryCondition == "Outdoors") && (surfaceType == "ROOFCEILING")
        surface.setConstruction(constrRoof)
      elsif surfaceType == "FLOOR"
        surface.setConstruction(interiorConstrSlab)
      elsif surfaceType == "ROOFCEILING"
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
AddMaterialsAndConstruction.new.registerWithApplication
