Attribute VB_Name = "RunOpenStudioCLI"
Sub RunOpenStudioCLI()
    Dim Argument As String
    Dim processMessage As String

    CreateEmptyOSMFile GetOutputFolder() & "\" + Range("FileName") + ".osm"

    Argument = Chr(34) & GetOpenStudioBinPath() & "\OpenStudio.exe" & Chr(34) & " --verbose run --workflow " & Chr(34) & GetOutputFolder() & "\" + Range("FileName") + ".osw" & Chr(34)

    Sheets("Hauptseite").Select
    retval = ExecCmd(Argument)

    Range("Status").Offset(1, 1) = "beendet (" & WorksheetFunction.Round((Time - Startzeit_indv) * 86400, 1) & " s)"
    Startzeit_indv = Time

    DoEvents

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
        Elseif InStr(ErrorString, "Successfully") Then
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

Sub CreateEmptyOSMFile(sOSMFilePath As String)
    Dim fso As Object
    Set fso = CreateObject("Scripting.FileSystemObject")
    Dim oFile As Object
    Set oFile = fso.CreateTextFile(sOSMFilePath)
    oFile.WriteLine "OS:Version,"
    oFile.WriteLine "  {0f20289d-c9f3-4775-8548-e6b6a77e899a}, !- Handle"
    oFile.WriteLine "  2.5.0;                                  !- Version Identifier"
    oFile.WriteLine ""
    ' should we include anything Else here To make it run smoother?
    oFile.Close
    Set fso = Nothing
    Set oFile = Nothing
End Sub
