Attribute VB_Name = "RunOpenStudioCLI"
Sub RunOpenStudioCLI()
    Dim Argument As String
    Dim processMessage As String

    Sheets("Hauptseite").Select

    Argument = GetRubyExePath() & " " & Chr(34) & GetMeasuresFolder & "/gensim_cli.rb" & Chr(34) _
        & " create_empty_osm --output_folder=" & Chr(34) & GetOutputFolder() & Chr(34) _
        & " " & Range("FileName") + ".osm"
    retval = ExecCmd(Argument)

    Argument = GetRubyExePath() & " " & Chr(34) & GetMeasuresFolder & "/gensim_cli.rb" & Chr(34) _
        & " run_workflow --output_folder=" & Chr(34) & GetOutputFolder() & Chr(34) _
        & " --os_bin_path=" & Chr(34) & GetOpenStudioBinPath() & "/openstudio.exe" & Chr(34) _
        & " " + Range("FileName") + ".osw"
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
