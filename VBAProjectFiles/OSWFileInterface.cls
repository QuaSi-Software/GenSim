VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "OSWFileInterface"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' This class is intended to provide an interface for writing parameters to an
' OSW file or reading them from one. The import/export is not a simple 1-to-1
' match of ranges and values, thus the macros might take some time and needs
' to write to the spreadsheet.
'
' The connections are unfortunately hardcoded, so every change in the spread-
' sheet needs to be also changed in this file, otherwise the parameters are
' not exported/imported correctly.


' Exports the parameters in the spreadsheet to a OWS file. The arguments are
' flags that control what is used in the simulation and what isn't.
' Note that this method prepares the OSW file for later use in an OpenStudio
' simulation and not for sharing/saving parameter configurations.
'
' @param sFilename String ByRef The filename of the exported file. Ths file
'     is automatically written to the output folder, so the filename should
'     only contain subdirectories of the output folder.
' @param bDoCustomExport Boolean ByVal If true, adds some parameters that are
'     not required (or expected) for a simulation run, but are useful for
'     saving a parameter configuration as a seperate file
' @param bPVSim Boolean ByVal If the PV simulation should run or not
' @param bBuildingSim Boolean ByVal If the building simulation should run or not
' @param bGeneric Boolean ByVal If a generic building model should be used or
'     instead an existing model be imported
Sub ExportToOSW( _
    ByVal sFilename As String, _
    ByVal bDoCustomExport As Boolean, _
    ByVal bPVSim As Boolean, _
    ByVal bBuildingSim As Boolean, _
    ByVal bGeneric As Boolean, _
    ByVal bDetailedHVAC As Boolean _
)
    Dim dd1 As DropDown 'Wetterdaten
    Set dd1 = Sheets("HAUPTSEITE").DropDowns("DropDown1")
    Dim dd2 As DropDown 'Orientierung
    Set dd2 = Sheets("HAUPTSEITE").DropDowns("Dropdown2")
    Dim dd21 As DropDown 'Gebäudestandard
    Set dd21 = Sheets("HAUPTSEITE").DropDowns("Dropdown21")
    Dim dd22 As DropDown 'innere Massen
    Set dd22 = Sheets("HAUPTSEITE").DropDowns("Dropdown22")
    Dim dd23 As DropDown 'Elektrische Geräte
    Set dd23 = Sheets("HAUPTSEITE").DropDowns("Dropdown23")
    Dim ddRatio1 As DropDown 'Verhältnis NRF/BGF
    Set ddRatio1 = Sheets("HAUPTSEITE").DropDowns("Dropdown_NRF_BGF")
    Dim ddRatio2 As DropDown 'Verhältnis NRF/BGF Importiert
    Set ddRatio2 = Sheets("HAUPTSEITE").DropDowns("Dropdown_NRF_BGF_Import")
    Dim dd42 As DropDown 'Adiabat Nord
    Set dd42 = Sheets("HAUPTSEITE").DropDowns("dropdown_adiabat_n")
    Dim dd43 As DropDown 'Adiabat Ost
    Set dd43 = Sheets("HAUPTSEITE").DropDowns("dropdown_adiabat_o")
    Dim dd44 As DropDown 'Adiabat SÃ¼d
    Set dd44 = Sheets("HAUPTSEITE").DropDowns("dropdown_adiabat_s")
    Dim dd45 As DropDown 'Adiabat West
    Set dd45 = Sheets("HAUPTSEITE").DropDowns("dropdown_adiabat_w")
    Dim dd46 As DropDown 'Adiabat Dach
    Set dd46 = Sheets("HAUPTSEITE").DropDowns("dropdown_adiabat_d")
    Dim dd47 As DropDown 'Adiabat Bodenplatte
    Set dd47 = Sheets("HAUPTSEITE").DropDowns("dropdown_adiabat_b")
    Dim dd49 As DropDown 'Beleuchtung
    Set dd49 = Sheets("HAUPTSEITE").DropDowns("Dropdown49")
    Dim dd50 As DropDown 'Personen Anwesenheit
    Set dd50 = Sheets("HAUPTSEITE").DropDowns("Dropdown50")
    Dim dd51 As DropDown 'Personen Aktivität
    Set dd51 = Sheets("HAUPTSEITE").DropDowns("Dropdown51")
    Dim dd55 As DropDown 'Betriebszeiten Lüftung
    Set dd55 = Sheets("HAUPTSEITE").DropDowns("Dropdown55")
    Dim dd_lueftung As DropDown 'Lüftungsanlage Typ
    Set dd_lueftung = Sheets("HAUPTSEITE").DropDowns("dd_lueftung")

    Dim cb_windowvent As CheckBox
    Set cb_windowvent = Sheets("HAUPTSEITE").CheckBoxes("Checkbox_windowvent")
    Dim cb_inf As CheckBox
    Set cb_inf = Sheets("HAUPTSEITE").CheckBoxes("checkbox_inf")
    Dim cb_lightingcontrol As CheckBox
    Set cb_lightingcontrol = Sheets("HAUPTSEITE").CheckBoxes("checkbox lightingcontrol")
    Dim cb_shadingcontrol As CheckBox
    Set cb_shadingcontrol = Sheets("HAUPTSEITE").CheckBoxes("checkbox_shadingcontrol")
    Dim cb_buildingSim As CheckBox
    Set cb_buildingSim = Sheets("HAUPTSEITE").CheckBoxes("checkbox_buildingsim")
    Dim cb_pvSim As CheckBox
    Set cb_pvSim = Sheets("HAUPTSEITE").CheckBoxes("checkbox_pvsim")
    Dim cb_zoneDetails As CheckBox
    Set cb_zoneDetails = Sheets("Parameter").CheckBoxes("checkbox_ZoneDetails")
    Dim cb_detailedHVAC As CheckBox
    Set cb_detailedHVAC = Sheets("Parameter").CheckBoxes("checkbox_hvac")
    
    Dim dd60 As DropDown 'Solltemp Heizung
    Set dd60 = Sheets("HAUPTSEITE").DropDowns("Dropdown60")
    Dim dd86 As DropDown 'Solltemp Kühlung
    Set dd86 = Sheets("HAUPTSEITE").DropDowns("Dropdown86")
    Dim dd_timestep As DropDown
    Set dd_timestep = Sheets("Hauptseite").DropDowns("dropdown_timestep")
    Dim Timestep As Double
    Dim Timestep_s As String
    Timestep = 60 / dd_timestep.List(dd_timestep.Value)
    Timestep_s = Timestep

    Dim jFile As New JSONFile

    If bBuildingSim And Not bGeneric Then
        ' only if we have an import and geometry sim selected we import the external OSM file
        ' copy the imported osm file into the currrent folder and replace any umlaut
        Dim fso As New FileSystemObject
        Dim sOSMFileName As String
        Dim sOSMPathName As String
        sOSMPathName = Range("path_geometry_Import")
        sOSMFileName = fso.GetFileName(sOSMPathName)
        sOSMFileName = Replace(sOSMFileName, Chr(228), "ae")
        sOSMFileName = Replace(sOSMFileName, Chr(252), "ue")
        sOSMFileName = Replace(sOSMFileName, Chr(246), "oe")
        sOSMFileName = Replace(sOSMFileName, Chr(196), "Ae")
        sOSMFileName = Replace(sOSMFileName, Chr(220), "Ue")
        sOSMFileName = Replace(sOSMFileName, Chr(214), "Oe")
        
        If Not (bDoCustomExport) Then
            Dim localOSMPath As String
            localOSMPath = GetOutputFolder() + "\" + sOSMFileName
            FileCopy sOSMPathName, localOSMPath
        End If
        jFile.CreateFile localOSMPath, GetWeatherFolder() & "\" & dd1.List(dd1.Value)
        
        jFile.AddArgument "WeatherFilePath", GetWeatherFolder() & "\" & dd1.List(dd1.Value)
        jFile.AddArgument "Timestep", Timestep_s
        jFile.AddMeasure "SetWeatherAxisTimestep"
    Else
        jFile.CreateFile Range("FileName") + ".osm", GetWeatherFolder() & "\" & dd1.List(dd1.Value)
        ' first we create an empty model with the empty model measure
        jFile.AddMeasure "CreateAnEmptyModel"

        jFile.AddArgument "WeatherFilePath", GetWeatherFolder() & "\" & dd1.List(dd1.Value)
        jFile.AddArgument "NorthAxis", dd2.List(dd2.Value)
        jFile.AddArgument "Timestep", Timestep_s
        jFile.AddMeasure "SetWeatherAxisTimestep"
    End If
    
    '--------Alle zusätzlichen Parameter für den 'CustomExport'
    If (bDoCustomExport) Then
    
        'Parameter Modell
        jFile.AddArgument "buildingSim", IIf(cb_buildingSim.Value = 1, 1, 0)
        jFile.AddArgument "pvSim", IIf(cb_pvSim.Value = 1, 1, 0)
        jFile.AddArgument "zoneDetails", IIf(cb_zoneDetails.Value = 1, 1, 0)
        jFile.AddArgument "detailedHVAC", IIf(cb_detailedHVAC.Value = 1, 1, 0)
        jFile.AddArgument "ventilation_type", dd_lueftung.Value
        
        'Parameter Geometrie, die nicht für Modellerzeugung benötigt werden
        jFile.AddArgument "floor_length", Range("LAENGE")
        jFile.AddArgument "floor_width", Range("BREITE")
        jFile.AddArgument "ratio_NRF_BGF", ddRatio1.List(ddRatio1.Value)
        jFile.AddArgument "NRF_BGF", Range("BGF_zu_NRF")
        
        ' Arguments "selected_standard", "is_custom_standard", "selected_masses" are added in Measure "AddingMaterialsAndConstructions"
        ' weitere Argumente are added in Measure "AddingInternalLoads"
        ' Arguments "hvacSchedule", "is_custom_hvac" are added in "AddDetailedHVAC" bzw. "AddingIdealAirLoads" (je nach cb_hvac)
        
        '  Nutzung - Feiertage
        Dim strArg As String
        strArg = ""
        Dim iEntry As Integer
        iEntry = 0
            
        Do While Not (IsEmpty(Sheets("EIGENE NUTZUNGSPROFILE").Range("feiertage").Offset(iEntry, 0)))
            strArg = strArg + CStr(Sheets("EIGENE NUTZUNGSPROFILE").Range("feiertage").Offset(iEntry, 0))
            strArg = strArg + ";" + CStr(Sheets("EIGENE NUTZUNGSPROFILE").Range("feiertage").Offset(iEntry, 1)) + ";"
            iEntry = iEntry + 1
        Loop
        jFile.AddArgument "Holidays", strArg

        
        'Lüftungsanlage
        jFile.AddArgument "vorlauf_Luft", Range("Vorlauf_Lüftung")
        jFile.AddArgument "nachlauf_Luft", Range("Nachlauf_Lüftung")
        
        'Weiteres
        jFile.AddArgument "Shadingcontrol", IIf(cb_shadingcontrol.Value = 1, 1, 0)
        jFile.AddArgument "Infiltration", IIf(cb_inf.Value = 1, 1, 0)
        jFile.AddArgument "Lightingcontrol", IIf(cb_lightingcontrol.Value = 1, 1, 0)
        jFile.AddArgument "Windowvent", IIf(cb_windowvent.Value = 1, 1, 0)
        
        'Geometrie
        If bGeneric Then
            jFile.AddArgument "genGeom", 1      'Range("geometry_source")
        Else
            jFile.AddArgument "genGeom", 2
        End If
                
        'Lüftung (neue Parameter "konditionierte Raumhöhe" und "Geschosshöhe Geometrieimport"
        jFile.AddArgument "FloorHeight_kond", Range("FloorHeight_kond")
        jFile.AddArgument "FloorHeight_import", Range("FloorHeight_import")
        jFile.AddArgument "ACH_Input_Parameter", Range("ACH")
        
        jFile.AddMeasure "CustomExportParams"

    End If

    ''''''''''''''''''''''''''''''' Building Model
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

    If Not bBuildingSim Then
        DeactivateStatusInfoForPVOnlyRun
    Else
        Range("GeomStatus") = "Start ..."

        ''''''''''''''''''''''''''''''' Geometry
        '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

        If bGeneric Then
            jFile.AddArgument "floor_area", Range("BldgArea")
            jFile.AddArgument "ns_to_ew_ratio", Range("NSEWRatio")
            jFile.AddArgument "number_of_stories", Range("NoFloors")
            jFile.AddArgument "floor_to_floor_height", Range("FloorHeight")
            jFile.AddArgument "surface_matching", "true"
            jFile.AddArgument "make_zones", "true"
            jFile.AddArgument "window_to_wall_ratio_north", Range("WWRN")
            jFile.AddArgument "window_to_wall_ratio_east", Range("WWRO")
            jFile.AddArgument "window_to_wall_ratio_south", Range("WWRS")
            jFile.AddArgument "window_to_wall_ratio_west", Range("WWRW")
            jFile.AddArgument "AdiabaticNorth", dd42.List(dd42.Value)
            jFile.AddArgument "AdiabaticEast", dd43.List(dd43.Value)
            jFile.AddArgument "AdiabaticSouth", dd44.List(dd44.Value)
            jFile.AddArgument "AdiabaticWest", dd45.List(dd45.Value)
            jFile.AddArgument "AdiabaticRoof", dd46.List(dd46.Value)
            jFile.AddArgument "AdiabaticFloor", dd47.List(dd47.Value)
            jFile.AddArgument "perimeterdepth", Range("PerimeterDepth")

            jFile.AddMeasure "BarAspectRatioStudy"
        End If
        ' update status
        Range("GeomStatus") = "Definiert"
        DoEvents

        ''''''''''''''''''''''''''''''' Assign Constructions
        '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

        If Not bBuildingSim Then
            Range("UStatus") = "Deaktiviert"
        Else
            Range("UStatus") = "Start ..."
            jFile.AddConstruction "ExternalWallMat", Range("AWMat1"), 4
            jFile.AddConstruction "RoofMat", Range("DMat1"), 4
            jFile.AddConstruction "SlabMat", Range("BPMat1"), 4
            jFile.AddConstruction "Massen", Range("Massen"), 3
            jFile.AddConstruction "InteriorSlabs", Range("ZwischenDecke"), 4
            jFile.AddInternalSourceConstructionHardcoded "ChilledCeiling", 2, 2, 2, 0.15, Range("ZwischenDecke"), 2
            jFile.AddWindowConstruction "Windows", Range("WINDOWSSLS"), Range("WINDOWSSLS").Offset(0, -1), Range("WINDOWSSLS").Offset(0, 1)

            If (bDoCustomExport) Then
                jFile.AddArgument "selected_standard", dd21.List(dd21.Value)
                jFile.AddArgument "is_custom_standard", IIf(dd21.Value > (dd21.ListCount - 4), "Ja", "Nein")
                jFile.AddArgument "selected_masses", dd22.List(dd22.Value)
            End If

            jFile.AddMeasure "AddingMaterialsAndConstructions"
            Range("UStatus") = "Definiert"
        End If
        DoEvents

        ''''''''''''''''''''''''''''''' Adding Thermal Zones and Detecting External Zones
        '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

        If bBuildingSim Then

            If Not bGeneric Then jFile.AddMeasure "AddThermalZones"

            jFile.AddMeasure "DetectingExternalZones"

        End If

        ''''''''''''''''''''''''''''''' internal load measure (schedules)
        '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

        If Not bBuildingSim Then
            Range("LoadStatus") = "Deaktiviert"
        Else

            Range("LoadStatus") = "Start ..."

            Dim nrf_bgf As Double
            Dim isCustom As Boolean
            Dim selected As String

            If bGeneric Then
                nrf_bgf = Range("BGF_zu_NRF")
                isCustom = ddRatio1.Value = 1
                selected = ddRatio1.List(ddRatio1.Value)
            Else
                nrf_bgf = Range("BGF_zu_NRF_import")
                isCustom = ddRatio2.Value = 1
                selected = ddRatio2.List(ddRatio2.Value)
            End If

            jFile.AddArgument "ElectricEquipmentPowerPerFloorArea", Range("Electric") * nrf_bgf
            jFile.AddArgument "LightingPowerPerFloorArea", Range("Lights") * nrf_bgf
            jFile.AddArgument "PeoplePerFloorArea", 1 / Range("People") * nrf_bgf
            jFile.AddSchedule "ElectricEquipmentSchedule", Range("ElectricWD")
            jFile.AddSchedule "LightSchedule", Range("LightWD")
            jFile.AddSchedule "PeopleSchedule", Range("PeopleWD")
            jFile.AddSchedule "PeopleActivitySchedule", Range("PeopleActivityWD")
            jFile.AddHolidays "Holidays", Range("Feiertage")
            
            If (bDoCustomExport) Then
                jFile.AddArgument "area_bgf_import", Range("BldgArea_import")
                jFile.AddArgument "NRF/BGF", CStr(nrf_bgf)
                jFile.AddArgument "selected_ratio", selected
                jFile.AddArgument "is_custom_ratio", IIf(isCustom, "true", "false")
                jFile.AddArgument "is_imported", IIf(bGeneric, "false", "true")
                jFile.AddArgument "ElectricEquipmentSchedule", dd23.List(dd23.Value)
                jFile.AddArgument "LightSchedule", dd49.List(dd49.Value)
                jFile.AddArgument "PeopleSchedule", dd50.List(dd50.Value)
                jFile.AddArgument "PeopleActivitySchedule", dd51.List(dd51.Value)
                jFile.AddArgument "is_custom_ElectricEquipment", IIf(dd23.Value > (dd23.ListCount - 2), "true", "false")
                jFile.AddArgument "is_custom_Light", IIf(dd49.Value > (dd49.ListCount - 2), "true", "false")
                jFile.AddArgument "is_custom_People", IIf(dd50.Value > (dd50.ListCount - 2), "true", "false")
                jFile.AddArgument "is_custom_PeopleActivity", IIf(dd51.Value > (dd51.ListCount - 2), "true", "false")
            End If

            jFile.AddMeasure "AddingInternalLoads"
            Range("LoadStatus") = "Definiert"
        End If
        DoEvents

        '''''''''''''''' Calling Ideal loads measure
        '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

        If Not bBuildingSim Then
            Range("IdealLoads") = "Deaktiviert"
        Else

            Range("IdealLoads") = "Start ..."
                              
            ' Pressure Rise
            If Range("WRG") = "None" Then
                PressureRise_ReturnFan = 750 ' Update 10.01.22 -> neue Norm DIN EN 16798-3 - SFP2
                PressureRise_SupplyFan = 750 ' Update 10.01.22 -> neue Norm DIN EN 16798-3 - SFP2
            Else
                PressureRise_ReturnFan = 750 ' Update 10.01.22 -> neue Norm DIN EN 16798-3 - SFP2
                PressureRise_SupplyFan = 750 ' Update 10.01.22 -> neue Norm DIN EN 16798-3 - SFP2
            End If
                      
            'Korrektur der zu hohen Luftwechselrate, weil das konditionierte Raumvolumen um die Zwischendecken-Dicke zu groß ist
            If Range("geometry_source") = 1 Then
                FloorHeight_Ratio = Range("FloorHeight_kond") / Range("FloorHeight")
            Else
                FloorHeight_Ratio = Range("FloorHeight_kond") / Range("FloorHeight_import")
            End If
            
            ' common arguments
            jFile.AddArgument "wrg", Range("WRG")
            jFile.AddArgument "latent", Range("LATENT")
            jFile.AddArgument "sensible", Range("SENSIBLE")
            jFile.AddArgument "ach", Range("ACH") * FloorHeight_Ratio * nrf_bgf 'Bugfix 01/22 : Korrektur kond. Raumhöhe sowie Korrektur NRF/BGF
            jFile.AddSchedule "hvacSched", Range("HVACWD")
            jFile.AddHolidays "Holidays", Range("Feiertage")
            If (bDoCustomExport) Then
               jFile.AddArgument "hvacSchedule", dd55.List(dd55.Value)
               jFile.AddArgument "is_custom_hvac", IIf(dd55.Value > (dd55.ListCount - 2), "true", "false")
            End If
            
            If bDetailedHVAC Then
                jFile.AddSchedule "zoneHeatingTempSched", Range("HeatingWD")
                jFile.AddSchedule "zoneCoolingTempSched", Range("CoolingWD")
                jFile.AddArgument "hotWaterTempSetpoint", 82
                jFile.AddArgument "hotWaterDeltaT", 11
                jFile.AddArgument "coldWaterTempSetpoint", 10
                jFile.AddArgument "coldWaterDeltaT", 5
                jFile.AddArgument "fanPressureRiseSupply", CStr(PressureRise_SupplyFan)
                jFile.AddArgument "fanPressureRiseReturn", CStr(PressureRise_ReturnFan)
                jFile.AddArgument "system_type", Range("system_type")

                jFile.AddMeasure "AddDetailedHVAC"
            Else
                jFile.AddMeasure "AddingIdealAirLoads"
            End If
            
            Range("IdealLoads") = "Definiert"
        End If
        DoEvents

        '''''''''''''''' Calling Shading Control measure
        '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

        If Not bBuildingSim Or Not cb_shadingcontrol.Value = 1 Then
            Range("ShadingControl") = "Deaktiviert"
        Else
            Range("ShadingControl") = "Start ..."
            jFile.AddArgument "SolarSetpoint", Range("SHCO_IRR")
            jFile.AddMeasure "AddingShadingControls"
            Range("ShadingControl") = "Definiert"
        End If
        DoEvents

        '''''''''''''''' Calling infiltration measure
        '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

        If Not bBuildingSim Or Not cb_inf.Value = 1 Then
            Range("Infiltration") = "Deaktiviert"
        Else
            Range("Infiltration") = "Start ..."
            jFile.AddArgument "AirChangesPerHour", Range("INFIL") * FloorHeight_Ratio * nrf_bgf
            jFile.AddMeasure "AddingInfiltration"
            Range("Infiltration") = "Definiert"
        End If
        DoEvents

        '''''''''''''''' Calling lighting control measure
        '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

        If Not bBuildingSim Or Not cb_lightingcontrol.Value = 1 Then
            Range("LightingControl") = "Deaktiviert"
        Else
            Range("LightingControl") = "Start ..."
            jFile.AddArgument "DaylightingSetpoint", Range("LC_LUX")
            jFile.AddMeasure "AddingLightingControls"
            Range("LightingControl") = "Definiert"
        End If

        '''''''''''''''' Calling Setpoint Measure loads measure
        '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

        If Not bBuildingSim Then
            Range("TempSetpoint") = "Deaktiviert"
        Else
            If (bDoCustomExport) Then
                jFile.AddArgument "heatingTemp", dd60.List(dd60.Value)
                jFile.AddArgument "coolingTemp", dd86.List(dd86.Value)
                jFile.AddArgument "is_custom_heating", IIf(dd60.Value > 3, "true", "false")  ' da bisher nur drei feste Profile zur Auswahl stehen
                jFile.AddArgument "is_custom_cooling", IIf(dd86.Value > 3, "true", "false")
            End If
' _  DEBUGGING
' _  SCHED durch SCHEDULE ersetzt, da beim 'ImportSchedule' abgefragt wird: scheduleName = "hvac" und entsprechend SCHEDULE und nicht SCHED zurück gegeben wird...
'            jFile.AddSchedule "zoneHeatingTempSched", Range("HeatingWD")
'            jFile.AddSchedule "zoneCoolingTempSched", Range("CoolingWD")
            jFile.AddSchedule "zoneHeatingTempSchedule", Range("HeatingWD")
            jFile.AddSchedule "zoneCoolingTempSchedule", Range("CoolingWD")
            jFile.AddHolidays "Holidays", Range("Feiertage")
            jFile.AddMeasure "AddingTemperatureSetpoints"
            Range("TempSetpoint") = "Definiert"
        End If

    End If 'Not bBuildingSim

    '''''''''''''''' Calling Photovoltaic Measure
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

    If Not bPVSim Then
        Range("Photovoltaic") = "Deaktiviert"
    Else
        Range("Photovoltaic") = "Start ..."

        If Range("azimuth") + dd2.List(dd2.Value) < 0 Then
            jFile.AddArgument "Azimuth", Range("azimuth") + dd2.List(dd2.Value) + 360
        Else
            jFile.AddArgument "Azimuth", Range("azimuth") + dd2.List(dd2.Value)
        End If
        jFile.AddArgument "Slope", Range("slope")
        jFile.AddArgument "CellEfficiency", Range("eff_PV")
        jFile.AddArgument "InverterEfficiency", Range("eff_sys_PV")
        jFile.AddArgument "FractionActiveSurfaceArea", 1
        jFile.AddMeasure "AddingPhotovoltaic"
        Range("Photovoltaic") = "Definiert"
    End If

    ' save in the resulting OSM for debugging with the SaveToModel measure
    jFile.AddArgument "pathtosave", GetOutputFolder()
    jFile.AddArgument "FileName", Range("FileName")
    jFile.AddMeasure "SaveModel"

    '''''''''''''''' Calling IDF window ventilation measure
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

    If Not bBuildingSim Or Not cb_windowvent.Value = 1 Then
        Range("window_ventilation") = "Deaktiviert"
    Else
        Range("window_ventilation") = "Start ..."
        jFile.AddArgument "VentilationACH", Range("windowvent_ach")
        jFile.AddArgument "MinIndoorTemperature", Range("windowvent_temp")
        jFile.AddArgument "DeltaT", Range("windowvent_dt")
        jFile.AddMeasure "InjectZoneVentilationIDF"
        Range("window_ventilation") = "Definiert"
    End If

    '''''''''''''''' Calling IDF Ideal loads Measure
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

    If Not bBuildingSim Then
        Range("IDFIdealLoads") = "Deaktiviert"
    Else
        Range("IDFIdealLoads") = "Start ..."

        jFile.AddArgument "HeatRecoveryType", Range("WRG")
        jFile.AddArgument "SensibleEffectiveness", Range("SENSIBLE")
        jFile.AddArgument "LatentEffectiveness", Range("LATENT")
        jFile.AddArgument "ACH", Range("ACH") * FloorHeight_Ratio * nrf_bgf 'Bugfix 01/22 : Korrektur kond. Raumhöhe sowie Korrektur NRF/BGF
        jFile.AddMeasure "InjectIdealLoadParametersIDF"
        Range("IDFIdealLoads") = "Definiert"
        ' update the progress messages
        DoEvents
    End If
    
    '''''''''''''''' Calling IDF Radiant Surface Measure
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

    If Not bBuildingSim Then
        'Range("IDFIdealLoads") = "Deaktiviert"
    Else
        If bDetailedHVAC Then
        'Range("IDFIdealLoads") = "Start ..."

        jFile.AddMeasure "InjectRadiantSurfacesIDF"
        'Range("IDFIdealLoads") = "Definiert"

        ' update the progress messages
        DoEvents
        End If
    End If

    '''''''''''''''' Calling IDF InjectHolidays Measure
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

    feiertage_active = 0
    For r = 1 To 5
        feiertage_active = feiertage_active + Range("Feiertage").Offset(r - 1, 0) + Range("Feiertage").Offset(r - 1, 1)
    Next

    If feiertage_active > 0 Then
        jFile.AddHolidays "Holidays", Range("Feiertage")
        jFile.AddMeasure "InjectHolidays"
    End If

    '''''''''''''''' Calling IDF Set Meters Measure
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

    jFile.AddArgument "Timestep", Timestep_s
    jFile.AddArgument "DayToStartSimulation", Range("DayToStartSimulation")
    jFile.AddArgument "HeatingSizingFactor", Range("HeatingSizingFactor")
    jFile.AddArgument "CoolingSizingFactor", Range("CoolingSizingFactor")
    jFile.AddMeasure "SetMeters"

    ' save the JSON file
    jFile.Save sFilename
End Sub

' Imports the OSW with the given filepath to the spreadsheet. This method is
' intended to be run on files that have been created with the method
' OSWFileInterface::ExportToOSW. It is not guarranteed that this method works
' on OSW files created otherwise.
'
' @see OSWFileInterface::ExportToOSW
'
' @param filename String ByRef The filepath (and name) of the file to be imported
Sub ImportFromOSW(ByRef filename As String)
    Sheets("HAUPTSEITE").Unprotect

    ' Read the given json file and parse it into a Dictionary/Collection
    Dim stream As Object
    Dim text As String
    Set stream = CreateObject("ADODB.Stream")

    stream.CharSet = "utf-8"
    stream.Open
    stream.LoadFromFile (filename)
    text = stream.ReadText()
    stream.Close

    Dim json As Object
    Set json = JsonConverter.ParseJson(text)

    ' Read highest-level data structures
    If json.Exists("seed_file") Then Range("path_geometry_Import") = json("seed_file")
    If json.Exists("weather_file") Then
        Dim parts() As String
        parts = Split(json("weather_file"), "\")
        If parts(UBound(parts)) <> "" Then
            Dim dd1 As DropDown: Set dd1 = Sheets("HAUPTSEITE").DropDowns("DropDown1")
            DDFindAndSetValue dd1, parts(UBound(parts))
        End If
    End If

    ' Read steps
    If json.Exists("steps") Then
        For Each item In json("steps")
            Call ImportStep(item)
        Next
    End If

    Sheets("HAUPTSEITE").Protect
End Sub

Sub ImportStep(ByVal item As Scripting.Dictionary)
    If Not item.Exists("measure_dir_name") Then Exit Sub
    If Not item.Exists("arguments") Then Exit Sub

    Dim args As Scripting.Dictionary: Set args = item("arguments")

    Dim dd2 As DropDown: Set dd2 = Sheets("HAUPTSEITE").DropDowns("Dropdown2")
    ' um doppeldeklarationen zu umgehen ------
    Dim ddRatio1 As DropDown: Set ddRatio1 = Sheets("HAUPTSEITE").DropDowns("Dropdown_NRF_BGF")
    Dim dd33 As DropDown: Set dd33 = Sheets("HAUPTSEITE").DropDowns("Dropdown33")
    Dim dd55 As DropDown: Set dd55 = Sheets("HAUPTSEITE").DropDowns("Dropdown55")
    Dim wrgVal As String

    Select Case item("measure_dir_name")
        Case "CustomExportParams":
            Dim cb_buildingSim As CheckBox
            Set cb_buildingSim = Sheets("HAUPTSEITE").CheckBoxes("checkbox_buildingsim")
            Dim cb_pvSim As CheckBox
            Set cb_pvSim = Sheets("HAUPTSEITE").CheckBoxes("checkbox_pvsim")
            Dim cb_zoneDetails As CheckBox
            Set cb_zoneDetails = Sheets("Parameter").CheckBoxes("checkbox_ZoneDetails")
            Dim cb_detailedHVAC As CheckBox
            Set cb_detailedHVAC = Sheets("Parameter").CheckBoxes("checkbox_hvac")
            
            Dim cb_shadingcontrol As CheckBox
            Set cb_shadingcontrol = Sheets("HAUPTSEITE").CheckBoxes("checkbox_shadingcontrol")
            Dim cb_inf As CheckBox
            Set cb_inf = Sheets("HAUPTSEITE").CheckBoxes("checkbox_inf")
            Dim cb_lightingcontrol As CheckBox
            Set cb_lightingcontrol = Sheets("HAUPTSEITE").CheckBoxes("checkbox lightingcontrol")
            Dim cb_windowvent As CheckBox
            Set cb_windowvent = Sheets("HAUPTSEITE").CheckBoxes("Checkbox_windowvent")
                
            Dim dd_lueftung As DropDown 'Lüftungsanlage Typ
            Set dd_lueftung = Sheets("HAUPTSEITE").DropDowns("dd_lueftung")
            
            'Parameter Modell
            If args.Exists("buildingSim") Then cb_buildingSim.Value = args("buildingSim")
            If args.Exists("pvSim") Then cb_pvSim.Value = args("pvSim")
            If args.Exists("zoneDetails") Then cb_zoneDetails.Value = args("zoneDetails")
            If args.Exists("detailedHVAC") Then cb_detailedHVAC.Value = args("detailedHVAC")
            If args.Exists("ventilation_type") Then dd_lueftung.Value = args("ventilation_type")
            Call dropdown_Lueftung
            
            'Parameter Geometrie, die nicht für Modellerzeugung benötigt werden
            If args.Exists("floor_length") Then Range("LAENGE") = args("floor_length")
            If args.Exists("floor_width") Then Range("BREITE") = args("floor_width")
            If args.Exists("NRF_BGF") Then Range("BGF_zu_NRF") = args("NRF_BGF")
            If args.Exists("ratio_NRF_BGF") Then DDFindAndSetValue ddRatio1, args("ratio_NRF_BGF")  'dd oben deklariert
            Call DropDown_BGF_NRF_Generisch
            
            'Lüftungsanlage
            If args.Exists("vorlauf_Luft") Then Range("Vorlauf_Lüftung") = args("vorlauf_Luft")
            If args.Exists("nachlauf_Luft") Then Range("Nachlauf_Lüftung") = args("nachlauf_Luft")
            
            'Weiteres
            If args.Exists("Shadingcontrol") Then cb_shadingcontrol.Value = args("Shadingcontrol")
            If args.Exists("Infiltration") Then cb_inf.Value = args("Infiltration")
            If args.Exists("Lightingcontrol") Then cb_lightingcontrol.Value = args("Lightingcontrol")
            If args.Exists("Windowvent") Then cb_windowvent.Value = args("Windowvent")
            
            'Geometrie Generisch/Importiert
            If args.Exists("genGeom") Then Range("geometry_source") = args("genGeom")
            Call label_geom

            'Nutzung - Feiertage
            Dim datum() As String
            Dim iEntry  As Integer
            iEntry = 0
            
            'Lüftung
             If args.Exists("FloorHeight_kond") Then Range("FloorHeight_kond") = args("FloorHeight_kond")
             If args.Exists("FloorHeight_import") Then Range("FloorHeight_import") = args("FloorHeight_import")
             If args.Exists("ACH_Input_Parameter") Then Range("ACH") = args("ACH_Input_Parameter") 'hier wird durch unveränderte Eingabeparameter zurückgeschrieben (ohne Berücksichtigung FloorHeightRation und NRF/BGF)
            If args.Exists("Holidays") Then
                datum = Split(args("Holidays"), ";")
                DatesCount = UBound(datum())

                Do While iEntry <= (DatesCount / 2 - 1)
                    Sheets("EIGENE NUTZUNGSPROFILE").Range("feiertage").Offset(iEntry, 0) = DateValue(datum(iEntry * 2))
                    Sheets("EIGENE NUTZUNGSPROFILE").Range("feiertage").Offset(iEntry, 1) = DateValue(datum(iEntry * 2 + 1))
                    iEntry = iEntry + 1
                Loop
            End If
            
        Case "SetWeatherAxisTimestep":
            If args.Exists("WeatherFilePath") Then
                Dim parts() As String
                parts = Split(args("WeatherFilePath"), "\")
                If parts(UBound(parts)) <> "" Then
                    Dim dd1 As DropDown: Set dd1 = Sheets("HAUPTSEITE").DropDowns("DropDown1")
                    DDFindAndSetValue dd1, parts(UBound(parts))
                End If
            End If

            If args.Exists("NorthAxis") Then
                DDFindAndSetValue dd2, args("NorthAxis")
            End If

            If args.Exists("Timestep") Then
                Dim dd_timestep As DropDown
                Set dd_timestep = Sheets("Hauptseite").DropDowns("dropdown_timestep")
                dd_timestep.Value = IIf(args("Timestep") = 4, 1, 2)
            End If

        Case "BarAspectRatioStudy":
            Dim dd42 As DropDown: Set dd42 = Sheets("HAUPTSEITE").DropDowns("dropdown_adiabat_n")
            Dim dd43 As DropDown: Set dd43 = Sheets("HAUPTSEITE").DropDowns("dropdown_adiabat_o")
            Dim dd44 As DropDown: Set dd44 = Sheets("HAUPTSEITE").DropDowns("dropdown_adiabat_s")
            Dim dd45 As DropDown: Set dd45 = Sheets("HAUPTSEITE").DropDowns("dropdown_adiabat_w")
            Dim dd46 As DropDown: Set dd46 = Sheets("HAUPTSEITE").DropDowns("dropdown_adiabat_d")
            Dim dd47 As DropDown: Set dd47 = Sheets("HAUPTSEITE").DropDowns("dropdown_adiabat_b")
           ' Dim ddRatio1 As DropDown: Set ddRatio1 = Sheets("HAUPTSEITE").DropDowns("Dropdown_NRF_BGF")         ' oben deklariert, sonst doppelt

            If args.Exists("number_of_stories") Then Range("NoFloors") = args("number_of_stories")
            If args.Exists("floor_to_floor_height") Then Range("FloorHeight") = args("floor_to_floor_height")
            If args.Exists("window_to_wall_ratio_north") Then Range("WWRN") = args("window_to_wall_ratio_north")
            If args.Exists("window_to_wall_ratio_east") Then Range("WWRO") = args("window_to_wall_ratio_east")
            If args.Exists("window_to_wall_ratio_south") Then Range("WWRS") = args("window_to_wall_ratio_south")
            If args.Exists("window_to_wall_ratio_west") Then Range("WWRW") = args("window_to_wall_ratio_west")

            If args.Exists("AdiabaticNorth") Then DDFindAndSetValue dd42, IIf(args("AdiabaticNorth") = "true", "Ja", "Nein")
            If args.Exists("AdiabaticEast") Then DDFindAndSetValue dd43, IIf(args("AdiabaticEast") = "true", "Ja", "Nein")
            If args.Exists("AdiabaticSouth") Then DDFindAndSetValue dd44, IIf(args("AdiabaticSouth") = "true", "Ja", "Nein")
            If args.Exists("AdiabaticWest") Then DDFindAndSetValue dd45, IIf(args("AdiabaticWest") = "true", "Ja", "Nein")
            If args.Exists("AdiabaticRoof") Then DDFindAndSetValue dd46, IIf(args("AdiabaticRoof") = "true", "Ja", "Nein")
            If args.Exists("AdiabaticFloor") Then DDFindAndSetValue dd47, IIf(args("AdiabaticFloor") = "true", "Ja", "Nein")

            If args.Exists("perimeterdepth") Then Range("PerimeterDepth") = args("perimeterdepth")

        Case "AddingMaterialsAndConstructions":
            Dim dd21 As DropDown: Set dd21 = Sheets("HAUPTSEITE").DropDowns("Dropdown21")
            Dim dd22 As DropDown: Set dd22 = Sheets("HAUPTSEITE").DropDowns("Dropdown22")

            If args.Exists("is_custom_standard") And args.Exists("selected_standard") Then

                If args("is_custom_standard") = "true" Then
                    Dim i, j, k As Integer
                    Dim nrOfLayers As Integer: nrOfLayers = 4
                    Dim names(1 To 4) As String: names(1) = "ExternalWallMat": names(2) = "RoofMat"
                        names(3) = "SlabMat": names(4) = "InteriorSlabs"
                    Dim attrs(1 To 5) As String: attrs(1) = "Name": attrs(2) = "Thickness"
                        attrs(3) = "Conductivity": attrs(4) = "Density": attrs(5) = "SpecificHeat"
                    Dim rangeAttrs As Variant: rangeAttrs = Sheets("EIGENE BAUTEILE").Range("C8:V11")
                    Dim rangeWindows As Variant: rangeWindows = Sheets("EIGENE BAUTEILE").Range("B13:D13")

                    For idx_name = 1 To UBound(names)
                        For idx_layer = 1 To nrOfLayers
                            For idx_attr = 1 To UBound(attrs)
                                'And Not Abfrage ergänzt
                                '       - Wenn kein Bauteil Name eingetragen ist, dann sollen die Nullen der folgenden 'attrs'
                                '       (Thickness, Conductivity, Density, SpecificHeat)
                                '       nicht geschrieben, sondern übersprungen werden ...
                                If args.Exists(names(idx_name) & idx_layer & attrs(idx_attr)) And Not args(names(idx_name) & idx_layer & attrs(1)) = "" Then
                                    rangeAttrs(idx_name, (idx_layer - 1) * UBound(attrs) + idx_attr) = _
                                        args(names(idx_name) & idx_layer & attrs(idx_attr))
                                End If
                            Next
                        Next
                    Next

                    If args.Exists("WindowsUValue") Then rangeWindows(1, 1) = args("WindowsUValue")
                    If args.Exists("WindowsName") Then rangeWindows(1, 2) = args("WindowsName")
                    If args.Exists("WindowsSHGC") Then rangeWindows(1, 3) = args("WindowsSHGC")

                    Sheets("EIGENE BAUTEILE").Range("B6") = args("selected_standard")
                    Sheets("EIGENE BAUTEILE").Range("C8:V11") = rangeAttrs
                    Sheets("EIGENE BAUTEILE").Range("B13:D13") = rangeWindows

                End If
            End If

            If args.Exists("selected_standard") Then DDFindAndSetValue dd21, args("selected_standard")
            If args.Exists("selected_masses") Then DDFindAndSetValue dd22, args("selected_masses")

        Case "AddingInternalLoads":
            If args.Exists("NRF/BGF") And args.Exists("ElectricEquipmentPowerPerFloorArea") Then
                Range("Electric") = val(args("ElectricEquipmentPowerPerFloorArea")) / val(args("NRF/BGF"))
            End If
            If args.Exists("NRF/BGF") And args.Exists("LightingPowerPerFloorArea") Then
                Range("Lights") = val(args("LightingPowerPerFloorArea")) / val(args("NRF/BGF"))
            End If
            If args.Exists("NRF/BGF") And args.Exists("PeoplePerFloorArea") Then
                Range("People") = 1# / (val(args("PeoplePerFloorArea")) / val(args("NRF/BGF")))
            End If

            If args.Exists("is_imported") And args.Exists("is_custom_ratio") Then
    '            Dim ddRatio1 As DropDown: Set ddRatio1 = Sheets("HAUPTSEITE").DropDowns("Dropdown_NRF_BGF")            'auskommentiert, wegen doppelter Deklaration
                Dim ddRatio2 As DropDown: Set ddRatio2 = Sheets("HAUPTSEITE").DropDowns("Dropdown_NRF_BGF_Import")

                If args("is_imported") = "true" Then
                    If args.Exists("selected_ratio") Then DDFindAndSetValue ddRatio2, args("selected_ratio")
                    Call DropDown_BGF_NRF_Geometrie_Import
                    If args("is_custom_ratio") = "true" Then Range("BGF_zu_NRF_import") = args("NRF/BGF")
                    If args.Exists("area_bgf_import") Then Range("BldgArea_import") = args("area_bgf_import")
                Else
                    If args.Exists("selected_ratio") Then DDFindAndSetValue ddRatio1, args("selected_ratio")
                    If args("is_custom_ratio") = "true" Then Range("BGF_zu_NRF") = args("NRF/BGF")
                End If
            End If
            
            If args.Exists("ElectricEquipmentSchedule") And args.Exists("is_custom_ElectricEquipment") Then _
                ImportSchedule args, "ElectricEquipment", "B10:B105", "B8"
            If args.Exists("LightSchedule") And args.Exists("is_custom_Light") Then _
                ImportSchedule args, "Light", "J10:J105", "J8"
            If args.Exists("PeopleSchedule") And args.Exists("is_custom_People") Then _
                ImportSchedule args, "People", "R10:R105", "R8"
            If args.Exists("PeopleActivitySchedule") And args.Exists("is_custom_PeopleActivity") Then _
                ImportSchedule args, "PeopleActivity", "Z10:Z105", "Z8"

            If args.Exists("ElectricEquipmentSchedule") Then
                Dim dd23 As DropDown: Set dd23 = Sheets("HAUPTSEITE").DropDowns("Dropdown23")
                DDFindAndSetValue dd23, args("ElectricEquipmentSchedule")
            End If
            If args.Exists("LightSchedule") Then
                Dim dd49 As DropDown: Set dd49 = Sheets("HAUPTSEITE").DropDowns("Dropdown49")
                DDFindAndSetValue dd49, args("LightSchedule")
            End If
            If args.Exists("PeopleSchedule") Then
                Dim dd50 As DropDown: Set dd50 = Sheets("HAUPTSEITE").DropDowns("Dropdown50")
                DDFindAndSetValue dd50, args("PeopleSchedule")
            End If
            If args.Exists("PeopleActivitySchedule") Then
                Dim dd51 As DropDown: Set dd51 = Sheets("HAUPTSEITE").DropDowns("Dropdown51")
                DDFindAndSetValue dd51, args("PeopleActivitySchedule")
            End If

        Case "AddingIdealAirLoads":
            'Dim dd33 As DropDown: Set dd33 = Sheets("HAUPTSEITE").DropDowns("Dropdown33")
            'Dim dd55 As DropDown: Set dd55 = Sheets("HAUPTSEITE").DropDowns("Dropdown55")
    
            If args.Exists("wrg") Then
            '    Dim wrgVal As String
                wrgVal = IIf(args("wrg") = "None", "Keine", IIf(args("wrg") = "Sensible", "Sensibel", "Latent"))
                DDFindAndSetValue dd33, wrgVal
            End If

            If args.Exists("hvacSchedule") And args.Exists("is_custom_hvac") Then _
                ImportSchedule args, "hvac", "AH10:AH105", "AH8"

            If args.Exists("hvacSchedule") Then
                DDFindAndSetValue dd55, args("hvacSchedule")
            End If
            
            If args.Exists("latent") Then Range("LATENT") = args("latent")
            If args.Exists("sensible") Then Range("SENSIBLE") = args("sensible")
        
        Case "AddDetailedHVAC":                                                                 'Doppelpunkt hat gefehlt?!
            'Dim dd33 As DropDown: Set dd33 = Sheets("HAUPTSEITE").DropDowns("Dropdown33")
            'Dim dd55 As DropDown: Set dd55 = Sheets("HAUPTSEITE").DropDowns("Dropdown55")

            If args.Exists("wrg") Then
            '    Dim wrgVal As String
                wrgVal = IIf(args("wrg") = "None", "Keine", IIf(args("wrg") = "Sensible", "Sensibel", "Latent"))
                DDFindAndSetValue dd33, wrgVal
            End If

            If args.Exists("hvacSchedule") And args.Exists("is_custom_hvac") Then _
                ImportSchedule args, "hvac", "AH10:AH105", "AH8"

            If args.Exists("hvacSchedule") Then
                DDFindAndSetValue dd55, args("hvacSchedule")
            End If
        
            If args.Exists("latent") Then Range("LATENT") = args("latent")
            If args.Exists("sensible") Then Range("SENSIBLE") = args("sensible")

        Case "AddingShadingControls":
            If args.Exists("SolarSetpoint") Then Range("SHCO_IRR") = args("SolarSetpoint")

        Case "AddingInfiltration":
            If args.Exists("AirChangesPerHour") Then Range("INFIL") = args("AirChangesPerHour")

        Case "AddingLightingControls":
            If args.Exists("DaylightingSetpoint") Then Range("LC_LUX") = args("DaylightingSetpoint")

        Case "AddingTemperatureSetpoints":
            If args.Exists("heatingTemp") And args.Exists("is_custom_heating") Then _
                ImportSchedule args, "zoneHeatingTemp", "AP10:AP105", "AP8"
            If args.Exists("coolingTemp") And args.Exists("is_custom_cooling") Then _
                ImportSchedule args, "zoneCoolingTemp", "AX10:AX105", "AX8"

            If args.Exists("heatingTemp") Then
                Sheets("EIGENE NUTZUNGSPROFILE").Range("AP8") = args("heatingTemp")  ' NEU
                Dim dd60 As DropDown: Set dd60 = Sheets("HAUPTSEITE").DropDowns("Dropdown60")
                DDFindAndSetValue dd60, args("heatingTemp")
            End If
            If args.Exists("coolingTemp") Then
                Sheets("EIGENE NUTZUNGSPROFILE").Range("AX8") = args("coolingTemp")  'NEU
                Dim dd86 As DropDown: Set dd86 = Sheets("HAUPTSEITE").DropDowns("Dropdown86")
                DDFindAndSetValue dd86, args("coolingTemp")
            End If

            If args.Exists("HeatingTemperatureSetpoint") Then Range("HeatingSetpTemp") = args("HeatingTemperatureSetpoint") ' WOZU GEHÖRT DIESE RANGE ???
            If args.Exists("CoolingTemperatureSetpoint") Then Range("CoolingSetTemp") = args("CoolingTemperatureSetpoint")

        Case "AddingPhotovoltaic":
            If args.Exists("Azimuth") Then Range("azimuth") = args("Azimuth") - dd2.List(dd2.Value)

            If args.Exists("Slope") Then Range("slope") = args("Slope")
            If args.Exists("CellEfficiency") Then Range("eff_PV") = args("CellEfficiency")
            If args.Exists("InverterEfficiency") Then Range("eff_sys_PV") = args("InverterEfficiency")

        Case "SaveModel":
            If args.Exists("FileName") Then Range("FileName") = args("FileName")

        Case "InjectZoneVentilationIDF":

            If args.Exists("VentilationACH") Then Range("windowvent_ach") = args("VentilationACH")
            If args.Exists("MinIndoorTemperature") Then Range("windowvent_temp") = args("MinIndoorTemperature")
            If args.Exists("DeltaT") Then Range("windowvent_dt") = args("DeltaT")

        Case "InjectIdealLoadParametersIDF":
            'Already handled in AddingIdealAirLoads

        Case "InjectHolidays":
            'Holidays igored for now
            '@TODO Add import when holiday functionality is implemented

        Case "SetMeters":
            Dim dd80 As DropDown: Set dd80 = Sheets("HAUPTSEITE").DropDowns("Dropdown80")
            Dim translate As Scripting.Dictionary: Set translate = New Scripting.Dictionary
            translate.Add "Monday", "Montag"
            translate.Add "Tuesday", "Dienstag"
            translate.Add "Wednesday", "Mittwoch"
            translate.Add "Thursday", "Donnerstag"
            translate.Add "Friday", "Freitag"
            translate.Add "Saturday", "Samstag"
            translate.Add "Sunday", "Sonntag"
            translate.Add "UseWeatherFile", "Nach Wetterdaten"

            If args.Exists("DayToStartSimulation") Then
                If translate.Exists(args("DayToStartSimulation")) Then
                    DDFindAndSetValue dd80, translate(args("DayToStartSimulation"))
                End If
            End If

    End Select
End Sub

' Searches through the given dropdown's list for the given value. If the value
' is found in the list, the selected value of the dropdown is set to this entry.
'
' @param dd DropDown ByRef The dropdown
' @param val Variant ByVal The value to look for
Sub DDFindAndSetValue(ByRef dd As DropDown, ByVal val As Variant)
' ----- Sonderzeichen, Umlaute usw. die im ows/json file umgeschrieben wurden, müssen wieder 'zurück übersetzt' werden
' ----- siehe Export: JSONFile-Sub 'AddArgument'
    If InStr(val, ".") Then            '   Braucht es die Umwandlung '.' - ','  ???        TODO: Testen!!!!
        val = Replace(val, ".", ",")
    End If
    If InStr(val, "ae") Then
        val = Replace(val, "ae", "ä")
    End If
    If InStr(val, "ue") Then
        val = Replace(val, "ue", "ü")
    End If
    If InStr(val, "oe") Then
        val = Replace(val, "oe", "ö")
    End If


    Dim i As Integer
    For i = 1 To dd.ListCount
        If dd.List(i) = val Then dd.Value = i
    Next
End Sub

' Imports the given schedule from the given argument dictionary to the given ranges.
' This method is intended to run on data used in the import/export methods.
'
' @see OSWFileInterface::ImportFromOSW
' @see OSWFileInterface::ExportToOSW
'
' @param args Scripting.Dictionary ByRef The data container
' @param scheduleName String ByRef The schedule's name
' @param rangeName String ByRef The range where the data is written
' @param schedNameRange String ByRef The range where the name is written
Sub ImportSchedule(ByRef args As Scripting.Dictionary, ByRef scheduleName As String, ByRef rangeName As String, ByRef schedNameRange As String)
    If args("is_custom_" & scheduleName) = "false" Then Exit Sub

    Dim values As Variant
    Dim bs As String: bs = IIf(scheduleName = "hvac", "Sched", "Schedule")

    values = Split(Trim(args(scheduleName & bs & "Werktag")), ";")
    Sheets("EIGENE NUTZUNGSPROFILE").Range(rangeName).Offset(0, 0) = Application.Transpose(values)
    values = Split(Trim(args(scheduleName & bs & "Samstag")), ";")
    Sheets("EIGENE NUTZUNGSPROFILE").Range(rangeName).Offset(0, 1) = Application.Transpose(values)
    values = Split(Trim(args(scheduleName & bs & "Sonntag")), ";")
    Sheets("EIGENE NUTZUNGSPROFILE").Range(rangeName).Offset(0, 2) = Application.Transpose(values)
    values = Split(Trim(args(scheduleName & bs & "Feiertag")), ";")
    Sheets("EIGENE NUTZUNGSPROFILE").Range(rangeName).Offset(0, 3) = Application.Transpose(values)

    Sheets("EIGENE NUTZUNGSPROFILE").Range(schedNameRange) = args(scheduleName & "Schedule")
End Sub
