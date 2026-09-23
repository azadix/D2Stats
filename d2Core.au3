#include-once
#include <MsgBoxConstants.au3>

; D2Stats.Core named-pipe client. Replaces NomadMemory process attach so
; D2Stats.exe never calls OpenProcess / RPM / WPM / VirtualAllocEx / CRT.

Global Const $CORE_ABI = 1
Global Const $CORE_MAGIC = 0x43324432
Global Const $CORE_CMD_GET_ABI = 1
Global Const $CORE_CMD_PING = 2
Global Const $CORE_CMD_ATTACH = 3
Global Const $CORE_CMD_CLOSE = 4
Global Const $CORE_CMD_READ = 5
Global Const $CORE_CMD_WRITE = 6
Global Const $CORE_CMD_ALLOC = 7
Global Const $CORE_CMD_FREE = 8
Global Const $CORE_CMD_REMOTE_THREAD = 9
Global Const $CORE_MAX_PAYLOAD = 262144

Global $g_hCorePipe = 0
Global $g_iCorePid = 0

Func Core_Startup()
	Local $sCore = @ScriptDir & "\D2Stats.Core.exe"
	If Not FileExists($sCore) Then
		Core_MissingMsg("D2Stats.Core.exe was not found in the same folder as D2Stats.")
		Return False
	EndIf

	$g_iCorePid = Run('"' & $sCore & '" ' & @AutoItPID, @ScriptDir, @SW_HIDE)
	If $g_iCorePid = 0 Then
		Core_MissingMsg("Could not start D2Stats.Core.exe.")
		Return False
	EndIf

	Local $sPipe = "\\.\pipe\D2StatsCore-" & @AutoItPID
	Local $hTimer = TimerInit()
	While TimerDiff($hTimer) < 8000
		If _Core_Connect($sPipe) Then ExitLoop
		If Not ProcessExists($g_iCorePid) Then
			$g_iCorePid = 0
			Core_MissingMsg("D2Stats.Core.exe exited before a connection could be made. Check antivirus exclusions for D2Stats.Core.exe.")
			Return False
		EndIf
		Sleep(50)
	WEnd

	If $g_hCorePipe = 0 Then
		ProcessClose($g_iCorePid)
		$g_iCorePid = 0
		Core_MissingMsg("Could not connect to D2Stats.Core.exe.")
		Return False
	EndIf

	Local $iAbi = Core_GetAbi()
	If @error Or $iAbi <> $CORE_ABI Then
		Core_Shutdown()
		Core_MissingMsg("D2Stats.Core.exe is the wrong version (ABI " & $iAbi & ", need " & $CORE_ABI & "). Extract the full D2Stats.zip from the latest GitHub release.")
		Return False
	EndIf

	Return True
EndFunc

Func Core_MissingMsg($sDetail)
	MsgBox($MB_ICONERROR, "D2Stats", _
		$sDetail & @CRLF & @CRLF & _
		"Extract the full D2Stats.zip from the GitHub release. Do not copy only D2Stats.exe." & @CRLF & @CRLF & _
		"https://github.com/azadix/D2Stats/releases")
EndFunc

Func Core_Shutdown()
	If $g_hCorePipe Then
		DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $g_hCorePipe)
		$g_hCorePipe = 0
	EndIf
	If $g_iCorePid Then
		Local $hWait = TimerInit()
		While ProcessExists($g_iCorePid) And TimerDiff($hWait) < 2000
			Sleep(50)
		WEnd
		If ProcessExists($g_iCorePid) Then ProcessClose($g_iCorePid)
		$g_iCorePid = 0
	EndIf
EndFunc

Func _Core_Connect($sPipe)
	DllCall("kernel32.dll", "bool", "WaitNamedPipeW", "wstr", $sPipe, "dword", 200)
	Local $a = DllCall("kernel32.dll", "handle", "CreateFileW", _
		"wstr", $sPipe, _
		"dword", 0xC0000000, _
		"dword", 0, _
		"ptr", 0, _
		"dword", 3, _
		"dword", 0, _
		"handle", 0)
	If @error Or $a[0] = 0 Or $a[0] = Ptr(-1) Then Return False
	$g_hCorePipe = $a[0]
	Return True
EndFunc

Func _Core_WriteBytes($pBuf, $iSize)
	Local $iOff = 0
	While $iOff < $iSize
		Local $a = DllCall("kernel32.dll", "bool", "WriteFile", "handle", $g_hCorePipe, "ptr", $pBuf + $iOff, "dword", $iSize - $iOff, "dword*", 0, "ptr", 0)
		If @error Or Not $a[0] Or $a[4] = 0 Then Return False
		$iOff += $a[4]
	WEnd
	Return True
EndFunc

Func _Core_ReadBytes($pBuf, $iSize)
	Local $iOff = 0
	While $iOff < $iSize
		Local $a = DllCall("kernel32.dll", "bool", "ReadFile", "handle", $g_hCorePipe, "ptr", $pBuf + $iOff, "dword", $iSize - $iOff, "dword*", 0, "ptr", 0)
		If @error Or Not $a[0] Or $a[4] = 0 Then Return False
		$iOff += $a[4]
	WEnd
	Return True
EndFunc

; Returns response payload struct (or 0). Sets @error on failure.
Func _Core_Call($iCmd, $pPayload = 0, $iPayloadSize = 0)
	If Not $g_hCorePipe Then Return SetError(1, 0, 0)

	Local $tHdr = DllStructCreate("uint magic;uint cmd;uint size")
	DllStructSetData($tHdr, "magic", $CORE_MAGIC)
	DllStructSetData($tHdr, "cmd", $iCmd)
	DllStructSetData($tHdr, "size", $iPayloadSize)
	If Not _Core_WriteBytes(DllStructGetPtr($tHdr), 12) Then Return SetError(2, 0, 0)
	If $iPayloadSize > 0 Then
		If Not _Core_WriteBytes($pPayload, $iPayloadSize) Then Return SetError(2, 0, 0)
	EndIf

	Local $tResp = DllStructCreate("uint magic;uint status;uint size")
	If Not _Core_ReadBytes(DllStructGetPtr($tResp), 12) Then Return SetError(3, 0, 0)
	If DllStructGetData($tResp, "magic") <> $CORE_MAGIC Then Return SetError(3, 0, 0)

	Local $iSize = DllStructGetData($tResp, "size")
	Local $iStatus = DllStructGetData($tResp, "status")
	Local $tBody = 0
	If $iSize > 0 Then
		If $iSize > $CORE_MAX_PAYLOAD Then Return SetError(4, 0, 0)
		$tBody = DllStructCreate("byte[" & $iSize & "]")
		If Not _Core_ReadBytes(DllStructGetPtr($tBody), $iSize) Then Return SetError(3, 0, 0)
	EndIf

	If $iStatus <> 0 Then Return SetError(5, 0, 0)
	Return $tBody
EndFunc

Func Core_GetAbi()
	Local $t = _Core_Call($CORE_CMD_GET_ABI)
	If @error Then Return SetError(@error, 0, 0)
	Local $tAbi = DllStructCreate("uint", DllStructGetPtr($t))
	Return DllStructGetData($tAbi, 1)
EndFunc

Func Core_Attach($iPid)
	Local $t = DllStructCreate("uint")
	DllStructSetData($t, 1, $iPid)
	_Core_Call($CORE_CMD_ATTACH, DllStructGetPtr($t), 4)
	If @error Then Return SetError(@error, 0, False)
	Return True
EndFunc

Func Core_CloseGame()
	_Core_Call($CORE_CMD_CLOSE)
EndFunc

Func Core_ReadProcessMemory($pAddress, $pBuffer, $iSize)
	If $iSize <= 0 Then Return SetError(1, 0, False)
	Local $tReq = DllStructCreate("uint addr;uint size")
	DllStructSetData($tReq, "addr", $pAddress)
	DllStructSetData($tReq, "size", $iSize)
	Local $t = _Core_Call($CORE_CMD_READ, DllStructGetPtr($tReq), 8)
	If @error Then Return SetError(@error, 0, False)
	DllCall("kernel32.dll", "none", "RtlMoveMemory", "ptr", $pBuffer, "ptr", DllStructGetPtr($t), "ulong_ptr", $iSize)
	Return True
EndFunc

Func Core_WriteProcessMemory($pAddress, $pBuffer, $iSize)
	If $iSize <= 0 Then Return SetError(1, 0, False)
	Local $tReq = DllStructCreate("uint addr;uint size;byte data[" & $iSize & "]")
	DllStructSetData($tReq, "addr", $pAddress)
	DllStructSetData($tReq, "size", $iSize)
	DllCall("kernel32.dll", "none", "RtlMoveMemory", "ptr", DllStructGetPtr($tReq, "data"), "ptr", $pBuffer, "ulong_ptr", $iSize)
	_Core_Call($CORE_CMD_WRITE, DllStructGetPtr($tReq), 8 + $iSize)
	If @error Then Return SetError(@error, 0, False)
	Return True
EndFunc

Func Core_VirtualAllocEx($iSize, $iAlloc, $iProtect)
	Local $tReq = DllStructCreate("uint size;uint alloc;uint protect")
	DllStructSetData($tReq, "size", $iSize)
	DllStructSetData($tReq, "alloc", $iAlloc)
	DllStructSetData($tReq, "protect", $iProtect)
	Local $t = _Core_Call($CORE_CMD_ALLOC, DllStructGetPtr($tReq), 12)
	If @error Then Return SetError(@error, 0, 0)
	Local $tAddr = DllStructCreate("uint", DllStructGetPtr($t))
	Return DllStructGetData($tAddr, 1)
EndFunc

Func Core_VirtualFreeEx($pAddress, $iSize, $iFreeType)
	Local $tReq = DllStructCreate("uint addr;uint size;uint type")
	DllStructSetData($tReq, "addr", $pAddress)
	DllStructSetData($tReq, "size", $iSize)
	DllStructSetData($tReq, "type", $iFreeType)
	_Core_Call($CORE_CMD_FREE, DllStructGetPtr($tReq), 12)
	If @error Then Return SetError(@error, 0, False)
	Return True
EndFunc

Func Core_RemoteThread($pFunc, $iVar = 0)
	Local $tReq = DllStructCreate("uint func;uint arg")
	DllStructSetData($tReq, "func", $pFunc)
	DllStructSetData($tReq, "arg", $iVar)
	Local $t = _Core_Call($CORE_CMD_REMOTE_THREAD, DllStructGetPtr($tReq), 8)
	If @error Then Return SetError(@error, 0, 0)
	Local $tCode = DllStructCreate("uint", DllStructGetPtr($t))
	Return DllStructGetData($tCode, 1)
EndFunc

Func _MemoryOpen($iv_Pid, $iv_DesiredAccess = 0x1F0FFF, $if_InheritHandle = 1)
	#forceref $iv_DesiredAccess, $if_InheritHandle
	If Not ProcessExists($iv_Pid) Then
		SetError(1)
		Return 0
	EndIf
	If Not Core_Attach($iv_Pid) Then
		SetError(3)
		Return 0
	EndIf
	Local $ah_Handle[2] = [1, 1]
	Return $ah_Handle
EndFunc

Func _MemoryClose($ah_Handle)
	If Not IsArray($ah_Handle) Then
		SetError(1)
		Return 0
	EndIf
	Core_CloseGame()
	Return 1
EndFunc

Func _MemoryRead($iv_Address, $ah_Handle, $sv_Type = "dword")
	If Not IsArray($ah_Handle) Then
		SetError(1)
		Return 0
	EndIf
	Local $v_Buffer = DllStructCreate($sv_Type)
	If @error Then
		SetError(@error + 1)
		Return 0
	EndIf
	If Not Core_ReadProcessMemory($iv_Address, DllStructGetPtr($v_Buffer), DllStructGetSize($v_Buffer)) Then
		SetError(6)
		Return 0
	EndIf
	Return DllStructGetData($v_Buffer, 1)
EndFunc

Func _MemoryWrite($iv_Address, $ah_Handle, $v_Data, $sv_Type = "dword")
	If Not IsArray($ah_Handle) Then
		SetError(1)
		Return 0
	EndIf
	Local $v_Buffer = DllStructCreate($sv_Type)
	If @error Then
		SetError(@error + 1)
		Return 0
	EndIf
	DllStructSetData($v_Buffer, 1, $v_Data)
	If @error Then
		SetError(6)
		Return 0
	EndIf
	If Not Core_WriteProcessMemory($iv_Address, DllStructGetPtr($v_Buffer), DllStructGetSize($v_Buffer)) Then
		SetError(7)
		Return 0
	EndIf
	Return 1
EndFunc

Func _MemoryPointerRead($iv_Address, $ah_Handle, $av_Offset, $sv_Type = "dword")
	If IsArray($av_Offset) Then
		If IsArray($ah_Handle) Then
			Local $iv_PointerCount = UBound($av_Offset) - 1
		Else
			SetError(2)
			Return 0
		EndIf
	Else
		SetError(1)
		Return 0
	EndIf

	Local $iv_Data = 0
	Local $i
	For $i = 0 To $iv_PointerCount
		If $i = $iv_PointerCount Then
			$iv_Address = $iv_Data + $av_Offset[$i]
			Return _MemoryRead($iv_Address, $ah_Handle, $sv_Type)
		ElseIf $i = 0 Then
			$iv_Data = _MemoryRead($iv_Address, $ah_Handle, "dword")
			If @error Then
				SetError(7)
				Return 0
			EndIf
		Else
			$iv_Address = $iv_Data + $av_Offset[$i]
			$iv_Data = _MemoryRead($iv_Address, $ah_Handle, "dword")
			If @error Then
				SetError(7)
				Return 0
			EndIf
		EndIf
	Next
EndFunc
