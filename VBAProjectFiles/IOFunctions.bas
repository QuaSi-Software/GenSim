Attribute VB_Name = "IOFunctions"

Dim constList(0 To 29) As String

Const METER_HEATING = "DistrictHeating:Facility"
Const METER_COOLING = "DistrictCooling:Facility"

Const METER_ELECTRICITY_LIGHTS = "InteriorLights:Electricity"
Const METER_ELECTRICITY_PLUGS = "InteriorEquipment:Electricity"

Const METER_ELECTRICITY_FANS = "Fans:Electricity"
Const METER_ELECTRICITY_PUMPS = "Pumps:Electricity"

Const METER_ZONE_PLUGS = "METER ZONE ELECTRIC EQUIPMENT TOTAL HEATING ENERGY"
Const METER_ZONE_LIGHTS = "METER ZONE LIGHTS TOTAL HEATING ENERGY"
Const METER_ZONE_PEOPLE = "METER PEOPLE TOTAL HEATING ENERGY"

Const METER_WINDOW_SURFACE_HEAT_GAIN = "METER SURFACE WINDOW HEAT GAIN ENERGY"
Const METER_WINDOW_SURFACE_HEAT_LOSS = "METER SURFACE WINDOW HEAT LOSS ENERGY"

Const METER_INTERNAL_LOADS = "METER INTERNAL LOADS HEATING ENERGY"

Const METER_SURFACE_FACE_CONDUCTION_TOTAL = "METER SURFACE AVERAGE FACE CONDUCTION HEAT TRANSFER ENERGY"

Const METER_INFILTRATION_HEAT_LOSS = "METER ZONE INFILTRATION HEAT LOSS"
Const METER_INFILTRATION_HEAT_GAIN = "METER ZONE INFILTRATION HEAT GAIN"
Const METER_VENTILATION_HEAT_LOSS = "METER ZONE VENTILATION HEAT LOSS"
Const METER_VENTILATION_HEAT_GAIN = "METER ZONE VENTILATION HEAT GAIN"

'Mechanische Lüftung
Const Zone_Mechanical_Ventilation_Cooling_Load_Increase_Energy = "METER MECHANICAL VENTILATION GAIN"
Const Zone_Mechanical_Ventilation_No_Load_Heat_Removal_Energy = "METER MECHANICAL VENTILATION LOSS"

Const METER_ELECTRICITY_PV = "Photovoltaic:ElectricityProduced"
Const METER_ELECTRICITY_PRODUCED = "ElectricityProduced:Plant"

Const FACILITY_HEATING_SEPOINT_NOT_MET = "Facility Heating Setpoint Not Met Time"
Const FACILITY_HEATING_SEPOINT_NOT_MET_OCC = "Facility Heating Setpoint Not Met While Occupied Time"
Const FACILITY_COOLING_SEPOINT_NOT_MET = "Facility Cooling Setpoint Not Met Time"
Const FACILITY_COOLING_SEPOINT_NOT_MET_OCC = "Facility Cooling Setpoint Not Met While Occupied Time"

'Zonen
Const ZONE_MEAN_AIR_TEMPERATURE = "Zone Mean Air Temperature"
Const ZONE_HEATING_SEPOINT_NOT_MET = "Zone Heating Setpoint Not Met Time"
Const ZONE_HEATING_SEPOINT_NOT_MET_OCC = "Zone Heating Setpoint Not Met While Occupied Time"
Const ZONE_COOLING_SEPOINT_NOT_MET = "Zone Cooling Setpoint Not Met Time"
Const ZONE_COOLING_SEPOINT_NOT_MET_OCC = "Zone Cooling Setpoint Not Met While Occupied Time"


Sub AssembleConstList()
    Dim i As Integer
    i = -1
    constList(Inc(i)) = METER_HEATING
    constList(Inc(i)) = METER_COOLING
    
    constList(Inc(i)) = METER_ELECTRICITY_LIGHTS
    constList(Inc(i)) = METER_ELECTRICITY_PLUGS
    
    constList(Inc(i)) = METER_ELECTRICITY_FANS
    constList(Inc(i)) = METER_ELECTRICITY_PUMPS
    
    constList(Inc(i)) = METER_ZONE_PLUGS
    constList(Inc(i)) = METER_ZONE_LIGHTS
    constList(Inc(i)) = METER_ZONE_PEOPLE
    
    constList(Inc(i)) = METER_WINDOW_SURFACE_HEAT_GAIN
    constList(Inc(i)) = METER_WINDOW_SURFACE_HEAT_LOSS
    
    constList(Inc(i)) = METER_INTERNAL_LOADS
    
    constList(Inc(i)) = METER_SURFACE_FACE_CONDUCTION_TOTAL
    
    constList(Inc(i)) = METER_INFILTRATION_HEAT_LOSS
    constList(Inc(i)) = METER_INFILTRATION_HEAT_GAIN
    constList(Inc(i)) = METER_VENTILATION_HEAT_LOSS
    constList(Inc(i)) = METER_VENTILATION_HEAT_GAIN
    
    constList(Inc(i)) = Zone_Mechanical_Ventilation_Cooling_Load_Increase_Energy
    constList(Inc(i)) = Zone_Mechanical_Ventilation_No_Load_Heat_Removal_Energy
    
    constList(Inc(i)) = METER_ELECTRICITY_PV
    constList(Inc(i)) = METER_ELECTRICITY_PRODUCED
    
    constList(Inc(i)) = FACILITY_HEATING_SEPOINT_NOT_MET
    constList(Inc(i)) = FACILITY_HEATING_SEPOINT_NOT_MET_OCC
    constList(Inc(i)) = FACILITY_COOLING_SEPOINT_NOT_MET
    constList(Inc(i)) = FACILITY_COOLING_SEPOINT_NOT_MET_OCC
    
    Dim cb_detailed_zone_Results As CheckBox
    Set cb_detailed_zone_Results = Sheets("Parameter").CheckBoxes("checkbox_ZoneDetails")
    detailed_zone_Results = cb_detailed_zone_Results.Value = 1
    
    If detailed_zone_Results Then
        constList(Inc(i)) = ZONE_MEAN_AIR_TEMPERATURE
        constList(Inc(i)) = ZONE_HEATING_SEPOINT_NOT_MET
        constList(Inc(i)) = ZONE_HEATING_SEPOINT_NOT_MET_OCC
        constList(Inc(i)) = ZONE_COOLING_SEPOINT_NOT_MET
        constList(Inc(i)) = ZONE_COOLING_SEPOINT_NOT_MET_OCC
    Else
        constList(Inc(i)) = ""
        constList(Inc(i)) = ""
        constList(Inc(i)) = ""
        constList(Inc(i)) = ""
        constList(Inc(i)) = ""
    End If
    
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

Function ConvertESOFile(filePath As String) As Boolean
    AssembleConstList
    
    Dim rviFile As String
    rviFile = GetOutputFolder() + "\Rvi.rvi"
    
    Dim fso As Object
    Set fso = CreateObject("Scripting.FileSystemObject")
    Dim oFile As Object
    Set oFile = fso.CreateTextFile(rviFile)
    oFile.WriteLine filePath
    oFile.WriteLine Replace(filePath, ".eso", ".csv")
    For Each item In constList
        oFile.WriteLine item
    Next item
    oFile.WriteLine "0"
    oFile.Close
    Set fso = Nothing
    Set oFile = Nothing
    
    retval = ExecCmd(Application.ActiveWorkbook.path + "\ReadVarsEso\ReadVarsEso.exe " + Chr(34) + rviFile + Chr(34) + " unlimited ")
    If retval > 0 Then
        MsgBox "Fehler waehrend der Generation der CSV Datei, Fehler Code: " & retval
        Range("SimStatus") = "Simulation nicht erfolgreich"
        ConvertESOFile = False
    Else
        ConvertESOFile = True
    End If
End Function

Function ImportCSVFileNEW(filePath As String) As Boolean

    Application.ScreenUpdating = False
    
    If CheckSheet("RawResults") Then
        Application.DisplayAlerts = False
        Worksheets("RawResults").Delete
        Application.DisplayAlerts = True
    End If
    
    Workbooks.Open filename:=filePath, Local:=False
    ', Semicolon:=False, Comma:=True, DecimalSeparator:="."
    ActiveSheet.Move After:=ThisWorkbook.Sheets(ThisWorkbook.Sheets.Count)
    ActiveSheet.name = "RawResults"
          
    Worksheets("HAUPTSEITE").Activate
    Worksheets("RawResults").Visible = False
    
    Application.ScreenUpdating = True
    
    ImportCSVFileNEW = True
End Function

Function ParseEIOFile(filePath As String) As Boolean
    Application.ScreenUpdating = False
    
    Range("SizingHeating") = ""
    Range("SizingCooling") = ""
    Dim FileNum As Integer
    Dim DataLine As String
    
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
    'Range("SizingCooling").Offset(0, 2) = dCoolingSystem
    'Range("SizingHeating").Offset(0, 2) = dHeatingSystem
    
    Worksheets("HAUPTSEITE").Activate
    Worksheets("RawResults").Visible = False
    
    Application.ScreenUpdating = True
    
    ParseEIOFile = bFound
End Function


Sub CreateResults()
    
    Dim cb_hvac As CheckBox
    Set cb_hvac = Sheets("Parameter").CheckBoxes("checkbox_hvac")
    
    Application.ScreenUpdating = False
    Sheets("GEBÄUDEBILANZ").Unprotect
    Sheets("HAUPTSEITE").Unprotect
    
    Dim sheet As Worksheet
    Set sheet = ThisWorkbook.Worksheets("RawResults")
    Dim j As Integer
    Dim iMaxCol As Integer
    
    'determine the number of output variables (iMaxCol)
    Do While finished <> True
        If sheet.Cells(1, Inc(j)) = "" Then
            iMaxCol = j - 1
            finished = True
        End If
    Loop
    Sheets("pivot").Range("BZ1") = iMaxCol + 1
    Sheets("pivot").Range("CA1") = iMaxCol + 2
    
    'iMaxRow
    Dim iMaxRow As Double
    iMaxRow = 60 / Range("Timestep") * 24 * 365 + 2
    'If cb_hvac.Value = 1 Then iMaxRow = iMaxRow + 3 * 24 * (60 / Range("Timestep")) 'bei Ideals Loads werden die DesignDays mit ausgegeben!
    
    Dim RawResults  As Variant
    ReDim RawResults(1 To iMaxRow, 1 To iMaxCol)
    Dim Results  As Variant
    ReDim Results(1 To iMaxRow, 1 To iMaxCol + 2)
    
    'Quick and dirty Bugfix Designdays
    If Left(Sheets("RawResults").Range("A2"), 6) <> " 01/01" Then
        Do While Left(Sheets("RawResults").Range("A2"), 6) <> " 01/01"
            Sheets("RawResults").Rows(2 & ":" & 24 * 60 / Range("Timestep") + 1).Delete
        Loop
    End If
    
    ''''''Read RawResults into Array
    RawResults = Sheets("RawResults").Range(Sheets("RawResults").Cells(1, 1), Sheets("RawResults").Cells(iMaxRow, iMaxCol))
    
    '--------------------- ALLE PROFILE
    '-------------------------------------------------------------
    
    ''''''Calculate Results in kWh/m
    
    ' NRF-Fläche
    Dim dBldgArea_NRF As Double
    Dim dBldgArea_BGF As Double
    If Range("geometry_source") = 1 Then
        dBldgArea_NRF = CDbl(Range("BldgArea_NRF"))
        dBldgArea_BGF = Range("BldgArea")
    Else
        dBldgArea_NRF = CDbl(Range("BldgArea_NRF_import"))
        dBldgArea_BGF = CDbl(Range("BldgArea_import"))
    End If
        
    Dim dAnnualResult() As Double
    ReDim dAnnualResult(iMaxCol + 4) As Double
    
    For rwIndex = 1 To iMaxRow
    
'        'Überspringen von 3 Design Days bei IdealsLoads! (UNVOLLSTÄNDIG)
'        If cb_hvac.Value = 1 Then
'            If rwIndex = 1 Then
'                rwIndex_rawresults = 1
'            Else
'                rwIndex_rawresults = rwIndex + 3 * 24 * (60 / Range("Timestep"))
'            End If
'        End If
    
        For colIndex = 1 To iMaxCol
            If RawResults(1, colIndex) <> "" Then
                If rwIndex = 1 Or colIndex = 1 Then     'IN ZEILE 1 ODER SPALTE 1 -> Beschriftung!!!
                    If (InStr(RawResults(rwIndex, colIndex), "Plant")) Or (InStr(RawResults(rwIndex, colIndex), "Photovoltaic")) Then 'PV Spaltenbeschriftung
                        Results(rwIndex, colIndex) = Replace(RawResults(rwIndex, colIndex), "[J](TimeStep)", "[Wh/m²PV]")
                    ElseIf (InStr(RawResults(rwIndex, colIndex), "J")) Then
                        Results(rwIndex, colIndex) = Replace(RawResults(rwIndex, colIndex), "[J](TimeStep)", "[Wh/m²NRF]")    'alles weitere Spaltenbeschriftung
                    Else
                        Results(rwIndex, colIndex) = RawResults(rwIndex, colIndex) 'Datumsspalte komplett übernehmen
                    End If
                    If rwIndex = iMaxRow Then Results(rwIndex, colIndex) = "Jahressumme [Wh/m²a]" 'Letzte Zeile "Beschriftung"
                Else                                    'IN ZEILE 2-X UND SPALTE 2-X
                    If (InStr(RawResults(1, colIndex), "Plant")) Or (InStr(RawResults(1, colIndex), "Photovoltaic")) Then    'Wenn Spalte Photovoltaik Umrechnung von J in Wh
                        Results(rwIndex, colIndex) = RawResults(rwIndex, colIndex) / 3600
                    ElseIf InStr(RawResults(1, colIndex), "Temperature") Or InStr(RawResults(1, colIndex), "Not Met") Then 'Spalten Temperaturen oder Unmet Hours keine Umrechnung
                        Results(rwIndex, colIndex) = RawResults(rwIndex, colIndex)
                        'Temperatur Min/Max
                        If InStr(RawResults(1, colIndex), "Temperature") Then
                            Results(rwIndex, iMaxCol + 1) = WorksheetFunction.Max(RawResults(rwIndex, colIndex), Results(rwIndex, iMaxCol + 1))
                            If Results(rwIndex, iMaxCol + 2) = 0 Then
                                Results(rwIndex, iMaxCol + 2) = RawResults(rwIndex, colIndex)
                            Else
                                Results(rwIndex, iMaxCol + 2) = WorksheetFunction.Min(RawResults(rwIndex, colIndex), Results(rwIndex, iMaxCol + 2))
                            End If
                        End If
                    'ElseIf InStr(RawResults(1, colIndex), "Fans") Then
                        'Results(rwIndex, colIndex) = RawResults(rwIndex, colIndex) / 3600 / dBldgArea_BGF    'Ventilatorstrom muss auf BGF bezogen werden!!!
                    Else
                        Results(rwIndex, colIndex) = RawResults(rwIndex, colIndex) / 3600 / dBldgArea_NRF    'alles weitere Umrechnung von J in Wh/m²NRF
                    End If
                    
                    'Jahressummen
                    dAnnualResult(colIndex) = dAnnualResult(colIndex) + Results(rwIndex, colIndex) / 1000 ' Jahressumme und Umrechnung von Wh/m² in kWh/m²
                    If rwIndex = iMaxRow Then
                        Results(rwIndex, colIndex) = dAnnualResult(colIndex)  'in die letzte Zeile die Jahressumme schreiben!
                    Else
                        'Transmission -> LOSS/GAIN
                        If (InStr(RawResults(1, colIndex), "CONDUCTION HEAT TRANSFER ENERGY ")) Then
                            If Results(rwIndex, colIndex) < 0 Then
                                dAnnualResult(iMaxCol + 1) = dAnnualResult(iMaxCol + 1) + Results(rwIndex, colIndex) / 1000
                            Else
                                dAnnualResult(iMaxCol + 2) = dAnnualResult(iMaxCol + 2) + Results(rwIndex, colIndex) / 1000
                            End If
                        End If
                        
                        'UnmetHours Jahreswerte
                        If (InStr(RawResults(1, colIndex), "Facility Heating Setpoint Not Met While")) Then
                            dAnnualResult(iMaxCol + 3) = dAnnualResult(iMaxCol + 3) + Results(rwIndex, colIndex)
                        ElseIf (InStr(RawResults(1, colIndex), "Facility Cooling Setpoint Not Met While")) Then
                            dAnnualResult(iMaxCol + 4) = dAnnualResult(iMaxCol + 4) + Results(rwIndex, colIndex)
                        End If
                    End If
                    
                End If 'Beschriftung oder Daten
            Else 'RawResults(1, colINdex) <> ""
                Results(rwIndex, colIndex) = ""
            End If
        Next 'col
    Next 'row
    
    ''''''Write Loadprofils into Excel
    Sheets("e+ Outputs").Range("A1:ZZ35100").Offset(5, 0).ClearContents
    Sheets("e+ Outputs").Range(Sheets("e+ Outputs").Cells(1, 1), Sheets("e+ Outputs").Cells(iMaxRow, iMaxCol + 2)).Offset(5, 0) = Results
    
    '--------------------- NUTZENERGIE PROFILE
    '-------------------------------------------------------------
    
    Dim Results_Nutzenergie  As Variant
    ReDim Results_Nutzenergie(1 To iMaxRow + 1, 0 To 7)
    
    Dim Results_Nutzenergie_1h  As Variant
    ReDim Results_Nutzenergie_1h(1 To iMaxRow + 1, 1 To 7)
    'ReDim Results_Nutzenergie_1h(1 To 8760 + 1, 1 To 7)
    
    '''''' Write selective Loadprofiles into Excel
    
    'Find colums
    For colIndex = 1 To iMaxCol
        If (InStr(Results(1, colIndex), METER_HEATING)) Then col_heating = colIndex
        If (InStr(Results(1, colIndex), METER_COOLING)) Then col_cooling = colIndex
        If (InStr(Results(1, colIndex), METER_ELECTRICITY_LIGHTS)) Then col_lights = colIndex
        If (InStr(Results(1, colIndex), METER_ELECTRICITY_PLUGS)) Then col_elec = colIndex
        If (InStr(Results(1, colIndex), METER_ELECTRICITY_PRODUCED)) Then col_pv = colIndex
        If (InStr(Results(1, colIndex), METER_ELECTRICITY_FANS)) Then col_fans = colIndex
        If (InStr(Results(1, colIndex), METER_ELECTRICITY_PUMPS)) Then col_pumps = colIndex
    Next
    
    'Create Array with selected columns and the original timestep
    For rwIndex = 2 To (iMaxRow - 1)
        Results_Nutzenergie(rwIndex, 0) = Results(rwIndex, 1)
        If Not IsEmpty(col_heating) Then Results_Nutzenergie(rwIndex, 1) = Results(rwIndex, col_heating)
        If Not IsEmpty(col_cooling) Then Results_Nutzenergie(rwIndex, 2) = Results(rwIndex, col_cooling)
        If Not IsEmpty(col_lights) Then Results_Nutzenergie(rwIndex, 3) = Results(rwIndex, col_lights)
        If Not IsEmpty(col_elec) Then Results_Nutzenergie(rwIndex, 4) = Results(rwIndex, col_elec)
        If Not IsEmpty(col_fans) Then Results_Nutzenergie(rwIndex, 5) = Results(rwIndex, col_fans)
        If Not IsEmpty(col_pumps) Then Results_Nutzenergie(rwIndex, 6) = Results(rwIndex, col_pumps)
        If Not IsEmpty(col_pv) Then Results_Nutzenergie(rwIndex, 7) = Results(rwIndex, col_pv)
    Next
    
    'Create Array with selected columns commulated in Wh/hour
    '[ACHTUNG : NICHT MEHR AGGREGIERT ]
    rwIndex_1h = 1
    For rwIndex = 1 To (iMaxRow - 2)
        If Not IsEmpty(col_heating) Then Results_Nutzenergie_1h(rwIndex_1h + 1, 1) = Results_Nutzenergie_1h(rwIndex_1h + 1, 1) + Results(rwIndex + 1, col_heating)
        If Not IsEmpty(col_cooling) Then Results_Nutzenergie_1h(rwIndex_1h + 1, 2) = Results_Nutzenergie_1h(rwIndex_1h + 1, 2) + Results(rwIndex + 1, col_cooling)
        If Not IsEmpty(col_lights) Then Results_Nutzenergie_1h(rwIndex_1h + 1, 3) = Results_Nutzenergie_1h(rwIndex_1h + 1, 3) + Results(rwIndex + 1, col_lights)
        If Not IsEmpty(col_elec) Then Results_Nutzenergie_1h(rwIndex_1h + 1, 4) = Results_Nutzenergie_1h(rwIndex_1h + 1, 4) + Results(rwIndex + 1, col_elec)
        If Not IsEmpty(col_fans) Then Results_Nutzenergie_1h(rwIndex_1h + 1, 5) = Results_Nutzenergie_1h(rwIndex_1h + 1, 5) + Results(rwIndex + 1, col_fans)
        If Not IsEmpty(col_pumps) Then Results_Nutzenergie_1h(rwIndex_1h + 1, 6) = Results_Nutzenergie_1h(rwIndex_1h + 1, 6) + Results(rwIndex + 1, col_pumps)
        If Not IsEmpty(col_pv) Then Results_Nutzenergie_1h(rwIndex_1h + 1, 7) = Results_Nutzenergie_1h(rwIndex_1h + 1, 7) + Results(rwIndex + 1, col_pv)

'        If rwIndex - rwIndex_alt = (60 / Range("Timestep")) Then
'            rwIndex_1h = rwIndex_1h + 1
'            rwIndex_alt = rwIndex
'        End If

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
    
    Results_Nutzenergie_1h(1, 7) = "PV-Ertrag [Wh/m²PV]"
    Results_Nutzenergie(1, 7) = "PV-Ertrag [Wh/m²PV]"
    
       
    'Write into Excel Sheet
    Sheets("NUTZENERGIE PROFILE").Range("A6:F" & 35100).ClearContents
    Sheets("NUTZENERGIE PROFILE").Range("A6:H" & iMaxRow + 5) = Results_Nutzenergie
    
    Sheets("pivot").Range("D3:J" & 35100).ClearContents
    Sheets("pivot").Range("D3:J" & iMaxRow + 5) = Results_Nutzenergie_1h
    
    Sheets("HAUPTSEITE").Range("unmethours_h") = dAnnualResult(iMaxCol + 3)
    Sheets("HAUPTSEITE").Range("unmethours_c") = dAnnualResult(iMaxCol + 4)
    
    'Aggregierung in Pivot Table auf Summe ändern
    If Sheets("pivot").Range("A1") <> Energie Then
        For i = 1 To 7
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
    
    '--------------------- Übersicht Gebäudebilanz
    '-------------------------------------------------------------
    
    'Reset
    Range("heating_annual") = ""
    Range("cooling_annual") = ""
    Range("lights_annual") = ""
    Range("equipment_annual") = ""
    
    Range("pv_annual") = ""
    Range("pv_annual_kWp") = ""
    
    Range("pumps_annual") = ""
    Range("fans_annual") = ""
    
    For colIndex = 1 To iMaxCol
        'Basic Output
        If (InStr(Results(1, colIndex), METER_HEATING)) Then Range("heating_annual") = Results(iMaxRow, colIndex)
        If (InStr(Results(1, colIndex), METER_COOLING)) Then Range("cooling_annual") = Results(iMaxRow, colIndex)
        If (InStr(Results(1, colIndex), METER_ELECTRICITY_LIGHTS)) Then Range("lights_annual") = Results(iMaxRow, colIndex)
        If (InStr(Results(1, colIndex), METER_ELECTRICITY_PLUGS)) Then Range("equipment_annual") = Results(iMaxRow, colIndex)
        If (InStr(Results(1, colIndex), METER_ELECTRICITY_PUMPS)) Then Range("pumps_annual") = Results(iMaxRow, colIndex)
        If (InStr(Results(1, colIndex), METER_ELECTRICITY_FANS)) Then Range("fans_annual") = Results(iMaxRow, colIndex)
        'PV
        If (InStr(Results(1, colIndex), "Plant")) Then Range("pv_annual") = Results(iMaxRow, colIndex)
        Range("pv_annual_kWp") = Range("pv_annual") / Range("eff_PV")
    Next
    
    '------ Liste Gebäudebilanz
    
    Sheets("GEBÄUDEBILANZ").Range("N10:N13") = ""
    Sheets("GEBÄUDEBILANZ").Range("N18:N24") = ""
    
    For colIndex = 1 To iMaxCol
        'Verluste
        If (InStr(Results(1, colIndex), METER_WINDOW_SURFACE_HEAT_LOSS)) Then Sheets("GEBÄUDEBILANZ").Range("N11") = Results(iMaxRow, colIndex) * -1
        If (InStr(Results(1, colIndex), METER_INFILTRATION_HEAT_LOSS)) Then Sheets("GEBÄUDEBILANZ").Range("N12") = Results(iMaxRow, colIndex) * -1
        If (InStr(Results(1, colIndex), METER_VENTILATION_HEAT_LOSS)) Then Sheets("GEBÄUDEBILANZ").Range("N13") = Results(iMaxRow, colIndex) * -1
        'If (InStr(Results(1, colIndex), "MECHANISCHE LÜFTUNG")) Then Sheets("GEBÄUDEBILANZ").Range("N14") = Results(iMaxRow, colIndex) * -1
        
        'Gewinne
        If (InStr(Results(1, colIndex), METER_WINDOW_SURFACE_HEAT_GAIN)) Then Sheets("GEBÄUDEBILANZ").Range("N19") = Results(iMaxRow, colIndex)
        If (InStr(Results(1, colIndex), METER_INFILTRATION_HEAT_GAIN)) Then Sheets("GEBÄUDEBILANZ").Range("N20") = Results(iMaxRow, colIndex)
        If (InStr(Results(1, colIndex), METER_VENTILATION_HEAT_GAIN)) Then Sheets("GEBÄUDEBILANZ").Range("N21") = Results(iMaxRow, colIndex)
        If (InStr(Results(1, colIndex), METER_ZONE_PLUGS)) Then Sheets("GEBÄUDEBILANZ").Range("N22") = Results(iMaxRow, colIndex)
        If (InStr(Results(1, colIndex), METER_ZONE_LIGHTS)) Then Sheets("GEBÄUDEBILANZ").Range("N23") = Results(iMaxRow, colIndex)
        If (InStr(Results(1, colIndex), METER_ZONE_PEOPLE)) Then Sheets("GEBÄUDEBILANZ").Range("N24") = Results(iMaxRow, colIndex)
    Next
    
    'Transmission Wände
    Sheets("GEBÄUDEBILANZ").Range("N10") = dAnnualResult(iMaxCol + 1) 'loss
    Sheets("GEBÄUDEBILANZ").Range("N18") = dAnnualResult(iMaxCol + 2) 'gain
    
    
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
    ReDim Results_Nutzenergie_out(1 To iMaxRow, 1 To 7)
    
    'Blattschutz und Excel-Berechnung
    TB_diag.Unprotect
    Application.Calculation = xlCalculationManual
    
    Results_Nutzenergie = Sheets("pivot").Range("D4:J" & iMaxRow + 3)
    
    berechnet = False
    
    If leistung And Sheets("pivot").Range("A1") = "Energie" Then
        'Umrechnung in Leistung [W]
        For rwIndex = 1 To iMaxRow
            For colIndex = 1 To 7
                Results_Nutzenergie_out(rwIndex, colIndex) = Results_Nutzenergie(rwIndex, colIndex) / (Range("Timestep") / 60)
            Next
        Next
        'Aggregierung in Pivot Table auf Mitterlwert ändern
        For i = 1 To 7
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
            For colIndex = 1 To 7
                Results_Nutzenergie_out(rwIndex, colIndex) = Results_Nutzenergie(rwIndex, colIndex) * (Range("Timestep") / 60)
            Next
        Next
        'Aggregierung in Pivot Table auf Summe ändern
        For i = 1 To 7
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
