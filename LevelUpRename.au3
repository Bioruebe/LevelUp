#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile=biolur.exe
#AutoIt3Wrapper_Outfile_x64=biolur64.exe
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.2
 Author:         Bioruebe

 Script Function:
	Move all files from subdirectories to current folder and rename them after their original directory

#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here

#include <Array.au3>
#include <WinAPI.au3>

$sSearchPath = '.'
$sExtension = '*'
$iSizeTreshold = 0 ; MB
$bConfirm = True

; Print header
ConsoleWrite("LevelUp & Rename, version 1.0, 2016 by Bioruebe, licensed under a BSD 3-clause license" & @CRLF & @CRLF & _
				 "A tool to move all files of a given type and size (optionally) from subdirectories to a base directory." & _
				 @CRLF & @CRLF & "Usage: " & @CRLF & @TAB & @ScriptName & " [options] startfolder" & @CRLF & @CRLF & _
				 "   Options:" & @CRLF & @TAB & "/? or /h" & @TAB & "Display this help screen" & @CRLF & @CRLF & @TAB & _
				 "/s[size]" & @TAB & "Set minimum size of files to move, in MB" & @CRLF & @CRLF & @TAB & _
				 "/e[extension]" & @TAB & "Set file extension to move" & @CRLF & @CRLF & @TAB & _
				 "/y" & @TAB & @TAB & "Disable confirmation prompt before performing any action"& @CRLF & @CRLF & _
				 "--------------------------------------------------------------------" & @CRLF & @CRLF)

; Parse command line
If $CmdLine[0] > 0 Then
	If $CmdLine[1] = "/h" Or $CmdLine[1] = "-h" Or $CmdLine[1] = "-help" Or $CmdLine[1] = "/?" Then
		Exit 0
	Else
		For $i = $CmdLine[0] To 1 Step -1
			$ret = StringLeft($CmdLine[$i], 1)
			If $ret = "/" Or $ret = "-" Then
				$ret = StringTrimLeft($CmdLine[$i], 2)
				Switch StringMid($CmdLine[$i], 2, 1)
					Case "e"
						$sExtension = $ret
					Case "s"
						$iSizeTreshold = Int($ret)
					Case "y"
						$bConfirm = False
				EndSwitch
			ElseIf FileExists($CmdLine[$i]) Then
				$sSearchPath = $CmdLine[$i]
			Else
				ConsoleWrite("Invalid command line argument: " & $CmdLine[$i] & @CRLF & @CRLF)
				Exit 1
			EndIf
		Next
	EndIf
EndIf

If Not FileExists($sSearchPath) Then
	ConsoleWrite("Invalid path specified" & @CRLF)
	Exit 1
EndIf

; If only one file is specified, use file extension and make assumptions about path and file size
If Not StringInStr(FileGetAttrib($sSearchPath), "D") Then
	$iFileSize = FileGetSize($sSearchPath)
	$sExtension = StringTrimLeft($sSearchPath, StringInStr($sSearchPath, ".", 0, -1))
	$sSearchPath = StringLeft($sSearchPath, StringInStr($sSearchPath, "\", 0, -2))
	If $iSizeTreshold > $iFileSize Then $iSizeTreshold = Floor($iFileSize * 0.75)
EndIf

ConsoleWrite("Search path: " & $sSearchPath & @CRLF)
ConsoleWrite("File extension: " & $sExtension & @CRLF)
ConsoleWrite("Size treshold: " & $iSizeTreshold & @CRLF)

If $bConfirm Then
	Do
		$sContinue = _ConsoleInput(@CRLF & "Continue?  (y|n)" & @CRLF)
		If $sContinue = "n" Then Exit 0
	Until $sContinue = "y"
EndIf

$ret = _GetFilesFolder_Rekursiv($sSearchPath, $sExtension, 0, 0)
;_ArrayDisplay($ret)
$iFiles = 0
For $i = 1 to UBound($ret)-1
	If $iSizeTreshold == 0 Or FileGetSize($ret[$i]) > $iSizeTreshold * 1048576 Then
		$aSplit = StringSplit($ret[$i], "\")
		$aExtension = StringSplit($aSplit[$aSplit[0]], ".")
		$sName = $aSplit[$aSplit[0]-1] & "." & $aExtension[$aExtension[0]]
		FileMove($ret[$i], $sSearchPath & "\" & $sName)
		$iFiles += 1
	EndIf
Next

ConsoleWrite(@CRLF & "Finished. " & $iFiles & " file" & ($iFiles > 1? "s were": " was") & " moved and renamed." & @CRLF)


; https://www.autoitscript.com/forum/topic/107951-help-with-_winapi_createfile-function-and-raw-mode/#comment-761205
Func _ConsoleInput($sPrompt)
    If Not @Compiled Then Return SetError(1, 0, 0)
    ConsoleWrite($sPrompt)

    Local $tBuffer = DllStructCreate("char"), $nRead, $sRet = ""
    Local $hFile = _WinAPI_CreateFile("CON", 2, 2)

    While 1
        _WinAPI_ReadFile($hFile, DllStructGetPtr($tBuffer), 1, $nRead)
        If DllStructGetData($tBuffer, 1) = @CR Then ExitLoop
        If $nRead > 0 Then $sRet &= DllStructGetData($tBuffer, 1)
    WEnd

    _WinAPI_CloseHandle($hFile)
    Return $sRet
EndFunc

;==================================================================================================
; Function Name:   _GetFilesFolder_Rekursiv($sPath [, $sExt='*' [, $iDir=-1 [, $iRetType=0 ,[$sDelim='0']]]])
; Description:     Rekursive Auflistung von Dateien und/oder Ordnern
; Parameter(s):    $sPath     der Basispfad für die Auflistung ('.' -aktueller Pfad, '..' -Parentpfad)
;                  $sExt      Erweiterung für Dateiauswahl '*' oder -1 für alle (Standard)
;                  $iDir      -1 Dateien+Ordner(Standard), 0 nur Dateien, 1 nur Ordner
;      optional:   $iRetType  0 gibt Array, 1 gibt String zurück
;      optional:   $sDelim    legt Trennzeichen für Stringrückgabe fest
;                             0 -@CRLF (Standard)  1 -@CR  2 -@LF  3 -';'  4 -'|'
; Return Value(s): Array (Standard) od. String mit den gefundenen Pfaden der Dateien und/oder Ordner
;                  Array[0] enthält die Anzahl der gefundenen Dateien/Ordner
; Author(s):       BugFix (bugfix@autoit.de)
;==================================================================================================
Func _GetFilesFolder_Rekursiv($sPath, $sExt='*', $iDir=-1, $iRetType=0, $sDelim='0')
    Global $oFSO = ObjCreate('Scripting.FileSystemObject')
    Global $strFiles = ''
    Switch $sDelim
        Case '1'
            $sDelim = @CR
        Case '2'
            $sDelim = @LF
        Case '3'
            $sDelim = ';'
        Case '4'
            $sDelim = '|'
        Case Else
            $sDelim = @CRLF
    EndSwitch
    If ($iRetType < 0) Or ($iRetType > 1) Then $iRetType = 0
    If $sExt = -1 Then $sExt = '*'
    If ($iDir < -1) Or ($iDir > 1) Then $iDir = -1
    _ShowSubFolders($oFSO.GetFolder($sPath),$sExt,$iDir,$sDelim)
    If $iRetType = 0 Then
        Local $aOut
        $aOut = StringSplit(StringTrimRight($strFiles, StringLen($sDelim)), $sDelim, 1)
        If $aOut[1] = '' Then
            ReDim $aOut[1]
            $aOut[0] = 0
        EndIf
        Return $aOut
    Else
        Return StringTrimRight($strFiles, StringLen($sDelim))
    EndIf
EndFunc

Func _ShowSubFolders($Folder, $Ext='*', $Dir=-1, $Delim=@CRLF)
    If Not IsDeclared("strFiles") Then Global $strFiles = ''
    If ($Dir = -1) Or ($Dir = 0) Then
        For $file In $Folder.Files
            If $Ext <> '*' Then
                If StringRight($file.Name, StringLen($Ext)) = $Ext Then _
                    $strFiles &= $file.Path & $Delim
            Else
                $strFiles &= $file.Path & $Delim
            EndIf
        Next
    EndIf
    For $Subfolder In $Folder.SubFolders
        If ($Dir = -1) Or ($Dir = 1) Then $strFiles &= $Subfolder.Path & '\' & $Delim
        _ShowSubFolders($Subfolder, $Ext, $Dir, $Delim)
    Next
EndFunc