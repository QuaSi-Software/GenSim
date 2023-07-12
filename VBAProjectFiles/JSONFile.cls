VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "JSONFile"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Dim Steps As New Collection
Dim jsonDictionary As New Dictionary
Dim JSONArgs As Dictionary

Public Sub Class_Initialize()
    'Set arguments = New Collection
End Sub

Public Sub CreateFile(sOSMPathName As String, sEPWFileName As String)
    Dim MeasurePaths As New Collection
    MeasurePaths.Add (GetMeasuresFolder())
    jsonDictionary.Add "measure_paths", MeasurePaths
    jsonDictionary("seed_file") = sOSMPathName
    jsonDictionary("weather_file") = sEPWFileName
    
    Set JSONArgs = New Dictionary
End Sub

Public Sub AddArgument(sArgName As String, sArg As String)
    If sArg = "Ja" Then
        JSONArgs.Add sArgName, "true"
    ElseIf sArg = "Nein" Then
        JSONArgs.Add sArgName, "false"
    ElseIf InStr(sArg, ",") Then
        JSONArgs.Add sArgName, Replace(sArg, ",", ".")
    Else
        If InStr(sArg, "ä") Then
            sArg = Replace(sArg, "ä", "ae")
        End If
        If InStr(sArg, "ü") Then
            sArg = Replace(sArg, "ü", "ue")
        End If
        If InStr(sArg, "ö") Then
            sArg = Replace(sArg, "ö", "oe")
        End If
        If InStr(sArg, "ß") Then
            sArg = Replace(sArg, "ß", "ss")
        End If
        If InStr(sArg, "°") Then
            sArg = Replace(sArg, "°", "deg")
        End If
        JSONArgs.Add sArgName, sArg
    End If
End Sub

Public Sub AddInternalSourceConstruction(sMatPrefix As String, iLayer As String, iTempCalc As String, iCTF As String, dSpacing As String, r As Range, iCount As Integer)
    Dim iCounter As Integer
    iCounter = 0
    AddArgument sMatPrefix + "SourceLayer", iLayer
    AddArgument sMatPrefix + "TempCalcLayer", iTempCalc
    AddArgument sMatPrefix + "DimCTF", iCTF
    AddArgument sMatPrefix + "TubeSpacing", dSpacing
    For iItem = 1 To iCount
        AddArgument sMatPrefix + Trim(Str(iItem)) + "Name", r.Offset(0, iCounter)
        If r.Offset(0, iCounter) = "" Then
            AddArgument sMatPrefix + Trim(Str(iItem)) + "Thickness", 0
            AddArgument sMatPrefix + Trim(Str(iItem)) + "Conductivity", 0
            AddArgument sMatPrefix + Trim(Str(iItem)) + "Density", 0
            AddArgument sMatPrefix + Trim(Str(iItem)) + "SpecificHeat", 0
        Else
            AddArgument sMatPrefix + Trim(Str(iItem)) + "Thickness", r.Offset(0, iCounter + 1)
            AddArgument sMatPrefix + Trim(Str(iItem)) + "Conductivity", r.Offset(0, iCounter + 2)
            AddArgument sMatPrefix + Trim(Str(iItem)) + "Density", r.Offset(0, iCounter + 3)
            AddArgument sMatPrefix + Trim(Str(iItem)) + "SpecificHeat", r.Offset(0, iCounter + 4)
        End If
        iCounter = iCounter + 5
    Next
End Sub

Public Sub AddInternalSourceConstructionHardcoded(sMatPrefix As String, iLayer As String, iTempCalc As String, iCTF As String, dSpacing As String, r As Range, iCount As Integer)
    Dim iCounter As Integer
    iCounter = 0
    AddArgument sMatPrefix + "SourceLayer", iLayer
    AddArgument sMatPrefix + "TempCalcLayer", iTempCalc
    AddArgument sMatPrefix + "DimCTF", iCTF
    AddArgument sMatPrefix + "TubeSpacing", dSpacing
 '   iItem = 1
 '       AddArgument sMatPrefix + Trim(Str(iItem)) + "Name", "Metal"
 '       AddArgument sMatPrefix + Trim(Str(iItem)) + "Thickness", 0.002
 '       AddArgument sMatPrefix + Trim(Str(iItem)) + "Conductivity", 45
 '       AddArgument sMatPrefix + Trim(Str(iItem)) + "Density", 7824
 '       AddArgument sMatPrefix + Trim(Str(iItem)) + "SpecificHeat", 800
    iItem = 1
        AddArgument sMatPrefix + Trim(Str(iItem)) + "Name", "I01 25mm insulation board"
        AddArgument sMatPrefix + Trim(Str(iItem)) + "Thickness", 0.0254
        AddArgument sMatPrefix + Trim(Str(iItem)) + "Conductivity", 0.03
        AddArgument sMatPrefix + Trim(Str(iItem)) + "Density", 43
        AddArgument sMatPrefix + Trim(Str(iItem)) + "SpecificHeat", 1210
    iItem = 2
        AddArgument sMatPrefix + Trim(Str(iItem)) + "Name", "Metal"
        AddArgument sMatPrefix + Trim(Str(iItem)) + "Thickness", 0.01
        AddArgument sMatPrefix + Trim(Str(iItem)) + "Conductivity", 45
        AddArgument sMatPrefix + Trim(Str(iItem)) + "Density", 7824
        AddArgument sMatPrefix + Trim(Str(iItem)) + "SpecificHeat", 800
    iItem = 3
        AddArgument sMatPrefix + Trim(Str(iItem)) + "Name", ""
        AddArgument sMatPrefix + Trim(Str(iItem)) + "Thickness", 0
        AddArgument sMatPrefix + Trim(Str(iItem)) + "Conductivity", 0
        AddArgument sMatPrefix + Trim(Str(iItem)) + "Density", 0
        AddArgument sMatPrefix + Trim(Str(iItem)) + "SpecificHeat", 0
    iItem = 4
        AddArgument sMatPrefix + Trim(Str(iItem)) + "Name", ""
        AddArgument sMatPrefix + Trim(Str(iItem)) + "Thickness", 0
        AddArgument sMatPrefix + Trim(Str(iItem)) + "Conductivity", 0
        AddArgument sMatPrefix + Trim(Str(iItem)) + "Density", 0
        AddArgument sMatPrefix + Trim(Str(iItem)) + "SpecificHeat", 0
End Sub

Public Sub AddConstruction(sMatPrefix As String, r As Range, iCount As Integer)
    Dim iCounter As Integer
    iCounter = 0
    For iItem = 1 To iCount
        AddArgument sMatPrefix + Trim(Str(iItem)) + "Name", r.Offset(0, iCounter)
        If r.Offset(0, iCounter) = "" Then
            AddArgument sMatPrefix + Trim(Str(iItem)) + "Thickness", 0
            AddArgument sMatPrefix + Trim(Str(iItem)) + "Conductivity", 0
            AddArgument sMatPrefix + Trim(Str(iItem)) + "Density", 0
            AddArgument sMatPrefix + Trim(Str(iItem)) + "SpecificHeat", 0
        Else
            AddArgument sMatPrefix + Trim(Str(iItem)) + "Thickness", r.Offset(0, iCounter + 1)
            AddArgument sMatPrefix + Trim(Str(iItem)) + "Conductivity", r.Offset(0, iCounter + 2)
            AddArgument sMatPrefix + Trim(Str(iItem)) + "Density", r.Offset(0, iCounter + 3)
            AddArgument sMatPrefix + Trim(Str(iItem)) + "SpecificHeat", r.Offset(0, iCounter + 4)
        End If
        iCounter = iCounter + 5
    Next
End Sub

Public Sub AddWindowConstruction(sMatPrefix As String, name As String, uValue As String, shgc As String)
    AddArgument sMatPrefix + "Name", name
    AddArgument sMatPrefix + "UValue", uValue
    AddArgument sMatPrefix + "SHGC", shgc
End Sub

Public Sub AddSchedule(sArgName As String, r As Range)
    AddOneSchedule sArgName + "Werktag", r
    AddOneSchedule sArgName + "Samstag", r.Offset(0, 1)
    AddOneSchedule sArgName + "Sonntag", r.Offset(0, 2)
    If IsEmpty(r.Offset(0, 3)) Then
        AddOneSchedule sArgName + "Feiertag", r.Offset(0, 2)
    Else
        AddOneSchedule sArgName + "Feiertag", r.Offset(0, 3)
    End If
End Sub

Private Sub AddOneSchedule(sArgName As String, r As Range)
    iCells = 96
    Dim strArg As String
    strArg = Str(r.Value)
    For i = 1 To iCells - 1
        strArg = strArg + ";" + CStr(r.Offset(i, 0))
    Next i
    AddArgument sArgName, strArg
End Sub


Public Sub AddHolidays(sArgName As String, r As Range)
    Dim iRow As Integer
    iRow = 1
    Dim sTemp As String
    sTemp = Format(r.Offset(0, 0), "dd.MM.") & "-" & Format(r.Offset(0, 1), "dd.MM.")
    Do While Not (IsEmpty(r.Offset(iRow, 0)))
        sTemp = sTemp & ";" & Format(r.Offset(iRow, 0), "dd.MM.") & "-" & Format(r.Offset(iRow, 1), "dd.MM.")
        iRow = iRow + 1
    Loop
    
    AddArgument sArgName, sTemp
End Sub

Public Sub AddMeasure(sMeasureName As String)
    Dim step As New Dictionary
  '  Dim JSONargs As New Dictionary
  '  JSONargs.Add "Test1", "Test2"
    step.Add "arguments", JSONArgs
    step.Add "measure_dir_name", sMeasureName
    Steps.Add step
    
    Set JSONArgs = New Dictionary
End Sub

Public Sub Save(sFilename As String)
    jsonDictionary.Add "steps", Steps
    Dim jsonFileObject As New FileSystemObject
    Dim jsonFileExport As TextStream
    Set jsonFileExport = jsonFileObject.CreateTextFile(sFilename, True)
    jsonFileExport.WriteLine (ConvertToJson(ByVal jsonDictionary, Whitespace:=3))
End Sub

Public Sub ParseOutputFile(sFilename As String)
    Dim fso As New FileSystemObject
    Dim JsonTS As TextStream
    Dim JsonText As String
    Dim Parsed As Dictionary
    ' Read .json file
    Set JsonTS = fso.OpenTextFile(sFilename, ForReading)
    JsonText = JsonTS.ReadAll
    JsonTS.Close
    
    ' Parse json to Dictionary
    ' "values" is parsed as Collection
    ' each item in "values" is parsed as Dictionary
    Set Parsed = JsonConverter.ParseJson(JsonText)
    
    ' Prepare and write values to sheet
    Dim step As Dictionary
    For Each step In Parsed("steps")
        Dim result As Dictionary
        If step("measure_dir_name") = "BarAspectRatioStudy" Then
            Range("GeomStatus") = GetStepStatus(step)
        ElseIf step("measure_dir_name") = "AddingMaterialsAndConstructions" Then
            Range("UStatus") = GetStepStatus(step)
        ElseIf step("measure_dir_name") = "AddingInternalLoads" Then
            Range("LoadStatus") = GetStepStatus(step)
        ElseIf step("measure_dir_name") = "AddingIdealAirLoads" Then
            Range("IdealLoads") = GetStepStatus(step)
        ElseIf step("measure_dir_name") = "AddingShadingControls" Then
            Range("ShadingControl") = GetStepStatus(step)
        ElseIf step("measure_dir_name") = "AddingInfiltration" Then
            Range("Infiltration") = GetStepStatus(step)
        ElseIf step("measure_dir_name") = "AddingLightingControls" Then
            Range("LightingControl") = GetStepStatus(step)
        ElseIf step("measure_dir_name") = "AddingTemperatureSetpoints" Then
            Range("TempSetpoint") = GetStepStatus(step)
        ElseIf step("measure_dir_name") = "AddingPhotovoltaic" Then
            Range("Photovoltaic") = GetStepStatus(step)
        ElseIf step("measure_dir_name") = "InjectZoneVentilationIDF" Then
            Range("window_ventilation") = GetStepStatus(step)
        ElseIf step("measure_dir_name") = "InjectIdealLoadParametersIDF" Then
            Range("IDFIdealLoads") = GetStepStatus(step)
        End If
    Next step
End Sub

Private Function GetStepStatus(step As Dictionary) As String
    If Not IsEmpty(step("result")) Then
        Set result = step("result")
        GetStepStatus = result("step_result")
    Else
        GetStepStatus = "Not completed"
    End If
End Function
