Attribute VB_Name = "UIFunctions"
Dim strOpenStudioDir As String
Dim strMeasureDir As String
Dim strOutputDir As String
Dim strWeatherDir As String

Function GetOpenStudioBinPath()
    If Range("DirOpenStudio") = "" Then
        GetOpenStudioBinPath = "C:\OpenStudio-2.5.0\bin"
    Else
        GetOpenStudioBinPath = Range("DirOpenStudio") & "\bin"
    End If
End Function
    
Function GetRubyPath()
    If Range("DirOpenStudio") = "" Then
        GetRubyPath = "C:\Program Files\OpenStudio 1.14.0\ruby-install\ruby\bin\"
    Else
        GetRubyPath = Range("DirOpenStudio") & "\ruby-install\ruby\bin\"
    End If
End Function

Function GetMeasuresFolder()
    GetMeasuresFolder = Application.ActiveWorkbook.path & "\Measures"
End Function

Function GetWeatherFolder()
    GetWeatherFolder = Application.ActiveWorkbook.path & "\Wetter"
End Function
   
Function GetOutputFolder()
    GetOutputFolder = Application.ActiveWorkbook.path & "\Output"
       
    If Dir(GetOutputFolder, vbDirectory) = "" Then
        MkDir GetOutputFolder
    End If
End Function
   
Function GetWorkingPath()
    Dim sTempPath As String
    sTempPath = Application.ActiveWorkbook.path & "\Temp"
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
    
    Range("ThisDir") = Application.ActiveWorkbook.path
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
    Set objFolder = objFSO.GetFolder(Application.ActiveWorkbook.path & "\Wetter")

    Set sht = ThisWorkbook.Worksheets("Wetterdateien")
    i = 0
    'loops through each file in the directory and prints their names and path
    For Each objFile In objFolder.Files()
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
        strOpenStudioDir = "C:\Program Files\OpenStudio 1.12.4"
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
        Range("ThisDir") = Application.ActiveWorkbook.path
    End If
    If Range("MeasuresDir") = "" Then
        strMeasureDir = Application.ActiveWorkbook.path & "\Measures"
    Else
        strMeasureDir = Range("MeasuresDir")
    End If
    strMeasureDir = GetFolder("Bitte wähle den Ordner der OpenStudio Installation", strMeasureDir)
    Range("MeasuresDir") = strMeasureDir
End Sub

Sub BrowseOutputDir()
    If Range("ThisDir") = "" Then
        Range("ThisDir") = Application.ActiveWorkbook.path
    End If
    If Range("OutputDir") = "" Then
        strOutputDir = Application.ActiveWorkbook.path & "\Output"
    Else
        strOutputDir = Range("OutputDir")
    End If
    strOutputDir = GetFolder("Bitte wähle den Ordner der OpenStudio Installation", strOutputDir)
    Range("OutputDir") = strOutputDir
End Sub

Sub BrowseWeatherDir()
    If Range("ThisDir") = "" Then
        Range("ThisDir") = Application.ActiveWorkbook.path
    End If
    If Range("WeatherDir") = "" Then
        strWeatherDir = Application.ActiveWorkbook.path & "\Wetter"
    Else
        strWeatherDir = Range("WeatherDir")
    End If
    strWeatherDir = GetFolder("Bitte wähle den Ordner der OpenStudio Installation", strWeatherDir)
    Range("WeatherDir") = strWeatherDir
End Sub

Function load_file_from_folder(filetype As String)
    Dim result As Integer
    Dim selectedPath As String
    Dim zipPath As Variant
    Dim isComplete As Boolean: isComplete = True
    Dim fileDialog As fileDialog: Set fileDialog = Application.fileDialog(msoFileDialogFilePicker)

    fileDialog.InitialFileName = Application.ActiveWorkbook.path
    fileDialog.ButtonName = "Speichern"
    fileDialog.Title = "Bitte Datei auswählen"
    fileDialog.InitialFileName = Application.ActiveWorkbook.path & "\*." & filetype
    fileDialog.Filters.Clear
    fileDialog.Filters.Add filetype & " Files", "*." & filetype, 1
    fileDialog.FilterIndex = 1

    result = fileDialog.Show

    If result <> 0 Then
        load_file_from_folder = fileDialog.SelectedItems(1)
    End If
End Function

Sub import_geometry_osm()
    path_osm = load_file_from_folder("osm")
    If path_osm <> Empty Then
        Range("path_geometry_Import") = path_osm
    End If
End Sub

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
        myFile = Application.ActiveWorkbook.path & "\Wetter\" & dd.List(dd.Value)
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

Sub Ansicht_Normen()
    Sheets("HAUPTSEITE").Unprotect
    Application.GoTo Reference:=Sheets("Referenzwerte Normen").Range("A1"), Scroll:=True
    Sheets("HAUPTSEITE").Protect
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
    fileDialog.InitialFileName = Application.ActiveWorkbook.path & "\Output"
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

    Dim cb_buildingSim As CheckBox
    Set cb_buildingSim = Sheets("HAUPTSEITE").CheckBoxes("checkbox_buildingsim")
    Dim cb_pvSim As CheckBox
    Set cb_pvSim = Sheets("HAUPTSEITE").CheckBoxes("checkbox_pvsim")

    If cb_pvSim.Value = 1 And Not cb_buildingSim.Value = 1 Then
        MsgBox "Bei einer reinen PV-Simulation wird kein Export durchgeführt."
        Exit Sub
    End If

    Dim varResult As Variant
    'displays the save file dialog
    varResult = Application.GetSaveAsFilename(FileFilter:= _
        "OSW Files (*.osw), *.osw", Title:="Bitte Speicherort auswählen", _
        InitialFileName:=Application.ActiveWorkbook.path & "\Output\exported.osw")
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
    Dim filename As String
    Dim result As Integer
    Dim last As String
    
    current = Dir(Application.ActiveWorkbook.path & "\Output\run\eplusout.err")
    filename = current
    Do While Len(current) > 0
        last = current
        current = Dir
        If Len(current) > 0 Then
            If CompareTimestamps(current, last) > 0 Then
                filename = current
            End If
        End If
    Loop
    
    If (filename <> "") Then
        result = Shell("notepad.exe " & Application.ActiveWorkbook.path & "\Output\run\" & filename, vbNormalFocus)
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

Sub label_building_pv()
    Dim cb_buildingSim As CheckBox
    Set cb_buildingSim = Sheets("HAUPTSEITE").CheckBoxes("checkbox_buildingsim")
    Dim cb_pvSim As CheckBox
    Set cb_pvSim = Sheets("HAUPTSEITE").CheckBoxes("checkbox_pvsim")

    ActiveSheet.Shapes.Range(Array("label_building")).Visible = cb_buildingSim.Value <> 1
    ActiveSheet.Shapes.Range(Array("label_pv")).Visible = cb_pvSim.Value <> 1
End Sub
