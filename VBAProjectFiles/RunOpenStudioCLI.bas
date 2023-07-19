Attribute VB_Name = "RunOpenStudioCLI"
Sub RunOpenStudioCLI()
    Dim Argument As String
    Dim processMessage As String
    
    CreateEmptyOSMFile GetOutputFolder() & "\" + Range("FileName") + ".osm"
        
    'argument = Chr(34) & GetOpenStudioBinPath() & "\OpenStudio.exe" & Chr(34) & " --verbose run --workflow " & Chr(34) & GetOutputFolder() & "\" + Range("FileName") + ".osw" & Chr(34)
    Argument = Chr(34) & GetOpenStudioBinPath() & "\OpenStudio.exe" & Chr(34) & " --verbose run --workflow " & Chr(34) & GetOutputFolder() & "\" + Range("FileName") + ".osw" & Chr(34)
    
    Sheets("Hauptseite").Select
    retval = ExecCmd(Argument)
    
    Range("Status").Offset(1, 1) = "beendet (" & WorksheetFunction.Round((Time - Startzeit_indv) * 86400, 1) & " s)"
    Startzeit_indv = Time
    
    DoEvents
    ' "C:\openstudio-2.5.0\bin\OpenStudio.exe" --verbose run --workflow "R:\GenSimEPlus\GenSimEPlus\Output\" + Range("FileName") + ".osw"
 '   processMessage = ShellRun(Argument)
    
    'RunOpenStudioWithProgressMessagesInExcel Argument
 '   RunOpenStudioWithProgressMessages Argument
 '   Argument = "cmd.exe /S /K" & Chr(34) & Argument & Chr(34)
 '   Argument = Chr(34) & Argument & Chr(34)
'    retval = Shell(Argument, vbNormalFocus)
 '   retval = ExecCmd(Argument)
'    Dim jFile As New JSONFile
'    jFile.ParseOutputFile GetOutputFolder() & "\out.osw"
    
    Range("Status").Offset(2, 0) = "Error-File einlesen"
    If retval > 0 Then
        MsgBox "Fehler waehrend der Simulation, Fehler Code: " & retval
        Range("SimStatus") = "Simulation nicht erfolgreich"
        Exit Sub
    Else
        Dim ErrorString As String
        ErrorString = IOFunctions.CheckErrFile(GetOutputFolder() & "\run\eplusout.err")
        If InStr(ErrorString, "Fatal Error Detected") Then
            Range("SimStatus") = "mit Fehlern"
        ElseIf InStr(ErrorString, "Successfully") Then
            Range("SimStatus") = "Erfolgreich"
        Else
            Range("SimStatus") = "Unbekannt"
        End If
        Range("StatusEnergyPlusSimulation") = ErrorString
    End If
    Range("Status").Offset(2, 1) = "beendet (" & WorksheetFunction.Round((Time - Startzeit_indv) * 86400, 1) & " s)"
    Startzeit_indv = Time
    
    DoEvents
    If Range("SimStatus") = "Erfolgreich" Then
        Range("Status").Offset(3, 0) = "CSV Datei generieren"
        If IOFunctions.ConvertESOFile(GetOutputFolder() & "\run\eplusout.eso") Then
            Range("Status").Offset(3, 1) = "beendet (" & WorksheetFunction.Round((Time - Startzeit_indv) * 86400, 1) & " s)"
            Startzeit_indv = Time
            
            DoEvents
            
            Range("Status").Offset(4, 0) = "CSV Datei importieren"
            IOFunctions.ImportCSVFileNEW GetOutputFolder() & "\run\eplusout.csv"
            Range("Status").Offset(4, 1) = "beendet (" & WorksheetFunction.Round((Time - Startzeit_indv) * 86400, 1) & " s)"
            Startzeit_indv = Time
            
            DoEvents
            
            Range("Status").Offset(4, 0) = "EIO Datei importieren"
            IOFunctions.ParseEIOFile GetOutputFolder() & "\run\eplusout.eio"
            Range("Status").Offset(4, 1) = "beendet (" & WorksheetFunction.Round((Time - Startzeit_indv) * 86400, 1) & " s)"
            Startzeit_indv = Time
            
            DoEvents
            
            Range("Status").Offset(5, 0) = "Profile/Jahreswerte bilden"
            CreateResults
            If Range("param_delete_sheet_rawresults") = "Ja" Then
                Application.DisplayAlerts = False
                Sheets("RawResults").Delete
                Application.DisplayAlerts = True
            End If
            Range("Status").Offset(5, 1) = "beendet (" & WorksheetFunction.Round((Time - Startzeit_indv) * 86400, 1) & " s)"
            Startzeit_indv = Time
                
            DoEvents
        Else
            Range("Status").Offset(4, 0) = "Fehler bei generieren der CSV Datei"
            
            DoEvents
        End If
    End If
End Sub

'Sub RunOpenStudioWithProgressMessagesInExcel(Argument As String)
'    Dim wShell As New WshShell
'    Dim wsExec As WshExec
'
'    Dim iRow As Integer
'    iRow = 0
'    Set wsExec = wShell.Exec(Argument)
'    Do While wsExec.Status = 0
'        'range("ProgressString").Offset(4, 0) = range("ProgressString").Offset(3, 0)
'        'range("ProgressString").Offset(3, 0) = range("ProgressString").Offset(2, 0)
'        'range("ProgressString").Offset(2, 0) = range("ProgressString").Offset(1, 0)
'        'range("ProgressString").Offset(1, 0) = range("ProgressString")
'        range("ProgressString") = wsExec.StdOut.ReadLine
'        If InStr(range("ProgressString"), "Error") Then
'            range("EnergyPlusErrors").Offset(iRow, 0) = range("ProgressString")
'            iRow = iRow + 1
'        End If
'        DoEvents
'    Loop
'End Sub

Sub RunOpenStudioWithProgressMessages(Argument As String)
    Dim wShell As New WshShell
    Dim wsExec As WshExec
    
    Dim iRow As Integer
    iRow = 0
    Set wsExec = wShell.Exec(Argument)
    Do While wsExec.Status = 0
        'range("ProgressString").Offset(4, 0) = range("ProgressString").Offset(3, 0)
        'range("ProgressString").Offset(3, 0) = range("ProgressString").Offset(2, 0)
        'range("ProgressString").Offset(2, 0) = range("ProgressString").Offset(1, 0)
        'range("ProgressString").Offset(1, 0) = range("ProgressString")
        Application.Wait Now + TimeValue("0:00:01")
    Loop
End Sub


Sub CreateEmptyOSMFile(sOSMFilePath As String)
    Dim fso As Object
    Set fso = CreateObject("Scripting.FileSystemObject")
    Dim oFile As Object
    Set oFile = fso.CreateTextFile(sOSMFilePath)
    oFile.WriteLine "OS:Version,"
    oFile.WriteLine "  {0f20289d-c9f3-4775-8548-e6b6a77e899a}, !- Handle"
    oFile.WriteLine "  2.5.0;                                  !- Version Identifier"
    oFile.WriteLine ""
' should we include anything else here to make it run smoother?
    oFile.Close
    Set fso = Nothing
    Set oFile = Nothing
End Sub
