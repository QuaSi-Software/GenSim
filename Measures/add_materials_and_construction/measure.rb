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
  MatLayerCount = 10

  # human readable name
  def name
    return "AddMaterialsAndConstruction"
  end

  # general description of measure
  def description
    return "Inject materials and constructions into the model"
  end

  # description for users of what the measure does and how it works
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
      osMat.setThickness(mat.Thickness)
      osMat.setThermalResistance(mat.Conductivity)

      return osMat
    else
      osMat = OpenStudio::Model::StandardOpaqueMaterial.new(model)
      osMat.setName(mat.Name)
      osMat.setRoughness("Rough")
      # set argument values
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
    for i in 1..MatLayerCount
      args << OpenStudio::Measure::OSArgument.makeStringArgument(argumentName + i.to_s + "_name", i == 1)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_thickness", i == 1)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_conductivity", i == 1)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_density", i == 1)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_heat_capacity", i == 1)
    end

    # RoofMat
    argumentName = "roof_"
    for i in 1..MatLayerCount
      args << OpenStudio::Measure::OSArgument.makeStringArgument(argumentName + i.to_s + "_name", i == 1)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_thickness", i == 1)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_conductivity", i == 1)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_density", i == 1)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_heat_capacity", i == 1)
    end

    # SlabMat
    argumentName = "base_plate_"
    for i in 1..MatLayerCount
      args << OpenStudio::Measure::OSArgument.makeStringArgument(argumentName + i.to_s + "_name", i == 1)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_thickness", i == 1)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_conductivity", i == 1)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_density", i == 1)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_heat_capacity", i == 1)
    end

    # Massen
    argumentName = "inner_masses_"
    for i in 1..MatLayerCount
      args << OpenStudio::Measure::OSArgument.makeStringArgument(argumentName + i.to_s + "_name", i == 1)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_thickness", i == 1)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_conductivity", i == 1)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_density", i == 1)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_heat_capacity", i == 1)
    end

    # Massen
    argumentName = "interior_slab_"
    for i in 1..MatLayerCount
      args << OpenStudio::Measure::OSArgument.makeStringArgument(argumentName + i.to_s + "_name", i == 1)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_thickness", i == 1)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_conductivity", i == 1)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_density", i == 1)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_heat_capacity", i == 1)
    end

    # Internal chilled ceiling
    argumentName = "chilled_ceiling_"
    args << OpenStudio::Measure::OSArgument.makeIntegerArgument(argumentName + "source_layer", true)
    args << OpenStudio::Measure::OSArgument.makeIntegerArgument(argumentName + "temp_calc_layer", true)
    args << OpenStudio::Measure::OSArgument.makeIntegerArgument(argumentName + "dim_ctf", true)
    args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + "tube_spacing", true)
    for i in 1..MatLayerCount
      args << OpenStudio::Measure::OSArgument.makeStringArgument(argumentName + i.to_s + "_name", i == 1)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_thickness", i == 1)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_conductivity", i == 1)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_density", i == 1)
      args << OpenStudio::Measure::OSArgument.makeDoubleArgument(argumentName + i.to_s + "_heat_capacity", i == 1)
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

  # parses a material definition from the arguments
  def getMaterialFromArguments(prefix, nr, as_optional, runner, user_arguments)
    if as_optional
      name = runner.getOptionalStringArgumentValue(prefix + nr.to_s + "_name", user_arguments)
      if name.empty?
        return false
      end

      return Material.new(
        name.get(),
        runner.getOptionalDoubleArgumentValue(prefix + nr.to_s + "_thickness", user_arguments).get(),
        runner.getOptionalDoubleArgumentValue(prefix + nr.to_s + "_conductivity", user_arguments).get(),
        runner.getOptionalDoubleArgumentValue(prefix + nr.to_s + "_density", user_arguments).get(),
        runner.getOptionalDoubleArgumentValue(prefix + nr.to_s + "_heat_capacity", user_arguments).get()
      )

    else
      return Material.new(
        runner.getStringArgumentValue(prefix + nr.to_s + "_name", user_arguments),
        runner.getDoubleArgumentValue(prefix + nr.to_s + "_thickness", user_arguments),
        runner.getDoubleArgumentValue(prefix + nr.to_s + "_conductivity", user_arguments),
        runner.getDoubleArgumentValue(prefix + nr.to_s + "_density", user_arguments),
        runner.getDoubleArgumentValue(prefix + nr.to_s + "_heat_capacity", user_arguments)
      )
    end
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    return false unless runner.validateUserArguments(arguments(model), user_arguments)

    # create constructions from user inputs. each construction must consist of at least one
    # fully specified material layer.
    constructions = {}
    construction_names = {
      "external_wall" => "ExternalWallConstruction",
      "roof" => "RoofConstruction",
      "base_plate" => "SlabConstruction",
      "inner_masses" => "InteriorConstruction",
      "interior_slab" => "InteriorSlabConstruction",
    }

    construction_names.each{ |mat_prefix, constrName|
      mats = []
      for i in 1..MatLayerCount
        mat = getMaterialFromArguments(mat_prefix + "_", i, i > 1, runner, user_arguments)
        if not mat
          break
        end
        mats << mat
      end

      constructions[constrName] = CreateConstruction(model, constrName, mats)
      runner.registerInfo("#{constrName} was added.")
    }

    # windows construction requires different arguments and doesn't consist of layers
    constructions["WindowsConstruction"] = CreateWindowConstruction(
      model,
      "WindowsConstruction",
      runner.getStringArgumentValue("windows_name", user_arguments),
      runner.getDoubleArgumentValue("windows_u_value", user_arguments),
      runner.getDoubleArgumentValue("windows_shgc", user_arguments)
    )
    runner.registerInfo("WindowsConstruction was added.")

    # now add the constructions to surfaces, depending on the type of surface
    model.getSurfaces.each do |surface|
      surfaceType = surface.surfaceType.upcase
      if (surface.outsideBoundaryCondition == "Ground") && (surfaceType == "FLOOR")
        surface.setConstruction(constructions["SlabConstruction"])
      elsif (surface.outsideBoundaryCondition == "Outdoors") && (surfaceType == "WALL")
        surface.setConstruction(constructions["ExternalWallConstruction"])
      elsif (surface.outsideBoundaryCondition == "Outdoors") && (surfaceType == "ROOFCEILING")
        surface.setConstruction(constructions["RoofConstruction"])
      elsif surfaceType == "FLOOR"
        surface.setConstruction(constructions["InteriorSlabConstruction"])
      elsif surfaceType == "ROOFCEILING"
        surface.setConstruction(constructions["InteriorSlabConstruction"])
      else
        surface.setConstruction(constructions["InteriorConstruction"])
      end
      # iterate over the subsurfaces to assign the window construction
      surface.subSurfaces.each do |subSurface|
        subSurface.setConstruction(constructions["WindowsConstruction"])
      end
    end

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getSurfaces.size} surfaces that have constructions now.")

    return true
  end
end

# register the measure to be used by the application
AddMaterialsAndConstruction.new.registerWithApplication
