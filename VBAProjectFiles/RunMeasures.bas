Attribute VB_Name = "RunMeasures"
Dim iRow As Integer
Public Startzeit_indv As Variant

Sub ClearCells()
    ' set status cells empty
    Range("Debug").ClearContents
    Range("calc_time").ClearContents
    Range("GeomStatus").ClearContents
    Range("UStatus").ClearContents
    Range("LoadStatus").ClearContents
    Range("IdealLoads").ClearContents
    Range("ShadingControl").ClearContents
    Range("Infiltration").ClearContents
    Range("LightingControl").ClearContents
    Range("TempSetpoint").ClearContents
    Range("Photovoltaic").ClearContents
    Range("window_ventilation").ClearContents
    Range("IDFIdealLoads").ClearContents
    
    Range("SimStatus").ClearContents
    Range("StatusEnergyPlusSimulation") = ""
    
    Sheets("HAUPTSEITE").Range("M27:O32").ClearContents
    
End Sub

Sub CreateWorkflowAndExecute()

    Application.Calculation = xlCalculationManual

    ' set application path
    SetApplicationPath

    ' make the main sheet unprotected so we can read and write on it
    Sheets("HAUPTSEITE").Unprotect

    ' set status cells empty
    Call ClearCells

    Range("Status").Offset(0, 0) = "OSW-file wird erzeugt"

    ' execution time measurement
    Startzeit = Time
    Startzeit_indv = Time
    DoEvents

    If Dir(Range("DirOpenStudio"), vbDirectory) = "" Then
        MsgBox ("OpenStudio directory not found at: " & Range("DirOpenStudio") & "\nPlease change it on sheet 1 or install a version of OpenStudio.")
    End If

    If Range("PerimeterDepth") * 2 > WorksheetFunction.Min(Range("LAENGE"), Range("BREITE")) - 1 Then MsgBox "Fehler in der Geometrie-Eingabe: 'Tiefe Außenzonen' zu groß!": Exit Sub

    ' control flow variables
    Dim bPVSim As Boolean: bPVSim = False
    Dim bBuildingSim As Boolean: bBuildingSim = False
    Dim bGeneric As Boolean: bGeneric = False
    Dim bDetailedHVAC As Boolean: bDetailedHVAC = True

    Dim cb_buidlingsim As CheckBox
    Set cb_buidlingsim = Sheets("HAUPTSEITE").CheckBoxes("checkbox_buildingsim")
    Dim cb_pvSim As CheckBox
    Set cb_pvSim = Sheets("HAUPTSEITE").CheckBoxes("checkbox_pvsim")
    Dim cb_hvac As CheckBox
    Set cb_hvac = Sheets("Parameter").CheckBoxes("checkbox_hvac")

    If cb_hvac.Value = 1 Then
        bDetailedHVAC = False
        Range("IdealLoads").Offset(0, -1) = "IdealLoads"
    Else
        Range("IdealLoads").Offset(0, -1) = "DetailedHVAC"
    End If
    If Range("geometry_source") = 1 Then
        bGeneric = True
    End If
    If cb_buidlingsim.Value = 1 Then
        bBuildingSim = True
    End If
    If cb_pvSim.Value = 1 Then
        bPVSim = True
    End If
    
    If bPVSim = False And bBuildingSim = False Then
        MsgBox ("Bitte mindestens entweder Gebaeude oder PV Simulation auswaehlen")
        Sheets("HAUPTSEITE").Protect
        Exit Sub
    End If
    
    ' Jahreswerte
    Range("heating_annual") = "k.A."
    Range("cooling_annual") = "k.A."
    Range("lights_annual") = "k.A."
    Range("equipment_annual") = "k.A."
    Range("pumps_annual") = "k.A."
    Range("fans_annual") = "k.A."
    
    'Gebäudebilanz
    ' Range("SizingHeating") = "k.A."
    
    ' unmet Hours
    Range("unmethours_h") = "k.A."
    Range("unmethours_c") = "k.A."
    
    'Photovoltaik
    Range("pv_annual") = "k.A."
    Range("pv_annual_kWp") = "k.A."
    
    'Sizing
    Range("SizingHeating") = "k.A."
    Range("SizingCooling") = "k.A."

    ' export steps, measures and parameters to OSW file
    Dim interface As OSWFileInterface: Set interface = New OSWFileInterface
    Call interface.ExportToOSW(GetOutputFolder() & "\" + Range("FileName") + ".osw", False, bPVSim, bBuildingSim, bGeneric, bDetailedHVAC)

    ' status
    Range("Status").Offset(0, 1) = "beendet (" & WorksheetFunction.Round((Time - Startzeit_indv) * 86400, 1) & " s)"
    Startzeit_indv = Time

    ' running the open studio CLI
    Range("Status").Offset(1, 0) = "Modellerzeugung und Simulation"

    ' execute the OpenStudio CLI
    RunOpenStudioCLI.RunOpenStudioCLI

    ' execution time measurement
    Debug.Print Time
    Endzeit = Time
    'Ausgabe Simulationsdauer
    Range("calc_time") = Round((Endzeit - Startzeit) * 86400, 1) & " s (" & Round((Endzeit - Startzeit) * 86400 / 60, 1) & " min)"
    Range("sim_date") = Format(Now, "dd.mm.yyyy\ hh:mm")
    
    ' update pivot tables
    Call Aktualisieren_pivots

    Sheets("HAUPTSEITE").Protect
    
    Application.Calculation = xlCalculationAutomatic
    
End Sub

Sub DeactivateStatusInfoForPVOnlyRun()
    Range("GeomStatus") = "Deaktiviert"
    Range("UStatus") = "Deaktiviert"
    Range("LoadStatus") = "Deaktiviert"
    Range("IdealLoads") = "Deaktiviert"
    Range("ShadingControl") = "Deaktiviert"
    Range("Infiltration") = "Deaktiviert"
    Range("LightingControl") = "Deaktiviert"
    Range("TempSetpoint") = "Deaktiviert"
    Range("window_ventilation") = "Deaktiviert"
    Range("IDFIdealLoads") = "Deaktiviert"
End Sub
        
'Function RunMeasure(MeasureFile As String, MeasureName As String, sArgument As String) As String
'    Dim MeasurePath As String
'    MeasurePath = GetRubyPath & "ruby """ & GetMeasuresFolder() & "\" & MeasureFile & """ "
'
'    ' For debugging we can print out the path and arguments into a cell
'    '   range("Debug").Offset(iRow, 0) = MeasurePath
'    '   range("Debug").Offset(iRow, 1) = sArgument
'
'    ' update the progress messages
'    DoEvents
'
'    ' calling the measure
'    retval = ExecCmd(MeasurePath & " " & sArgument)
'    If retval > 0 Then
'        MsgBox "Fehler im " & MeasureName & ". Fehler Code: " & retval
'        RunMeasure = "Nicht erfolgreich"
'    Else
'        RunMeasure = "Erfolgreich"
'    End If
'
'        ' update the progress messages
'    DoEvents
'End Function
