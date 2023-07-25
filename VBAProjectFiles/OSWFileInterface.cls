VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "OSWFileInterface"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False

' Export method for measure CreateAnEmptyModel.
'
' @param jFile JSONFile ByRef The JSON file to which the parameters are exported
Sub ExportCreateAnEmptyModel(ByRef jFile As JSONFile)
    Dim dd1 As DropDown 'weather data
    Set dd1 = Sheets("HAUPTSEITE").DropDowns("DropDown1")

    jFile.CreateFile Range("FileName") + ".osm", GetWeatherFolder() & "\" & dd1.List(dd1.Value)
    jFile.AddMeasure "CreateAnEmptyModel"
End Sub

' Export method for measure SetWeatherAxisTimestep.
'
' @param jFile JSONFile ByRef The JSON file to which the parameters are exported
' @param bGeneric Boolean ByVal If the geometry is generic (true) or imported (false)
' @param bCopyOSMFile Boolean ByVal If true makes a copy of the supplied geometry file.
'   This is a necessary step only for the export before a simulation run, but is not
'   not required for an export of parameters for other purposes.
Sub ExportSetWeatherAxisTimestep( _
    ByRef jFile As JSONFile, _
    ByVal bGeneric As Boolean, _
    ByVal bCopyOSMFile As Boolean _
)
    Dim dd1 As DropDown 'weather data
    Set dd1 = Sheets("HAUPTSEITE").DropDowns("DropDown1")
    Dim dd2 As DropDown 'orientation
    Set dd2 = Sheets("HAUPTSEITE").DropDowns("Dropdown2")
    Dim dd_timestep As DropDown
    Set dd_timestep = Sheets("Hauptseite").DropDowns("dropdown_timestep")
    Dim Timestep As Double
    Dim Timestep_s As String
    Timestep = 60 / dd_timestep.List(dd_timestep.Value)
    Timestep_s = Timestep

    If bGeneric Then
        jFile.AddArgument "WeatherFilePath", GetWeatherFolder() & "\" & dd1.List(dd1.Value)
        jFile.AddArgument "NorthAxis", dd2.List(dd2.Value)
        jFile.AddArgument "Timestep", Timestep_s
    Else
        Dim localOSMPath As String: localOSMPath = ""

        If bCopyOSMFile Then
            Dim fso As New FileSystemObject
            Dim sOSMFileName As String
            Dim sOSMPathName As String
            sOSMPathName = Range("path_geometry_Import")
            sOSMFileName = fso.GetFileName(sOSMPathName)
            sOSMFileName = Replace(sOSMFileName, Chr(223), "ss")
            sOSMFileName = Replace(sOSMFileName, Chr(228), "ae")
            sOSMFileName = Replace(sOSMFileName, Chr(252), "ue")
            sOSMFileName = Replace(sOSMFileName, Chr(246), "oe")
            sOSMFileName = Replace(sOSMFileName, Chr(196), "Ae")
            sOSMFileName = Replace(sOSMFileName, Chr(220), "Ue")
            sOSMFileName = Replace(sOSMFileName, Chr(214), "Oe")

            localOSMPath = GetOutputFolder() + "\" + sOSMFileName
            FileCopy sOSMPathName, localOSMPath
        End If

        jFile.CreateFile localOSMPath, GetWeatherFolder() & "\" & dd1.List(dd1.Value)
        jFile.AddArgument "WeatherFilePath", GetWeatherFolder() & "\" & dd1.List(dd1.Value)
        jFile.AddArgument "Timestep", Timestep_s
    End If

    jFile.AddMeasure "SetWeatherAxisTimestep"
End Sub

' Export method for measure CustomExportParams.
'
' @param jFile JSONFile ByRef The JSON file to which the parameters are exported
' @param bGeneric Boolean ByVal If the geometry is generic (true) or imported (false)
Sub ExportCustomExportParams( _
    ByRef jFile As JSONFile, _
    ByVal bGeneric As Boolean _
)
    Dim ddRatio1 As DropDown 'ratio NFA/GFA
    Set ddRatio1 = Sheets("HAUPTSEITE").DropDowns("Dropdown_NRF_BGF")
    Dim dd_lueftung As DropDown 'type of ventilation
    Set dd_lueftung = Sheets("HAUPTSEITE").DropDowns("dd_lueftung")
    Dim cb_windowvent As CheckBox
    Set cb_windowvent = Sheets("HAUPTSEITE").CheckBoxes("Checkbox_windowvent")
    Dim cb_inf As CheckBox
    Set cb_inf = Sheets("HAUPTSEITE").CheckBoxes("checkbox_inf")
    Dim cb_lightingcontrol As CheckBox
    Set cb_lightingcontrol = Sheets("HAUPTSEITE").CheckBoxes("checkbox lightingcontrol")
    Dim cb_shadingcontrol As CheckBox
    Set cb_shadingcontrol = Sheets("HAUPTSEITE").CheckBoxes("checkbox_shadingcontrol")
    Dim cb_zoneDetails As CheckBox
    Set cb_zoneDetails = Sheets("Parameter").CheckBoxes("checkbox_ZoneDetails")
    Dim cb_detailedHVAC As CheckBox
    Set cb_detailedHVAC = Sheets("Parameter").CheckBoxes("checkbox_hvac")

    'parameters for the generic HVAC model
    jFile.AddArgument "zoneDetails", IIf(cb_zoneDetails.Value = 1, 1, 0)
    jFile.AddArgument "detailedHVAC", IIf(cb_detailedHVAC.Value = 1, 1, 0)
    jFile.AddArgument "ventilation_type", dd_lueftung.Value

    'parameters of the geometry which are not required in the measures
    jFile.AddArgument "floor_length", Range("LAENGE")
    jFile.AddArgument "floor_width", Range("BREITE")
    jFile.AddArgument "ratio_NRF_BGF", ddRatio1.List(ddRatio1.Value)
    jFile.AddArgument "NRF_BGF", Range("BGF_zu_NRF")

    If bGeneric Then
        jFile.AddArgument "genGeom", 1
    Else
        jFile.AddArgument "genGeom", 2
    End If

    'definition of holidays
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

    'parameters of the ventilation system
    jFile.AddArgument "vorlauf_Luft", Range("Vorlauf_Lüftung")
    jFile.AddArgument "nachlauf_Luft", Range("Nachlauf_Lüftung")
    jFile.AddArgument "FloorHeight_kond", Range("FloorHeight_kond")
    jFile.AddArgument "FloorHeight_import", Range("FloorHeight_import")
    jFile.AddArgument "ACH_Input_Parameter", Range("ACH")
    jFile.AddArgument "Windowvent", IIf(cb_windowvent.Value = 1, 1, 0)
    jFile.AddArgument "Infiltration", IIf(cb_inf.Value = 1, 1, 0)

    'other parameters
    jFile.AddArgument "Shadingcontrol", IIf(cb_shadingcontrol.Value = 1, 1, 0)
    jFile.AddArgument "Lightingcontrol", IIf(cb_lightingcontrol.Value = 1, 1, 0)

    jFile.AddMeasure "CustomExportParams"
End Sub

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
' @param bGeneric Boolean ByVal If a generic building model should be used or
'     instead an existing model be imported
' @param bCopyOSMFile Boolean ByVal If true, copies the OSM file, provided that
'     the geometry is imported and not generic, to the run folder. This is
'     necessary for a simulation run, but not for the export of paramters.
' @param bDetailedHVAC Boolean ByVal If true, sets the simulation up with a
'     detailed HVAC model, otherwise with ideal loads
Sub ExportToOSW( _
    ByVal sFilename As String, _
    ByVal bGeneric As Boolean, _
    ByVal bCopyOSMFile As Boolean, _
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
    Dim dd44 As DropDown 'Adiabat Süd
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

    If bGeneric Then
        Call ExportCreateAnEmptyModel(jFile)
    End If

    Call ExportSetWeatherAxisTimestep(jFile, bGeneric, bCopyOSMFile)
    Call ExportCustomExportParams(jFile, bGeneric)

    ''''''''''''''''''''''''''''''' Building Model
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

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

    Range("UStatus") = "Start ..."
    jFile.AddConstruction "ExternalWallMat", Range("AWMat1"), 4
    jFile.AddConstruction "RoofMat", Range("DMat1"), 4
    jFile.AddConstruction "SlabMat", Range("BPMat1"), 4
    jFile.AddConstruction "Massen", Range("Massen"), 3
    jFile.AddConstruction "InteriorSlabs", Range("ZwischenDecke"), 4
    jFile.AddInternalSourceConstructionHardcoded "ChilledCeiling", 2, 2, 2, 0.15, Range("ZwischenDecke"), 2
    jFile.AddWindowConstruction "Windows", Range("WINDOWSSLS"), Range("WINDOWSSLS").Offset(0, -1), Range("WINDOWSSLS").Offset(0, 1)
    jFile.AddArgument "selected_standard", dd21.List(dd21.Value)
    jFile.AddArgument "is_custom_standard", IIf(dd21.Value > (dd21.ListCount - 4), "Ja", "Nein")
    jFile.AddArgument "selected_masses", dd22.List(dd22.Value)

    jFile.AddMeasure "AddingMaterialsAndConstructions"
    Range("UStatus") = "Definiert"
    DoEvents

    ''''''''''''''''''''''''''''''' Adding Thermal Zones and Detecting External Zones
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

    If Not bGeneric Then jFile.AddMeasure "AddThermalZones"
    jFile.AddMeasure "DetectingExternalZones"

    ''''''''''''''''''''''''''''''' internal load measure (schedules)
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

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

    jFile.AddMeasure "AddingInternalLoads"
    Range("LoadStatus") = "Definiert"
    DoEvents

    '''''''''''''''' Calling Ideal loads measure
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

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
    jFile.AddArgument "hvacSchedule", dd55.List(dd55.Value)
    jFile.AddArgument "is_custom_hvac", IIf(dd55.Value > (dd55.ListCount - 2), "true", "false")

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
    DoEvents

    '''''''''''''''' Calling Shading Control measure
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

    If Not cb_shadingcontrol.Value = 1 Then
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

    If Not cb_inf.Value = 1 Then
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

    If Not cb_lightingcontrol.Value = 1 Then
        Range("LightingControl") = "Deaktiviert"
    Else
        Range("LightingControl") = "Start ..."
        jFile.AddArgument "DaylightingSetpoint", Range("LC_LUX")
        jFile.AddMeasure "AddingLightingControls"
        Range("LightingControl") = "Definiert"
    End If

    '''''''''''''''' Calling Setpoint Measure loads measure
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

    jFile.AddArgument "heatingTemp", dd60.List(dd60.Value)
    jFile.AddArgument "coolingTemp", dd86.List(dd86.Value)
    jFile.AddArgument "is_custom_heating", IIf(dd60.Value > 3, "true", "false")  ' da bisher nur drei feste Profile zur Auswahl stehen
    jFile.AddArgument "is_custom_cooling", IIf(dd86.Value > 3, "true", "false")
    jFile.AddSchedule "zoneHeatingTempSchedule", Range("HeatingWD")
    jFile.AddSchedule "zoneCoolingTempSchedule", Range("CoolingWD")
    jFile.AddHolidays "Holidays", Range("Feiertage")
    jFile.AddMeasure "AddingTemperatureSetpoints"
    Range("TempSetpoint") = "Definiert"

    ' save in the resulting OSM for debugging with the SaveToModel measure
    jFile.AddArgument "pathtosave", GetOutputFolder()
    jFile.AddArgument "FileName", Range("FileName")
    jFile.AddMeasure "SaveModel"

    '''''''''''''''' Calling IDF window ventilation measure
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

    If Not cb_windowvent.Value = 1 Then
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

    Range("IDFIdealLoads") = "Start ..."

    jFile.AddArgument "HeatRecoveryType", Range("WRG")
    jFile.AddArgument "SensibleEffectiveness", Range("SENSIBLE")
    jFile.AddArgument "LatentEffectiveness", Range("LATENT")
    jFile.AddArgument "ACH", Range("ACH") * FloorHeight_Ratio * nrf_bgf 'Bugfix 01/22 : Korrektur kond. Raumhöhe sowie Korrektur NRF/BGF
    jFile.AddMeasure "InjectIdealLoadParametersIDF"
    Range("IDFIdealLoads") = "Definiert"
    ' update the progress messages
    DoEvents

    '''''''''''''''' Calling IDF Radiant Surface Measure
    '''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

    If bDetailedHVAC Then
        'Range("IDFIdealLoads") = "Start ..."

        jFile.AddMeasure "InjectRadiantSurfacesIDF"
        'Range("IDFIdealLoads") = "Definiert"

        ' update the progress messages
        DoEvents
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
            If args.Exists("zoneDetails") Then cb_zoneDetails.Value = GetArgument(args, "zoneDetails")
            If args.Exists("detailedHVAC") Then cb_detailedHVAC.Value = GetArgument(args, "detailedHVAC")
            If args.Exists("ventilation_type") Then dd_lueftung.Value = GetArgument(args, "ventilation_type")
            Call dropdown_Lueftung

            'Parameter Geometrie, die nicht für Modellerzeugung benötigt werden
            If args.Exists("floor_length") Then Range("LAENGE") = GetArgument(args, "floor_length")
            If args.Exists("floor_width") Then Range("BREITE") = GetArgument(args, "floor_width")
            If args.Exists("NRF_BGF") Then Range("BGF_zu_NRF") = GetArgument(args, "NRF_BGF")
            If args.Exists("ratio_NRF_BGF") Then DDFindAndSetValue ddRatio1, GetArgument(args, "ratio_NRF_BGF")  'dd oben deklariert
            Call DropDown_BGF_NRF_Generisch

            'Lüftungsanlage
            If args.Exists("vorlauf_Luft") Then Range("Vorlauf_Lüftung") = GetArgument(args, "vorlauf_Luft")
            If args.Exists("nachlauf_Luft") Then Range("Nachlauf_Lüftung") = GetArgument(args, "nachlauf_Luft")

            'Weiteres
            If args.Exists("Shadingcontrol") Then cb_shadingcontrol.Value = GetArgument(args, "Shadingcontrol")
            If args.Exists("Infiltration") Then cb_inf.Value = GetArgument(args, "Infiltration")
            If args.Exists("Lightingcontrol") Then cb_lightingcontrol.Value = GetArgument(args, "Lightingcontrol")
            If args.Exists("Windowvent") Then cb_windowvent.Value = GetArgument(args, "Windowvent")

            'Geometrie Generisch/Importiert
            If args.Exists("genGeom") Then Range("geometry_source") = GetArgument(args, "genGeom")
            Call label_geom

            'Nutzung - Feiertage
            Dim datum() As String
            Dim iEntry  As Integer
            iEntry = 0

            'Lüftung
            If args.Exists("FloorHeight_kond") Then Range("FloorHeight_kond") = GetArgument(args, "FloorHeight_kond")
            If args.Exists("FloorHeight_import") Then Range("FloorHeight_import") = GetArgument(args, "FloorHeight_import")
            'hier wird durch unveränderte Eingabeparameter zurückgeschrieben (ohne Berücksichtigung FloorHeightRation und NRF/BGF)
            If args.Exists("ACH_Input_Parameter") Then Range("ACH") = GetArgument(args, "ACH_Input_Parameter")
            If args.Exists("Holidays") Then
                datum = Split(GetArgument(args, "Holidays", True), ";")
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
                DDFindAndSetValue dd2, GetArgument(args, "NorthAxis")
            End If

            If args.Exists("Timestep") Then
                Dim dd_timestep As DropDown
                Set dd_timestep = Sheets("Hauptseite").DropDowns("dropdown_timestep")
                dd_timestep.Value = IIf(GetArgument(args, "Timestep") = 4, 1, 2)
            End If

        Case "BarAspectRatioStudy":
            Dim dd42 As DropDown: Set dd42 = Sheets("HAUPTSEITE").DropDowns("dropdown_adiabat_n")
            Dim dd43 As DropDown: Set dd43 = Sheets("HAUPTSEITE").DropDowns("dropdown_adiabat_o")
            Dim dd44 As DropDown: Set dd44 = Sheets("HAUPTSEITE").DropDowns("dropdown_adiabat_s")
            Dim dd45 As DropDown: Set dd45 = Sheets("HAUPTSEITE").DropDowns("dropdown_adiabat_w")
            Dim dd46 As DropDown: Set dd46 = Sheets("HAUPTSEITE").DropDowns("dropdown_adiabat_d")
            Dim dd47 As DropDown: Set dd47 = Sheets("HAUPTSEITE").DropDowns("dropdown_adiabat_b")

            If args.Exists("number_of_stories") Then Range("NoFloors") = GetArgument(args, "number_of_stories")
            If args.Exists("floor_to_floor_height") Then Range("FloorHeight") = GetArgument(args, "floor_to_floor_height")
            If args.Exists("window_to_wall_ratio_north") Then Range("WWRN") = GetArgument(args, "window_to_wall_ratio_north")
            If args.Exists("window_to_wall_ratio_east") Then Range("WWRO") = GetArgument(args, "window_to_wall_ratio_east")
            If args.Exists("window_to_wall_ratio_south") Then Range("WWRS") = GetArgument(args, "window_to_wall_ratio_south")
            If args.Exists("window_to_wall_ratio_west") Then Range("WWRW") = GetArgument(args, "window_to_wall_ratio_west")

            If args.Exists("AdiabaticNorth") Then DDFindAndSetValue dd42, GetArgument(args, "AdiabaticNorth")
            If args.Exists("AdiabaticEast") Then DDFindAndSetValue dd43, GetArgument(args, "AdiabaticEast")
            If args.Exists("AdiabaticSouth") Then DDFindAndSetValue dd44, GetArgument(args, "AdiabaticSouth")
            If args.Exists("AdiabaticWest") Then DDFindAndSetValue dd45, GetArgument(args, "AdiabaticWest")
            If args.Exists("AdiabaticRoof") Then DDFindAndSetValue dd46, GetArgument(args, "AdiabaticRoof")
            If args.Exists("AdiabaticFloor") Then DDFindAndSetValue dd47, GetArgument(args, "AdiabaticFloor")

            If args.Exists("perimeterdepth") Then Range("PerimeterDepth") = GetArgument(args, "perimeterdepth")

        Case "AddingMaterialsAndConstructions":
            Dim dd21 As DropDown: Set dd21 = Sheets("HAUPTSEITE").DropDowns("Dropdown21")
            Dim dd22 As DropDown: Set dd22 = Sheets("HAUPTSEITE").DropDowns("Dropdown22")

            If args.Exists("is_custom_standard") And args.Exists("selected_standard") Then

                If GetArgument(args, "is_custom_standard") = "Ja" Then
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
                                ' Wenn kein Bauteil Name eingetragen ist, dann sollen die Nullen der folgenden 'attrs'
                                ' (Thickness, Conductivity, Density, SpecificHeat)
                                ' nicht geschrieben, sondern übersprungen werden ...
                                If args.Exists(names(idx_name) & idx_layer & attrs(idx_attr)) _
                                    And Not GetArgument(args, names(idx_name) & idx_layer & attrs(1)) = "" _
                                Then
                                    rangeAttrs(idx_name, (idx_layer - 1) * UBound(attrs) + idx_attr) = _
                                        GetArgument(args, names(idx_name) & idx_layer & attrs(idx_attr))
                                End If
                            Next
                        Next
                    Next

                    If args.Exists("WindowsUValue") Then rangeWindows(1, 1) = GetArgument(args, "WindowsUValue")
                    If args.Exists("WindowsName") Then rangeWindows(1, 2) = GetArgument(args, "WindowsName")
                    If args.Exists("WindowsSHGC") Then rangeWindows(1, 3) = GetArgument(args, "WindowsSHGC")

                    Sheets("EIGENE BAUTEILE").Range("B6") = GetArgument(args, "selected_standard")
                    Sheets("EIGENE BAUTEILE").Range("C8:V11") = rangeAttrs
                    Sheets("EIGENE BAUTEILE").Range("B13:D13") = rangeWindows

                End If
            End If

            If args.Exists("selected_standard") Then DDFindAndSetValue dd21, GetArgument(args, "selected_standard")
            If args.Exists("selected_masses") Then DDFindAndSetValue dd22, GetArgument(args, "selected_masses")

        Case "AddingInternalLoads":
            If args.Exists("NRF/BGF") And args.Exists("ElectricEquipmentPowerPerFloorArea") Then
                Range("Electric") = val(GetArgument(args, "ElectricEquipmentPowerPerFloorArea")) _
                    / val(GetArgument(args, "NRF/BGF"))
            End If
            If args.Exists("NRF/BGF") And args.Exists("LightingPowerPerFloorArea") Then
                Range("Lights") = val(GetArgument(args, "LightingPowerPerFloorArea")) _
                    / val(GetArgument(args, "NRF/BGF"))
            End If
            If args.Exists("NRF/BGF") And args.Exists("PeoplePerFloorArea") Then
                Range("People") = 1# / (val(GetArgument(args, "PeoplePerFloorArea")) / val(GetArgument(args, "NRF/BGF")))
            End If

            If args.Exists("is_imported") And args.Exists("is_custom_ratio") Then
                Dim ddRatio2 As DropDown: Set ddRatio2 = Sheets("HAUPTSEITE").DropDowns("Dropdown_NRF_BGF_Import")

                If GetArgument(args, "is_imported") = "Ja" Then
                    If args.Exists("selected_ratio") Then DDFindAndSetValue ddRatio2, GetArgument(args, "selected_ratio")
                    Call DropDown_BGF_NRF_Geometrie_Import
                    If GetArgument(args, "is_custom_ratio") = "Ja" Then Range("BGF_zu_NRF_import") = GetArgument(args, "NRF/BGF")
                    If args.Exists("area_bgf_import") Then Range("BldgArea_import") = GetArgument(args, "area_bgf_import")
                Else
                    If args.Exists("selected_ratio") Then DDFindAndSetValue ddRatio1, GetArgument(args, "selected_ratio")
                    If GetArgument(args, "is_custom_ratio") = "Ja" Then Range("BGF_zu_NRF") = GetArgument(args, "NRF/BGF")
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
                DDFindAndSetValue dd23, GetArgument(args, "ElectricEquipmentSchedule")
            End If
            If args.Exists("LightSchedule") Then
                Dim dd49 As DropDown: Set dd49 = Sheets("HAUPTSEITE").DropDowns("Dropdown49")
                DDFindAndSetValue dd49, GetArgument(args, "LightSchedule")
            End If
            If args.Exists("PeopleSchedule") Then
                Dim dd50 As DropDown: Set dd50 = Sheets("HAUPTSEITE").DropDowns("Dropdown50")
                DDFindAndSetValue dd50, GetArgument(args, "PeopleSchedule")
            End If
            If args.Exists("PeopleActivitySchedule") Then
                Dim dd51 As DropDown: Set dd51 = Sheets("HAUPTSEITE").DropDowns("Dropdown51")
                DDFindAndSetValue dd51, GetArgument(args, "PeopleActivitySchedule")
            End If

        Case "AddingIdealAirLoads":
            If args.Exists("wrg") Then
                wrgVal = IIf(GetArgument(args, "wrg") = "None", "Keine", IIf(GetArgument(args, "wrg") = "Sensible", "Sensibel", "Latent"))
                DDFindAndSetValue dd33, wrgVal
            End If

            If args.Exists("hvacSchedule") And args.Exists("is_custom_hvac") Then _
                ImportSchedule args, "hvac", "AH10:AH105", "AH8"

            If args.Exists("hvacSchedule") Then
                DDFindAndSetValue dd55, GetArgument(args, "hvacSchedule")
            End If

            If args.Exists("latent") Then Range("LATENT") = GetArgument(args, "latent")
            If args.Exists("sensible") Then Range("SENSIBLE") = GetArgument(args, "sensible")

        Case "AddDetailedHVAC":
            If args.Exists("wrg") Then
                wrgVal = IIf(GetArgument(args, "wrg") = "None", "Keine", IIf(GetArgument(args, "wrg") = "Sensible", "Sensibel", "Latent"))
                DDFindAndSetValue dd33, wrgVal
            End If

            If args.Exists("hvacSchedule") And args.Exists("is_custom_hvac") Then _
                ImportSchedule args, "hvac", "AH10:AH105", "AH8"

            If args.Exists("hvacSchedule") Then
                DDFindAndSetValue dd55, GetArgument(args, "hvacSchedule")
            End If

            If args.Exists("latent") Then Range("LATENT") = GetArgument(args, "latent")
            If args.Exists("sensible") Then Range("SENSIBLE") = GetArgument(args, "sensible")

        Case "AddingShadingControls":
            If args.Exists("SolarSetpoint") Then Range("SHCO_IRR") = GetArgument(args, "SolarSetpoint")

        Case "AddingInfiltration":
            If args.Exists("AirChangesPerHour") Then Range("INFIL") = GetArgument(args, "AirChangesPerHour")

        Case "AddingLightingControls":
            If args.Exists("DaylightingSetpoint") Then Range("LC_LUX") = GetArgument(args, "DaylightingSetpoint")

        Case "AddingTemperatureSetpoints":
            If args.Exists("heatingTemp") And args.Exists("is_custom_heating") Then _
                ImportSchedule args, "zoneHeatingTemp", "AP10:AP105", "AP8"
            If args.Exists("coolingTemp") And args.Exists("is_custom_cooling") Then _
                ImportSchedule args, "zoneCoolingTemp", "AX10:AX105", "AX8"

            If args.Exists("heatingTemp") Then
                Sheets("EIGENE NUTZUNGSPROFILE").Range("AP8") = GetArgument(args, "heatingTemp")  ' NEU
                Dim dd60 As DropDown: Set dd60 = Sheets("HAUPTSEITE").DropDowns("Dropdown60")
                DDFindAndSetValue dd60, GetArgument(args, "heatingTemp")
            End If
            If args.Exists("coolingTemp") Then
                Sheets("EIGENE NUTZUNGSPROFILE").Range("AX8") = GetArgument(args, "coolingTemp")  'NEU
                Dim dd86 As DropDown: Set dd86 = Sheets("HAUPTSEITE").DropDowns("Dropdown86")
                DDFindAndSetValue dd86, GetArgument(args, "coolingTemp")
            End If

            If args.Exists("HeatingTemperatureSetpoint") Then Range("HeatingSetpTemp") = GetArgument(args, "HeatingTemperatureSetpoint") ' WOZU GEHÖRT DIESE RANGE ???
            If args.Exists("CoolingTemperatureSetpoint") Then Range("CoolingSetTemp") = GetArgument(args, "CoolingTemperatureSetpoint")

        Case "SaveModel":
            If args.Exists("FileName") Then Range("FileName") = GetArgument(args, "FileName")

        Case "InjectZoneVentilationIDF":

            If args.Exists("VentilationACH") Then Range("windowvent_ach") = GetArgument(args, "VentilationACH")
            If args.Exists("MinIndoorTemperature") Then Range("windowvent_temp") = GetArgument(args, "MinIndoorTemperature")
            If args.Exists("DeltaT") Then Range("windowvent_dt") = GetArgument(args, "DeltaT")

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
                    DDFindAndSetValue dd80, translate(GetArgument(args, "DayToStartSimulation"))
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
    If GetArgument(args, "is_custom_" & scheduleName) = "Nein" Then Exit Sub

    Dim values As Variant
    Dim bs As String: bs = IIf(scheduleName = "hvac", "Sched", "Schedule")

    values = Split(Trim(GetArgument(args, scheduleName & bs & "Werktag", True)), ";")
    Sheets("EIGENE NUTZUNGSPROFILE").Range(rangeName).Offset(0, 0) = Application.Transpose(values)
    values = Split(Trim(GetArgument(args, scheduleName & bs & "Samstag", True)), ";")
    Sheets("EIGENE NUTZUNGSPROFILE").Range(rangeName).Offset(0, 1) = Application.Transpose(values)
    values = Split(Trim(GetArgument(args, scheduleName & bs & "Sonntag", True)), ";")
    Sheets("EIGENE NUTZUNGSPROFILE").Range(rangeName).Offset(0, 2) = Application.Transpose(values)
    values = Split(Trim(GetArgument(args, scheduleName & bs & "Feiertag", True)), ";")
    Sheets("EIGENE NUTZUNGSPROFILE").Range(rangeName).Offset(0, 3) = Application.Transpose(values)

    Sheets("EIGENE NUTZUNGSPROFILE").Range(schedNameRange) = GetArgument(args, scheduleName & "Schedule", True)
End Sub
