#include-once

#Region Notifier globals
global enum $eNotifyFlagsTier, $eNotifyFlagsQuality, $eNotifyFlagsMisc, $eNotifyFlagsNoMask, $eNotifyFlagsColour, $eNotifyFlagsSound, $eNotifyFlagsName, $eNotifyFlagsStat, $eNotifyFlagsMatchStats, $eNotifyFlagsMatch, $eNotifyFlagsLast
global $g_asNotifyFlags[$eNotifyFlagsLast][32] = [ _
	[ "0", "1", "2", "3", "4", "sacred", "angelic", "master" ], _
	[ "low", "normal", "superior", "magic", "set", "rare", "unique", "craft", "honor" ], _
	[ "eth" ], _
	[], _
	[ "transparent", "white", "red", "lime", "blue", "gold", "grey", "black", "pink", "orange", "yellow", "green", "purple" ], _
	[ "sound_none", "sound1", "sound2", "sound3", "sound4", "sound5", "sound6" ], _
	[ "name" ], _
	[ "stat" ] _
]
global $g_aiFlagsCountPerLine[0]

global const $g_iNumSounds = 6 ; Max 31
global $g_idVolumeSlider

global const $g_sNotifierRulesDirectory = $g_sAppDir & "\NotifierRules"
global const $g_sNotifierRulesExtension = ".rules"
global $g_avNotifyCache[0][3]					; Name, Tier flag, Last line of name
global $g_avNotifyCompile[0][$eNotifyFlagsLast]	; Flags, Regex
global $g_bNotifyCache = True
global $g_bNotifyCompile = True
global $g_bNotifierChanged = False

global $g_goblinIds = [2774, 2775, 2776, 2779, 2780, 2781, 2784, 2785, 2786, 2787, 2788, 2789, 2790, 2791, 2792, 2793, 2794, 2795, 2799, 2802, 2803, 2805]
global $g_goblinBuffer[] = []
#EndRegion

#Region Drop notifier
func NotifierFlag($sFlag)
	for $i = 0 to $eNotifyFlagsLast - 1
		for $j = 0 to UBound($g_asNotifyFlags, $UBOUND_COLUMNS) - 1
			if ($g_asNotifyFlags[$i][$j] == "") then
				exitloop
			elseif ($g_asNotifyFlags[$i][$j] == $sFlag) then
				return $i > $eNotifyFlagsNoMask ? $j : BitRotate(1, $j, "D")
			endif
		next
	next
	return SetError(1, 0, 0)
endfunc

func NotifierCache()
	if (not $g_bNotifyCache) then return
	$g_bNotifyCache = False

	local $iItemsTxt = _MemoryRead($g_hD2Common + 0x9FB94, $g_ahD2Handle)
	local $pItemsTxt = _MemoryRead($g_hD2Common + 0x9FB98, $g_ahD2Handle)

	local $pBaseAddr, $iNameID, $sName, $asMatch, $sTier, $iTierFlag

	redim $g_avNotifyCache[$iItemsTxt][3]

	for $iClass = 0 to $iItemsTxt - 1
		$pBaseAddr = $pItemsTxt + 0x1A8 * $iClass

		$iNameID = _MemoryRead($pBaseAddr + 0xF4, $g_ahD2Handle, "word")
		$sName = RemoteThread($g_pD2InjectGetString, $iNameID)
		$sName = _MemoryRead($sName, $g_ahD2Handle, "wchar[100]")

		$sName = StringReplace($sName, @LF, "|")
		$sName = StringRegExpReplace($sName, "ÿc.", "")
		$sTier = "0"

		if (_MemoryRead($pBaseAddr + 0x84, $g_ahD2Handle)) then ; Weapon / Armor
			$asMatch = StringRegExp($sName, "[1-4]|\Q(Sacred)\E|\Q(Angelic)\E|\Q(Mastercrafted)\E", $STR_REGEXPARRAYGLOBALMATCH)
			if (not @error) and IsArray($asMatch) then
				if (Ubound($asMatch) > 1 or $asMatch[0] == "") then
					_Debug("NotifierCache", StringFormat("Error while parsing item: '%s'", $sName))
					$sTier = "0"
				else
					select
						Case $asMatch[0] == "(Sacred)"
							$sTier = "sacred"
						Case $asMatch[0] == "(Angelic)"
							$sTier = "angelic"
						Case $asMatch[0] == "(Mastercrafted)"
							$sTier = "master"
						Case Else
							$sTier = $asMatch[0]
					EndSelect
				endif
			endif
		endif

		$iTierFlag = NotifierFlag($sTier)
		if (@error) then
			_Debug("NotifierCache", StringFormat("Invalid tier flag '%s'", $sTier))
			$iTierFlag = NotifierFlag("0")
		endif

		$g_avNotifyCache[$iClass][0] = $sName
		$g_avNotifyCache[$iClass][1] = $iTierFlag
		$g_avNotifyCache[$iClass][2] = StringRegExpReplace($sName, ".+\|", "")
	next
endfunc

func NotifierFlagRef($sFlag, ByRef $iFlag, ByRef $iGroup)
	$iFlag = 0
	$iGroup = 0

	for $i = 0 to $eNotifyFlagsLast - 1
		for $j = 0 to UBound($g_asNotifyFlags, $UBOUND_COLUMNS) - 1
			if ($g_asNotifyFlags[$i][$j] == "") then
				exitloop
			elseif (StringLower($g_asNotifyFlags[$i][$j]) == StringLower($sFlag)) then
				$iGroup = $i
				$iFlag = $j
				return 1
			endif
		next
	next

	return SetError(1, 0, 0)
endfunc

func NotifierCompileFlag($sFlag, ByRef $avRet, $sLine)
	if ($sFlag == "") then return False
	
	local $iFlag, $iGroup
	if (not NotifierFlagRef($sFlag, $iFlag, $iGroup)) then
		MsgBox($MB_ICONWARNING, "D2Stats", StringFormat("Unknown notifier flag '%s' in line:%s%s", $sFlag, @CRLF, $sLine))
		return False
	endif

	if ($iGroup < $eNotifyFlagsNoMask) then $iFlag = BitOR(BitRotate(1, $iFlag, "D"), $avRet[$iGroup])
	$avRet[$iGroup] = $iFlag

	return $iGroup <> $eNotifyFlagsColour
endfunc

func GetStatsGroups(byref $sLine, byref $avRet)
	local $sGroupsRegex = "\{(.*?)\}"
	local $sGroupsRemoveRegex = "\{.*?\}"
	local $asStatsGroups = StringRegExp($sLine, $sGroupsRegex, $STR_REGEXPARRAYGLOBALMATCH)

	if (UBound($asStatsGroups)) then
		$avRet[$eNotifyFlagsMatchStats] = $asStatsGroups
		$sLine = StringRegExpReplace($sLine, $sGroupsRemoveRegex, "")
	endif
endfunc

func NotifierCompileLine($sLine, byref $avRet, $iCount)
	$sLine = StringStripWS(StringRegExpReplace($sLine, "#.*", ""), BitOR($STR_STRIPLEADING, $STR_STRIPTRAILING, $STR_STRIPSPACES))
	local $iLineLength = StringLen($sLine)

	local $sArg = "", $sChar
	local $bItemPattern = False, $bHasFlags = False

	redim $avRet[0]
	redim $avRet[$eNotifyFlagsLast]

	GetStatsGroups($sLine, $avRet)

	for $i = 1 to $iLineLength
		$sChar = StringMid($sLine, $i, 1)

		if ($sChar == '"') then
			if ($bItemPattern) then
				$avRet[$eNotifyFlagsMatch] = $sArg
				$sArg = ""
			endif

			$bItemPattern = not $bItemPattern
		elseif ($sChar == " " and not $bItemPattern) then
			if (NotifierCompileFlag($sArg, $avRet, $sLine)) then
				$bHasFlags = True
				$g_aiFlagsCountPerLine[$iCount] += 1
			endif

			$sArg = ""
		else
			$sArg &= $sChar
		endif
	next

	if (NotifierCompileFlag($sArg, $avRet, $sLine)) then
		$bHasFlags = True
		$g_aiFlagsCountPerLine[$iCount] += 1
	endif

	if ($avRet[$eNotifyFlagsMatch] == "") then
		if (not $bHasFlags) then return False
		$avRet[$eNotifyFlagsMatch] = ".+"
	endif

	return True
endfunc

func NotifierCompile()
	if (not $g_bNotifyCompile) then return
	$g_bNotifyCompile = False
	$g_bNotifierChanged = True

	local $asLines = StringSplit(_GUI_Option("notify-text"), @LF)
	local $iLines = $asLines[0]

	redim $g_avNotifyCompile[0][0]
	redim $g_avNotifyCompile[$iLines][$eNotifyFlagsLast]

	redim $g_aiFlagsCountPerLine[0]
	redim $g_aiFlagsCountPerLine[$iLines]

	local $avRet[0]
	local $iCount = 0

	for $i = 1 to $iLines
		if (NotifierCompileLine($asLines[$i], $avRet, $iCount)) then
			for $j = 0 to $eNotifyFlagsLast - 1
				$g_avNotifyCompile[$iCount][$j] = $avRet[$j]
			next
			$iCount += 1
		endif
	next

	redim $g_aiFlagsCountPerLine[$iCount]
	redim $g_avNotifyCompile[$iCount][$eNotifyFlagsLast]
endfunc

func NotifierHelp($sInput)
	NotifierCache()

	local $iItems = UBound($g_avNotifyCache)
	local $asMatches[$iItems][2]
	local $iCount = 0

	local $avRet[0]

	if (NotifierCompileLine($sInput, $avRet, $iCount)) then
		local $sMatch = $avRet[$eNotifyFlagsMatch]
		local $iFlagsTier = $avRet[$eNotifyFlagsTier]

		local $sName, $iTierFlag

		for $i = 0 to $iItems - 1
			$sName = $g_avNotifyCache[$i][0]
			$iTierFlag = $g_avNotifyCache[$i][1]

			if (StringRegExp(StringLower($sName), StringLower($sMatch))) then
				if ($iFlagsTier and not BitAND($iFlagsTier, $iTierFlag)) then continueloop

				$asMatches[$iCount][0] = $sName
				$asMatches[$iCount][1] = $g_avNotifyCache[$i][2]
				$iCount += 1
			endif
		next
	endif

	redim $asMatches[$iCount][2]
	_ArrayDisplay($asMatches, "Notifier Help", default, 32, @LF, "Item|Text")
endfunc

func NotifierMain()
	NotifierCache()
	NotifierCompile()

	local $aiOffsets[4] = [0, 0x2C, 0x1C, 0x0]
	local $pPaths = _MemoryPointerRead($g_hD2Client + 0x11BBFC, $g_ahD2Handle, $aiOffsets)

	$aiOffsets[3] = 0x24
	local $iPaths = _MemoryPointerRead($g_hD2Client + 0x11BBFC, $g_ahD2Handle, $aiOffsets)

	if (not $pPaths or not $iPaths) then return

	local $pPath, $pUnit, $pUnitData, $pCurrentUnit
	local $iUnitType, $iClass, $iUnitId, $iQuality, $iFileIndex, $iEarLevel, $iFlags, $iTierFlag
	local $bIsEthereal
	local $iFlagsTier, $iFlagsQuality, $iFlagsMisc, $iFlagsColour, $iFlagsSound, $iFlagsDisplayName, $iFlagsDisplayStat
	local $sType

	local $tUnitAny = DllStructCreate("dword iUnitType;dword iClass;dword pad1;dword dwUnitId;dword pad2;dword pUnitData;dword pad3[52];dword pUnit;")
	local $tItemData = DllStructCreate("dword iQuality;dword pad1[5];dword iFlags;dword pad2[3];dword dwFileIndex; dword pad2[7];byte iEarLevel;")
	local $tUniqueItemsTxt = DllStructCreate("dword pad1[13];word wLvl;")
	local $pUniqueItemsTxt = _MemoryRead($g_pD2sgpt + 0xC24, $g_ahD2Handle)

	local $sMatchingLine
	local $aOnGroundDisplayPool[0][4]

	for $i = 0 to $iPaths - 1
		$pPath = _MemoryRead($pPaths + 4 * $i, $g_ahD2Handle)
		$pUnit = _MemoryRead($pPath + 0x74, $g_ahD2Handle)

		; while object observable
		while $pUnit
			_WinAPI_ReadProcessMemory($g_ahD2Handle[1], $pUnit, DllStructGetPtr($tUnitAny), DllStructGetSize($tUnitAny), 0)
			$iUnitType = DllStructGetData($tUnitAny, "iUnitType")
			$pUnitData = DllStructGetData($tUnitAny, "pUnitData")
			$iUnitId = DllStructGetData($tUnitAny, "dwUnitId")
			$iClass = DllStructGetData($tUnitAny, "iClass")
			$pCurrentUnit = $pUnit
			$pUnit = DllStructGetData($tUnitAny, "pUnit")

			; iUnitType 1 = monster
			if(_GUI_Option("goblin-alert")) Then
				if ($iUnitType == 1 and _ArraySearch($g_goblinIds, $iClass) > -1) then
					GoblinAlert($iUnitId)
				endif
			endif
			
			; iUnitType 4 = item
			if ($iUnitType == 4) then
				_WinAPI_ReadProcessMemory($g_ahD2Handle[1], $pUnitData, DllStructGetPtr($tItemData), DllStructGetSize($tItemData), 0)
				$iQuality = DllStructGetData($tItemData, "iQuality")
				$iFlags = DllStructGetData($tItemData, "iFlags")
				$iEarLevel = DllStructGetData($tItemData, "iEarLevel")
				$iFileIndex = DllStructGetData($tItemData, "dwFileIndex")
				
				; Using the ear level field to check if we've seen this item on the ground before
				; Resets when the item is picked up or we move too far away (search for OnGroundFilterItems func)
				if (not $g_bNotifierChanged and $iEarLevel <> 0) then continueloop
				; We are showing items on ground by default
				DisplayItemOnGround($pUnitData, true)

				if ($iClass < 0 or $iClass >= UBound($g_avNotifyCache)) then continueloop
				
				$bIsEthereal = BitAND(0x400000, $iFlags) <> 0

				$sType = $g_avNotifyCache[$iClass][0]
				$iTierFlag = $g_avNotifyCache[$iClass][1]

				; Match with notifier rules
				for $j = 0 to UBound($g_avNotifyCompile) - 1
					if (StringRegExp(StringLower($sType), StringLower($g_avNotifyCompile[$j][$eNotifyFlagsMatch]))) then
		                _WinAPI_ReadProcessMemory($g_ahD2Handle[1], $pUniqueItemsTxt + ($iFileIndex * 0x14c), DllStructGetPtr($tUniqueItemsTxt), DllStructGetSize($tUniqueItemsTxt), 0)
		                local $iLvl = DllStructGetData($tUniqueItemsTxt, "wLvl")

						$sMatchingLine = $g_avNotifyCompile[$j][$eNotifyFlagsMatch]
						$iFlagsTier = $g_avNotifyCompile[$j][$eNotifyFlagsTier]
						$iFlagsQuality = $g_avNotifyCompile[$j][$eNotifyFlagsQuality]
						$iFlagsMisc = $g_avNotifyCompile[$j][$eNotifyFlagsMisc]
						$iFlagsColour = $g_avNotifyCompile[$j][$eNotifyFlagsColour]
						$iFlagsSound = $g_avNotifyCompile[$j][$eNotifyFlagsSound]
						$iFlagsDisplayName = $g_avNotifyCompile[$j][$eNotifyFlagsName]
						$iFlagsDisplayStat = $g_avNotifyCompile[$j][$eNotifyFlagsStat]

						local $asStatGroups = $g_avNotifyCompile[$j][$eNotifyFlagsMatchStats]

						local $iFlagsCount = $g_aiFlagsCountPerLine[$j]

						; For notification display flags
						local $bNotEquipment = $iQuality == $eQualityNormal and $iTierFlag == NotifierFlag("0")
						local $bShowItemName = $iFlagsDisplayName == NotifierFlag("name")
						local $bDisplayItemStats = $iFlagsDisplayStat == NotifierFlag("stat")

						if ($iFlagsTier and not BitAND($iFlagsTier, $iTierFlag)) then continueloop
						if ($iFlagsQuality and not BitAND($iFlagsQuality, BitRotate(1, $iQuality - 1, "D"))) then continueloop
						if (not $bIsEthereal and BitAND($iFlagsMisc, NotifierFlag("eth"))) then continueloop

						; Flags are added to the object because I don't know a more
                        ; convenient way to pass them to the function :)
						local $oItemFlags = ObjCreate("Scripting.Dictionary")

						; Collecting flags per item for overlay notifications
						$oItemFlags.add('$iFlagsColour', $iFlagsColour)
						$oItemFlags.add('$iFlagsSound', $iFlagsSound)
						$oItemFlags.add('$asStatGroups', $asStatGroups)
						$oItemFlags.add('$iFlagsCount', $iFlagsCount)
						$oItemFlags.add('$sMatchingLine', $sMatchingLine)
						$oItemFlags.add('$bIsEthereal', $bIsEthereal)
						$oItemFlags.add('$bNotEquipment', $bNotEquipment)
						$oItemFlags.add('$iQuality', $iQuality)
						$oItemFlags.add('$pCurrentUnit', $pCurrentUnit)
						$oItemFlags.add('$pUnitData', $pUnitData)
						$oItemFlags.add('$bDisplayItemStats', $bDisplayItemStats)
						$oItemFlags.add('$bShowItemName', $bShowItemName)
						$oItemFlags.add('$iLvl', $iLvl)

						; Forming an array of notifications to add to the pool
                        local $aOnGroundItem[1][4] = [[$sType, $oItemFlags]]
						
                        _ArrayAdd($aOnGroundDisplayPool, $aOnGroundItem)
					endif
				next
				if (UBound($aOnGroundDisplayPool) > 0) then ProcessItems($aOnGroundDisplayPool)
			endif
		wend

		$g_bNotifierChanged = False
	next
endfunc

func ProcessItems(byref $aOnGroundDisplayPool)
	local $asNotificationsPool[0][4]

	local $asPreNotificationsPool = OnGroundFilterItems($aOnGroundDisplayPool)
	
	; $asNotificationsPool represents an array of notifications per item base
	$asNotificationsPool = FormatNotifications($asPreNotificationsPool)
	
	; Display notifications from pool
	DisplayNotification($asNotificationsPool)
endfunc

func DisplayItemOnGround($pUnitData, $iShow)
	_MemoryWrite($pUnitData + 0x48, $g_ahD2Handle, $iShow ? 1 : 2, "byte")		
endfunc

func OnGroundFilterItems(byref $aOnGroundDisplayPool)
	if (UBound($aOnGroundDisplayPool) == 0) then return

	local $asPreNotificationsPool[0][4]

	for $i = 0 to UBound($aOnGroundDisplayPool) - 1
		local $aNotification[1][4] = [[$aOnGroundDisplayPool[$i][0], $aOnGroundDisplayPool[$i][1]]]
		_ArrayAdd($asPreNotificationsPool, $aNotification)
	next

	; Clean "on ground" pool after processing
	redim $aOnGroundDisplayPool[0][4]
	return $asPreNotificationsPool
endfunc

func FormatNotifications(byref $asPreNotificationsPool)
	if (UBound($asPreNotificationsPool) == 0) then return
	
	local $asNotificationsPool[0][4]
	
	for $i = 0 to UBound($asPreNotificationsPool) - 1
		local $oFlags = $asPreNotificationsPool[$i][1]
		
		local $pCurrentUnit = $oFlags.item('$pCurrentUnit')
		local $asStatGroups = $oFlags.item('$asStatGroups')
		local $bDisplayItemStats = $oFlags.item('$bDisplayItemStats')
		local $bIsEthereal = $oFlags.item('$bIsEthereal')
		local $iFlagsColour = $oFlags.item('$iFlagsColour')
		local $bNotEquipment = $oFlags.item('$bNotEquipment')
		local $iQuality = $oFlags.item('$iQuality')
		local $bShowItemName = $oFlags.item('$bShowItemName')
		local $iLvl = $oFlags.item('$iLvl')

		local $bIsMatchByStats = False

		local $asItem = GetItemName($pCurrentUnit)
		local $asItemName = UBound($asItem) == 3 ? $asItem[2] : ""
        local $asItemType = (IsArray($asItem) and UBound($asItem) >= 2) ? $asItem[1] : ""
        local $asItemStats = ""
        local $iItemColor = $ePrintWhite
		if ($bNotEquipment) then
			$iItemColor = $ePrintOrange
		elseif ($iQuality >= 0 and $iQuality < UBound($g_iQualityColor)) then
			$iItemColor = $g_iQualityColor[$iQuality]
		endif
        local $sPreName = ""
		
        ; collect a reversed 2d array of stats and color
        ; to display as notifications per line
        if (UBound($asStatGroups) or $bDisplayItemStats) then
			local $sGetItemStats = GetItemStats($pCurrentUnit)
			local $iSocketCount = GetUnitStat($oFlags.item('$pCurrentUnit'), 0xC2)
			if $iQuality > 0 and $iQuality < 5 then
				$sGetItemStats = "Socketed (" & $iSocketCount & ")" & @CRLF & $sGetItemStats
			endif
			$asItemStats = HighlightStats($sGetItemStats, $asStatGroups, $bIsMatchByStats)
            $oFlags.add('$bIsMatchByStats', $bIsMatchByStats)
        endif
		
        ; Don't display notification if no match by stats from rule
        if (UBound($asStatGroups) and not $bIsMatchByStats) then
			continueloop
        endif

		; Notifications section. Assembling text, collecting in pool
		if ($bIsEthereal) then
			$sPreName = "(Eth) " & $sPreName
		endif

	    if ($iFlagsColour) then $iItemColor = $iFlagsColour - 1

	    if (_GUI_Option("notify-superior") and $iQuality == $eQualitySuperior) then $sPreName = "Superior " & $sPreName

        if(_GUI_Option("unique-tier") and $iQuality == 7) Then
            if($iLvl == 1) Then
            elseif ($iLvl <= 100) then
                $sPreName = "{TU} " & $sPreName
            elseif ($iLvl <= 115) then
                $sPreName = "{SU} " & $sPreName
            elseif ($iLvl <= 120) then
                $sPreName = "{SSU} " & $sPreName
            elseif ($iLvl <= 130) then
                $sPreName = "{SSSU} " & $sPreName
            endif
        endif

        if ($iFlagsColour or $bNotEquipment) then
            $asItemName = StringRegExpReplace($asItemName, "ÿc.", "")
            $asItemType = StringRegExpReplace($asItemType, "ÿc.", "")
        endif

		; compiling texts for item notifications
		if ($bNotEquipment) then
			local $sCombinedName = $asItemName == "" ? $asItemType : $asItemName
            local $asNewName = ["- " & $sPreName & $sCombinedName, $iItemColor]
            $asItemName = $asNewName
            $asItemType = ""
        else
	        if ($asItemName and ($bShowItemName or $bIsMatchByStats)) then
	            if(_GUI_Option("oneline-name")) then
	                local $asNewName = ["- " & $sPreName & $asItemName & "  " & $asItemType, $iItemColor]

	                $asItemName = $asNewName
	                $asItemType = ""
	            else
		            local $asNewName = ["- " & $sPreName & $asItemName, $iItemColor]
		            local $asNewType = ["  " & $asItemType, $ePrintGrey]

		            $asItemName = $asNewName
		            $asItemType = $asNewType
	            endif
	        else
	            local $asNewType = ["- " & $sPreName & $asItemType, $iItemColor]
	            $asItemName = ""
	            $asItemType = $asNewType
            endif
        endif
        local $aNotification[1][4] = [[$asItemName, $asItemType, $asItemStats, $oFlags]]
        _ArrayAdd($asNotificationsPool, $aNotification)
	next
	return $asNotificationsPool
endfunc

func DisplayNotification(ByRef $asNotificationsPool)
    if (UBound($asNotificationsPool) == 0) then return

    local $aNotifications = NarrowNotificationsPool($asNotificationsPool)
    if (not UBound($aNotifications)) then return

    local $asName = $aNotifications[0]
    local $asType = $aNotifications[1]
    local $asStats = $aNotifications[2]
    local $oFlags = $aNotifications[3]

    local $sMatchingLine = $oFlags.item('$sMatchingLine')
    local $iFlagsSound = $oFlags.item('$iFlagsSound')
    local $pCurrentUnit = $oFlags.item('$pCurrentUnit')
    local $iQuality = $oFlags.item('$iQuality')

    ; Play sound if needed
    if ($iFlagsSound <> NotifierFlag("sound_none")) then
        NotifierPlaySound($iFlagsSound)
    endif

    ; Group this item's PrintString calls so history keeps live overlay order
    $g_bOverlayHistoryGroup = True
    $g_iOverlayHistoryGroupLen = 0

    ; Display name and type
    ShowIfAvailable($asName)
    ShowIfAvailable($asType)

    ; Show stats
    DisplayStats($asStats)

    ; Debug info
    if (_GUI_Option("debug-notifier")) then
        PrintString("rule - " & $sMatchingLine, $ePrintRed)
    endif

    $g_bOverlayHistoryGroup = False
    If $g_iOverlayHistoryGroupLen > 0 Then OverlayAddItemGap($g_iOverlayHistoryGroupLen - 1)
    $g_iOverlayHistoryGroupLen = 0
endfunc

;Show a 2-element array if it exists
func ShowIfAvailable($arr)
    if (UBound($arr)) then
        PrintString($arr[0], $arr[1])
    endif
endfunc

;Display stats based on GUI options
func DisplayStats($asStats)
    if (not UBound($asStats)) then return

    local $asCombinedStats = ""
	local $bHasKeywordColumn = UBound($asStats, 2) > 2

    for $n = 0 to UBound($asStats) - 1
        local $statText = $asStats[$n][0]
        local $statColor = $asStats[$n][1]
		local $bKeywordMatched = $bHasKeywordColumn ? $asStats[$n][2] : ($statColor == $ePrintRed)

        if ($statText == "") then continueLoop

        if (_GUI_Option("oneline-stats")) then
			;Skip prefixes and suffixes when pringing oneline stat style
			if StringInStr($statText, "Prefixes") = 0 AND StringInStr($statText, "Suffixes") = 0 then
				if (ShouldPrintStat($statColor, $bKeywordMatched)) then
					$asCombinedStats &= $statText & ", "
				endif
			endif
        else
            if (ShouldPrintStat($statColor, $bKeywordMatched)) then
                PrintString("  " & $statText, $statColor)
            endif
        endif
    next

    if (_GUI_Option("oneline-stats")) and ($asCombinedStats <> "") then
		local $ePrintColor = $ePrintBlue
		;Modify print color based on notify filtered stats checkbox state
		if (_GUI_Option("notify-only-filtered")) then $ePrintColor = $ePrintRed

		PrintString(StringTrimRight($asCombinedStats, 2), $ePrintColor)
	endif
endfunc

;Determine whether a stat should be printed
func ShouldPrintStat($color, $bKeywordMatched = False)
    if (_GUI_Option("notify-only-filtered")) then
        return $bKeywordMatched
    endif
    return True
endfunc

; To display only one notification we need to narrow notifications
; pool by filtering and prioritising
func NarrowNotificationsPool($asNotificationsPool)
	local $aNotifications[0]
	local $iLastFlagsCount

	local $aPrioritizeByStats = False
	local $aPrioritizeByColour = False
	local $aPrioritizeByFlagsCount = False

	for $i = 0 to UBound($asNotificationsPool) - 1
		local $aPool[4] = [$asNotificationsPool[$i][0], $asNotificationsPool[$i][1], $asNotificationsPool[$i][2], $asNotificationsPool[$i][3]]
		local $oFlags = $aPool[3]

		local $iFlagsColour = $oFlags.item('$iFlagsColour')
		local $iFlagsCount = $oFlags.item('$iFlagsCount')
		local $bIsMatchByStats = $oFlags.item('$bIsMatchByStats')

		if ($bIsMatchByStats) then
			$aPrioritizeByStats = $aPool
			continueloop;

		elseif ($iFlagsColour) then
			$aPrioritizeByColour = $aPool
			continueloop;

		elseif ($iFlagsCount > $iLastFlagsCount or $iFlagsCount == 0) then
			$aPrioritizeByFlagsCount = $aPool
			$iLastFlagsCount = $iFlagsCount
			continueloop;
		endif
    next

    if (UBound($aPrioritizeByStats)) then
			$aNotifications = $aPrioritizeByStats
			if(_GUI_Option("debug-notifier")) then PrintString('match by stats', $ePrintRed)

    elseif (UBound($aPrioritizeByColour)) then
			$aNotifications = $aPrioritizeByColour
			if(_GUI_Option("debug-notifier")) then PrintString('match by color', $ePrintRed)

    elseif (UBound($aPrioritizeByFlagsCount)) then
			$aNotifications = $aPrioritizeByFlagsCount
			if(_GUI_Option("debug-notifier")) then PrintString($iFlagsCount & ' match by flags count', $ePrintRed)

    else
		$aNotifications = $aPool
	endif

	return $aNotifications
endfunc

; Map Diablo II ÿcX color codes to overlay print colors. Default remains blue.
func GetD2StatPrintColor($sStat)
	local $asCode = StringRegExp($sStat, "ÿc(.)", $STR_REGEXPARRAYMATCH)
	if (@error) then return $ePrintBlue

	select
		case $asCode[0] == "0"
			return $ePrintWhite
		case $asCode[0] == "1"
			return $ePrintRed
		case $asCode[0] == "2"
			return $ePrintLime
		case $asCode[0] == "3"
			return $ePrintBlue
		case $asCode[0] == "4" or $asCode[0] == "7"
			return $ePrintGold
		case $asCode[0] == "5"
			return $ePrintGrey
		case $asCode[0] == "6"
			return $ePrintBlack
		case $asCode[0] == "8"
			return $ePrintOrange
		case $asCode[0] == "9"
			return $ePrintYellow
		case $asCode[0] == ":"
			return $ePrintGreen
		case $asCode[0] == ";"
			return $ePrintPurple
		case else
			return $ePrintBlue
	endselect
endfunc

func HighlightStats($sGetItemStats, $asStatGroups, byref $bIsMatchByStats)
	local $asStats = StringSplit($sGetItemStats, @LF)
	local $aPlainStats[$asStats[0]][3]
	local $aColoredStats[$asStats[0]][3]
	local $iMatchCounter = 0

    for $k = 1 to $asStats[0]
        local $sStat = $asStats[$k]
		local $sStatText = StringRegExpReplace($sStat, "ÿc.", "")
		local $iStatColor = GetD2StatPrintColor($sStat)
		local $iRow = $asStats[0] - $k
		local $bKeywordMatched = False

		$aColoredStats[$iRow][0] = $sStatText
        $aColoredStats[$iRow][1] = $iStatColor
		$aColoredStats[$iRow][2] = False

        $aPlainStats[$iRow][0] = $sStatText
        $aPlainStats[$iRow][1] = $iStatColor
		$aPlainStats[$iRow][2] = False

        for $i = 0 to UBound($asStatGroups) - 1
            if ($asStatGroups[$i] == "" or $bKeywordMatched) then
                continueloop
            endif

            if (StringRegExp(StringLower($sStatText), StringLower($asStatGroups[$i]))) then
                $aColoredStats[$iRow][1] = $ePrintRed
				$aColoredStats[$iRow][2] = True
                $bKeywordMatched = True
                $iMatchCounter += 1
            endif
        next
    next
	
	if ($iMatchCounter >= UBound($asStatGroups)) then
		$bIsMatchByStats = True
		return $aColoredStats
	else
		$bIsMatchByStats = False
		return $aPlainStats
	endif
endfunc

func NotifierPlaySound($iSound)
	local $iVolume = _GUI_Volume($iSound - 1) * 10
	if ($iVolume > 0) then
		local $sScriptFile = @Compiled ? "" : StringFormat(' "%s"', @ScriptFullPath)
		local $sRun = StringFormat('"%s"%s %s %s %s %s', @AutoItExe, $sScriptFile, "sound", $iSound, $iVolume, _GUI_Option("use-wav") ? "wav" : "mp3")
		Run($sRun)
	endif
endfunc
#EndRegion

#Region Notifier UI
func OnChange_NotifyRulesCombo()
	if (BitAND(GUICtrlGetState($g_idNotifySave), $GUI_ENABLE)) then
		local $iButton = MsgBox(BitOR($MB_ICONQUESTION, $MB_YESNO), "D2Stats", "There are unsaved changes in the current notifier rules. Save?", 0, $g_hGUI)
		if ($iButton == $IDYES) then
			SaveCurrentNotifierRulesToFile(_GUI_Option("selectedNotifierRulesName"))
		endif
	endif
	
	local $sSelectedNofitierRules = GUICtrlRead($g_idNotifyRulesCombo)
	
	local $sNotifierRulesFilePath = ""
	for $i = 1 to $g_aNotifierRulesFilePaths[0] step +1
		if (GetNotifierRulesName($g_aNotifierRulesFilePaths[$i]) == $sSelectedNofitierRules) then
			$sNotifierRulesFilePath = $g_aNotifierRulesFilePaths[$i]
			exitloop
		endif
	next
	
	;First case should never happen, but we'll check anyway
	if ($sNotifierRulesFilePath == "" or not FileExists($sNotifierRulesFilePath)) then
		MsgBox($MB_ICONERROR, "File Not Found", "The file for the notifier rules named " & $sNotifierRulesFilePath & " could not be found.")
		return
	endif

	local $aNotifierRules[] = []
	if (not _FileReadToArray($sNotifierRulesFilePath, $aNotifierRules)) then
		MsgBox($MB_ICONERROR, "Error Reading File", "Could not read the file '" & $sNotifierRulesFilePath & "'. Error code: " & @error)
		return
	endif

	local $sNotifierRules = ""
	for $i = 1 to $aNotifierRules[0] step +1
		$sNotifierRules &= $aNotifierRules[$i] & @CRLF
	next

	GUICtrlSetData($g_idNotifyEdit, $sNotifierRules)

	_GUI_Option("selectedNotifierRulesName", $sSelectedNofitierRules)
	_GUI_Option("notify-text", $sNotifierRules)
	OnChange_NotifyEdit()
	$g_bNotifyCompile = True
endfunc

func OnClick_NotifyNew()
	local $sNewNotifierRulesName = ""
	if (not AskUserForNotifierRulesName($sNewNotifierRulesName)) then
		return False
	endif

	if not CreateNotifierRulesFile(GetNotifierRulesFilePath($sNewNotifierRulesName)) then
		return False
	endif

	RefreshNotifyRulesCombo($sNewNotifierRulesName)
endfunc

func OnClick_NotifyRename()
	local $sOldNotifierRulesName = GUICtrlRead($g_idNotifyRulesCombo)
	local $sNewNotifierRulesName = ""

	if (not AskUserForNotifierRulesName($sNewNotifierRulesName, $sOldNotifierRulesName)) then
		return False
	endif

	if (not FileMove(GetNotifierRulesFilePath($sOldNotifierRulesName), GetNotifierRulesFilePath($sNewNotifierRulesName))) then
		MsgBox($MB_ICONERROR, "Error!", "An error occurred while renaming the notifier rules file!")
		return False
	endif

	RefreshNotifyRulesCombo($sNewNotifierRulesName)
endfunc

func OnClick_NotifyDelete()
	local $sSelectedNofitierRules = GUICtrlRead($g_idNotifyRulesCombo)

	local $iMessageBoxResult = MsgBox(4, "Delete Notifier Rules?" ,"Are you sure you want to delete the notifier rules named '" & $sSelectedNofitierRules & "'?", 0, $g_hGUI)
	if ($iMessageBoxResult == $IDNO) then
		return
	endif

	if (not FileDelete(GetNotifierRulesFilePath($sSelectedNofitierRules))) then
		MsgBox($MB_ICONERROR, "Error!", "An error occurred while deleting the notifier rules file!")
		return
	endif

	RefreshNotifyRulesCombo()
endfunc

func OnClick_NotifySave()
	SaveCurrentNotifierRulesToFile(GUICtrlRead($g_idNotifyRulesCombo))
endfunc

func OnClick_NotifyReset()
	GUICtrlSetData($g_idNotifyEdit, _GUI_Option("notify-text"))
	OnChange_NotifyEdit()
endfunc

func OnClick_NotifyHelp()
	local $asText[] = [ _
		'"Item Name" {Stat name} flag1 flag2 ... flagN # Everything after hashtag is a comment.', _
		'', _
		'Item name is what you''re matching against. It''s a regex string.', _
		'Stat name is the attribute you are looking for on the item.', _
		'If you''re unsure what regex is, use letters only.', _
		'', _
		'Flags:', _
		'> 0-4 sacred angelic master - Item must be one of these tiers.', _
		'   Tier 0 means untiered items (runes, amulets, etc).', _
		'> normal superior rare set unique - Item must be one of these qualities.', _
		'> name - To print type name and real name.', _
		'> stat - To print type name and full stats. You can mix it with name flag', _
		'> eth - Item must be ethereal.', _
		'> white red lime blue gold orange yellow green purple - Notification color.', _
		StringFormat('> sound[1-%s] - Notification sound.', $g_iNumSounds), _
		'', _
		'Example 1:', _
		'"Battle" sacred unique eth sound3', _
		'This would notify for ethereal SU Battle Axe, Battle Staff,', _
		'Short Battle Bow and Long Battle Bow, and would play Sound 3', _
		'', _
		'Example 2:', _
        'sacred {socketed \([0,6]\)}', _
        'This would match ever sacred item with 0 or 6 Sockets', _
		'', _
        'Example 3:', _
        '"Amulet$" normal rare magic', _
        '"Amulet$" rare {[3-5] to All Skills}', _
        'This would match ever rare amulet with 3-5 to All skills', _
		'', _
        'Example 4:', _
        '"Amulet$" {[3-5] to All Skills} {Spell Focus} {to Spell Damage}', _
        '"Amulet$" {Fire Spell} {Maximum Mana}', _
        'This would match every amulet with "3-5 to all skills", "spell focus"', _
        'and "to spell damage" OR amulets with "fire spell damage" and "maximum mana"', _
		'', _
		'Write something in this box and click OK to see what matches!' _
	]

	local $sText = ""
	for $i = 0 to UBound($asText) - 1
		$sText &= $asText[$i] & @CRLF
	next

	local $sInput = InputBox("Notifier Help", $sText, default, default, 450, 120 + UBound($asText) * 13, default, default, default, $g_hGUI)
	if (not @error) then
		if (IsIngame()) then
			NotifierHelp($sInput)
		else
			MsgBox($MB_ICONINFORMATION, "D2Stats", "You need to be ingame to do that.")
		endif
	endif
endfunc

func OnClick_NotifyDefault()
	GUICtrlSetData($g_idNotifyEdit, $g_sNotifyTextDefault)
	OnChange_NotifyEdit()
endfunc

func OnChange_NotifyEdit()
	local $iState = _GUI_Option("notify-text") == GUICtrlRead($g_idNotifyEdit) ? $GUI_DISABLE : $GUI_ENABLE
	GUICtrlSetState($g_idNotifySave, $iState)
	GUICtrlSetState($g_idNotifyReset, $iState)
endfunc

func GetNotifierRulesName($sNotifierRulesFilePath)
	return StringReplace(StringMid($sNotifierRulesFilePath, StringInStr($sNotifierRulesFilePath, "\", 2, -1) + 1), $g_sNotifierRulesExtension, "", -1)
endfunc

func GetNotifierRulesFilePath($sNotifierRulesName)
	return $g_sNotifierRulesDirectory & "\" & $sNotifierRulesName & $g_sNotifierRulesExtension
endfunc

func SaveCurrentNotifierRulesToFile($sNotifierRulesName)
	local $sNotifyEditContents = GUICtrlRead($g_idNotifyEdit)
	CreateNotifierRulesFile(GetNotifierRulesFilePath($sNotifierRulesName), $sNotifyEditContents)
	_GUI_Option("selectedNotifierRulesName", $sNotifierRulesName)
	_GUI_Option("notify-text", $sNotifyEditContents)
	OnChange_NotifyEdit()
	$g_bNotifyCompile = True
endfunc

func CreateNotifierRulesFile($sNotifierRulesFilePath, $sNotifierRules = "")
	DirCreate($g_sNotifierRulesDirectory)

	if ($sNotifierRules == "") then $sNotifierRules = $g_sNotifyTextDefault

	local $aNotifierRules[] = [$sNotifierRules]

	if (not _FileWriteFromArray($sNotifierRulesFilePath, $aNotifierRules)) then
		MsgBox($MB_ICONERROR, "Error Creating File", "An error occurred when creating the notifier rules file. File: " & $sNotifierRulesFilePath & " Error code: " & @error)
		return False
	endif

	return True
endfunc

func AskUserForNotifierRulesName(byref $sNewNotifierRulesName, $sInitialNotifierRulesName = "")
	local const $iMaxNameLength = 30
	local $sInputBoxTitle = $sInitialNotifierRulesName == "" ? "New Notifier Rules" : "Rename Notifier Rules"

	while (True)
		local $sUserInput = InputBox($sInputBoxTitle, "Enter a name for the notifier rules (max "& $iMaxNameLength & " characters):", $sInitialNotifierRulesName, "", 320, 130, default, default, 0, $g_hGUI)

		if (@error) then
			return False
		endif

		$sUserInput = StringStripWS($sUserInput, BitOR($STR_STRIPLEADING, $STR_STRIPTRAILING))
		$sInitialNotifierRulesName = $sUserInput
		if ($sUserInput == "") then
			MsgBox($MB_ICONERROR, "Invalid Name", 'No name entered.')
			continueloop
		endif

		if (StringRegExp($sUserInput, '[\Q\/:*?"<>|\E]')) then
			MsgBox($MB_ICONERROR, "Invalid Name", 'The name you have entered should NOT contain the following symbols: \/:*?"<>|')
			continueloop
		endif

		if (StringLen($sUserInput) > $iMaxNameLength) then
			MsgBox($MB_ICONERROR, "Invalid Name", "The name you have entered is too long. Maximum is " & $iMaxNameLength & " characters.")
			continueloop
		endif

		local $sNewNotifierRulesFilePath = GetNotifierRulesFilePath($sUserInput)
		if (FileExists($sNewNotifierRulesFilePath)) then
			MsgBox($MB_ICONERROR, "Notifier Rules Already Exists", "The notifier rules name you have entered is already in use. Choose another name.")
			continueloop
		endif

		$sNewNotifierRulesName = $sUserInput
		return True
	wend
endfunc

func RefreshNotifyRulesCombo($sSelectedNotifierRulesName = "")
	global $g_aNotifierRulesFilePaths = _FileListToArray($g_sNotifierRulesDirectory, "*" & $g_sNotifierRulesExtension, $FLTA_FILES, True)
	if (@error <> 0 or $g_aNotifierRulesFilePaths == 0) then
		SetError(0)
		CreateNotifierRulesFile(GetNotifierRulesFilePath("Default"), _GUI_Option("notify-text"))
		$g_aNotifierRulesFilePaths = _FileListToArray($g_sNotifierRulesDirectory, "*" & $g_sNotifierRulesExtension, $FLTA_FILES, True)
	endif

	if (@error <> 0 or $g_aNotifierRulesFilePaths == 0) then
		MsgBox($MB_ICONERROR, "Error!", "Could not locate/create any notifier rules files inside " & $g_sNotifierRulesDirectory)
		return False
	endif

	local $sComboData = ""
	local $sDefaultSelectedNotifierRules = GetNotifierRulesName($g_aNotifierRulesFilePaths[1])

	for $i = 1 to $g_aNotifierRulesFilePaths[0] step +1
		local $sNotifierRulesName = GetNotifierRulesName($g_aNotifierRulesFilePaths[$i])
		; the data must start with | so it can wipe the old data from the combo control
		$sComboData &= "|" & $sNotifierRulesName

		if ($sSelectedNotifierRulesName == $sNotifierRulesName) then
			$sDefaultSelectedNotifierRules = $sNotifierRulesName
		endif
	next

	GUICtrlSetData($g_idNotifyRulesCombo, $sComboData, $sDefaultSelectedNotifierRules)
	OnChange_NotifyRulesCombo()
endfunc

func OnChange_VolumeSlider()
	SaveGUIVolume()
endfunc

func OnClick_VolumeTest()
	; Hacky way of getting a sound test button's sound index through the Sound # label
	local $sText = GUICtrlRead(@GUI_CtrlId - 1)
	local $asWords = StringSplit($sText, " ")
	local $iIndex = Int($asWords[2])
	NotifierPlaySound($iIndex)
endfunc

Func GoblinAlert($id)
	If CheckGoblinHaveSeenBefore($id) Then
		NotifierPlaySound(6)
		PrintString("There is a goblin nearby.")
	EndIf
EndFunc

Func CheckGoblinHaveSeenBefore($id)
    If _ArraySearch($g_goblinBuffer, $id) <> -1 Then
        Return False
    EndIf

    _ArrayAdd($g_goblinBuffer, $id)
    If UBound($g_goblinBuffer) > 10 Then
        _ArrayDelete($g_goblinBuffer, 0)
    EndIf

    Return True
EndFunc

func Notifier_CreateTab()
	local $iBottomButtonCoords = $g_iGUIHeight - 30
	GUICtrlCreateTabItem("Notifier")
	
	local $iButtonWidth = 60
	local $iControlMargin = 4
	local $iComboWidth = $g_iGUIWidth - 3 * $iButtonWidth - 3 * $iControlMargin - 8

	global $g_idNotifyRulesCombo = GUICtrlCreateCombo("", $iControlMargin, _GUI_LineY(0) + 1, $iComboWidth, 25, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	GUICtrlSetOnEvent(-1, "OnChange_NotifyRulesCombo")
	global $g_idNotifyRulesNew = GUICtrlCreateButton("New", $iComboWidth + 2 * $iControlMargin, _GUI_LineY(0), $iButtonWidth, 25)
	GUICtrlSetOnEvent(-1, "OnClick_NotifyNew")
	global $g_idNotifyRulesRename = GUICtrlCreateButton("Rename", $iComboWidth + $iButtonWidth + 3 * $iControlMargin, _GUI_LineY(0), $iButtonWidth, 25)
	GUICtrlSetOnEvent(-1, "OnClick_NotifyRename")
	global $g_idNotifyRulesDelete = GUICtrlCreateButton("Delete", $iComboWidth + 2 * $iButtonWidth + 4 * $iControlMargin, _GUI_LineY(0), $iButtonWidth, 25)
	GUICtrlSetOnEvent(-1, "OnClick_NotifyDelete")

	global $g_idNotifyEdit = GUICtrlCreateEdit("", 4, _GUI_LineY(2), $g_iGUIWidth - 8, $iBottomButtonCoords - _GUI_LineY(2) - 5)
	GUICtrlSetResizing (-1, $GUI_DOCKAUTO)
	GUICtrlSetLimit(-1, 2147483647)
	
	global $g_idNotifySave = GUICtrlCreateButton("Save", 4 + 0*62, $iBottomButtonCoords, 60, 25)
	GUICtrlSetOnEvent(-1, "OnClick_NotifySave")
	; Add Ctrl + S as hotkey for saving notifier
	local $avAccelKeys[][2] = [ ["^s", $g_idNotifySave] ]
	GUISetAccelerators($avAccelKeys)

	global $g_idNotifyReset = GUICtrlCreateButton("Reset", 4 + 1*62, $iBottomButtonCoords, 60, 25)
	GUICtrlSetOnEvent(-1, "OnClick_NotifyReset")

	global $g_idNotifyTest = GUICtrlCreateButton("Help", 4 + 2*62, $iBottomButtonCoords, 60, 25)
	GUICtrlSetOnEvent(-1, "OnClick_NotifyHelp")

	GUICtrlCreateButton("Default", 4 + 3*62, $iBottomButtonCoords, 60, 25)
	GUICtrlSetOnEvent(-1, "OnClick_NotifyDefault")

	OnClick_NotifyReset()
	RefreshNotifyRulesCombo(_GUI_Option("selectedNotifierRulesName"))
endfunc

func Notifier_CreateSoundsTab()
	GUICtrlCreateTabItem("Sounds")
	for $i = 0 to $g_iNumSounds - 1
		local $iLine = 1 + $i*2

		local $id = GUICtrlCreateSlider(60, _GUI_LineY($iLine), $g_iGUIWidth-128, 25, BitOR($TBS_TOOLTIPS, $TBS_AUTOTICKS, $TBS_ENABLESELRANGE))
		GUICtrlSetLimit(-1, 10, 0)
		GUICtrlSetOnEvent(-1, "OnChange_VolumeSlider")
			_GUICtrlSlider_SetTicFreq($id, 1)

		_GUI_NewTextBasic($iLine, "Sound " & ($i + 1), False)

		GUICtrlCreateButton("Test", $g_iGUIWidth-68, _GUI_LineY($iLine), 60, 25)
		GUICtrlSetOnEvent(-1, "OnClick_VolumeTest")
	
		if ($i == 0) then $g_idVolumeSlider = $id
		_GUI_Volume($i, 5)
	next
	LoadGUIVolume()
endfunc
#EndRegion
