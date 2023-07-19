Attribute VB_Name = "ShellUtilities"
' Module that encapsulates functionalities for calling shell commands from the VBA
' environment.
'
' Sources:
' 
' https://stackoverflow.com/questions/68034191/waitforsingleobject-not-working-on-64-bit-vba
' Copyright 2021 User 'PEH'
' Released under Creative Commons Attribution-ShareAlike 4.0 International Public License
' Full text of license available here: https://creativecommons.org/licenses/by-sa/4.0/legalcode
'
' https://stackoverflow.com/questions/2784367/capture-output-value-from-a-shell-command-in-vba
' Copyright 2015 User 'Brian Burns'
' Released under Creative Commons Attribution-ShareAlike 3.0 Unported
' Full text of license available here: https://creativecommons.org/licenses/by-sa/3.0/legalcode
Option Explicit

Private Type STARTUPINFO
    cb As Long
    lpReserved As String
    lpDesktop As String
    lpTitle As String
    dwX As Long
    dwY As Long
    dwXSize As Long
    dwYSize As Long
    dwXCountChars As Long
    dwYCountChars As Long
    dwFillAttribute As Long
    dwFlags As Long
    wShowWindow As Integer
    cbReserved2 As Integer
    lpReserved2 As Long
    hStdInput As Long
    hStdOutput As Long
    hStdError As Long
End Type

Private Type PROCESS_INFORMATION
    hProcess As Long
    hThread As Long
    dwProcessID As Long
    dwThreadID As Long
End Type

Private Declare PtrSafe Function WaitForSingleObject Lib "kernel32" (ByVal _
    hHandle As Long, ByVal dwMilliseconds As Long) As Long

Private Declare PtrSafe Function CreateProcessA Lib "kernel32" (ByVal _
    lpApplicationName As String, ByVal lpCommandLine As String, ByVal _
    lpProcessAttributes As Long, ByVal lpThreadAttributes As Long, _
    ByVal bInheritHandles As Long, ByVal dwCreationFlags As Long, _
    ByVal lpEnvironment As Long, ByVal lpCurrentDirectory As String, _
    lpStartupInfo As STARTUPINFO, lpProcessInformation As _
    PROCESS_INFORMATION) As Long

Private Declare PtrSafe Function CloseHandle Lib "kernel32" _
    (ByVal hObject As Long) As Long

Private Declare PtrSafe Function GetExitCodeProcess Lib "kernel32" _
    (ByVal hProcess As Long, lpExitCode As Long) As Long

Private Const NORMAL_PRIORITY_CLASS = &H20&
Private Const INFINITE = -1&

Public Function ExecCmd(cmdline$)
    Dim proc As PROCESS_INFORMATION
    Dim start As STARTUPINFO
    Dim ret As LongPtr
    Dim retval As Long

    ' Initialize the STARTUPINFO structure:
    start.cb = Len(start)

    ' Start the shelled application:
    ret& = CreateProcessA(vbNullString, cmdline$, 0&, 0&, 1&, _
        NORMAL_PRIORITY_CLASS, 0&, vbNullString, start, proc)

    ' Wait for the shelled application to finish:
    retval = WaitForSingleObject(proc.hProcess, INFINITE)
    Call GetExitCodeProcess(proc.hProcess, retval)
    Call CloseHandle(proc.hThread)
    Call CloseHandle(proc.hProcess)
    ExecCmd = retval
End Function

Public Function ShellRun(sCmd As String) As String
    'Run a shell command, returning the output as a string
    Dim oShell As WshShell
    Set oShell = CreateObject("WScript.Shell")

    'run command
    Dim oExec As Object
    Dim oOutput As Object
    Set oExec = oShell.Exec(GetOpenStudioBinPath() & "\OpenStudio.exe")
    Set oOutput = oExec.StdOut
    oShell.SendKeys " --verbose run --workflow " & Chr(34) & GetOutputFolder() & "\" + Range("FileName") + ".osw", True

    'handle the results as they are written to and read from the StdOut object
    Dim s As String
    Dim sLine As String
    While Not oOutput.AtEndOfStream
        sLine = oOutput.ReadLine
        If sLine <> "" Then s = s & sLine & vbCrLf
    Wend

    ShellRun = s
End Function
    