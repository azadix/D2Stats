#include-once

#Region GameMemory globals
global $g_hD2Client, $g_hD2Common, $g_hD2Win, $g_hD2Lang, $g_hD2Sigma, $g_hGameExe
global $g_ahD2Handle
global $g_iD2pid, $g_iUpdateFailCounter
global $g_pD2sgpt, $g_pD2InjectPrint, $g_pD2InjectString, $g_pD2InjectParams, $g_pD2InjectGetString, $g_pD2Client_GetItemName, $g_pD2Client_GetItemStat, $g_pD2Common_GetUnitStat
global $g_pHoverTextBuffer, $g_pHoverTextHook, $g_pDrawFramedText
global const $g_iD2WinDrawFramedTextOrd = 10085
global const $g_iHoverTextWChars = 8192
global const $g_iHoverTextBytes = $g_iHoverTextWChars * 2
#EndRegion

#Region GameMemory
func _CloseHandle()
	if ($g_ahD2Handle) then
		_MemoryClose($g_ahD2Handle)
		$g_ahD2Handle = 0
		$g_iD2pid = 0
	endif
endfunc

func UpdateHandle()
	; Cache window handle to reduce expensive WinGetHandle calls
	Static $hCachedWnd = 0
	Static $iLastHandleCheck = 0
	
	; Only check for new window every 1 second
	If TimerDiff($iLastHandleCheck) < 1000 And $hCachedWnd <> 0 Then
		Local $iPID = WinGetProcess($hCachedWnd)
		If $iPID <> -1 And $iPID == $g_iD2pid Then Return
	EndIf
	
	$iLastHandleCheck = TimerInit()
	local $hWnd = WinGetHandle("[CLASS:Diablo II]")
	local $iPID = WinGetProcess($hWnd)
	$hCachedWnd = $hWnd

	if ($iPID == -1) then return _CloseHandle()
	if ($iPID == $g_iD2pid) then return

	_CloseHandle()
	$g_iUpdateFailCounter += 1
	$g_ahD2Handle = _MemoryOpen($iPID)
	if (@error) then return _Debug("UpdateHandle", "Couldn't open Diablo II memory handle.")

	if (not UpdateDllHandles()) then
		_CloseHandle()
		return _Debug("UpdateHandle", "Couldn't update dll handles.")
	endif

	if (not InjectFunctions()) then
		_CloseHandle()
		return _Debug("UpdateHandle", "Couldn't inject functions.")
	endif

	$g_iUpdateFailCounter = 0
	$g_iD2pid = $iPID
	$g_pD2sgpt = _MemoryRead($g_hD2Common + 0x99E1C, $g_ahD2Handle)
	$g_bScCatalogReady = False
	$g_bScMorphSkillsCached = False
endfunc

func IsIngame()
	if (not $g_iD2pid) then return False
	return _MemoryRead($g_hD2Client + 0x11BBFC, $g_ahD2Handle) <> 0
endfunc
#EndRegion

#Region Injection
func RemoteThread($pFunc, $iVar = 0) ; $var is in EBX register
	local $aResult = DllCall($g_ahD2Handle[0], "ptr", "CreateRemoteThread", "ptr", $g_ahD2Handle[1], "ptr", 0, "uint", 0, "ptr", $pFunc, "ptr", $iVar, "dword", 0, "ptr", 0)
	local $hThread = $aResult[0]
	if ($hThread == 0) then return _Debug("RemoteThread", "Couldn't create remote thread.")

	_WinAPI_WaitForSingleObject($hThread)

	local $tDummy = DllStructCreate("dword")
	DllCall($g_ahD2Handle[0], "bool", "GetExitCodeThread", "handle", $hThread, "ptr", DllStructGetPtr($tDummy))
	local $iRet = Dec(Hex(DllStructGetData($tDummy, 1)))

	_WinAPI_CloseHandle($hThread)
	return $iRet
endfunc

func SwapEndian($pAddress)
	return StringFormat("%08s", StringLeft(Hex(Binary($pAddress)), 8))
endfunc

func GetItemName($pUnit)
	if (not IsIngame()) then return ""
	;~ clean before use
	_MemoryWrite($g_pD2InjectString, $g_ahD2Handle, 0, "byte[256]")
	RemoteThread($g_pD2Client_GetItemName, $pUnit)
	if (@error) then return _Log("GetItemName", "Failed to create remote thread.")
	return StringSplit(GetOutputString(256), @LF)
endfunc

; D2 color codes are wchar U+00FF, "c", then a code (0-9, :, ;).
func StripD2ColorCodes($sText)
	if (not IsString($sText) or $sText == "") then return ""

	local $sOut = ""
	local $i = 1
	local $iLen = StringLen($sText)
	while $i <= $iLen
		if ($i + 2 <= $iLen and AscW(StringMid($sText, $i, 1)) == 0xFF and StringMid($sText, $i + 1, 1) == "c") then
			$i += 3
			continueloop
		endif
		$sOut &= StringMid($sText, $i, 1)
		$i += 1
	wend
	return $sOut
endfunc

func GetD2TextPrintColor($sText, $iDefault = $ePrintWhite)
	if (not IsString($sText) or $sText == "") then return $iDefault

	local $sCode = ""
	local $i = 1
	local $iLen = StringLen($sText)
	while $i <= $iLen - 2
		if (AscW(StringMid($sText, $i, 1)) == 0xFF and StringMid($sText, $i + 1, 1) == "c") then
			$sCode = StringMid($sText, $i + 2, 1)
			exitloop
		endif
		$i += 1
	wend
	if ($sCode == "") then return $iDefault

	select
		case $sCode == "0"
			return $ePrintWhite
		case $sCode == "1"
			return $ePrintRed
		case $sCode == "2"
			return $ePrintLime
		case $sCode == "3"
			return $ePrintBlue
		case $sCode == "4" or $sCode == "7"
			return $ePrintGold
		case $sCode == "5"
			return $ePrintGrey
		case $sCode == "6"
			return $ePrintBlack
		case $sCode == "8"
			return $ePrintOrange
		case $sCode == "9"
			return $ePrintYellow
		case $sCode == ":"
			return $ePrintGreen
		case $sCode == ";"
			return $ePrintPurple
		case else
			return $iDefault
	endselect
endfunc

; D2Client GetItemDesc prints dummy unique aura/oskill/proc skills whose name
; string is missing as "FLYING POLAR BUFFALO ERROR". The in-game unique tooltip
; hides those lines; strip them so overlay stats match.
func StripMissingSkillDescLines($sStats)
	if ($sStats == "") then return ""

	local $asLines = StringSplit($sStats, @LF)
	local $sOut = ""
	local $i
	for $i = 1 to $asLines[0]
		if (StringInStr($asLines[$i], "FLYING POLAR BUFFALO ERROR")) then continueloop
		if ($sOut <> "") then $sOut &= @LF
		$sOut &= $asLines[$i]
	next
	return $sOut
endfunc

func GetItemStats($pUnit)
	if (not IsIngame()) then return ""
	;~ clean before use
	_MemoryWrite($g_pD2InjectString, $g_ahD2Handle, 0, "byte[" & $g_iD2InjectStringBytes & "]")
	RemoteThread($g_pD2Client_GetItemStat, $pUnit)
	if (@error) then return _Log("GetItemStats", "Failed to create remote thread.")
	local $sStats = StripMissingSkillDescLines(GetOutputString($g_iD2InjectStringWChars))

	; Omitted stats must be prepended: HighlightStats reverses formatter output
	; to match the in-game tooltip, so a trailing line would display first.
	; Median XL custom stat 427 uses descFunc=38, which the D2Client formatter omits.
	local $iActivationFrequency = GetUnitStat($pUnit, 427)
	if ($iActivationFrequency <> 0 and StringInStr($sStats, "Activation Frequency") == 0) then
		local $sActivationFrequency = "Activation Frequency +" & $iActivationFrequency & "%"
		$sStats = ($sStats <> "") ? ($sActivationFrequency & @CRLF & $sStats) : $sActivationFrequency
	endif

	; Stat 74 is stored 10x the tooltip value. The D2Client formatter often omits
	; Median XL's "Life Regenerated per Second" line the same way as descFunc=38.
	local $iLifeRegen = Floor(GetUnitStat($pUnit, 74) / 10)
	if ($iLifeRegen <> 0 and StringInStr($sStats, "Life Regenerat") == 0 and StringInStr($sStats, "Life regeneration") == 0 and StringInStr($sStats, "Replenish Life") == 0) then
		local $sLifeRegen = "+" & $iLifeRegen & " Life Regenerated per Second"
		$sStats = ($sStats <> "") ? ($sLifeRegen & @CRLF & $sStats) : $sLifeRegen
	endif
	
	return $sStats
endfunc

func GetUnitStat($pUnit, $iStat)
	if (not IsIngame()) then return 0
	_MemoryWrite($g_pD2InjectParams, $g_ahD2Handle, $iStat, "dword")
	_MemoryWrite($g_pD2InjectParams + 0x4, $g_ahD2Handle, $pUnit, "dword")
	RemoteThread($g_pD2Common_GetUnitStat, $g_pD2InjectParams)
	if (@error) then return _Log("GetUnitStat", "Failed to create remote thread.")
	return GetOutputNumber()
endfunc

func GetOutputString($length)
	if (not IsIngame()) then return ""
	local $sString = _MemoryRead($g_pD2InjectString, $g_ahD2Handle, StringFormat("wchar[%s]", $length))
	if (@error) then return _Log("GetOutputString", "Failed to create remote thread.")
	return $sString
endfunc

func GetOutputNumber()
	if (not IsIngame()) then return 0
	local $iNumber = _MemoryRead($g_pD2InjectString, $g_ahD2Handle, "dword")
	if (@error) then return _Log("GetOutputNumber", "Failed to create remote thread.")
	return $iNumber
endfunc

func InjectCode($pWhere, $sCode)
	_MemoryWrite($pWhere, $g_ahD2Handle, $sCode, StringFormat("byte[%s]", StringLen($sCode)/2 - 1))

	local $iConfirm = _MemoryRead($pWhere, $g_ahD2Handle)
	return Hex($iConfirm, 8) == Hex(Binary(Int(StringLeft($sCode, 10))))
endfunc

func InjectFunctions()
#cs
	D2Client.dll+CDE00 - 53                    - push ebx
	D2Client.dll+CDE01 - 68 *                  - push D2Client.dll+CDE20
	D2Client.dll+CDE06 - 31 C0                 - xor eax,eax
	D2Client.dll+CDE08 - E8 *                  - call D2Client.dll+7D850
	D2Client.dll+CDE0D - C3                    - ret
#ce
	local $iPrintOffset = ($g_hD2Client + 0x7D850) - ($g_hD2Client + 0xCDE0E)
	local $sWrite = "0x5368" & SwapEndian($g_pD2InjectString) & "31C0E8" & SwapEndian($iPrintOffset) & "C3"
	local $bPrint = InjectCode($g_pD2InjectPrint, $sWrite)

#cs
	D2Client.dll+CDE10 - 8B CB                 - mov ecx,ebx
	D2Client.dll+CDE12 - 31 C0                 - xor eax,eax
	D2Client.dll+CDE14 - BB *                  - mov ebx,D2Lang.dll+9450
	D2Client.dll+CDE19 - FF D3                 - call ebx
	D2Client.dll+CDE1B - C3                    - ret
#ce
	$sWrite = "0x8BCB31C0BB" & SwapEndian($g_hD2Lang + 0x9450) & "FFD3C3"
	local $bGetString = InjectCode($g_pD2InjectGetString, $sWrite)

#cs
	D2Client.dll+CDE20 - 68 00010000           - push 00000100
	D2Client.dll+CDE25 - 68 *                  - push D2Client.dll+CDEF0
	D2Client.dll+CDE2A - 53                    - push ebx
	D2Client.dll+CDE2B - E8 *                  - call D2Client.dll+914F0
	D2Client.dll+CDE30 - C3                    - ret
#ce
	local $iIDWNT = ($g_hD2Client + 0x914F0) - ($g_hD2Client + 0xCDE31)
	$sWrite = "0x680001000068" & SwapEndian($g_pD2InjectString) & "53E8" & SwapEndian($iIDWNT) & "C3"
	local $bGetItemName = InjectCode($g_pD2Client_GetItemName, $sWrite)

#cs
	D2Client.dll+CDE40 - 57                    - push edi
	D2Client.dll+CDE41 - BF *                  - mov edi,D2Client.dll+CDEF0
	D2Client.dll+CDE43 - 6A 00                 - push 00
	D2Client.dll+CDE45 - 6A 01                 - push 01
	D2Client.dll+CDE47 - 53                    - push ebx
	D2Client.dll+CDE4B - E8 *                  - call D2Client.QueryInterface+A240
	D2Client.dll+CDE50 - 5F                    - pop edi
	D2Client.dll+CDE51 - C3                    - ret
#ce
	local $iIDWNTT = ($g_hD2Client + 0x560B0) - ($g_hD2Client + 0xCDE4E)
	$sWrite = "0x57BF" & SwapEndian($g_pD2InjectString) & "6A006A0153E8" & SwapEndian($iIDWNTT) & "5FC3"
	local $bGetItemStat = InjectCode($g_pD2Client_GetItemStat, $sWrite)

#cs 
	D2Client.dll+CDE54 - 6A 00                 - push 00
	D2Client.dll+CDE56 - FF 33                 - push [ebx]
	D2Client.dll+CDE58 - FF 73 04              - push [ebx+04]
	D2Client.dll+CDE5B - E8 10AD2000           - call D2Common.Ordinal10973
	D2Client.dll+CDE60 - A3 *                  - mov *,eax
	D2Client.dll+CDE65 - C3                    - ret 
#ce
	local $iIDWNT3 = ($g_hD2Common + 0x38B70) - ($g_hD2Client + 0xCDE60)
	$sWrite = "0x6A00FF33FF7304E8" & SwapEndian($iIDWNT3) & "A3" & SwapEndian($g_pD2InjectString) & "C3"
	local $bGetUnitStat = InjectCode($g_pD2Common_GetUnitStat, $sWrite)

	; Capture DrawFramedText's string so hover-copy works with vanilla text and D2GL HD Text.
	; Failure is non-fatal: ReadHoverText still uses D2Win's scratch buffer.
	InjectHoverTextHook()

	return $bPrint and $bGetString and $bGetItemName and $bGetItemStat and $bGetUnitStat
endfunc

func PtrEq($pA, $pB)
	return Hex($pA, 8) == Hex($pB, 8)
endfunc

func MemoryWriteDwordProtected($pAddress, $iValue)
	local $aProtect = DllCall($g_ahD2Handle[0], "bool", "VirtualProtectEx", "handle", $g_ahD2Handle[1], "ptr", $pAddress, "ulong_ptr", 4, "dword", $PAGE_EXECUTE_READWRITE, "dword*", 0)
	local $iOld = 0
	if (IsArray($aProtect) and $aProtect[0]) then $iOld = $aProtect[5]

	local $bOk = _MemoryWrite($pAddress, $g_ahD2Handle, $iValue, "dword")

	if ($iOld) then
		DllCall($g_ahD2Handle[0], "bool", "VirtualProtectEx", "handle", $g_ahD2Handle[1], "ptr", $pAddress, "ulong_ptr", 4, "dword", $iOld, "dword*", 0)
	endif

	return $bOk
endfunc

func RemoteGetProcOrdinal($hModule, $iOrdinal)
	local $pGetProcAddress = _WinAPI_GetProcAddress(_WinAPI_GetModuleHandle("kernel32.dll"), "GetProcAddress")
	if (not $pGetProcAddress) then return 0

	local $pStub = _MemVirtualAllocEx($g_ahD2Handle[1], 0, 0x20, BitOR($MEM_COMMIT, $MEM_RESERVE), $PAGE_EXECUTE_READWRITE)
	if (not $pStub) then return 0

	; push ordinal; push hModule; mov eax, GetProcAddress; call eax; ret
	local $sWrite = "0x68" & SwapEndian($iOrdinal) & "68" & SwapEndian($hModule) & "B8" & SwapEndian($pGetProcAddress) & "FFD0C3"
	local $pFunc = 0
	if (InjectCode($pStub, $sWrite)) then $pFunc = RemoteThread($pStub, 0)

	_MemVirtualFreeEx($g_ahD2Handle[1], $pStub, 0, $MEM_RELEASE)
	return $pFunc
endfunc

func GetPeImportDirRva($hModule)
	local $iLfanew = _MemoryRead($hModule + 0x3C, $g_ahD2Handle, "dword")
	if ($iLfanew < 0x40 or $iLfanew > 0x1000) then return 0

	local $iMagic = _MemoryRead($hModule + $iLfanew + 24, $g_ahD2Handle, "word")
	if ($iMagic <> 0x10B) then return 0 ; IMAGE_NT_OPTIONAL_HDR32_MAGIC

	return _MemoryRead($hModule + $iLfanew + 0x80, $g_ahD2Handle, "dword")
endfunc

; Returns IAT slot addresses for D2Win ordinal 10085 (DrawFramedText on 1.13c).
func FindDrawFramedTextIatSlots($hModule, $pDrawFramedText)
	local $aSlots[8]
	local $iCount = 0
	if (not $hModule) then return $aSlots

	local $iImportRva = GetPeImportDirRva($hModule)
	if (not $iImportRva) then return $aSlots

	local $pDesc = $hModule + $iImportRva
	local $iDesc
	for $iDesc = 1 to 64
		local $iNameRva = _MemoryRead($pDesc + 12, $g_ahD2Handle, "dword")
		if (not $iNameRva) then exitloop

		local $sDllName = StringLower(_MemoryRead($hModule + $iNameRva, $g_ahD2Handle, "char[64]"))
		local $iOrigThunk = _MemoryRead($pDesc, $g_ahD2Handle, "dword")
		local $iFirstThunk = _MemoryRead($pDesc + 16, $g_ahD2Handle, "dword")
		$pDesc += 20

		if ($sDllName <> "d2win.dll" or not $iFirstThunk) then continueloop

		local $pIlt = 0
		if ($iOrigThunk) then $pIlt = $hModule + $iOrigThunk
		local $pIat = $hModule + $iFirstThunk

		local $iThunk
		for $iThunk = 0 to 512
			local $iIatVal = _MemoryRead($pIat, $g_ahD2Handle, "dword")
			if (not $iIatVal) then exitloop

			local $bMatch = False
			if ($pIlt) then
				local $iIltVal = _MemoryRead($pIlt, $g_ahD2Handle, "dword")
				if (not $iIltVal) then exitloop
				if (StringLeft(Hex($iIltVal, 8), 4) == "8000" and Dec(StringRight(Hex($iIltVal, 8), 4)) == $g_iD2WinDrawFramedTextOrd) then $bMatch = True
			endif
			if ((not $bMatch) and $pDrawFramedText and PtrEq($iIatVal, $pDrawFramedText)) then $bMatch = True

			if ($bMatch) then
				$aSlots[$iCount] = $pIat
				$iCount += 1
				if ($iCount >= UBound($aSlots)) then exitloop 2
			endif

			$pIat += 4
			if ($pIlt) then $pIlt += 4
		next
	next

	; Sentinel: unused slots stay 0
	return $aSlots
endfunc

func InjectHoverTextHook()
	if (not $g_pHoverTextHook or not $g_pHoverTextBuffer) then return False

	if (not $g_pDrawFramedText) then
		$g_pDrawFramedText = RemoteGetProcOrdinal($g_hD2Win, $g_iD2WinDrawFramedTextOrd)
	endif

	local $ahModules[5] = [$g_hD2Client, $g_hD2Sigma, $g_hD2Common, $g_hD2Lang, $g_hGameExe]
	local $aPatchSlots[8]
	local $iPatchCount = 0
	local $pOriginal = 0
	local $iFound = 0
	local $iMod, $iSlot

	for $iMod = 0 to UBound($ahModules) - 1
		local $aSlots = FindDrawFramedTextIatSlots($ahModules[$iMod], $g_pDrawFramedText)
		for $iSlot = 0 to UBound($aSlots) - 1
			if (not $aSlots[$iSlot]) then continueloop

			$iFound += 1
			local $pIatVal = _MemoryRead($aSlots[$iSlot], $g_ahD2Handle, "dword")
			if (PtrEq($pIatVal, $g_pHoverTextHook)) then continueloop

			if (not $pOriginal) then $pOriginal = $pIatVal
			$aPatchSlots[$iPatchCount] = $aSlots[$iSlot]
			$iPatchCount += 1
			if ($iPatchCount >= UBound($aPatchSlots)) then exitloop 2
		next
	next

	if (not $iFound) then return False
	if (not $iPatchCount) then return True
	if (not $pOriginal) then return False

#cs
	pushad
	cld
	mov esi, ecx            ; DrawFramedText is __fastcall; str in ECX
	test esi, esi
	jz skip
	cmp word ptr [esi], 0
	je skip
	mov edi, hoverBuffer
	mov ecx, 8191
copy:
	lodsw
	stosw
	test ax, ax
	jz skip
	loop copy
	xor ax, ax
	stosw
skip:
	popad
	push original
	ret
#ce
	local $sWrite = "0x60FC8BF185F6742066833E00741ABF" & SwapEndian($g_pHoverTextBuffer) & "B9FF1F000066AD66AB6685C07407E2F56631C066AB6168" & SwapEndian($pOriginal) & "C3"
	if (not InjectCode($g_pHoverTextHook, $sWrite)) then return False

	local $bPatched = False
	for $iSlot = 0 to $iPatchCount - 1
		if (MemoryWriteDwordProtected($aPatchSlots[$iSlot], $g_pHoverTextHook)) then $bPatched = True
	next

	return $bPatched
endfunc

func ReadHoverText()
	local $sOutput = ""

	if ($g_pHoverTextBuffer) then
		$sOutput = _MemoryRead($g_pHoverTextBuffer, $g_ahD2Handle, StringFormat("wchar[%s]", $g_iHoverTextWChars))
		if ($sOutput <> "") then return $sOutput
	endif

	; Vanilla D2Win DrawFramedText fills this scratch buffer; D2GL HD Text does not.
	local $aiOffsets[2] = [0, 0]
	return _MemoryPointerRead($g_hD2Win + 0x1191F, $g_ahD2Handle, $aiOffsets, StringFormat("wchar[%s]", $g_iHoverTextWChars))
endfunc

func UpdateDllHandles()
	local $pLoadLibraryA = _WinAPI_GetProcAddress(_WinAPI_GetModuleHandle("kernel32.dll"), "LoadLibraryA")
	if (not $pLoadLibraryA) then return _Debug("UpdateDllHandles", "Couldn't retrieve LoadLibraryA address.")

	local $pAllocAddress = _MemVirtualAllocEx($g_ahD2Handle[1], 0, 0x100, BitOR($MEM_COMMIT, $MEM_RESERVE), $PAGE_EXECUTE_READWRITE)
	if (@error) then return _Debug("UpdateDllHandles", "Failed to allocate memory.")

	local $iDLLs = UBound($g_asDLL)
	local $hDLLHandle[$iDLLs]
	local $bFailed = False

	for $i = 0 to $iDLLs - 1
		_MemoryWrite($pAllocAddress, $g_ahD2Handle, $g_asDLL[$i], StringFormat("char[%s]", StringLen($g_asDLL[$i]) + 1))
		$hDLLHandle[$i] = RemoteThread($pLoadLibraryA, $pAllocAddress)
		if ($hDLLHandle[$i] == 0) then $bFailed = True
	next

	$g_hD2Client = $hDLLHandle[0]
	$g_hD2Common = $hDLLHandle[1]
	$g_hD2Win = $hDLLHandle[2]
	$g_hD2Lang = $hDLLHandle[3]
	$g_hD2Sigma = $hDLLHandle[4]

	$g_hGameExe = 0
	local $pGetModuleHandleA = _WinAPI_GetProcAddress(_WinAPI_GetModuleHandle("kernel32.dll"), "GetModuleHandleA")
	if ($pGetModuleHandleA) then $g_hGameExe = RemoteThread($pGetModuleHandleA, 0)

	local $pD2Inject = $g_hD2Client + 0xCDE00
	$g_pD2InjectPrint = $pD2Inject + 0x01 ; memory alignment
	$g_pD2InjectGetString = $pD2Inject + 0x11
	$g_pD2Client_GetItemName = $pD2Inject + 0x21
	$g_pD2Client_GetItemStat = $pD2Inject + 0x3E
	$g_pD2Common_GetUnitStat = $pD2Inject + 0x54
	; Output buffer for injected GetItemStats (game wcscpy, no dest length)
	$g_pD2InjectString = _MemVirtualAllocEx($g_ahD2Handle[1], 0, $g_iD2InjectStringBytes, BitOR($MEM_COMMIT, $MEM_RESERVE), $PAGE_EXECUTE_READWRITE)
	;~ make room for params array
	$g_pD2InjectParams = _MemVirtualAllocEx($g_ahD2Handle[1], 0, 0x100, BitOR($MEM_COMMIT, $MEM_RESERVE), $PAGE_EXECUTE_READWRITE)

	$g_pDrawFramedText = 0
	$g_pHoverTextBuffer = _MemVirtualAllocEx($g_ahD2Handle[1], 0, $g_iHoverTextBytes, BitOR($MEM_COMMIT, $MEM_RESERVE), $PAGE_EXECUTE_READWRITE)
	$g_pHoverTextHook = _MemVirtualAllocEx($g_ahD2Handle[1], 0, 0x40, BitOR($MEM_COMMIT, $MEM_RESERVE), $PAGE_EXECUTE_READWRITE)
	if ($g_pHoverTextBuffer) then _MemoryWrite($g_pHoverTextBuffer, $g_ahD2Handle, 0, StringFormat("byte[%s]", $g_iHoverTextBytes))

	$g_pD2sgpt = _MemoryRead($g_hD2Common + 0x99E1C, $g_ahD2Handle)

	_MemVirtualFreeEx($g_ahD2Handle[1], $pAllocAddress, 0x100, $MEM_RELEASE)
	if (@error) then return _Debug("UpdateDllHandles", "Failed to free memory.")
	if ($bFailed) then return _Debug("UpdateDllHandles", "Couldn't retrieve dll addresses.")

	return True
endfunc
#EndRegion
