#include-once

#Region Hotkeys globals
global $g_bHotkeysEnabled = False
global $g_hTimerCopyName = 0
global $g_sCopyName = ""
global $g_bNotifierLogVisible = False
global $g_aNotifierLogLines[0]
#EndRegion

#Region Hotkeys
func HotKey_CopyStatsToClipboard()
	if (not IsIngame()) then return

	UpdateStatValues()
	local $sOutput = ""

	for $i = 0 to $g_iNumStats - 1
		local $iVal = GetStatValue($i)

		if ($iVal) then
			$sOutput &= StringFormat("%s = %s%s", $i, $iVal, @CRLF)
		endif
	next

	ClipPut($sOutput)
	PrintString("Stats copied to clipboard.")
endfunc

func HotKey_CopyItemsToClipboard()
	if (not IsIngame()) then return

	local $iItemsTxt = _MemoryRead($g_hD2Common + 0x9FB94, $g_ahD2Handle)
	local $pItemsTxt = _MemoryRead($g_hD2Common + 0x9FB98, $g_ahD2Handle)

	local $pBaseAddr, $iNameID, $sName, $iMisc
	local $sOutput = ""

	for $iClass = 0 to $iItemsTxt - 1
		$pBaseAddr = $pItemsTxt + 0x1A8 * $iClass

		$iMisc = _MemoryRead($pBaseAddr + 0x84, $g_ahD2Handle, "dword")
		$iNameID = _MemoryRead($pBaseAddr + 0xF4, $g_ahD2Handle, "word")

		$sName = RemoteThread($g_pD2InjectGetString, $iNameID)
		$sName = _MemoryRead($sName, $g_ahD2Handle, "wchar[100]")
		$sName = StringReplace($sName, @LF, "|")

		$sOutput &= StringFormat("[class:%04i] [misc:%s] <%s>%s", $iClass, $iMisc ? 0 : 1, $sName, @CRLF)
	next

	ClipPut($sOutput)
	PrintString("Items copied to clipboard.")
endfunc

func HotKey_CopyItem($TEST = False)
	if ($TEST or not IsIngame()) then return

	local $hTimerRetry = TimerInit()
	local $sOutput = ""

	while ($sOutput == "" and TimerDiff($hTimerRetry) < 10)
		$sOutput = ReadHoverText()
	wend

	if (StringLen($sOutput) == 0) then
		PrintString("Hover the cursor over an item first.", $ePrintRed)
		return
	endif

	$sOutput = StringRegExpReplace($sOutput, "ÿc.", "")
	local $asLines = StringSplit($sOutput, @LF)

	if (_GUI_Option("copy-name")) then
		if ($g_hTimerCopyName == 0 or not (ClipGet() == $g_sCopyName)) then $g_sCopyName = ""
		$g_hTimerCopyName = TimerInit()

		$g_sCopyName &= $asLines[$asLines[0]] & @CRLF
		ClipPut($g_sCopyName)

		local $avItems = StringRegExp($g_sCopyName, @CRLF, $STR_REGEXPARRAYGLOBALMATCH)
		PrintString(StringFormat("%s item name(s) copied.", UBound($avItems)))
		return
	endif

	$sOutput = ""
	for $i = $asLines[0] to 1 step -1
		if ($asLines[$i] <> "") then $sOutput &= $asLines[$i] & @CRLF
	next

	ClipPut($sOutput)
	PrintString("Item text copied.")
endfunc

func HotKey_ReadStats()
	UpdateStatValues()
	UpdateGUI()

	$g_aiStatsCacheCopy = $g_aiStatsCache
endfunc

func HotKey_ShowNotifierLog()
	if (not IsIngame()) then return
	
	$g_bNotifierLogVisible = not $g_bNotifierLogVisible
	
	if ($g_bNotifierLogVisible) then
		; Clear current overlay first
		if ($g_hOverlayGUI <> 0) then
			for $i = 0 to UBound($g_aMessages) - 1
				GUICtrlDelete($g_aMessages[$i][0])
				GUICtrlDelete($g_aMessages[$i][1])
			next
			ReDim $g_aMessages[0][4]
			$g_iNextYPos = 0
			$g_bCleanupRunning = False
			AdlibUnRegister("CleanUpExpiredText")
		endif
		
		; Set history mode flag
		$g_bOverlayHistoryMode = True
		
		; Show header first
		PrintString("--- Overlay History (Press again to hide) ---", $ePrintYellow)
		OverlayAddItemGap()
		
		; Then show overlay history (newest first)
		local $iHistorySize = UBound($g_aOverlayHistory)
		if ($iHistorySize > 0) then
			for $i = 0 to $iHistorySize - 1
				PrintString($g_aOverlayHistory[$i][0], $g_aOverlayHistory[$i][1])
				if ($g_aOverlayHistory[$i][2]) then OverlayAddItemGap()
			next
		else
			PrintString("No overlay history available.", $ePrintGrey)
		endif
		
		; Clear history mode flag
		$g_bOverlayHistoryMode = False
	else
		; Hide log by clearing overlay messages
		if ($g_hOverlayGUI <> 0) then
			; Clear all messages
			for $i = 0 to UBound($g_aMessages) - 1
				GUICtrlDelete($g_aMessages[$i][0])
				GUICtrlDelete($g_aMessages[$i][1])
			next
			ReDim $g_aMessages[0][4]
			$g_iNextYPos = 0
			$g_bCleanupRunning = False
			AdlibUnRegister("CleanUpExpiredText")
		endif
	endif
endfunc
#EndRegion
