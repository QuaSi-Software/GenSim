# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2021, Alliance for Sustainable Energy, LLC.
# With modifications by: Tobias Maile
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# (1) Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# (2) Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# (3) Neither the name of the copyright holder nor the names of any contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission from the respective party.
#
# (4) Other than as required in clauses (1) and (2), distributions in any form
# of modifications or other derivative works may not use the "OpenStudio"
# trademark, "OS", "os", or any other confusingly similar designation without
# specific prior written permission from Alliance for Sustainable Energy, LLC.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER(S) AND ANY CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER(S), ANY CONTRIBUTORS, THE
# UNITED STATES GOVERNMENT, OR THE UNITED STATES DEPARTMENT OF ENERGY, NOR ANY OF
# THEIR EMPLOYEES, BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
# OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# *******************************************************************************

# see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

# see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

#start the measure
class BarAspectRatioStudy < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "Bar Aspect Ratio Study"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new
    
    #make an argument for total floor area
    floor_area = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("floor_area",true)
    floor_area.setDisplayName("Total Building Floor Area")
    floor_area.setUnits("m^2")
    args << floor_area

    #make an argument for building length
    building_length = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("building_length",true)
    building_length.setDisplayName("Length of North/South Facade")
    building_length.setDefaultValue(20.0)
    args << building_length

    #make an argument for building width
    building_width = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("building_width",true)
    building_width.setDisplayName("Width of East/West Facade")
    building_width.setDefaultValue(10.0)
    args << building_width

    #make an argument for number of floors
    number_of_stories = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("number_of_stories",true)
    number_of_stories.setDisplayName("Number of Floors.")
    number_of_stories.setDefaultValue(2)
    args << number_of_stories

    #make an argument for floor height
    floor_to_floor_height = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("floor_to_floor_height",true)
    floor_to_floor_height.setDisplayName("Floor to Floor Height")
    floor_to_floor_height.setUnits("m")
    floor_to_floor_height.setDefaultValue(3.3)
    args << floor_to_floor_height

    #make an argument to surface match
    surface_matching = OpenStudio::Ruleset::OSArgument::makeBoolArgument("surface_matching",true)
    surface_matching.setDisplayName("Surface Matching?")
    surface_matching.setDefaultValue(true)
    args << surface_matching

    #make an argument to create zones from spaces
    make_zones = OpenStudio::Ruleset::OSArgument::makeBoolArgument("make_zones",true)
    make_zones.setDisplayName("Make Thermal Zones from Spaces?")
    make_zones.setDefaultValue(true)
    args << make_zones
	
	#make an argument for wwr
    window_to_wall_ratio_north = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("window_to_wall_ratio_north",true)
    window_to_wall_ratio_north.setDisplayName("Window to Wall Ratio North")
    window_to_wall_ratio_north.setDefaultValue(0.3)
    args << window_to_wall_ratio_north
	
	#make an argument for wwr
    window_to_wall_ratio_east = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("window_to_wall_ratio_east",true)
    window_to_wall_ratio_east.setDisplayName("Window to Wall Ratio East")
    window_to_wall_ratio_east.setDefaultValue(0.3)
    args << window_to_wall_ratio_east
	
  	#make an argument for wwr
    window_to_wall_ratio_south = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("window_to_wall_ratio_south",true)
    window_to_wall_ratio_south.setDisplayName("Window to Wall Ratio South")
    window_to_wall_ratio_south.setDefaultValue(0.3)
    args << window_to_wall_ratio_south
	
	  #make an argument for wwr
    window_to_wall_ratio_west = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("window_to_wall_ratio_west",true)
    window_to_wall_ratio_west.setDisplayName("Window to Wall Ratio West")
    window_to_wall_ratio_west.setDefaultValue(0.3)
    args << window_to_wall_ratio_west
    
    #make an argument to create zones from spaces
    adiabaticN = OpenStudio::Ruleset::OSArgument::makeBoolArgument("AdiabaticNorth",false)
    adiabaticN.setDisplayName("Adiabatic north facade?")
    adiabaticN.setDefaultValue(false)
    args << adiabaticN
    
    #make an argument to create zones from spaces
    adiabaticE = OpenStudio::Ruleset::OSArgument::makeBoolArgument("AdiabaticEast",false)
    adiabaticE.setDisplayName("Adiabatic east facade?")
    adiabaticE.setDefaultValue(false)
    args << adiabaticE
    
    #make an argument to create zones from spaces
    adiabaticS = OpenStudio::Ruleset::OSArgument::makeBoolArgument("AdiabaticSouth",false)
    adiabaticS.setDisplayName("Adiabatic south facade?")
    adiabaticS.setDefaultValue(false)
    args << adiabaticS
    
    #make an argument to create zones from spaces
    adiabaticW = OpenStudio::Ruleset::OSArgument::makeBoolArgument("AdiabaticWest",false)
    adiabaticW.setDisplayName("Adiabatic west facade?")
    adiabaticW.setDefaultValue(false)
    args << adiabaticW
    
    #make an argument to create zones from spaces
    adiabaticR = OpenStudio::Ruleset::OSArgument::makeBoolArgument("AdiabaticRoof",false)
    adiabaticR.setDisplayName("Adiabatic roof?")
    adiabaticR.setDefaultValue(false)
    args << adiabaticR
    
    #make an argument to create zones from spaces
    adiabaticF = OpenStudio::Ruleset::OSArgument::makeBoolArgument("AdiabaticFloor",false)
    adiabaticF.setDisplayName("Adiabatic floor?")
    adiabaticF.setDefaultValue(false)
    args << adiabaticF

    #make an argument for depth of perimeter zone
    perimeterdepth = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("perimeterdepth",false)
    perimeterdepth.setDisplayName("Perimeter Depth")
    perimeterdepth.setDefaultValue(6)
    args << perimeterdepth

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    floor_area = runner.getDoubleArgumentValue("floor_area",user_arguments)
    building_length = runner.getDoubleArgumentValue("building_length",user_arguments)
    building_width = runner.getDoubleArgumentValue("building_width",user_arguments)
    number_of_stories = runner.getIntegerArgumentValue("number_of_stories",user_arguments)
    floor_to_floor_height = runner.getDoubleArgumentValue("floor_to_floor_height",user_arguments)
    surface_matching = runner.getBoolArgumentValue("surface_matching",user_arguments)
    make_zones = runner.getBoolArgumentValue("make_zones",user_arguments)
    window_to_wall_ratio_north = runner.getDoubleArgumentValue("window_to_wall_ratio_north",user_arguments)
    window_to_wall_ratio_east = runner.getDoubleArgumentValue("window_to_wall_ratio_east",user_arguments)
    window_to_wall_ratio_south = runner.getDoubleArgumentValue("window_to_wall_ratio_south",user_arguments)
    window_to_wall_ratio_west = runner.getDoubleArgumentValue("window_to_wall_ratio_west",user_arguments)
    adiabaticNorth = runner.getBoolArgumentValue("AdiabaticNorth",user_arguments)
    adiabaticEast = runner.getBoolArgumentValue("AdiabaticEast",user_arguments)
    adiabaticSouth = runner.getBoolArgumentValue("AdiabaticSouth",user_arguments)
    adiabaticWest = runner.getBoolArgumentValue("AdiabaticWest",user_arguments)
    adiabaticRoof = runner.getBoolArgumentValue("AdiabaticRoof",user_arguments)
    adiabaticFloor = runner.getBoolArgumentValue("AdiabaticFloor",user_arguments)
    perimeterdepth = runner.getDoubleArgumentValue("perimeterdepth",user_arguments)

    #test for positive inputs
    if not floor_area > 0
      runner.registerError("Enter a total building area greater than 0.")
    end
    if not building_length > 0
      runner.registerError("Enter a building length greater than 0.")
    end
    if not building_width > 0
      runner.registerError("Enter a building width greater than 0.")
    end
    if not number_of_stories > 0
      runner.registerError("Enter a number of stories 1 or greater.")
    end
    if not floor_to_floor_height > 0
      runner.registerError("Enter a positive floor height.")
    end

    #helper to make numbers pretty (converts 4125001.25641 to 4,125,001.26 or 4,125,001). The definition be called through this measure.
    def neat_numbers(number, roundto = 2) #round to 0 or 2)
      if roundto == 2
        number = sprintf "%.2f", number
      else
        number = number.round
      end
      #regex to add commas
      number.to_s.reverse.gsub(%r{([0-9]{3}(?=([0-9])))}, "\\1,").reverse
    end #end def neat_numbers

    #helper to make it easier to do unit conversions on the fly.  The definition be called through this measure.
    def unit_helper(number,from_unit_string,to_unit_string)
      converted_number = OpenStudio::convert(OpenStudio::Quantity.new(number, OpenStudio::createUnit(from_unit_string).get), OpenStudio::createUnit(to_unit_string).get).get.value
    end

    #determine if core and perimeter zoning can be used
    if building_length > 10 and building_width > 10
      perimeter_zone_depth = perimeterdepth #hard coded in meters
    else
      perimeter_zone_depth = 0 #if any size is to small then just model floor as single zone, issue warning
      runner.registerWarning("Due to the size of the building modeling each floor as a single zone.")
    end

    #Loop through the number of floors
    for floor in (0..number_of_stories-1)

      z = floor_to_floor_height * floor

      #Create a new story within the building
      story = OpenStudio::Model::BuildingStory.new(model)
      story.setNominalFloortoFloorHeight(floor_to_floor_height)
      story.setName("Story #{floor+1}")

      nw_point = OpenStudio::Point3d.new(0,building_width,z)
      ne_point = OpenStudio::Point3d.new(building_length,building_width,z)
      se_point = OpenStudio::Point3d.new(building_length,0,z)
      sw_point = OpenStudio::Point3d.new(0,0,z)

      # Identity matrix for setting space origins
      m = OpenStudio::Matrix.new(4,4,0)
      m[0,0] = 1
      m[1,1] = 1
      m[2,2] = 1
      m[3,3] = 1

      #Define polygons for a rectangular building
      if perimeter_zone_depth > 0
        perimeter_nw_point = nw_point + OpenStudio::Vector3d.new(perimeter_zone_depth,-perimeter_zone_depth,0)
        perimeter_ne_point = ne_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,-perimeter_zone_depth,0)
        perimeter_se_point = se_point + OpenStudio::Vector3d.new(-perimeter_zone_depth,perimeter_zone_depth,0)
        perimeter_sw_point = sw_point + OpenStudio::Vector3d.new(perimeter_zone_depth,perimeter_zone_depth,0)

        west_polygon = OpenStudio::Point3dVector.new
        west_polygon << sw_point
        west_polygon << nw_point
        west_polygon << perimeter_nw_point
        west_polygon << perimeter_sw_point
        west_space = OpenStudio::Model::Space::fromFloorPrint(west_polygon, floor_to_floor_height, model)
        west_space = west_space.get
        m[0,3] = sw_point.x
        m[1,3] = sw_point.y
        m[2,3] = sw_point.z
        west_space.changeTransformation(OpenStudio::Transformation.new(m))
        west_space.setBuildingStory(story)
        west_space.setName("Story #{floor+1} West Perimeter Space")

        north_polygon = OpenStudio::Point3dVector.new
        north_polygon << nw_point
        north_polygon << ne_point
        north_polygon << perimeter_ne_point
        north_polygon << perimeter_nw_point
        north_space = OpenStudio::Model::Space::fromFloorPrint(north_polygon, floor_to_floor_height, model)
        north_space = north_space.get
        m[0,3] = perimeter_nw_point.x
        m[1,3] = perimeter_nw_point.y
        m[2,3] = perimeter_nw_point.z
        north_space.changeTransformation(OpenStudio::Transformation.new(m))
        north_space.setBuildingStory(story)
        north_space.setName("Story #{floor+1} North Perimeter Space")

        east_polygon = OpenStudio::Point3dVector.new
        east_polygon << ne_point
        east_polygon << se_point
        east_polygon << perimeter_se_point
        east_polygon << perimeter_ne_point
        east_space = OpenStudio::Model::Space::fromFloorPrint(east_polygon, floor_to_floor_height, model)
        east_space = east_space.get
        m[0,3] = perimeter_se_point.x
        m[1,3] = perimeter_se_point.y
        m[2,3] = perimeter_se_point.z
        east_space.changeTransformation(OpenStudio::Transformation.new(m))
        east_space.setBuildingStory(story)
        east_space.setName("Story #{floor+1} East Perimeter Space")

        south_polygon = OpenStudio::Point3dVector.new
        south_polygon << se_point
        south_polygon << sw_point
        south_polygon << perimeter_sw_point
        south_polygon << perimeter_se_point
        south_space = OpenStudio::Model::Space::fromFloorPrint(south_polygon, floor_to_floor_height, model)
        south_space = south_space.get
        m[0,3] = sw_point.x
        m[1,3] = sw_point.y
        m[2,3] = sw_point.z
        south_space.changeTransformation(OpenStudio::Transformation.new(m))
        south_space.setBuildingStory(story)
        south_space.setName("Story #{floor+1} South Perimeter Space")

        core_polygon = OpenStudio::Point3dVector.new
        core_polygon << perimeter_sw_point
        core_polygon << perimeter_nw_point
        core_polygon << perimeter_ne_point
        core_polygon << perimeter_se_point
        core_space = OpenStudio::Model::Space::fromFloorPrint(core_polygon, floor_to_floor_height, model)
        core_space = core_space.get
        m[0,3] = perimeter_sw_point.x
        m[1,3] = perimeter_sw_point.y
        m[2,3] = perimeter_sw_point.z
        core_space.changeTransformation(OpenStudio::Transformation.new(m))
        core_space.setBuildingStory(story)
        core_space.setName("Story #{floor+1} Core Space")

        # Minimal zones
      else
        core_polygon = OpenStudio::Point3dVector.new
        core_polygon << sw_point
        core_polygon << nw_point
        core_polygon << ne_point
        core_polygon << se_point
        core_space = OpenStudio::Model::Space::fromFloorPrint(core_polygon, floor_to_floor_height, model)
        core_space = core_space.get
        m[0,3] = sw_point.x
        m[1,3] = sw_point.y
        m[2,3] = sw_point.z
        core_space.changeTransformation(OpenStudio::Transformation.new(m))
        core_space.setBuildingStory(story)
        core_space.setName("Story #{floor+1} Core Space")

      end

      #Set vertical story position
      story.setNominalZCoordinate(z)

    end #End of floor loop

    #put all of the spaces in the model into a vector
    spaces = OpenStudio::Model::SpaceVector.new
    model.getSpaces.each do |space|
      spaces << space
      if make_zones
        #create zones
        new_zone = OpenStudio::Model::ThermalZone.new(model)
        space.setThermalZone(new_zone)
        zone_name = space.name.get.gsub("Space","Zone")
        new_zone.setName(zone_name)
      end
    end

    if surface_matching
      #match surfaces for each space in the vector
      OpenStudio::Model.matchSurfaces(spaces)
    end
	
	#loop through surfaces finding exterior walls with proper orientation
  surfaces = model.getSurfaces
  surfaces.each do |s|
    if s.surfaceType == "RoofCeiling" and s.outsideBoundaryCondition == "Outdoors" and adiabaticRoof
      s.setOutsideBoundaryCondition("Adiabatic")
    elsif s.surfaceType == "Floor" and s.outsideBoundaryCondition == "Outdoors" and adiabaticFloor
      s.setOutsideBoundaryCondition("Adiabatic")
	elsif s.surfaceType == "Floor" and s.outsideBoundaryCondition == "Ground" and adiabaticFloor
      s.setOutsideBoundaryCondition("Adiabatic")
    end
    
    next if not s.surfaceType == "Wall"
    next if not s.outsideBoundaryCondition == "Outdoors"
    if s.space.empty?
      runner.registerWarning("#{s.name} doesn't have a parent space and won't be included in the measure reporting or modifications.")
      next
    end

      # get the absoluteAzimuth for the surface so we can categorize it
      absoluteAzimuth =  OpenStudio::convert(s.azimuth,"rad","deg").get + s.space.get.directionofRelativeNorth + model.getBuilding.northAxis
      until absoluteAzimuth < 360.0
        absoluteAzimuth = absoluteAzimuth - 360.0
      end

      #if facade == "North"
      if (absoluteAzimuth >= 315.0 or absoluteAzimuth < 45.0)
        if(adiabaticNorth)
          s.setOutsideBoundaryCondition("Adiabatic")
			    s.setWindowToWallRatio(0.0)
			  else
			    s.setWindowToWallRatio(window_to_wall_ratio_north)
			  end
      #elsif facade == "East"
      elsif (absoluteAzimuth >= 45.0 and absoluteAzimuth < 135.0)
			 if(adiabaticEast)
          s.setOutsideBoundaryCondition("Adiabatic")
          s.setWindowToWallRatio(0.0)
        else
          s.setWindowToWallRatio(window_to_wall_ratio_east)
        end
      #elsif facade == "South"
      elsif (absoluteAzimuth >= 135.0 and absoluteAzimuth < 225.0)
			 if(adiabaticSouth)
          s.setOutsideBoundaryCondition("Adiabatic")
          s.setWindowToWallRatio(0.0)
        else
          s.setWindowToWallRatio(window_to_wall_ratio_south)
        end
      #elsif facade == "West"
      elsif (absoluteAzimuth >= 225.0 and absoluteAzimuth < 315.0)
			 if(adiabaticWest)
          s.setOutsideBoundaryCondition("Adiabatic")
          s.setWindowToWallRatio(0.0)
        else
          s.setWindowToWallRatio(window_to_wall_ratio_west)
        end
      end
	end

    #reporting final condition of model
    finishing_spaces = model.getSpaces
    runner.registerFinalCondition("The building finished with #{finishing_spaces.size} spaces.")
    
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
BarAspectRatioStudy.new.registerWithApplication