Set fso = CreateObject("Scripting.FileSystemObject")
Set WshShell = CreateObject("WScript.Shell")
batPath = fso.GetParentFolderName(WScript.ScriptFullName) & "\TaskManagerMinimize.bat"
WshShell.Run Chr(34) & batPath & Chr(34), 7, False
