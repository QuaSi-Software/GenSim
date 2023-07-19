Attribute VB_Name = "Base"
Option Explicit

Const SCRIPTING_RUNTIME_GUID As String = "{420B2830-E718-11CF-893D-00A0C9054228}"

' Activates the required MS VBA Extensibility 5.3 library "VBIDE"
Sub ActivateRequiredLibraries()
    Dim VBEobj As Object
    On Error Resume Next
    VBEobj = Application.VBE.ActiveVBProject.References.AddFromGuid( _
        "{0002E157-0000-0000-C000-000000000046}", 5, 3 _
    )
End Sub

' Activates the scripting runtime
Sub ActivateScriptingRuntime()
    Dim objRef As Object
    On Error GoTo Cleanup

    Set objRef = ThisWorkbook.VBProject.References
    objRef.AddFromGuid SCRIPTING_RUNTIME_GUID, 1, 0

Cleanup:
    Set objRef = Nothing
    If Err.Number = 32813 Then Exit Sub
    If Err.Number <> 0 Then
        MsgBox "Error: " & Err.Number & " " & Err.Description
    End If
End Sub

Sub Main()
    Call ActivateScriptingRuntime
End Sub
