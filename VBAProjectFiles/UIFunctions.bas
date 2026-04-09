Attribute VB_Name = "UIFunctions"
Dim strOpenStudioDir As String
Dim strMeasureDir As String
Dim strOutputDir As String
Dim strWeatherDir As String
Public Const IFC_IMPORT As Boolean = True

Function GetOpenStudioBinPath()
    If Range("DirOpenStudio") = "" Then
        GetOpenStudioBinPath = "C:\openstudio-3.10.0\bin"
    Else
        GetOpenStudioBinPath = Range("DirOpenStudio") & "\bin"
    End If
End Function

Function GetRubyExePath()
    If Range("DirOpenStudio") = "" Then
        GetRubyExePath = "C:\openstudio-3.10.0\pat\ruby\bin\ruby.exe"
    Else
        GetRubyExePath = Range("DirOpenStudio") & "\pat\ruby\bin\ruby.exe"
    End If
End Function

Function GetMeasuresFolder()
    GetMeasuresFolder = Application.ActiveWorkbook.Path & "\Measures"
End Function

Function GetWeatherFolder()
    GetWeatherFolder = Application.ActiveWorkbook.Path & "\Wetter"
End Function
   
Function GetOutputFolder()
    GetOutputFolder = Application.ActiveWorkbook.Path & "\Output"
       
    If Dir(GetOutputFolder, vbDirectory) = "" Then
        MkDir GetOutputFolder
    End If
End Function
   
Function GetWorkingPath()
    Dim sTempPath As String
    sTempPath = Application.ActiveWorkbook.Path & "\Temp"
    If Dir(sTempPath, vbDirectory) = "" Then
        MkDir (sTempPath)
    End If
    GetWorkingPath = sTempPath
End Function
   
Sub Auto_Open()
    SetApplicationPath

'    Dim sht As Worksheet
'    Dim myDropDown As Shape
'
'    Set sht = ThisWorkbook.Worksheets("HAUPTSEITE")
'    Set myDropDown = sht.Shapes("DropDown1")
    
'    ReadWeatherFiles
'    Sheets("HAUPTSEITE").Unprotect
'    FillLocationParameters (True)
'    Sheets("HAUPTSEITE").Protect
End Sub

Sub SetApplicationPath()
    Sheets("Installation").Unprotect
    
    Range("ThisDir") = Application.ActiveWorkbook.Path
    Range("InstallationStatus") = ""
    
    Sheets("Installation").Protect
End Sub

Sub ReadWeatherFiles()
    Dim objFSO As Object
    Dim objFolder As Object
    Dim objFile As Object
    Dim i As Integer

    Dim dd1 As DropDown
    Set dd1 = Sheets("HAUPTSEITE").DropDowns("DropDown1")

    Application.Calculation = xlCalculationManual

    'Value = dd1.Value
    dd1.RemoveAllItems

    'Create an instance of the FileSystemObject
    Set objFSO = CreateObject("Scripting.FileSystemObject")
    'Get the folder object
    Set objFolder = objFSO.GetFolder(Application.ActiveWorkbook.Path & "\Wetter")

    Set sht = ThisWorkbook.Worksheets("Wetterdateien")
    i = 0
    'loops through each file in the directory and prints their names and path
    For Each objFile In objFolder.files()
        If StringEndsWith(objFile.name, ".epw") Then
            'print file name
            sht.Cells(i + 1, 1) = objFile.name
            dd1.AddItem objFile.name
            i = i + 1
        End If
    Next objFile
    'dd1.Value = Value

    DropDown1_Change

    Application.Calculation = xlCalculationAutomatic
End Sub

Public Function StringEndsWith(ByVal strValue As String, CheckFor As String, Optional CompareType As VbCompareMethod = vbBinaryCompare) As Boolean
    Dim sCompare As String
    Dim lLen As Long

    lLen = Len(CheckFor)
    If lLen > Len(strValue) Then Exit Function
    sCompare = Right(strValue, lLen)
    StringEndsWith = StrComp(sCompare, CheckFor, CompareType) = 0
End Function

Function GetFolder(strTitle As String, strPath As String) As String
    Dim fldr As fileDialog
    Dim sItem As String
    Set fldr = Application.fileDialog(msoFileDialogFolderPicker)
    With fldr
        .Title = strTitle
        .AllowMultiSelect = False
        .InitialFileName = strPath
        If .Show <> -1 Then GoTo NextCode
        sItem = .SelectedItems(1)
    End With
NextCode:
    GetFolder = sItem
    Set fldr = Nothing
End Function

Sub BrowseOpenStudioInstallationDir()
    Sheets("Installation").Unprotect
    
    If Range("DirOpenStudio") = "" Then
        strOpenStudioDir = "C:\openstudio-3.10.0\"
    Else
        strOpenStudioDir = Range("DirOpenStudio")
    End If
    strOpenStudioDir = GetFolder("Bitte wähle den Ordner der OpenStudio Installation", strOpenStudioDir)
    Range("DirOpenStudio") = strOpenStudioDir
    Range("InstallationStatus") = ""
    
    Sheets("Installation").Protect
End Sub

Sub TestInstallation()
    Sheets("Installation").Unprotect
    ' here we are testing the installation to eliminate issues before trying to run the tool
    If Dir(Range("DirOpenStudio"), vbDirectory) = "" Then
        Range("InstallationStatus") = "OpenStudio Dateipfad NICHT korrekt!"
    Else
        Range("InstallationStatus") = "Installation OpenStudio und Konfiguration Dateipfade korrekt!"
    End If
    Sheets("Installation").Protect
End Sub

Sub BrowseMeasuresDir()
    If Range("ThisDir") = "" Then
        Range("ThisDir") = Application.ActiveWorkbook.Path
    End If
    If Range("MeasuresDir") = "" Then
        strMeasureDir = Application.ActiveWorkbook.Path & "\Measures"
    Else
        strMeasureDir = Range("MeasuresDir")
    End If
    strMeasureDir = GetFolder("Bitte wähle den Ordner der OpenStudio Installation", strMeasureDir)
    Range("MeasuresDir") = strMeasureDir
End Sub

Sub BrowseOutputDir()
    If Range("ThisDir") = "" Then
        Range("ThisDir") = Application.ActiveWorkbook.Path
    End If
    If Range("OutputDir") = "" Then
        strOutputDir = Application.ActiveWorkbook.Path & "\Output"
    Else
        strOutputDir = Range("OutputDir")
    End If
    strOutputDir = GetFolder("Bitte wähle den Ordner der OpenStudio Installation", strOutputDir)
    Range("OutputDir") = strOutputDir
End Sub

Sub BrowseWeatherDir()
    If Range("ThisDir") = "" Then
        Range("ThisDir") = Application.ActiveWorkbook.Path
    End If
    If Range("WeatherDir") = "" Then
        strWeatherDir = Application.ActiveWorkbook.Path & "\Wetter"
    Else
        strWeatherDir = Range("WeatherDir")
    End If
    strWeatherDir = GetFolder("Bitte wähle den Ordner der OpenStudio Installation", strWeatherDir)
    Range("WeatherDir") = strWeatherDir
End Sub

Function load_file_from_folder(filetype As String, weatherfile As String)
    Dim result As Integer
    Dim selectedPath As String
    Dim idf_file As String
    Dim zipPath As Variant
    Dim isComplete As Boolean: isComplete = True
    Dim fileDialog As fileDialog: Set fileDialog = Application.fileDialog(msoFileDialogFilePicker)
    
    
    fileDialog.InitialFileName = Application.ActiveWorkbook.Path
    fileDialog.ButtonName = "Speichern"
    fileDialog.Title = "Bitte Datei auswählen"
    fileDialog.Filters.Clear
    
    Dim parts() As String
    If InStr(filetype, "-") > 0 Then
        Dim firstPart As String
        Dim secondPart As String
        parts = Split(filetype, "-")
        firstPart = parts(0)
        secondPart = parts(1)
        fileDialog.InitialFileName = Application.ActiveWorkbook.Path & "\*." & firstPart
        fileDialog.Filters.Add firstPart & " Files", "*." & firstPart, 1
        fileDialog.Filters.Add secondPart & " Files", "*." & secondPart, 2
        If UBound(parts) >= 2 Then
            fileDialog.Filters.Add parts(2) & " Files", "*." & parts(2), 3
        End If
    Else
        fileDialog.InitialFileName = Application.ActiveWorkbook.Path & "\*." & filetype
        fileDialog.Filters.Add filetype & " Files", "*." & filetype, 1
    End If
    
    fileDialog.FilterIndex = 1
    result = fileDialog.Show

    If result <> 0 Then
        load_file_from_folder = fileDialog.SelectedItems(1)
        If LCase(Right(load_file_from_folder, 4)) = ".idf" Then
            load_file_from_folder = RunIDFConversionScript(fileDialog.SelectedItems(1))
        ElseIf LCase(Right(load_file_from_folder, 4)) = ".ifc" Then
            idf_file = RunIFCConversionScript(fileDialog.SelectedItems(1), weatherfile)
            If Len(idf_file) > 0 Then
                load_file_from_folder = RunIDFConversionScript(idf_file)
            Else
                MsgBox ("Error during conversion to IDF")
            End If
        End If
    End If
End Function

Sub import_geometry_osm()
    Dim file_types As String
    Dim weather_file As String
    file_types = "osm-idf"
    If IsDockerInstalled() And IFC_IMPORT Then
        file_types = "osm-idf-ifc"
        If Not (IsDockerRunning()) Then
            MsgBox ("Your Docker/Docker Desktop is not running, please start it.")
            Exit Sub
        End If
    End If
    weather_file = GetWeatherFilePath("TRY2015_Augsburg_Jahr.epw", GetWeatherFolder())
    path_osm = load_file_from_folder(file_types, weather_file)
    If path_osm <> Empty Then
        Range("path_geometry_Import") = path_osm
    End If
End Sub


Function IsDockerRunning() As Boolean
    Dim objWMIService As Object
    Dim colProcesses As Object
    Dim objProcess As Object

    Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")
    Set colProcesses = objWMIService.ExecQuery("SELECT Name FROM Win32_Process WHERE Name = 'Docker Desktop.exe' OR Name = 'Docker.exe'")

    IsDockerRunning = (colProcesses.Count > 0)
End Function


Function GetWeatherFilePath(defaultValue As String, weatherFolder As String) As String
    Dim ws As Worksheet
    Set ws = ThisWorkbook.Sheets("HAUPTSEITE")

    Dim selectedItem As String
    selectedItem = ""

    On Error Resume Next

    ' Try ActiveX ComboBox
    Dim ddActiveX As Object
    Set ddActiveX = ws.OLEObjects("dd1").Object
    If Not ddActiveX Is Nothing Then
        If ddActiveX.ListIndex <> -1 Then
            selectedItem = ddActiveX.List(ddActiveX.ListIndex)
        End If
    End If

    ' Try Form Control Dropdown (linked cell)
    If selectedItem = "" Then
        Dim linkedCell As Range
        ' Replace "B3" with your actual linked cell if known
        Set linkedCell = ws.Range("B9")
        If Not linkedCell Is Nothing Then
            selectedItem = linkedCell.Value
        End If
    End If

    On Error GoTo 0 ' Reset error handling

    ' Final fallback
    If Trim(selectedItem) = "" Then
        GetWeatherFilePath = weatherFolder & "\" & defaultValue
    Else
        GetWeatherFilePath = weatherFolder & "\" & selectedItem
    End If
End Function


Function IsDockerInstalled() As Boolean
    Dim objReg As Object
    Dim subKeys As Variant
    Dim subKey As Variant
    Dim displayName As Variant
    Dim rootKey As Long
    Dim keyPath As String
    Dim paths As Variant
    Dim i As Integer

    On Error GoTo ErrorHandler

    ' Create registry object
    Set objReg = GetObject("winmgmts:\\.\root\default:StdRegProv")

    ' Constants
    rootKey = &H80000002 ' HKEY_LOCAL_MACHINE

    ' Registry paths to check
    paths = Array( _
        "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", _
        "SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" _
    )

    ' Loop through both registry paths
    For i = LBound(paths) To UBound(paths)
        keyPath = paths(i)
        subKeys = Null
        objReg.EnumKey rootKey, keyPath, subKeys

        If Not IsNull(subKeys) Then
            For Each subKey In subKeys
                displayName = Null
                objReg.GetStringValue rootKey, keyPath & "\" & subKey, "DisplayName", displayName
                If Not IsNull(displayName) Then
                    If InStr(1, displayName, "Docker", vbTextCompare) > 0 Then
                        IsDockerInstalled = True
                        Exit Function
                    End If
                End If
            Next subKey
        End If
    Next i

    MsgBox "Docker is not installed. Please go to docker.com and install Docker Desktop."
    IsDockerInstalled = False
    Exit Function

ErrorHandler:
    IsDockerInstalled = False
End Function

Function RunIDFConversionScript(idfPath As String) As String
    RunMeasures.CreatePreWorkflowAndExecute (idfPath)
    Dim osmPath As String
    osmPath = Replace(LCase(idfPath), ".idf", ".osm")
    If Dir(osmPath) <> "" Then
        MsgBox "OSM file successfully generated: " & osmPath
        RunIDFConversionScript = osmPath
    Else
        MsgBox "OSM file was not properly generated."
    End If
End Function


Function RunIFCConversionScript(ifcPath As String, epwPath As String) As String
    Dim batFilePath As String
    Dim command As String
    Dim eplusPath As String

    ' Full path to your .bat file
    batFilePath = "run_conversion.bat"

    ' Input files
    eplusPath = "/usr/local/EnergyPlus-9-4-0/"

    ' Combine all arguments with quotes
    command = """" & batFilePath & """ " & _
              """" & ifcPath & """ " & _
              """" & epwPath & """ " & _
              """" & eplusPath & """"

    ' Run batch file and wait
    retval = ExecCmd(command)

    If retval <> 0 Then
        MsgBox "Fehler während der Konvertierung, Fehlercode: " & retval
        RunIFCConversionScript = ""
    Else
        RunIFCConversionScript = Replace(LCase(ifcPath), ".ifc", ".idf")
    End If
End Function


Sub DropDown1_Change()
    Sheets("HAUPTSEITE").Unprotect
    Application.Calculation = xlCalculationManual
    FillLocationParameters (True)
    'ReadWeatherFiles

    Application.Calculation = xlCalculationAutomatic
    Sheets("HAUPTSEITE").Protect
End Sub

Sub DropDown_BGF_NRF_Generisch()
    Sheets("Wetterdateien").Range("index_BGF_zu_NRF").Offset(1, 0) = 1
    Sheets("Wetterdateien").Range("index_BGF_zu_NRF").Calculate
    Range("BGF_zu_NRF") = Sheets("Wetterdateien").Range("index_BGF_zu_NRF")
End Sub

Sub DropDown_BGF_NRF_Geometrie_Import()
    Sheets("Wetterdateien").Range("index_BGF_zu_NRF_import").Offset(1, 0) = 1
    Sheets("Wetterdateien").Range("index_BGF_zu_NRF_import").Calculate
    Range("BGF_zu_NRF_import") = Sheets("Wetterdateien").Range("index_BGF_zu_NRF_import")
End Sub

Sub FillLocationParameters(bForce As Boolean)
    If bForce Or IsEmpty(Range("Name")) Then
        Dim dd As DropDown
        Set dd = Sheets("HAUPTSEITE").DropDowns("DropDown1")
        myFile = Application.ActiveWorkbook.Path & "\Wetter\" & dd.List(dd.Value)
        Value = dd.Value
        Open myFile For Input As #1
        ' read the first line
        Line Input #1, textline
       
        If InStr(textline, "LOCATION") Then
            Dim TestArray() As String
            TestArray = Split(textline, ",")
            
            Range("Name") = TestArray(3) & "_" & TestArray(2) & "_" & TestArray(1)
            Range("Latitude") = TestArray(6)
            Range("Longitude") = TestArray(7)
            Range("TimeZone") = TestArray(8)
            Range("Elevation") = TestArray(9)
        End If
        Close #1
        dd.Value = Value
   End If
End Sub

Sub Tab_Lastprofile()
    Sheets("PROFILE").Select
End Sub

Sub Tab_PV_Profile()
    Sheets("PV-PROFIL").Select
End Sub

Sub Ansicht_Profile()
    Sheets("HAUPTSEITE").Unprotect
    Application.GoTo Reference:=Sheets("HAUPTSEITE").Range("A71"), Scroll:=True
    Sheets("HAUPTSEITE").Protect
End Sub

Sub Feiertage()
    Sheets("HAUPTSEITE").Unprotect
    Application.GoTo Reference:=Sheets("EIGENE NUTZUNGSPROFILE").Range("BF6"), Scroll:=True
    Sheets("HAUPTSEITE").Protect
End Sub

Sub Ansicht_Feiertage()
    Application.GoTo Reference:=Sheets("EIGENE NUTZUNGSPROFILE").Range("AH8"), Scroll:=True
End Sub

'**************************   Gruppieren: TB: CO2-Bilanz    ****************************

Sub Diag_Monat()
    Dim PvtTbl As PivotTable
    Dim rngGroup As Range
    Set PvtTbl = Worksheets("pivot").PivotTables("PivotTable2")

    'set range of dates to be grouped
    Set rngGroup = PvtTbl.PivotFields("Datum").DataRange

    'rngGroup.Cells(1) indicates the first cell in the range of rngGroup - remember that the RangeObject in the Group Method should only be a single cell otherwise the method will fail.
    rngGroup.Cells(1).Group Periods:=Array(False, False, False, False, True, False, False)
End Sub

Sub Diag_Tag()
    Dim PvtTbl As PivotTable
    Dim rngGroup As Range

    Set PvtTbl = Worksheets("pivot").PivotTables("PivotTable2")
    Set rngGroup = PvtTbl.PivotFields("Datum").DataRange
    rngGroup.Cells(1).Group Periods:=Array(False, False, False, True, False, False, False)
End Sub

Sub Diag_Stunde()
    Dim PvtTbl As PivotTable
    Dim rngGroup As Range

    Set PvtTbl = Worksheets("pivot").PivotTables("PivotTable1")
    Set rngGroup = PvtTbl.PivotFields("Datum").DataRange
    If rngGroup.Group = True Then 'damit kein Fehler kommt wenn bereits ungruppiert und das Makro noch einmal ausgeführt wird
        rngGroup.Cells(1).Ungroup
    End If
End Sub

Sub Aktualisieren_pivots()
    Application.Calculation = xlCalculationManual
    Dim x As Integer
    Dim i As Integer
    For x = 1 To Worksheets.Count
        For i = 1 To Sheets(x).PivotTables.Count
            Sheets(x).PivotTables(i).PivotCache.Refresh
        Next i
    Next x
    Application.Calculation = xlCalculationAutomatic
End Sub

'*******************************   Filter: Monate CO2 Bilanz    ****************************

Sub PivotFilter_Monat()
    Dim PvtTbl As PivotTable
    Dim ws As Worksheet
    Set ws = Worksheets("pivot") 'Einfach hier das Tabellenblatt angeben

    Dim Monat As String
    Calculate
    Monat = Range("pivot_monat") 'und hier die Zelle in der der aktuelle Monat steht (vom Dropdown)
    For Each PvtTbl In ws.PivotTables
        PvtTbl.PivotFields("Monat").ClearAllFilters
        PvtTbl.PivotFields("Monat").CurrentPage = _
            Monat
    Next PvtTbl
End Sub

'**********************   Import/Export OSW File Buttons   ********************

' Prompts the user to select an OSW file to import, then runs the import
' functionality on that file.
'
' @see OSWFileInterface::ImportFromOSW
Sub ImportOSWFile()
    Dim result As Integer
    Dim selectedPath As String
    Dim fileDialog As fileDialog: Set fileDialog = Application.fileDialog(msoFileDialogOpen)

    Application.Calculation = xlCalculationManual
    
    'Request source file from user
    fileDialog.ButtonName = "Laden"
    fileDialog.Title = "Bitte Konfiguration auswählen"
    fileDialog.InitialFileName = Application.ActiveWorkbook.Path & "\Output"
    fileDialog.Filters.Add "OSW Files", "*.osw", 1
    fileDialog.FilterIndex = 1

    result = fileDialog.Show

    If result <> 0 Then
        'Notify the user that this process might take a while
        MsgBox "Konfiguration wird geladen. Bitte führen Sie keine weiteren " _
            & "Befehle aus bis der Vorgang abgeschlossen ist.", _
            vbInformation, "Status"

        'Do the import
        selectedPath = fileDialog.SelectedItems(1)
        Dim interface As OSWFileInterface: Set interface = New OSWFileInterface

        'As a temporary solution to a bug in the setting of dropdown values, do the import
        'twice in a row
        '@TODO find a better way to fix the bug
        Call interface.ImportFromOSW(selectedPath)
        Calculate
        Call interface.ImportFromOSW(selectedPath)
        Application.Calculation = xlCalculationAutomatic

        'All done
        MsgBox "Laden abgeschlossen.", vbInformation, "Status"
    End If
End Sub

' Prompts the user to select a path where an OSW file is going to be written,
' then runs the export functionality on that filepath.
'
' @see OSWFileInterface::ExportToOSW
Sub ExportOSWFile()
    Application.Calculation = xlCalculationManual

    Dim varResult As Variant
    'displays the save file dialog
    varResult = Application.GetSaveAsFilename(FileFilter:= _
        "OSW Files (*.osw), *.osw", Title:="Bitte Speicherort auswählen", _
        InitialFileName:=Application.ActiveWorkbook.Path & "\Output\exported.osw")
    'checks to make sure the user hasn't canceled the dialog
    If varResult <> False Then
        'Notify the user that this process might take a while
        MsgBox "Konfiguration wird gespeichert. Bitte führen Sie keine weiteren " _
            & "Befehle aus bis der Vorgang abgeschlossen ist.", _
            vbInformation, "Status"

        '  detailed hvac flac to pass for ExportToOSW Skript
        Dim cb_hvac As CheckBox
        Set cb_hvac = Sheets("Parameter").CheckBoxes("checkbox_hvac")
        If cb_hvac.Value = 1 Then
            bDetailedHVAC = False
        Else
            bDetailedHVAC = True
        End If

        'Do the import
        Dim interface As OSWFileInterface: Set interface = New OSWFileInterface
        Sheets("HAUPTSEITE").Unprotect
        Call interface.ExportToOSW(varResult, (Range("geometry_source") = 1), False, bDetailedHVAC)
        Sheets("HAUPTSEITE").Protect

        Application.Calculation = xlCalculationAutomatic
        'All done
        MsgBox "Speichern abgeschlossen.", vbInformation, "Status"
    End If
End Sub

Sub OpenErrorFile()
    Dim current As String
    Dim FileName As String
    Dim result As Integer
    Dim last As String
    
    current = Dir(Application.ActiveWorkbook.Path & "\Output\run\eplusout.err")
    FileName = current
    Do While Len(current) > 0
        last = current
        current = Dir
        If Len(current) > 0 Then
            If CompareTimestamps(current, last) > 0 Then
                FileName = current
            End If
        End If
    Loop
    
    If (FileName <> "") Then
        result = Shell("notepad.exe " & Application.ActiveWorkbook.Path & "\Output\run\" & FileName, vbNormalFocus)
    End If
End Sub

' Compares the two given timestamps and returns which is greater or if they are
' equal. The function assumes that the timestamps are formatted in a manner that
' allows an ordering digit-by-digit where the leftmost digit that differs between
' the strings decides which one is greater. For example this is the case for
' timestamps formatted like yyyy-mm-dd hh:mm:ss or the unix timestamp.
' Note that the method will return 0 if at least one of the strings has a length
' of zero.
' Note that if the timestamp strings contain non-number characters they will be
' compared by their codepoint values.
'
' @param t1 String ByRef The first timestamp
' @param t2 String ByRef The second timestamp
' @return Integer 1, if the first timestamp is greater; 0, if they are equal; -1,
'    if the second is greater
Function CompareTimestamps(ByRef t1 As String, ByRef t2 As String) As Integer
    Dim i As Integer
    For i = 1 To WorksheetFunction.Min(Len(t1), Len(t2))
        If Mid(t1, i, 1) > Mid(t2, i, 1) Then
            CompareTimestamps = 1
            Exit Function
        End If
        If Mid(t1, i, 1) < Mid(t2, i, 1) Then
            CompareTimestamps = -1
            Exit Function
        End If
    Next
    CompareTimestamps = 0
End Function

Sub dropdown_Lueftung()
    Dim sheet_eing As Worksheet
    Set sheet_eing = Worksheets("HAUPTSEITE")
    Dim dd_Anlage As DropDown
    Set dd_Anlage = sheet_eing.DropDowns("dd_lueftung")
    Dim dd_wrg As DropDown
    Set dd_wrg = sheet_eing.DropDowns("Dropdown33")
    
    Select Case dd_Anlage.ListIndex
        Case 1: dd_wrg.List = Worksheets("Wetterdateien").Range("R1")
                    dd_wrg.ListIndex = 1
        
        Case 2:  dd_wrg.List = Worksheets("Wetterdateien").Range("R1:R3")
                    dd_wrg.ListIndex = 1
    End Select
End Sub
 
Sub label_geom()
    ActiveSheet.Shapes.Range(Array("label_geom_gen")).Visible = Sheets("Wetterdateien").Range("geometry_source") = 2
    ActiveSheet.Shapes.Range(Array("label_geom_imp")).Visible = Sheets("Wetterdateien").Range("geometry_source") = 1
End Sub
