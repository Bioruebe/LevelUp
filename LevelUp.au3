#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile=.\biolu.exe
#AutoIt3Wrapper_Outfile_x64=.\biolu64.exe
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.1
 Author:         Bioruebe

 Script Function:
	Reduce amount of empty or single file containing folders
#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here

#include <Array.au3>

; Check commandline parameters
$sStartFolder = ""
$bRename = False
$bStrict = False

If $cmdline[0] = 0 Or $cmdline[1] == "/h" Or $cmdline[1] == "/?" Then
	ConsoleWrite("LevelUp Version 1.1.0, 2015 by Bioruebe, licensed under a BSD 3-clause license" & @CRLF & @CRLF & _
				 "A tool to delete all empty subfolders of a given input path and remove folders only containing one file after moving this file one level up. The initial folder will not be deleted." & _
				 @CRLF & @CRLF & "Usage: " & @CRLF & @TAB & @ScriptName & " [options] startfolder" & @CRLF & @CRLF & _
				 "   options:" & @CRLF & @TAB & "/? or /h" & @TAB & "Display this help screen" & @CRLF & @CRLF & @TAB & "/r" & _
				 @TAB & @TAB & "Rename moved files after their initial folder" & @CRLF & @TAB & @TAB & @TAB & _
				 "e.g. dir\foo\bar.txt will be renamed to dir\foo_bar.txt" & @CRLF & @CRLF & @TAB & "/s" & @TAB & @TAB & _
				 "Strict mode: files are only moved if no other files AND" & @CRLF & @TAB & @TAB & @TAB & _
				 "directories exist in their folders" & @CRLF & @CRLF)
	Exit 0
Else
	$sStartFolder = $cmdline[$cmdline[0]]
	For $i = $cmdline[0] -1 To 1 Step -1
;~ 		Cout($cmdline[$i])
		Switch $cmdline[$i]
			Case "/r"
				$bRename = True
			Case "/s"
				$bStrict = True
		EndSwitch
	Next
EndIf

;~ $sStartFolder = @ScriptDir & "\test\"

; Verify input
If Not (FileExists($sStartFolder) And StringInStr(FileGetAttrib($sStartFolder), "D")) Then
	Cout("Input path is not a valid folder", True)
	Exit 1
EndIf

Cout("Strict mode: " & @TAB & $bStrict)
Cout("Rename: " & @TAB & $bRename)

_Recurse($sStartFolder)
ConsoleWrite(@CRLF)
Cout("Finished")

; Main recursive function
Func _Recurse($sPath, $sTopPath = -1, $sPathName = -1)
	If StringRight($sPath, 1) <> "\" Then $sPath &= "\"
	Cout("Processing " & $sPath)

	Local $iFiles = 0, $iDirectories = 0, $sLastPath = -1
	$hSearch = FileFindFirstFile($sPath & "*")
	If @error Then
		Cout("Deleting empty folder " & $sPath)
		DirRemove($sPath)
		Return $iFiles
	EndIf

	While 1
		$sNextPath = FileFindNextFile($hSearch)
		If @error Then ExitLoop
		If @extended Then ;Directory
			$iReturn = _Recurse($sPath & $sNextPath, $sPath, $sNextPath)
			$iFiles += $iReturn
			If $iReturn == 0 Then $iDirectories += 1
		Else
			$iFiles += 1
			$sLastPath = $sNextPath
		EndIf
	WEnd

	Cout("Folder " & $sPath & " contains " & $iFiles & " file(s)")

	If $iFiles = 1 And $sTopPath > -1 And Not ($bStrict And $iDirectories > 0) Then
		If $sLastPath == -1 Then
			FileClose($hSearch)
			$hSearch = FileFindFirstFile($sPath & "*")
			While 1
				$sLastPath = FileFindNextFile($hSearch)
				If @error Or @extended == 0 Then ExitLoop
			WEnd
		EndIf
		Cout("Moving " & $sLastPath & " one level up to " & $sTopPath)
		If FileMove($sPath & $sLastPath, $sTopPath & ($bRename? $sPathName & "_": "") & $sLastPath) Then
			Cout("Deleting empty folder " & $sPath)
			DirRemove($sPath)
		Else
			Cout("Error: File " & $sLastPath & " could not be moved", True)
		EndIf
	Else
		$iFiles = 0
	EndIf

	FileClose($hSearch)
	Return $iFiles
EndFunc

; Write data to stdout stream
Func Cout($sData, $bError = False)
	If IsArray($sData) Then $sData = _ArrayToString($sData, @CRLF)
	Local $sOutput = @YEAR & "-" & @MON & "-" & @MDAY & " " & @HOUR & ":" & @MIN & ":" & @SEC & ":" & @MSEC & @TAB & $sData & @CRLF; & @CRLF

	If $bError Then
		ConsoleWriteError($sOutput)
	Else
		ConsoleWrite($sOutput)
	EndIf

	Return $sData
EndFunc

