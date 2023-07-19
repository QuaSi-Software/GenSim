Attribute VB_Name = "SensibilityAnalysis"
Option Explicit

Sub sens2()

'#### Variablen Deklaration
'-----------------------------------

Dim index(1 To 4) As Integer
Dim input_aktiv(1 To 4) As Boolean
Dim input_anzahl_durchlaeufe(1 To 4) As Integer
Dim i As Integer
Dim j As Integer
Dim k As Integer
Dim l As Integer
Dim a As Integer
Dim b As Integer
Dim counter As Integer

'Input Parameter
Dim input_parameter As Variant
ReDim input_parameter(1 To 4, 1 To 7)
'Output Parameter
Dim output_parameter As Variant
ReDim output_parameter(1 To 10, 1 To 4)
'Input Parameter Werte
ReDim input_parameter_werte(1 To 4) As Variant

'#### Berechnung auf Manuell
'-----------------------------------
Application.Calculation = xlCalculationManual

'#### Parameter aus Excel einlesen
'-----------------------------------

'Input Parameter
input_parameter = ActiveSheet.Range("A11:G14")
For a = 1 To 4
    input_aktiv(a) = ActiveSheet.OLEObjects("cb_sens" & a).Object.Value = True
Next
'Output-Größen
output_parameter = ActiveSheet.Range("A19:D28")

'#### Output löschen
'-----------------------------------

Sheets("Sensibilitätsanalyse").Unprotect
Sheets("Sensibilitätsanalyse").Range("I10:V1000").ClearContents

'#### Beschriftung erstellen
'-----------------------------------
For a = 1 To 10
    'Output-Werte (1 ... 10)
    Range("sens_out").Offset(0, a - 1 + 4) = CStr(output_parameter(a, 4))
    'Input-Werte (1 ... 4)
    If a <= 4 Then Range("sens_out").Offset(0, a - 1) = CStr(input_parameter(a, 7))
Next

'#### Parameterstudie
'-----------------------------------
For a = 1 To 4
    input_anzahl_durchlaeufe(a) = IIf(IsEmpty(input_parameter(a, 6)) Or Not input_aktiv(a), 0, input_parameter(a, 6) - 1)
Next

If WorksheetFunction.Sum(input_anzahl_durchlaeufe) = 0 Then Exit Sub

For i = 0 To input_anzahl_durchlaeufe(1)
    For j = 0 To input_anzahl_durchlaeufe(2)
        For k = 0 To input_anzahl_durchlaeufe(3)
            For l = 0 To input_anzahl_durchlaeufe(4)
                                
                index(1) = i
                index(2) = j
                index(3) = k
                index(4) = l
    
                '###Parameter schreiben für bis zu 4 Input-Parameter
                For a = 1 To 4
                    If input_aktiv(a) Then 'wenn Parameter aktiv
                        
                        'Werte der Input-Parameter erzeugen
                        input_parameter_werte(a) = input_parameter(a, 4) + (input_parameter(a, 5) - input_parameter(a, 4)) * index(a) / (input_parameter(a, 6) - 1)
                        Debug.Print "Input-Parameter " & a & " / Durchlauf " & counter & " : " & input_parameter_werte(a)
                        'Werte in Excel-Zellen schreiben
                        Sheets(CStr(input_parameter(a, 2))).Range(CStr(input_parameter(a, 3))) = input_parameter_werte(a)
                    
                    End If
                Next
                 
                '###Simulation
                CreateWorkflowAndExecute
                Application.Calculation = xlCalculationManual
                Worksheets("SENSIBILITÄTSANALYSE").Activate
                 
                '###Ergebnisse in Excel schreiben
                counter = counter + 1
                For a = 1 To 10
                    'Input-Werte schreiben (1 ... 4)
                    For b = 1 To 4
                        Range("sens_out").Offset(counter, b - 1) = input_parameter_werte(b)
                    Next
                    'Output-Werte schreiben (1 ... 10)
                    Range("sens_out").Offset(counter, a - 1 + 4) = Sheets(CStr(output_parameter(a, 2))).Range(CStr(output_parameter(a, 3)))
                Next
                 
            Next 'i
        Next 'j
    Next 'k
Next 'l

'#### Berechnung auf Manuell
Application.Calculation = xlCalculationAutomatic

Sheets("Sensibilitätsanalyse").Protect

End Sub
