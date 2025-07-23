Attribute VB_Name = "ImportExport"
Option Explicit

Const FS_SEPERATOR As String = "\"
Const EXPORT_FOLDER_NAME As String = "VBAProjectFiles"

Function ExportFolderPath() As String
    Dim workbook_path As String: workbook_path = Application.ActiveWorkbook.path

    If Right(workbook_path, 1) <> FS_SEPERATOR Then
        workbook_path = workbook_path & FS_SEPERATOR
    End If

    ExportFolderPath = workbook_path & EXPORT_FOLDER_NAME
End Function

Function EnsureFolderExists(ByVal folder_path As String) As String
    Dim file_system As Object: Set file_system = CreateObject("scripting.filesystemobject")

    If file_system.FolderExists(folder_path) = False Then
        On Error Resume Next
        MkDir folder_path
        On Error GoTo 0
    End If

    EnsureFolderExists = folder_path
    If file_system.FolderExists(folder_path) = False Then
        EnsureFolderExists = "Error"
    End If
End Function

Function ClearFolder(ByVal folder_path As String) As String
    Dim pattern As String: pattern = folder_path

    If Right(pattern, 1) <> FS_SEPERATOR Then
        pattern = pattern & FS_SEPERATOR
    End If
    pattern = pattern & "*.*"

    On Error Resume Next
        Kill pattern
    On Error GoTo 0
End Function

Public Sub ExportVBACode()
Attribute ExportVBACode.VB_ProcData.VB_Invoke_Func = "e\n14"
    Dim Workbook As Excel.Workbook: Set Workbook = Application.Workbooks(ActiveWorkbook.name)
    If Workbook.VBProject.Protection = 1 Then
        MsgBox "VBA code cannot be exported as the workbook is protected."
        Exit Sub
    End If

    Dim export_path As String: export_path = ExportFolderPath

    If EnsureFolderExists(export_path) = "Error" Then
        MsgBox "Could not create export folder."
        Exit Sub
    End If

    ClearFolder (export_path)

    Dim component As VBIDE.VBComponent
    Dim file_ending As String

    For Each component In Workbook.VBProject.VBComponents
        Select Case component.Type
            Case vbext_ct_ClassModule
                file_ending = ".cls"
            Case vbext_ct_MSForm
                file_ending = ".frm"
            Case vbext_ct_StdModule
                file_ending = ".bas"
            Case vbext_ct_Document
                ' not an exportable code file
                file_ending = "NO_EXPORT"
        End Select

        If file_ending <> "NO_EXPORT" Then
            component.Export (export_path & FS_SEPERATOR & component.name & file_ending)
        End If
    Next component

    MsgBox "Export of VBA code is finished"
End Sub

Function ClearVBACode()
    Dim vb_project As VBIDE.VBProject: Set vb_project = ActiveWorkbook.VBProject
    Dim component As VBIDE.VBComponent

    For Each component In vb_project.VBComponents
        If component.Type = vbext_ct_Document Then
            ' don't delete documents that aren't code files
        ElseIf component.name = "ImportExport" Then
            ' don't delete the import/export module
        Else
            vb_project.VBComponents.Remove component
        End If
    Next component
End Function

Public Sub ImportVBACode()
Attribute ImportVBACode.VB_ProcData.VB_Invoke_Func = "i\n14"
    Dim Workbook As Excel.Workbook: Set Workbook = Application.Workbooks(ActiveWorkbook.name)
    If Workbook.VBProject.Protection = 1 Then
        MsgBox "VBA code cannot be imported as the workbook is protected."
        Exit Sub
    End If

    Call ClearVBACode

    Dim file_system As Scripting.FileSystemObject: Set file_system = New Scripting.FileSystemObject
    Dim export_path As String: export_path = ExportFolderPath & FS_SEPERATOR
    Dim components As VBIDE.VBComponents: Set components = Workbook.VBProject.VBComponents
    Dim current_file As Scripting.file
    Dim extension As String

    For Each current_file In file_system.GetFolder(export_path).files
        extension = file_system.GetExtensionName(current_file.name)
        If (current_file.name <> "ImportExport.bas") And _
            (extension = "cls" Or extension = "frm" Or extension = "bas") _
        Then
            components.Import current_file.path
        End If
    Next current_file

    MsgBox "Import of VBA code is finished"
End Sub


