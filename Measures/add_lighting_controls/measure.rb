# *******************************************************************************
# OpenStudio(R), Copyright (c) 2008-2020, Alliance for Sustainable Energy, LLC.
# With modifications by: Matthias Stickel
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

# start the measure
class AddLightingControls < OpenStudio::Measure::ModelMeasure

  # human readable name
  def name
    return "AddLightingControls"
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

    #make an argument for setpoint
    setpoint = OpenStudio::Measure::OSArgument::makeDoubleArgument("daylighting_setpoint", true)
    setpoint.setDisplayName("Daylighting Setpoint (lux)")
    setpoint.setDefaultValue(500)
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

    # ===== assign the user inputs to variables
    setpoint = runner.getDoubleArgumentValue("daylighting_setpoint", user_arguments)

    # ===== check the setpoint for reasonableness
    if setpoint < 0 or setpoint > 9999
      runner.registerError("A setpoint of #{setpoint} lux is outside the measure limit.")
      return false
    elsif setpoint > 2000
      runner.registerWarning("A setpoint of #{setpoint} lux is abnormally high.")
    end

    # ===== variables for logging
    area = 0 #variable to tally the area to which the overall measure is applied
    sensor_count = 0 #variable to aggregate the number of sensors installed
    sensor_area = 0 #variable to aggregate the area affected of new sensors

    affected_zones = []
    affected_zone_names = []
    #hash to hold sensor objects
    new_sensor_objects = {}

    # ===== reporting initial condition of model
    spaces = model.getSpaces
    runner.registerInitialCondition("#{spaces.size} spaces without lighting control")

    # ===== loop through all spaces and add a daylighting sensor with dimming to each
    spaces.each do |space|
      area += space.floorArea
      #-----
      #ELIMINATE spaces that don't have exterior natural lighting
      has_ext_nat_light = false
      space.surfaces.each do |surface|
        next if not surface.outsideBoundaryCondition == "Outdoors"
        surface.subSurfaces.each do |sub_surface|
          next if sub_surface.subSurfaceType == "Door"
          next if sub_surface.subSurfaceType == "OverheadDoor"
          has_ext_nat_light = true
        end
      end
      if has_ext_nat_light == false
        runner.registerWarning("Space '#{space.name}' has no exterior natural lighting. No sensor will be added.")
        next
      end
      #FIND floors
      floors = []
      space.surfaces.each do |surface|
        next if not surface.surfaceType == "Floor"
        floors << surface
      end
      #THIS method only works for flat (non-inclined) floors
      boundingBox = OpenStudio::BoundingBox.new
      floors.each do |floor|
        boundingBox.addPoints(floor.vertices)
      end
      xmin = boundingBox.minX.get
      ymin = boundingBox.minY.get
      zmin = boundingBox.minZ.get
      xmax = boundingBox.maxX.get
      ymax = boundingBox.maxY.get
      #CREATE a new sensor and put at the center of the space
      sensor = OpenStudio::Model::DaylightingControl.new(model)
      sensor.setName("#{space.name} daylighting control")
      x_pos = (xmin + xmax) / 2
      y_pos = (ymin + ymax) / 2
      z_pos = zmin + 0.76 #put it 76 cm above the floor
      new_point = OpenStudio::Point3d.new(x_pos, y_pos, z_pos)
      sensor.setPosition(new_point)
      sensor.setIlluminanceSetpoint(setpoint)
      sensor.setLightingControlType("Stepped")
      sensor.setNumberofSteppedControlSteps(1)
      sensor.setSpace(space)
      puts sensor

      #-----
      #PUSH unique zones to array for use later in measure
      temp_zone = space.thermalZone.get
      if affected_zone_names.include?(temp_zone.name.to_s) == false
        affected_zones << temp_zone
        affected_zone_names << temp_zone.name.to_s
      end

      #PUSH sensor object into hash with space name
      new_sensor_objects[space.name.to_s] = sensor

      #ADD floor area to the daylighting area tally
      sensor_area += space.floorArea
      #ADD to sensor count for reporting
      sensor_count += 1
    end #end spaces.each do

    if sensor_count == 0
      runner.registerAsNotApplicable("No spaces became new lighting sensors.")
      return true
    end

    ##########
    #loop through THERMAL ZONES for spaces with daylighting controls added

    affected_zones.each do |zone|
      zone_spaces = zone.spaces
      zone_spaces_with_new_sensors = []
      zone_spaces.each do |zone_space|
        if not zone_space.daylightingControls.empty?
          zone_spaces_with_new_sensors << zone_space
        end
      end

      if not zone_spaces_with_new_sensors.empty?
        #need to identify the two largest spaces
        primary_area = 0
        secondary_area = 0
        primary_space = nil
        secondary_space = nil
        three_or_more_sensors = false

        # dfg temp - need to add another if statement so only get spaces with sensors
        zone_spaces_with_new_sensors.each do |zone_space|
          zone_space_area = zone_space.floorArea
          if zone_space_area > primary_area
            primary_area = zone_space_area
            primary_space = zone_space
          elsif zone_space_area > secondary_area
            secondary_area = zone_space_area
            secondary_space = zone_space
          else
            #setup flag to warn user that more than 2 sensors can't be added to a space
            three_or_more_sensors = true
          end
        end

        if primary_space
          #setup primary sensor
          sensor_primary = new_sensor_objects[primary_space.name.to_s]
          zone.setPrimaryDaylightingControl(sensor_primary)
          zone.setFractionofZoneControlledbyPrimaryDaylightingControl(primary_area / (primary_area + secondary_area))
        end

        if secondary_space
          #setup secondary sensor
          sensor_secondary = new_sensor_objects[secondary_space.name.to_s]
          zone.setSecondaryDaylightingControl(sensor_secondary)
          zone.setFractionofZoneControlledbySecondaryDaylightingControl(secondary_area / (primary_area + secondary_area))
        end

        #warn that additional sensors were not used
        if three_or_more_sensors == true
          runner.registerWarning("Thermal zone '#{zone.name}' had more than two spaces with sensors. Only two sensors were associated with the thermal zone.")
        end
      end #end if not zone_spaces.empty?
    end #end affected_zones.each do

    runner.registerInfo("#{area} square meters total area to which the overall daylighting control measure is applied")
    runner.registerFinalCondition("#{sensor_count} sensors added on a total effected sensor area of #{sensor_area} square meters")
    return true
  end
end

# register the measure to be used by the application
AddLightingControls.new.registerWithApplication
