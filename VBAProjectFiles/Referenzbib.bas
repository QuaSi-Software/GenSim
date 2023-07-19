Attribute VB_Name = "Referenzbib"
Public Sub Update_Datenbank()
    Dim d1 As ControlFormat
    Set d1 = Sheets("Referenzbibliothek").Shapes("dd_1").ControlFormat
    Dim Datenbank As clsDatenbank
    Set Datenbank = New clsDatenbank
    Dim optAuswahl_d0() As Variant
    
    d1.RemoveAllItems
    optAuswahl_d0 = Datenbank.StartSelection()

    With d1
        numKeys = UBound(optAuswahl_d0) - LBound(optAuswahl_d0) + 1
        For i = 1 To numKeys
        optAuswahl_d0(i - 1) = Replace(optAuswahl_d0(i - 1), "$$", "-")
          .AddItem optAuswahl_d0(i - 1)
        Next i
        .Value = vbEmpty
    End With
    
End Sub

Public Sub Referenzwerte_Normen()

    Application.Calculation = xlCalculationManual

    Dim d1 As ControlFormat
    Set d1 = ActiveSheet.Shapes("dd_1").ControlFormat
    Dim d2 As ControlFormat
    Set d2 = ActiveSheet.Shapes("dd_2").ControlFormat
    Dim d3 As ControlFormat
    Set d3 = ActiveSheet.Shapes("dd_3").ControlFormat
    Dim d4 As ControlFormat
    Set d4 = ActiveSheet.Shapes("dd_4").ControlFormat
    '_ALT:
    '       d1 - c
    '       d2 - e
    '       d3 - f
    '       d4 - g
    
    Dim index_d1 As Integer
    index_d1 = d1.ListIndex
    Dim entry_d1 As Variant
    entry_d1 = d1.List
    Dim index_d2 As Integer
    
    Dim Datenbank As clsDatenbank
    Set Datenbank = New clsDatenbank
    
    Dim optAuswahl_d2() As Variant
    Dim p1 As Variant
    Dim numKeys As Integer
    
    d2.RemoveAllItems
    d3.RemoveAllItems
    d4.RemoveAllItems
    Range("e8:j8").Clear
    Range("e9:j9").Clear
    Range("e10:j10").Clear
    
    p1 = Replace(entry_d1(index_d1), "-", "$$")
    optAuswahl_d2 = Datenbank.KeySelection(1, p1)
    
    With d2
        numKeys = UBound(optAuswahl_d2) - LBound(optAuswahl_d2) + 1
        For i = 1 To numKeys
        optAuswahl_d2(i - 1) = Replace(optAuswahl_d2(i - 1), "$$", "-")
          .AddItem optAuswahl_d2(i - 1)
        Next i
    End With
    d2.Value = vbEmpty
    
    Application.Calculation = xlCalculationAutomatic

End Sub


'Mit Auswahlinformation aus d2 - befülle Liste d3________
'---------------------------------------------------------
Public Sub Referenzwerte_Normen_e()
'-------------------------------------------------------

    Application.Calculation = xlCalculationManual
    
    Dim d1 As ControlFormat
    Set d1 = ActiveSheet.Shapes("dd_1").ControlFormat
    Dim d2 As ControlFormat
    Set d2 = ActiveSheet.Shapes("dd_2").ControlFormat
    Dim d3 As ControlFormat
    Set d3 = ActiveSheet.Shapes("dd_3").ControlFormat
    Dim d4 As ControlFormat
    Set d4 = ActiveSheet.Shapes("dd_4").ControlFormat
    
    Dim index_d1 As Integer
    index_d1 = d1.ListIndex
    Dim entry_d1 As Variant
    entry_d1 = d1.List
    Dim index_d2 As Integer
    index_d2 = d2.ListIndex
    Dim entry_d2 As Variant
    entry_d2 = d2.List
    
    Dim Datenbank As clsDatenbank
    Set Datenbank = New clsDatenbank
    
    Dim optAuswahl_d3() As Variant
    Dim p1 As Variant
    Dim p2 As Variant
    Dim numKeys As Integer

    d3.RemoveAllItems
    d4.RemoveAllItems
    
    p1 = Replace(entry_d1(index_d1), "-", "$$")
    p2 = Replace(entry_d2(index_d2), "-", "$$")
    optAuswahl_d3 = Datenbank.KeySelection(2, p1, p2)
    
    With d3
        numKeys = UBound(optAuswahl_d3) - LBound(optAuswahl_d3) + 1
        For i = 1 To numKeys
          optAuswahl_d3(i - 1) = Replace(optAuswahl_d3(i - 1), "$$", "-")
          .AddItem optAuswahl_d3(i - 1)
        Next i
    End With
    
    d3.Value = vbEmpty
    
    Application.Calculation = xlCalculationAutomatic

End Sub


'_Mit Auswahl d3 - befülle Liste d4_______________________
'---------------------------------------------------------
Public Sub Referenzwerte_Normen_f()
'----------------------------------------------------

    Application.Calculation = xlCalculationManual
    
    Dim d1 As ControlFormat
    Set d1 = ActiveSheet.Shapes("dd_1").ControlFormat
    Dim d2 As ControlFormat
    Set d2 = ActiveSheet.Shapes("dd_2").ControlFormat
    Dim d3 As ControlFormat
    Set d3 = ActiveSheet.Shapes("dd_3").ControlFormat
    Dim d4 As ControlFormat
    Set d4 = ActiveSheet.Shapes("dd_4").ControlFormat
    
    Dim index_d1 As Integer
    index_d1 = d1.ListIndex
    Dim entry_d1 As Variant
    entry_d1 = d1.List
    Dim index_d2 As Integer
    index_d2 = d2.ListIndex
    Dim entry_d2 As Variant
    entry_d2 = d2.List
    Dim index_d3 As Integer
    index_d3 = d3.ListIndex
    Dim entry_d3 As Variant
    entry_d3 = d3.List
    
    Dim Datenbank As clsDatenbank
    Set Datenbank = New clsDatenbank
    
    Dim optAuswahl_d4() As Variant
    Dim p1 As Variant
    Dim p2 As Variant
    Dim p3 As Variant
    Dim numKeys As Integer
    
    d4.RemoveAllItems
    
    p1 = Replace(entry_d1(index_d1), "-", "$$")
    p2 = Replace(entry_d2(index_d2), "-", "$$")
    p3 = Replace(entry_d3(index_d3), "-", "$$")
    optAuswahl_d4 = Datenbank.KeySelection(3, p1, p2, p3)
    
    With d4
        numKeys = UBound(optAuswahl_d4) - LBound(optAuswahl_d4) + 1
        For i = 1 To numKeys
        optAuswahl_d4(i - 1) = Replace(optAuswahl_d4(i - 1), "$$", "-")
          .AddItem optAuswahl_d4(i - 1)
        Next i
    End With
    d4.Value = vbEmpty
    
    Application.Calculation = xlCalculationAutomatic

End Sub

Public Sub Referenzwerte_Normen_g()

    Application.Calculation = xlCalculationManual
    
    Dim d1 As ControlFormat
    Set d1 = ActiveSheet.Shapes("dd_1").ControlFormat
    Dim d2 As ControlFormat
    Set d2 = ActiveSheet.Shapes("dd_2").ControlFormat
    Dim d3 As ControlFormat
    Set d3 = ActiveSheet.Shapes("dd_3").ControlFormat
    Dim d4 As ControlFormat
    Set d4 = ActiveSheet.Shapes("dd_4").ControlFormat
    
    Dim index_d1 As Integer
    index_d1 = d1.ListIndex
    Dim entry_d1 As Variant
    entry_d1 = d1.List
    Dim index_d2 As Integer
    index_d2 = d2.ListIndex
    Dim entry_d2 As Variant
    entry_d2 = d2.List
    Dim index_d3 As Integer
    index_d3 = d3.ListIndex
    Dim entry_d3 As Variant
    entry_d3 = d3.List
    Dim index_d4 As Integer
    index_d4 = d4.ListIndex
    Dim entry_d4 As Variant
    entry_d4 = d4.List
    
    Dim Datenbank As clsDatenbank
    Set Datenbank = New clsDatenbank
    
    Dim p1 As Variant
    Dim p2 As Variant
    Dim p3 As Variant
    Dim p4 As Variant
    Dim erg As Variant

    '__ Clear Ausgabebereich
    Range("e8:l15").Clear
    With ActiveSheet.Cells(13, "f")
        .Borders.LineStyle = xlNone
        .Interior.ColorIndex = 0
    End With
    
    p1 = Replace(entry_d1(index_d1), "-", "$$")
    p2 = Replace(entry_d2(index_d2), "-", "$$")
    p3 = Replace(entry_d3(index_d3), "-", "$$")
    p4 = Replace(entry_d4(index_d4), "-", "$$")


    '__ Wert aus Tabelle suchen:
    erg = Datenbank.TableValue(p1, p2, p3, p4)
    
    
    '__ Ausgabe:
    'erg = Replace(erg, "$$", "- keine Angabe -")
    erg = IIf(erg = "$$", "- keine Angabe -", Round(erg, 2))
    ActiveSheet.Cells(10, "e") = erg
    ActiveSheet.Cells(10, "e").Font.Bold = True
    Select Case index_d1
    
        Case 1: ' Geräte
            With ActiveSheet
                .Cells(9, "e") = "Spezifische Leistung:"
                .Cells(10, "f") = IIf(entry_d2(index_d2) = "ASHRAE 90.1 2013", "   [W/m²BGF]", "   [W/m²NGF]")
                .Columns.Hidden = False
                .Rows.EntireRow.Hidden = False
                .Range("A38:A39").EntireRow.Hidden = True
            End With

        Case 2: ' Beleuchtung
            With ActiveSheet
                .Cells(9, "e") = "Spezifische elektrische Leistung:"
                .Cells(10, "f") = IIf(entry_d2(index_d2) = "ASHRAE 90.1 2013", "   [W/m²BGF]", "   [W/m²NGF]")
                .Columns.Hidden = False
                .Rows.EntireRow.Hidden = False
                .Range("A38:A59").EntireRow.Hidden = True
            End With
            
        Case 3: ' Personenbelegung
            With ActiveSheet
                .Cells(9, "e") = "Raumbedarf:"
                .Cells(10, "f") = IIf(entry_d2(index_d2) = "ASHRAE 90.1 2013", "   [m²BGF/Person]", "    [m²NGF/Person]")
                .Columns.Hidden = False
                .Rows.EntireRow.Hidden = False
                .Range("A38:A72").EntireRow.Hidden = True
            End With
            
        Case 4: ' Raumtemperatur
            With ActiveSheet
                .Cells(9, "e") = "Raumtemperatur:"
                .Cells(10, "f") = "   [°C]"
                .Columns.Hidden = False
                .Rows.EntireRow.Hidden = False
                .Range("A38:A91").EntireRow.Hidden = True
            End With
            
        Case 5: ' Luftwechselrate
            With ActiveSheet
                .Cells(9, "e") = "Luftwechsel:"
                .Cells(10, "f") = "   [1/h]"
                .Columns.Hidden = False
                .Rows.EntireRow.Hidden = False
                .Range("A38:A113").EntireRow.Hidden = True
                If index_d2 = 2 Then
                    .Range("A116:A125").EntireRow.Hidden = True
                ElseIf index_d2 = 3 Then
                    .Range("A116:A139").EntireRow.Hidden = True
                End If
            End With
            MsgBox "Individuelle Werte für die Berechnung" & vbNewLine & "bitte in unten stehendem Eingabefeld ändern"
            
        
        Case 6: ' Infiltration
            With ActiveSheet
                .Cells(9, "e") = "Infiltrationsluftwechsel n_inf:"
                .Cells(10, "f") = "   [1/h]"
                .Columns.Hidden = False
                .Rows.EntireRow.Hidden = False
                .Range("A38:A150").EntireRow.Hidden = True
            End With
            MsgBox "Individuelle Werte für die Berechnung" & vbNewLine & "bitte in unten stehendem Eingabefeld ändern"

    End Select
    
    Application.Calculation = xlCalculationAutomatic
    
End Sub

Sub ShowEntireTable()
      ActiveSheet.Columns.Hidden = False        'Kurzform
      ActiveSheet.Rows.EntireRow.Hidden = False 'Langform
End Sub

