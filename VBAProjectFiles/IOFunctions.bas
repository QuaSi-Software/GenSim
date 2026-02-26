Attribute VB_Name = "IOFunctions"
Public outputs As Scripting.Dictionary

Public Sub InitOutputs()
    Set outputs = New Scripting.Dictionary
    
    ' Add values
    outputs.Add "Heating", "Baseboard Total Heating Energy"
    outputs.Add "Cooling", "Zone Radiant HVAC Cooling Energy"
    outputs.Add "Lights", "METER LIGHTS ELECTRICITY"
    outputs.Add "Plugs", "METER PLUGS ELECTRICITY"
    outputs.Add "Fans", "METER FANS ELECTRICITY"
    outputs.Add "Pumps", "METER PUMPS ELECTRICITY"
    outputs.Add "UnmetHeat", "METER HEATING SETPOINT NOT MET"
    outputs.Add "UnmetCool", "METER COOLING SETPOINT NOT MET"
    ' losses
    outputs.Add "SurfaceHeatLoss", "Zone Opaque Surface Inside Faces Total Conduction Heat Loss Energy"
    outputs.Add "WindowHeatLoss", "Zone Windows Total Heat Loss Energy"
    outputs.Add "InfilHeatLoss", "Zone Infiltration Sensible Heat Loss Energy"
    outputs.Add "VentHeatLoss", "Zone Ventilation Sensible Heat Loss Energy"
    outputs.Add "AirCooling", "Zone Air Terminal Sensible Cooling Energy"
    ' gains
    outputs.Add "SurfaceHeatGain", "Zone Opaque Surface Inside Faces Total Conduction Heat Gain Energy"
    outputs.Add "WindowHeatGain", "Zone Windows Total Heat Gain Energy"
    outputs.Add "InfilHeatGain", "Zone Infiltration Sensible Heat Gain Energy"
    outputs.Add "VentHeatGain", "Zone Ventilation Sensible Heat Gain Energy"
    outputs.Add "PeopleGain", "Zone People Sensible Heating Energy"
    outputs.Add "AirHeating", "Zone Air Terminal Sensible Heating Energy"
    ' latent
    outputs.Add "InfilHeatLossLat", "Zone Infiltration Latent Heat Loss Energy"
    outputs.Add "VentHeatLossLat", "Zone Ventilation Latent Heat Loss Energy"
    outputs.Add "InfilHeatGainLat", "Zone Infiltration Latent Heat Gain Energy"
    outputs.Add "VentHeatGainLat", "Zone Ventilation Latent Heat Gain Energy"
    outputs.Add "PeopleGainLat", "Zone People Latent Gain Energy"
End Sub

Function Inc(ByRef data As Integer)
    data = data + 1
    Inc = data
End Function

Function CheckErrFile(filePath As String) As String
    If Dir(filePath) = "" Then
        MsgBox ("EnergyPlus did not run, no error file found!")
        CheckErrFile = "EnergyPlus did not run, no error file found!"
        Exit Function
    End If

    Dim txtStream As TextStream
    Dim fso As FileSystemObject: Set fso = New FileSystemObject
    Set txtStream = fso.OpenTextFile(filePath, ForReading, False)

    Dim line As String
    Do While Not txtStream.AtEndOfStream
        line = txtStream.ReadLine
        If InStr(line, "EnergyPlus Terminated") Then
            CheckErrFile = line
            txtStream.Close
            Exit Function
        ElseIf InStr(line, "EnergyPlus Completed") Then
            CheckErrFile = line
            txtStream.Close
            Exit Function
        End If
    Loop
    txtStream.Close
    CheckErrFile = ""
End Function

Function GetCSVResultFilesNames() As Collection
    Dim files As Collection
    Set files = New Collection
    ' the Results measure gives us six different files with results pre-calculated relative
    ' to different areas and summed up to annual values. however we only needs two of these
    ' and importing all of them results in poor performance

    ' files.Add Array("RawResults-gross-Sum", "results_report_variables_ZoneTimestep-gross-Sum.csv")
    ' files.Add Array("RawResults-gross", "results_report_variables_ZoneTimestep-gross.csv")
    files.Add Array("RawResults-net-Sum", "results_report_variables_ZoneTimestep-net-Sum.csv")
    files.Add Array("RawResults-net", "results_report_variables_ZoneTimestep-net.csv")
    ' files.Add Array("RawResults-Sum", "results_report_variables_ZoneTimestep-Sum.csv")
    ' files.Add Array("RawResults", "results_report_variables_ZoneTimestep.csv")

    Set GetCSVResultFilesNames = files
End Function

Sub DeleteResultSheets()
    Application.DisplayAlerts = False

    Dim file As Variant
    For Each file In GetCSVResultFilesNames()
        If CheckSheet(file(0)) Then
            Worksheets(file(0)).Delete
        End If
    Next file

    Application.DisplayAlerts = True
End Sub

Function ImportCSVFile(ByVal filePath As String, ByVal sheetName As String) As Boolean
    Workbooks.Open FileName:=filePath, Local:=False
    ', Semicolon:=False, Comma:=True, DecimalSeparator:="."
    ActiveSheet.Move After:=ThisWorkbook.Sheets(ThisWorkbook.Sheets.Count)
    ActiveSheet.name = sheetName

    Worksheets(sheetName).Visible = False

    ImportCSVFile = True
End Function

Function ImportCSVResultFiles(ByVal directory As String) As Boolean
    Application.ScreenUpdating = False

    Call DeleteResultSheets

    Dim file As Variant
    For Each file In GetCSVResultFilesNames()
        ImportCSVFile directory & "/" & file(1), file(0)
    Next file

    Worksheets("HAUPTSEITE").Activate

    Application.ScreenUpdating = True

    ImportCSVResultFiles = True
End Function

Function ParseEIOFile(filePath As String) As Boolean
    Application.ScreenUpdating = False

    Range("SizingHeating") = ""
    Range("SizingCooling") = ""
    Dim FileNum As Integer
    Dim DataLine As String

    On Error GoTo CleanFail
    FileNum = FreeFile()
    Open filePath For Input As #FileNum

    Dim bFound As Boolean
    Dim splitarray() As String
    bFound = False

    Dim dCoolingZone As Double: dCoolingZone = 0
    Dim dHeatingZone As Double: dHeatingZone = 0
    Dim dCoolingSystem As Double: dCoolingSystem = 0
    Dim dHeatingSystem As Double: dHeatingSystem = 0
    While Not EOF(FileNum)
        Line Input #FileNum, DataLine ' read in data 1 line at a time
        ' decide what to do with dataline,
        If InStr(DataLine, "Component Sizing Information") Then
            splitarray = Split(DataLine, ",")
            If InStr(splitarray(1), "DistrictCooling") Then
                bFound = True
                If Application.International(xlDecimalSeparator) = "," Then
                    dCoolingSystem = CDbl(Replace(splitarray(4), ".", ",")) / 1000
                Else
                    dCoolingSystem = CDbl(splitarray(4)) / 1000
                End If
            ElseIf InStr(splitarray(1), "DistrictHeating") Then
                bFound = True
                If Application.International(xlDecimalSeparator) = "," Then
                    dHeatingSystem = CDbl(Replace(splitarray(4), ".", ",")) / 1000
                Else
                    dHeatingSystem = CDbl(splitarray(4)) / 1000
                End If
            ElseIf InStr(splitarray(1), "DistrictHeating:Water") Then  ' name change in the later energyPlus versions
                bFound = True
                If Application.International(xlDecimalSeparator) = "," Then
                    dHeatingSystem = CDbl(Replace(splitarray(4), ".", ",")) / 1000
                Else
                    dHeatingSystem = CDbl(splitarray(4)) / 1000
                End If
            End If
        End If

        If InStr(DataLine, "Zone Sizing Information") Then
            splitarray = Split(DataLine, ",")
            If InStr(splitarray(2), "Cooling") Then
                bFound = True
                If Application.International(xlDecimalSeparator) = "," Then
                    dCoolingZone = dCoolingZone + CDbl(Replace(splitarray(4), ".", ",")) / 1000
                Else
                    dCoolingZone = dCoolingZone + CDbl(splitarray(4)) / 1000
                End If
            ElseIf InStr(splitarray(2), "Heating") Then
                bFound = True
                If Application.International(xlDecimalSeparator) = "," Then
                    dHeatingZone = dHeatingZone + CDbl(Replace(splitarray(4), ".", ",")) / 1000
                Else
                    dHeatingZone = dHeatingZone + CDbl(splitarray(4)) / 1000
                End If
            End If
        End If
    Wend

     ' NRF-Fläche
    Dim dBldgArea_NRF As Double
    If Range("geometry_source") = 1 Then
        dBldgArea_NRF = CDbl(Range("BldgArea_NRF"))
    Else
        dBldgArea_NRF = CDbl(Range("BldgArea_NRF_import"))
    End If

    Range("SizingCooling") = dCoolingZone / dBldgArea_NRF * 1000
    Range("SizingHeating") = dHeatingZone / dBldgArea_NRF * 1000

    Worksheets("HAUPTSEITE").Activate
    Application.ScreenUpdating = True

    ParseEIOFile = bFound
    
CleanExit:
    If FileNum > 0 Then
        Close #FileNum   ' always close the file
    End If
    Exit Function
    
CleanFail:
    ' Optional: log or show error
    ' MsgBox "Error in ParseEIOFile: " & Err.Description
    ParseEIOFile = False
    Resume CleanExit
End Function


Sub CreateResults()
    Dim finished As Boolean
    Dim colIndex As Long
    Dim col_heating As Long, col_cooling As Long, col_lights As Long, col_elec As Long, col_fans As Long, col_pumps As Long
    Dim rwIndex As Long, rwIndex_1h As Long
    Dim i As Long
    Dim PivotField As PivotField
    Dim cb_hvac As CheckBox
    Set cb_hvac = Sheets("Parameter").CheckBoxes("checkbox_hvac")

    Application.ScreenUpdating = False
    Sheets("GEBÄUDEBILANZ").Unprotect
    Sheets("HAUPTSEITE").Unprotect

    Dim sheet As Worksheet
    Set sheet = ThisWorkbook.Worksheets("RawResults-net")
    Dim j As Integer
    Dim iMaxCol As Integer
    
    InitOutputs

    'determine the number of output variables (iMaxCol)
    Do While finished <> True
        If sheet.Cells(1, Inc(j)) = "" Then
            iMaxCol = j - 1
            finished = True
        End If
    Loop
    Sheets("pivot").Range("BV1") = iMaxCol + 1
    Sheets("pivot").Range("BW1") = iMaxCol + 2

    'the number of rows depends only on the timestep
    Dim iMaxRow As Double
    iMaxRow = 60 / Range("Timestep") * 24 * 365 + 2

    'Read results into Array
    Dim ResultsNFA  As Variant
    ReDim ResultsNFA(1 To iMaxRow, 1 To iMaxCol)
    Dim ResultsNFAAnnual  As Variant
    ReDim ResultsNFAAnnual(1 To 2, 1 To iMaxCol)
    ResultsNFA = Sheets("RawResults-net").Range( _
        Sheets("RawResults-net").Cells(1, 1), _
        Sheets("RawResults-net").Cells(iMaxRow, iMaxCol) _
    )
    ResultsNFAAnnual = Sheets("RawResults-net-Sum").Range( _
        Sheets("RawResults-net-Sum").Cells(1, 1), _
        Sheets("RawResults-net-Sum").Cells(2, iMaxCol) _
    )

    'Find colums for faster indexing
    For colIndex = 1 To iMaxCol
        If (InStr(ResultsNFA(1, colIndex), outputs("Heating"))) Then col_heating = colIndex
        If (InStr(ResultsNFA(1, colIndex), outputs("Cooling"))) Then col_cooling = colIndex
        If (InStr(ResultsNFA(1, colIndex), outputs("Lights"))) Then col_lights = colIndex
        If (InStr(ResultsNFA(1, colIndex), outputs("Plugs"))) Then col_elec = colIndex
        If (InStr(ResultsNFA(1, colIndex), outputs("Fans"))) Then col_fans = colIndex
        If (InStr(ResultsNFA(1, colIndex), outputs("Pumps"))) Then col_pumps = colIndex
    Next

    ' Copy profiles into user-visible sheet
    Sheets("e+ Outputs").Range("A1:ZZ35100").Offset(5, 0).ClearContents
    Sheets("e+ Outputs").Range( _
            Sheets("e+ Outputs").Cells(1, 1), _
            Sheets("e+ Outputs").Cells(iMaxRow, iMaxCol) _
        ).Offset(5, 0) = ResultsNFA

    For colIndex = 2 To iMaxCol
        Sheets("e+ Outputs").Cells(iMaxRow + 5, colIndex) = ResultsNFAAnnual(2, colIndex - 1)
    Next

    '--------------------- NUTZENERGIE PROFILE
    '-------------------------------------------------------------

    Dim Results_Nutzenergie  As Variant
    ReDim Results_Nutzenergie(1 To iMaxRow + 1, 0 To 6)

    Dim Results_Nutzenergie_1h  As Variant
    ReDim Results_Nutzenergie_1h(1 To iMaxRow + 1, 1 To 6)

    '''''' Write selective Loadprofiles into Excel

    'Create Array with selected columns and the original timestep
    For rwIndex = 2 To (iMaxRow - 1)
        Results_Nutzenergie(rwIndex, 0) = ResultsNFA(rwIndex, 1)
        If Not IsEmpty(col_heating) Then Results_Nutzenergie(rwIndex, 1) = ResultsNFA(rwIndex, col_heating)
        If Not IsEmpty(col_cooling) Then Results_Nutzenergie(rwIndex, 2) = ResultsNFA(rwIndex, col_cooling)
        If Not IsEmpty(col_lights) Then Results_Nutzenergie(rwIndex, 3) = ResultsNFA(rwIndex, col_lights)
        If Not IsEmpty(col_elec) Then Results_Nutzenergie(rwIndex, 4) = ResultsNFA(rwIndex, col_elec)
        If Not IsEmpty(col_fans) Then Results_Nutzenergie(rwIndex, 5) = ResultsNFA(rwIndex, col_fans)
        If Not IsEmpty(col_pumps) Then Results_Nutzenergie(rwIndex, 6) = ResultsNFA(rwIndex, col_pumps)
    Next

    'Create Array with selected columns commulated in Wh/hour
    '[ACHTUNG : NICHT MEHR AGGREGIERT ]
    rwIndex_1h = 1
    For rwIndex = 1 To (iMaxRow - 2)
        If Not IsEmpty(col_heating) Then Results_Nutzenergie_1h(rwIndex_1h + 1, 1) = Results_Nutzenergie_1h(rwIndex_1h + 1, 1) + ResultsNFA(rwIndex + 1, col_heating)
        If Not IsEmpty(col_cooling) Then Results_Nutzenergie_1h(rwIndex_1h + 1, 2) = Results_Nutzenergie_1h(rwIndex_1h + 1, 2) + ResultsNFA(rwIndex + 1, col_cooling)
        If Not IsEmpty(col_lights) Then Results_Nutzenergie_1h(rwIndex_1h + 1, 3) = Results_Nutzenergie_1h(rwIndex_1h + 1, 3) + ResultsNFA(rwIndex + 1, col_lights)
        If Not IsEmpty(col_elec) Then Results_Nutzenergie_1h(rwIndex_1h + 1, 4) = Results_Nutzenergie_1h(rwIndex_1h + 1, 4) + ResultsNFA(rwIndex + 1, col_elec)
        If Not IsEmpty(col_fans) Then Results_Nutzenergie_1h(rwIndex_1h + 1, 5) = Results_Nutzenergie_1h(rwIndex_1h + 1, 5) + ResultsNFA(rwIndex + 1, col_fans)
        If Not IsEmpty(col_pumps) Then Results_Nutzenergie_1h(rwIndex_1h + 1, 6) = Results_Nutzenergie_1h(rwIndex_1h + 1, 6) + ResultsNFA(rwIndex + 1, col_pumps)

        rwIndex_1h = rwIndex_1h + 1
    Next

    'Names first row
    Results_Nutzenergie_1h(1, 1) = "Heizenergie [Wh/m²NRF]"
    Results_Nutzenergie(1, 1) = "Heizenergie [Wh/m²NRF]"

    Results_Nutzenergie_1h(1, 2) = "Kühlenergie [Wh/m²NRF]"
    Results_Nutzenergie(1, 2) = "Kühlenergie [Wh/m²NRF]"

    Results_Nutzenergie_1h(1, 3) = "Beleuchtung [Wh/m²NRF]"
    Results_Nutzenergie(1, 3) = "Beleuchtung [Wh/m²NRF]"

    Results_Nutzenergie_1h(1, 4) = "Elektrische Geräte [Wh/m²NRF]"
    Results_Nutzenergie(1, 4) = "Elektrische Geräte [Wh/m²NRF]"

    Results_Nutzenergie_1h(1, 5) = "Lüftungsstrom [Wh/m²NRF]"
    Results_Nutzenergie(1, 5) = "Lüftungsstrom [Wh/m²NRF]"

    Results_Nutzenergie_1h(1, 6) = "Pumpenstrom [Wh/m²NRF]"
    Results_Nutzenergie(1, 6) = "Pumpenstrom [Wh/m²NRF]"

    'Write into Excel Sheet
    Sheets("NUTZENERGIE PROFILE").Range("A6:F" & 35100).ClearContents
    Sheets("NUTZENERGIE PROFILE").Range("A6:G" & iMaxRow + 5) = Results_Nutzenergie

    Sheets("pivot").Range("D3:I" & 35100).ClearContents
    Sheets("pivot").Range("D3:I" & iMaxRow + 5) = Results_Nutzenergie_1h

    'Aggregierung in Pivot Table auf Summe ändern
    If Sheets("pivot").Range("A1") <> Energie Then
        For i = 1 To 6
            For Each PivotField In Sheets("pivot").PivotTables("PivotTable" & i).DataFields
                With PivotField
                    .Function = xlSum
                End With
             Next
        Next
        ' Achsenbeschriftung
        Sheets("ANSICHT PROFILE").Unprotect
        For Each ChartObj In Sheets("ANSICHT PROFILE").ChartObjects
            With ChartObj
                .chart.Axes(xlValue, xlPrimary).HasTitle = True
                .chart.Axes(xlValue, xlPrimary).AxisTitle.Characters.text = Replace(.chart.Axes(xlValue, xlPrimary).AxisTitle.Characters.text, "W/", "Wh/")
            End With
        Next
        Sheets("ANSICHT PROFILE").Protect
        Sheets("pivot").Range("A1") = "Energie"
    End If

    ' '--------------------- Übersicht Gebäudebilanz
    ' '-------------------------------------------------------------

    Range("heating_annual") = "0"
    Range("cooling_annual") = "0"
    Range("lights_annual") = "0"
    Range("equipment_annual") = "0"
    Range("pumps_annual") = "0"
    Range("fans_annual") = "0"

    For colIndex = 1 To iMaxCol
        'Basic Output
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("Heating"))) Then Range("heating_annual") = ResultsNFAAnnual(2, colIndex) * 0.001
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("Cooling"))) Then Range("cooling_annual") = ResultsNFAAnnual(2, colIndex) * 0.001
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("Lights"))) Then Range("lights_annual") = ResultsNFAAnnual(2, colIndex) * 0.001
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("Plugs"))) Then Range("equipment_annual") = ResultsNFAAnnual(2, colIndex) * 0.001
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("Pumps"))) Then Range("pumps_annual") = ResultsNFAAnnual(2, colIndex) * 0.001
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("Fans"))) Then Range("fans_annual") = ResultsNFAAnnual(2, colIndex) * 0.001
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("UnmetHeat"))) Then Sheets("HAUPTSEITE").Range("unmethours_h") = ResultsNFAAnnual(2, colIndex)
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("UnmetCool"))) Then Sheets("HAUPTSEITE").Range("unmethours_c") = ResultsNFAAnnual(2, colIndex)
    Next

    '------ Liste Gebäudebilanz

    Sheets("GEBÄUDEBILANZ").Range("N10:N14") = Array(0, 0, 0, 0, 0)
    Sheets("GEBÄUDEBILANZ").Range("N18:N25") = Array(0, 0, 0, 0, 0, 0, 0, 0)

    For colIndex = 1 To iMaxCol
        'Verluste
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("SurfaceHeatLoss"))) Then Sheets("GEBÄUDEBILANZ").Range("N10") = ResultsNFAAnnual(2, colIndex) * -1 * 0.001
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("WindowHeatLoss"))) Then Sheets("GEBÄUDEBILANZ").Range("N11") = ResultsNFAAnnual(2, colIndex) * -1 * 0.001
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("InfilHeatLoss"))) Then Sheets("GEBÄUDEBILANZ").Range("N12") = ResultsNFAAnnual(2, colIndex) * -1 * 0.001
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("VentHeatLoss"))) Then Sheets("GEBÄUDEBILANZ").Range("N13") = ResultsNFAAnnual(2, colIndex) * -1 * 0.001
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("AirCooling"))) Then Sheets("GEBÄUDEBILANZ").Range("N14") = ResultsNFAAnnual(2, colIndex) * -1 * 0.001

        'Gewinne
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("SurfaceHeatGain"))) Then Sheets("GEBÄUDEBILANZ").Range("N18") = ResultsNFAAnnual(2, colIndex) * 0.001
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("WindowHeatGain"))) Then Sheets("GEBÄUDEBILANZ").Range("N19") = ResultsNFAAnnual(2, colIndex) * 0.001
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("InfilHeatGain"))) Then Sheets("GEBÄUDEBILANZ").Range("N20") = ResultsNFAAnnual(2, colIndex) * 0.001
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("VentHeatGain"))) Then Sheets("GEBÄUDEBILANZ").Range("N21") = ResultsNFAAnnual(2, colIndex) * 0.001
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("Plugs"))) Then Sheets("GEBÄUDEBILANZ").Range("N22") = ResultsNFAAnnual(2, colIndex) * 0.001
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("Lights"))) Then Sheets("GEBÄUDEBILANZ").Range("N23") = ResultsNFAAnnual(2, colIndex) * 0.001
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("PeopleGain"))) Then Sheets("GEBÄUDEBILANZ").Range("N24") = ResultsNFAAnnual(2, colIndex) * 0.001
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("AirHeating"))) Then Sheets("GEBÄUDEBILANZ").Range("N25") = ResultsNFAAnnual(2, colIndex) * 0.001
        
        ' heating and cooling
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("Heating"))) Then Sheets("GEBÄUDEBILANZ").Range("N31") = ResultsNFAAnnual(2, colIndex) * 0.001
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("Cooling"))) Then Sheets("GEBÄUDEBILANZ").Range("N32") = ResultsNFAAnnual(2, colIndex) * -1 * 0.001
        
        ' latent
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("InfilHeatLossLat"))) Then Sheets("GEBÄUDEBILANZ").Range("P12") = ResultsNFAAnnual(2, colIndex) * -1 * 0.001
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("VentHeatLossLat"))) Then Sheets("GEBÄUDEBILANZ").Range("P13") = ResultsNFAAnnual(2, colIndex) * -1 * 0.001
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("InfilHeatGainLat"))) Then Sheets("GEBÄUDEBILANZ").Range("P20") = ResultsNFAAnnual(2, colIndex) * 0.001
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("VentHeatGainLat"))) Then Sheets("GEBÄUDEBILANZ").Range("P21") = ResultsNFAAnnual(2, colIndex) * 0.001
        If (InStr(ResultsNFAAnnual(1, colIndex), outputs("PeopleGainLat"))) Then Sheets("GEBÄUDEBILANZ").Range("P24") = ResultsNFAAnnual(2, colIndex) * 0.001
    Next

    '------------------------
    Sheets("GEBÄUDEBILANZ").Protect
    Application.ScreenUpdating = True
End Sub

Sub DiagLeistung(leistung As Boolean)

    'Diagramme
    Dim TB_diag As Worksheet: Set TB_diag = Sheets("ANSICHT PROFILE")
    Dim ChartObj As ChartObject
    'Pivot Tables
    Dim TB_pivot As Worksheet: Set TB_pivot = Sheets("pivot")
    Dim pt As PivotTable
    Dim PivotField As PivotField

    Dim iMaxRow As Double
    iMaxRow = 60 / Range("Timestep") * 24 * 365

    Dim Results_Nutzenergie  As Variant
    'ReDim Results_Nutzenergie(0 To iMaxRow, 1 To 7)

    Dim Results_Nutzenergie_out  As Variant
    ReDim Results_Nutzenergie_out(1 To iMaxRow, 1 To 6)

    'Blattschutz und Excel-Berechnung
    TB_diag.Unprotect
    Application.Calculation = xlCalculationManual

    Results_Nutzenergie = Sheets("pivot").Range("D4:J" & iMaxRow + 3)

    berechnet = False

    If leistung And Sheets("pivot").Range("A1") = "Energie" Then
        'Umrechnung in Leistung [W]
        For rwIndex = 1 To iMaxRow
            For colIndex = 1 To 6
                Results_Nutzenergie_out(rwIndex, colIndex) = Results_Nutzenergie(rwIndex, colIndex) / (Range("Timestep") / 60)
            Next
        Next
        'Aggregierung in Pivot Table auf Mitterlwert ändern
        For i = 1 To 6
            For Each PivotField In TB_pivot.PivotTables("PivotTable" & i).DataFields
                With PivotField
                    .Function = xlAverage
                End With
            Next
        Next
        Sheets("pivot").Range("A1") = "Leistung"
        berechnet = True
    ElseIf Not leistung And Sheets("pivot").Range("A1") = "Leistung" Then
        'Umrechnung in Energie [Wh]
        For rwIndex = 1 To iMaxRow
            For colIndex = 1 To 6
                Results_Nutzenergie_out(rwIndex, colIndex) = Results_Nutzenergie(rwIndex, colIndex) * (Range("Timestep") / 60)
            Next
        Next
        'Aggregierung in Pivot Table auf Summe ändern
        For i = 1 To 6
            For Each PivotField In TB_pivot.PivotTables("PivotTable" & i).DataFields
                With PivotField
                    .Function = xlSum
                End With
             Next
        Next
        Sheets("pivot").Range("A1") = "Energie"
        berechnet = True
    End If

    If berechnet Then
        'Excel Tabelle schreiben
        Sheets("pivot").Range("D4:J" & iMaxRow + 3) = Results_Nutzenergie_out
        'Diagramm-Achsen ändern
        For Each ChartObj In TB_diag.ChartObjects
            If leistung Then
                With ChartObj
                    .chart.Axes(xlValue, xlPrimary).HasTitle = True
                    .chart.Axes(xlValue, xlPrimary).AxisTitle.Characters.text = Replace(.chart.Axes(xlValue, xlPrimary).AxisTitle.Characters.text, "Wh/", "W/")
                End With
            Else
                With ChartObj
                    .chart.Axes(xlValue, xlPrimary).HasTitle = True
                    .chart.Axes(xlValue, xlPrimary).AxisTitle.Characters.text = Replace(.chart.Axes(xlValue, xlPrimary).AxisTitle.Characters.text, "W/", "Wh/")
                End With
            End If
        Next
        'Pivot Table aktualisieren
        Call Aktualisieren_pivots
    End If

    'Blattschutz und Excel-Berechnung
    TB_diag.Protect
    Application.Calculation = xlCalculationAutomatic

End Sub

Function CheckSheet(ByVal sSheetName As String) As Boolean

    Dim oSheet As Excel.Worksheet
    Dim bReturn As Boolean

    For Each oSheet In ActiveWorkbook.Sheets

        If oSheet.name = sSheetName Then
            bReturn = True
            Exit For
        End If

    Next oSheet

    CheckSheet = bReturn

End Function
