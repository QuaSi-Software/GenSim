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

Public Sub AddArgument( _
    sArgName As String, sArg As String, _
    Optional forceCommaReplace As Boolean = False _
)
    If sArg = "Ja" Then
        JSONArgs.Add sArgName, "true"
    ElseIf sArg = "Nein" Then
        JSONArgs.Add sArgName, "false"
    ElseIf forceCommaReplace Or IsNumeric(Replace(sArg, ",", ".")) Then
        JSONArgs.Add sArgName, Replace(sArg, ",", ".")
    Else
        sArg = Replace(sArg, "ä", "$ae$")
        sArg = Replace(sArg, "ö", "$oe$")
        sArg = Replace(sArg, "ü", "$ue$")
        sArg = Replace(sArg, "Ä", "$AE$")
        sArg = Replace(sArg, "Ö", "$OE$")
        sArg = Replace(sArg, "Ü", "$UE$")
        sArg = Replace(sArg, "ß", "$ss$")
        sArg = Replace(sArg, "°", "$deg$")
        JSONArgs.Add sArgName, sArg
    End If
End Sub

Public Sub GetArgument( _
    oDict As Dictionary, sArgName As String, _
    Optional forceCommaReplace As Boolean = False _
)
    Dim sArg As String: sArg = oDict(sArgName)

    If sArg = "true" Then
        return "Ja"
    ElseIf sArg = "false" Then
        return "Nein"
    ElseIf forceCommaReplace Or IsNumeric(sArg) Then
        return Replace(sArg, ".", ",")
    Else
        sArg = Replace(sArg, "$ae$", "ä")
        sArg = Replace(sArg, "$oe$", "ö")
        sArg = Replace(sArg, "$ue$", "ü")
        sArg = Replace(sArg, "$AE$", "Ä")
        sArg = Replace(sArg, "$OE$", "Ö")
        sArg = Replace(sArg, "$UE$", "Ü")
        sArg = Replace(sArg, "$ss$", "ß")
        sArg = Replace(sArg, "$deg$", "°")
        return sArg
    End If
End Sub

Public Sub AddInternalSourceConstruction(sMatPrefix As String, iLayer As String, iTempCalc As String, iCTF As String, dSpacing As String, r As Range, iCount As Integer)
    Dim iCounter As Integer
    iCounter = 0
    AddArgument sMatPrefix + "_source_layer", iLayer
    AddArgument sMatPrefix + "_temp_calc_layer", iTempCalc
    AddArgument sMatPrefix + "_dim_ctf", iCTF
    AddArgument sMatPrefix + "_tube_spacing", dSpacing
    For iItem = 1 To iCount
        AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_name", r.Offset(0, iCounter)
        If r.Offset(0, iCounter) = "" Then
            AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_thickness", 0
            AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_conductivity", 0
            AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_density", 0
            AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_heat_capacity", 0
        Else
            AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_thickness", r.Offset(0, iCounter + 1)
            AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_conductivity", r.Offset(0, iCounter + 2)
            AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_density", r.Offset(0, iCounter + 3)
            AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_heat_capacity", r.Offset(0, iCounter + 4)
        End If
        iCounter = iCounter + 5
    Next
End Sub

Public Sub AddInternalSourceConstructionHardcoded(sMatPrefix As String, iLayer As String, iTempCalc As String, iCTF As String, dSpacing As String, r As Range, iCount As Integer)
    Dim iCounter As Integer
    iCounter = 0
    AddArgument sMatPrefix + "_source_layer", iLayer
    AddArgument sMatPrefix + "_temp_calc_layer", iTempCalc
    AddArgument sMatPrefix + "_dim_ctf", iCTF
    AddArgument sMatPrefix + "_tube_spacing", dSpacing

    iItem = 1
        AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_name", "I01 25mm insulation board"
        AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_thickness", 0.0254
        AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_conductivity", 0.03
        AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_density", 43
        AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_heat_capacity", 1210
    iItem = 2
        AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_name", "Metal"
        AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_thickness", 0.01
        AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_conductivity", 45
        AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_density", 7824
        AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_heat_capacity", 800
    iItem = 3
        AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_name", ""
        AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_thickness", 0
        AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_conductivity", 0
        AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_density", 0
        AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_heat_capacity", 0
    iItem = 4
        AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_name", ""
        AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_thickness", 0
        AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_conductivity", 0
        AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_density", 0
        AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_heat_capacity", 0
End Sub

Public Sub AddConstruction(sMatPrefix As String, r As Range, iCount As Integer)
    Dim iCounter As Integer
    iCounter = 0
    For iItem = 1 To iCount
        AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_name", r.Offset(0, iCounter)
        If r.Offset(0, iCounter) = "" Then
            AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_thickness", 0
            AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_conductivity", 0
            AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_density", 0
            AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_heat_capacity", 0
        Else
            AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_thickness", r.Offset(0, iCounter + 1)
            AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_conductivity", r.Offset(0, iCounter + 2)
            AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_density", r.Offset(0, iCounter + 3)
            AddArgument sMatPrefix + "_" + Trim(Str(iItem)) + "_heat_capacity", r.Offset(0, iCounter + 4)
        End If
        iCounter = iCounter + 5
    Next
End Sub

Public Sub AddWindowConstruction(sMatPrefix As String, name As String, uValue As String, shgc As String)
    AddArgument sMatPrefix + "_name", name
    AddArgument sMatPrefix + "_u_value", uValue
    AddArgument sMatPrefix + "_shgc", shgc
End Sub

Public Sub AddSchedule(sArgName As String, r As Range)
    AddOneSchedule sArgName + "_weekday", r
    AddOneSchedule sArgName + "_saturday", r.Offset(0, 1)
    AddOneSchedule sArgName + "_sunday", r.Offset(0, 2)
    If IsEmpty(r.Offset(0, 3)) Then
        AddOneSchedule sArgName + "_holiday", r.Offset(0, 2)
    Else
        AddOneSchedule sArgName + "_holiday", r.Offset(0, 3)
    End If
End Sub

Private Sub AddOneSchedule(sArgName As String, r As Range)
    iCells = 96
    Dim strArg As String
    strArg = Str(r.Value)
    For i = 1 To iCells - 1
        strArg = strArg + ";" + CStr(r.Offset(i, 0))
    Next i
    AddArgument sArgName, strArg, True
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
        If step("measure_dir_name") = "add_geometry" Then
            Range("GeomStatus") = GetStepStatus(step)
        ElseIf step("measure_dir_name") = "add_materials_and_construction" Then
            Range("UStatus") = GetStepStatus(step)
        ElseIf step("measure_dir_name") = "add_internal_loads" Then
            Range("LoadStatus") = GetStepStatus(step)
        ElseIf step("measure_dir_name") = "add_ideal_loads" Then
            Range("IdealLoads") = GetStepStatus(step)
        ElseIf step("measure_dir_name") = "add_shading_controls" Then
            Range("ShadingControl") = GetStepStatus(step)
        ElseIf step("measure_dir_name") = "add_infiltration" Then
            Range("Infiltration") = GetStepStatus(step)
        ElseIf step("measure_dir_name") = "add_lighting_controls" Then
            Range("LightingControl") = GetStepStatus(step)
        ElseIf step("measure_dir_name") = "add_temperature_setpoints" Then
            Range("TempSetpoint") = GetStepStatus(step)
        ElseIf step("measure_dir_name") = "inject_zone_ventilation_idf" Then
            Range("window_ventilation") = GetStepStatus(step)
        ElseIf step("measure_dir_name") = "inject_ideal_load_parameters_idf" Then
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
