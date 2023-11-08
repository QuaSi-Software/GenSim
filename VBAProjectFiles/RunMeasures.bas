Attribute VB_Name = "RunMeasures"
Dim iRow As Integer
Public Startzeit_indv As Variant

Sub ClearCells()
    ' Set status cells empty
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

    ' Set application path
    SetApplicationPath

    ' make the main sheet unprotected so we can read And write on it
    Sheets("HAUPTSEITE").Unprotect

    ' Set status cells empty
    Call ClearCells

    Range("Status").Offset(0, 0) = "OSW-file wird erzeugt"

    ' execution time measurement
    Startzeit = Time
    Startzeit_indv = Time
    DoEvents

    If Dir(Range("DirOpenStudio"), vbDirectory) = "" Then
        MsgBox ("OpenStudio directory Not found at: " & Range("DirOpenStudio") & "\nPlease change it on sheet 1 Or install a version of OpenStudio.")
    End If

    If Range("PerimeterDepth") * 2 > WorksheetFunction.Min(Range("LAENGE"), Range("BREITE")) - 1 Then MsgBox "Fehler in der Geometrie-Eingabe: 'Tiefe Auﬂenzonen' zu groﬂ!": Exit Sub

        ' control flow variables
        Dim bGeneric As Boolean: bGeneric = False
        Dim bDetailedHVAC As Boolean: bDetailedHVAC = True

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

        ' Jahreswerte
        Range("heating_annual") = "k.A."
        Range("cooling_annual") = "k.A."
        Range("lights_annual") = "k.A."
        Range("equipment_annual") = "k.A."
        Range("pumps_annual") = "k.A."
        Range("fans_annual") = "k.A."

        ' unmet Hours
        Range("unmethours_h") = "k.A."
        Range("unmethours_c") = "k.A."

        'Photovoltaik
        Range("pv_annual") = "k.A."
        Range("pv_annual_kWp") = "k.A."

        'Sizing
        Range("SizingHeating") = "k.A."
        Range("SizingCooling") = "k.A."

        ' export steps, measures And parameters To OSW file
        Dim interface As OSWFileInterface: Set interface = New OSWFileInterface
        Call interface.ExportToOSW(GetOutputFolder() & "\" + Range("FileName") + ".osw", bGeneric, True, bDetailedHVAC)

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
