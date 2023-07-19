VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "clsDatenbank"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False

'----- Variablen Deklaration
'----------

'private

Private DataTree As Scripting.Dictionary
Private P As Scripting.Dictionary                 ' (X) in Sub instanziieren ?!
Private sheet As Worksheet
'Private pBerechnet As Boolean

'Out
Private pTableValue As Variant 'Double
Private pKeyArray() As Variant
Private p1 As Variant
Private p2 As Variant
Private p3 As Variant
Private p4 As Variant
'Private path(1 To 4) As String


'----- Properies
'----------

Public Property Get StartSelection()
    'MsgBox "Property 'Update_Datenbank' in clsDatenbank found."
    
    sub_creatDataTree
    'MsgBox "DataTree erstellt"
    
    pKeyArray = DataTree.Keys
    StartSelection = pKeyArray
    'MsgBox "StartSelection erfolgreich rausgeschrieben"
    
End Property
    
 


Public Property Get KeySelection(numKeys As Integer, k1 As Variant, Optional k2 As Variant, Optional k3 As Variant)      ' einfacher mit Overloads...?!
'    MsgBox "Property 'KeySelection' in clsDatenbank found."
    
    sub_creatDataTree
'    MsgBox "DataTree erstellt"
    
    Select Case numKeys
      Case 1
        p1 = k1
        sub_Keys1
        KeySelection = pKeyArray
      Case 2
        p1 = k1
        p2 = k2
        sub_Keys2
        KeySelection = pKeyArray
      Case 3
        p1 = k1
        p2 = k2
        p3 = k3
        sub_Keys3
        KeySelection = pKeyArray
    End Select

End Property

Public Property Get TableValue(Path1 As Variant, Path2 As Variant, Path3 As Variant, Path4 As Variant)
'    MsgBox "Property in clsDatenbank found."
    p1 = Path1
    p2 = Path2
    p3 = Path3
    p4 = Path4
    
    sub_creatDataTree
'    MsgBox "DataTree erstellt"
    sub_searchValue
    TableValue = pTableValue
'    MsgBox "searchValue beendet."
    
End Property


'----- DataTree aus Tabelle erzeugen (Tabelle angeben oder fest verankert?)
'----------

Sub sub_creatDataTree()
    
    '_ interne Variablen__
    Dim z As Integer
    z = 5
    Dim i As Integer
    i = 1
    Dim n As Integer
    n = 1
    Dim cellValue As String
    Dim pPath As Scripting.Dictionary
    Set pPath = New Scripting.Dictionary
    Set DataTree = New Scripting.Dictionary         'doppelt deklariert?!
                                                    'kann ich aus anderen Properties auf das erstellte Dict zugreifen?
                                                    'Oder erstelle ich mir den sowieso immer neu?
                                                    'dann brauche ich diesen nicht als private Variable?
    Set sheet = Worksheets("Tabelle1") 'RefBib
    
    pPath.Add 0, DataTree
    
    'Zählvariablen:
'   z - äußere Schleife, läuft die Tabellenzeilen runter (1,2,...)
'   i - fängt in jeder neuen Zeile vorne an und läuft bis zum ersten Eintrag (bzw. dann bis zum letzten Eintrag, dem ein leeres Feld folgt...)
'   n - dient als Hilfsvariable für den Zugriff auf das Dict 'Path', in dem die (aktuellste) 'Schlüsselreihung' einer jeden Generation liegt
    
    With sheet
    '------ Schranke für z finden:
        If Application.WorksheetFunction.CountA(.Cells) <> 0 Then
            lastrow = .Cells.Find(What:="*", _
                          After:=.Range("A1"), _
                          Lookat:=xlPart, _
                          LookIn:=xlFormulas, _
                          SearchOrder:=xlByRows, _
                          SearchDirection:=xlPrevious, _
                          MatchCase:=False).Row
        Else
            lastrow = 1
        End If
    '-------- Struktur erstellen und mit Werten aus Tabelle füllen
        While z <= lastrow                                                          'letzte Tabellenzeile, die eingepflegt wird
            i = 1
            While IsEmpty(.Cells(z, i)) And i <= 4  '(X)                            ' Schleife 1 - läuft bis zum ersten Eintrag der aktuellen Zeile z
                i = i + 1
            Wend
            Do                 ' (X) Schleifen evtl. sinvoller wählen               ' Schleife 2 - baut Pfad aus allen folgenden Einträge
                n = i
                cellValue = .Cells(z, i).Value
                If InStr(1, cellValue, "-") > 0 Or InStr(1, cellValue, "~") > 0 Or InStr(1, cellValue, "?") > 0 Then
                    MsgBox "ERROR: Key contains invalid value as '-', '~' or '?' - please use '$$' to replace the character '-'"
                End If
                If IsEmpty(.Cells(z, i + 2)) Then                                   ' C1 - prüft ob Ende der Zeile erreicht ist und ergänzt den finalen Wert, anstelle eines neuen Dict
                    pPath(n - 1).Add .Cells(z, i).Value, .Cells(z, i + 1).Value
                    Exit Do
                Else                                                                ' C2 - ergänzt ein neues Dict und verwendet den Zelleneintrag als Key
                    pPath(n - 1).Add .Cells(z, i).Value, New Scripting.Dictionary
                    If pPath.Exists(n) Then pPath.Remove n
                    pPath.Add n, pPath(n - 1)(.Cells(z, i).Value)
                    
                    n = n + 1
                    i = i + 1
                End If
            Loop
            z = z + 1
        Wend
    End With
    
End Sub

'----- mit Pfad aus Schlüsselwörtern zugehörigen Wert auslesen
'----------
Sub sub_searchValue()
        
    Dim x1 As Variant 'Double
    x1 = DataTree(p1)(p2)(p3)(p4)
    pTableValue = x1

End Sub
'----- mit Pfad aus Schlüsselwörtern vorhandene Keys abrufen
'----------
Sub sub_Keys1()
    Dim P As Scripting.Dictionary
    Set P = DataTree(p1)
    pKeyArray = P.Keys
End Sub
Sub sub_Keys2()
    Dim P As Scripting.Dictionary
    Set P = DataTree(p1)(p2)
    pKeyArray = P.Keys
End Sub
Sub sub_Keys3()
    Dim P As Scripting.Dictionary
    Set P = DataTree(p1)(p2)(p3)
    pKeyArray = P.Keys
End Sub


