Attribute VB_Name = "ImportExport"
Option Explicit

' Module for importing and exporting VBA code to and from a workbook.

' Please note that the implementation is tailored towards a complete replacement of user
' forms, modules and classes to/from text files on disk. The intention of this module is
' to enable the development with source control, IDEs (other than the built-in one) and
' such useful tools. There are other modules more suited for a more finely grained approach
' to importing/exporting.
'
' The implementation is inspired by a similar module by Ron de Bruin available here:
' https://www.rondebruin.nl/win/s9/win002.htm
'
' USAGE
' 
' With the workbook open and unprotected, run the ImportVBACode or ExportVBACode macros.
' The code will then be placed (or be taken from) a folder in the same folder in which the
' workbook resides. The name of the subfolder is defined in the constant
' EXPORT_FOLDER_NAME.
' 
' **WARNING**
' Please note that the import macro deletes all VBA code files in the workbook before
' importing and the export macro deletes all files in the subfolder before exporting!

Const FS_SEPERATOR As String = "\"
Const EXPORT_FOLDER_NAME As String = "VBAProjectFiles"

' Returns the path to the folder to where code files are being exported.
' 
' This is the same folder from where code files are being imported.
'
' @return (String) The path to the export folder without trailing seperator.
Function ExportFolderPath() As String
    Dim workbook_path As String: workbook_path = Application.ActiveWorkbook.path

    If Right(workbook_path, 1) <> FS_SEPERATOR Then
        workbook_path = workbook_path & FS_SEPERATOR
    End If

    ExportFolderPath = workbook_path & EXPORT_FOLDER_NAME
End Function

' Ensures a folder exists at the given path and creates it if not.
'
' @param folder_path (String, ByVal) The path to check
' @return (String) The path or "Error" if creating the folder failed
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

' Deletes all files in the folder at the given path.
'
' @param folder_path (String, ByVal) The folder to clear
Function ClearFolder(ByVal folder_path As String)
    Dim pattern As String: pattern = folder_path

    If Right(pattern, 1) <> FS_SEPERATOR Then
        pattern = pattern & FS_SEPERATOR
    End If
    pattern = pattern & "*.*"

    On Error Resume Next
        Kill pattern
    On Error GoTo 0
End Function

' Performs the export of all VBA code in the currently active workbook to files on disk.
' 
' Please be advised that the method deletes all files in the target export folder (defined
' in global constant EXPORT_FOLDER_NAME as subdirectory of the directory in which the
' workbook resides) before exporting.
Public Sub ExportVBACode()
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

' Clears the currently active workbook from all code.
'
' This does not delete the ImportExport module itself, as this would stop
' execution of the importer code.
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

' Performs the import of VBA code files to the currently active workbook.
' 
' Please be advised that the method deletes all code (modules, class modules and user
' forms, excepting the import/export module itself) in the currently active workbook
' before importing. The imported files are read from the export folder, defined in
' global constant EXPORT_FOLDER_NAME as subdirectory of the directory in which the
' workbook resides.
Public Sub ImportVBACode()
    Dim Workbook As Excel.Workbook: Set Workbook = Application.Workbooks(ActiveWorkbook.name)
    If Workbook.VBProject.Protection = 1 Then
        MsgBox "VBA code cannot be imported as the workbook is protected."
        Exit Sub
    End If

    Call ClearVBACode

    Dim file_system As Scripting.FileSystemObject: Set file_system = New Scripting.FileSystemObject
    Dim export_path As String: export_path = ExportFolderPath & FS_SEPERATOR
    Dim components As VBIDE.VBComponents: Set components = Workbook.VBProject.VBComponents
    Dim current_file As Scripting.File
    Dim extension As String

    For Each current_file In file_system.GetFolder(export_path).Files
        extension = file_system.GetExtensionName(current_file.name)
        If (current_file.name <> "ImportExport.bas") And _
            (extension = "cls" Or extension = "frm" Or extension = "bas") _
        Then
            components.Import current_file.path
        End If
    Next current_file

    MsgBox "Import of VBA code is finished"
End Sub


