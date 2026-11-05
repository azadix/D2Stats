#include-once
#include <Array.au3>

#Region Notifier globals
global enum $eNotifyFlagsTier, $eNotifyFlagsQuality, $eNotifyFlagsMisc, $eNotifyFlagsSocket, $eNotifyFlagsNoMask, $eNotifyFlagsColour, $eNotifyFlagsSound, $eNotifyFlagsName, $eNotifyFlagsStat, $eNotifyFlagsMatchStats, $eNotifyFlagsMatch, $eNotifyFlagsLast
global $g_asNotifyFlags[$eNotifyFlagsLast][32] = [ _
	[ "0", "1", "2", "3", "4", "sacred", "angelic", "master" ], _
	[ "low", "normal", "superior", "magic", "set", "rare", "unique", "craft", "honor" ], _
	[ "eth" ], _
	[ "socketed0", "socketed1", "socketed2", "socketed3", "socketed4", "socketed5", "socketed6", "socketed_any" ], _
	[], _
	[ "transparent", "white", "red", "lime", "blue", "gold", "grey", "black", "pink", "orange", "yellow", "green", "purple" ], _
	[ "sound_none", "sound1", "sound2", "sound3", "sound4", "sound5", "sound6" ], _
	[ "name" ], _
	[ "stat" ] _
]
global const $g_iSocketMaskAny = 0x7F ; bits 0..6 = socketed0 .. socketed6
global $g_aiFlagsCountPerLine[0]

global const $g_iNumSounds = 6 ; Max 31
global $g_idVolumeSlider

global const $g_sNotifierRulesDirectory = $g_sAppDir & "\NotifierRules"
global const $g_sNotifierRulesExtension = ".rules"
global $g_avNotifyCache[0][4]					; Name, Tier flag, Last line of name, Can have sockets
global $g_avNotifyCompile[0][$eNotifyFlagsLast]	; Flags, Regex
global $g_bNotifyCache = True
global $g_bNotifyCompile = True
global $g_bNotifierChanged = False
global $g_asNotifierErrors[0]
global $g_iNotifierErrorCount = 0

global $g_goblinIds = [2774, 2775, 2776, 2777, 2779, 2780, 2781, 2782, 2783, 2784, 2785, 2786, 2787, 2788, 2789, 2790, 2791, 2792, 2793, 2794, 2795]
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

	local $pBaseAddr, $iNameID, $sName, $asMatch, $sTier, $iTierFlag, $bCanHaveSockets

	redim $g_avNotifyCache[$iItemsTxt][4]

	for $iClass = 0 to $iItemsTxt - 1
		$pBaseAddr = $pItemsTxt + 0x1A8 * $iClass

		$iNameID = _MemoryRead($pBaseAddr + 0xF4, $g_ahD2Handle, "word")
		$sName = RemoteThread($g_pD2InjectGetString, $iNameID)
		$sName = _MemoryRead($sName, $g_ahD2Handle, "wchar[100]")

		$sName = StringReplace($sName, @LF, "|")
		$sName = StripD2ColorCodes($sName)
		$sTier = "0"
		$bCanHaveSockets = _MemoryRead($pBaseAddr + 0x84, $g_ahD2Handle) <> 0

		if ($bCanHaveSockets) then ; Weapon / Armor
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
		$g_avNotifyCache[$iClass][3] = $bCanHaveSockets
	next

	NotifierPushItemNames()
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
		; Reported through the notifier log instead of a modal message box: the
		; rule editor highlights unknown keywords while typing.
		NotifierLogError(StringFormat("Unknown flag '%s' in line: %s", $sFlag, $sLine))
		return False
	endif

	if ($iGroup < $eNotifyFlagsNoMask) then
		if ($iGroup == $eNotifyFlagsSocket and StringLower($sFlag) == "socketed_any") then
			; "socketed_any" matches every socket count.
			$iFlag = $g_iSocketMaskAny
		else
			$iFlag = BitRotate(1, $iFlag, "D")
		endif
		$iFlag = BitOR($iFlag, $avRet[$iGroup])
	endif
	$avRet[$iGroup] = $iFlag

	return $iGroup <> $eNotifyFlagsColour
endfunc

; Collects compile problems so they can be reported once, without blocking the
; UI with a message box for every typo.
func NotifierLogError($sMessage)
	$g_iNotifierErrorCount += 1
	if (UBound($g_asNotifierErrors) >= 20) then return
	_ArrayAdd($g_asNotifierErrors, $sMessage)
endfunc

func NotifierFlushErrors()
	if (UBound($g_asNotifierErrors) == 0) then return

	local $sText = ""
	for $i = 0 to UBound($g_asNotifierErrors) - 1
		$sText &= @CRLF & "- " & $g_asNotifierErrors[$i]
	next
	if ($g_iNotifierErrorCount > UBound($g_asNotifierErrors)) then
		$sText &= @CRLF & StringFormat("- ... and %d more", $g_iNotifierErrorCount - UBound($g_asNotifierErrors))
	endif

	_Debug("NotifierCompile", "Rule problems:" & $sText)

	redim $g_asNotifierErrors[0]
	$g_iNotifierErrorCount = 0
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

; Strips the comment and the surrounding whitespace from a rule line.
func NotifierTrim($sLine)
	return StringStripWS(StringRegExpReplace($sLine, "#.*", ""), BitOR($STR_STRIPLEADING, $STR_STRIPTRAILING, $STR_STRIPSPACES))
endfunc

; Parses one rule line into $avRet.
; $iFlagCount receives the number of flags written on the line itself.
; Returns True when the line produces a rule.
func NotifierParseLine($sLine, byref $avRet, byref $iFlagCount)
	$iFlagCount = 0
	$sLine = NotifierTrim($sLine)
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
				$iFlagCount += 1
			endif

			$sArg = ""
		else
			$sArg &= $sChar
		endif
	next

	if (NotifierCompileFlag($sArg, $avRet, $sLine)) then
		$bHasFlags = True
		$iFlagCount += 1
	endif

	if ($avRet[$eNotifyFlagsMatch] == "") then
		; A line that only carries stat patterns is still a valid rule body.
		if (not $bHasFlags and not IsArray($avRet[$eNotifyFlagsMatchStats])) then return False
		$avRet[$eNotifyFlagsMatch] = ".+"
	endif

	return True
endfunc

#Region Rule groups
; A group shares one set of attributes between the rules inside it:
;
;	["Amulet|Ring$" rare sound2] {
;	  {(2[5-9]|[3-9]\d) to all Attributes}
;	  {[3-9] to All Skills}
;	}
;
; The header is a normal rule without the body: it may carry a name pattern,
; flags and stat patterns. Every line inside the braces becomes one rule that
; inherits the header. A line may be just a stat pattern, just flags or just a
; name - whatever it does not specify comes from the header. Values the rule
; writes itself win over the header's value for the same flag group (tier,
; quality, misc, color, sound, display) and for the name pattern. Stat patterns
; are ANDed, so an item has to match the header patterns and the rule patterns.

; Recognizes a group header line '[flags]' or '[flags] {'.
; Returns 0 - not a header, 1 - header that opens the group, 2 - header that
; expects the opening brace on a following line.
func NotifierGroupHeader($sLine, byref $sHeader, byref $sRest)
	$sHeader = ""
	$sRest = ""

	if (StringLeft($sLine, 1) <> "[") then return 0

	local $iClose = StringInStr($sLine, "]", 1, -1)
	if ($iClose < 2) then return 0

	$sHeader = StringMid($sLine, 2, $iClose - 2)
	$sRest = StringStripWS(StringMid($sLine, $iClose + 1), BitOR($STR_STRIPLEADING, $STR_STRIPTRAILING))

	return $sRest == "{" ? 1 : 2
endfunc

; True when the line closes a group. People write both "}" and "} ]" (closing the
; header bracket again), so accept any mix of braces and brackets.
func NotifierIsGroupClose($sLine)
	$sLine = StringStripWS($sLine, BitOR($STR_STRIPLEADING, $STR_STRIPTRAILING))
	if ($sLine == "" or StringInStr($sLine, "}") == 0) then return False
	return StringRegExp($sLine, "^[\s\}\]]+$") = 1
endfunc

; Applies the header attributes to a parsed rule line. Values the rule writes
; itself win; everything else is inherited from the header.
func NotifierGroupApply(byref $avLine, $avHeader)
	local $i

	for $i = 0 to $eNotifyFlagsMatchStats - 1
		if (Int($avLine[$i]) == 0) then $avLine[$i] = $avHeader[$i]
	next

	; A line without its own name pattern uses the header's.
	if ($avLine[$eNotifyFlagsMatch] == ".+" and $avHeader[$eNotifyFlagsMatch] <> "" And $avHeader[$eNotifyFlagsMatch] <> ".+") then
		$avLine[$eNotifyFlagsMatch] = $avHeader[$eNotifyFlagsMatch]
	endif

	if (IsArray($avHeader[$eNotifyFlagsMatchStats])) then
		if (IsArray($avLine[$eNotifyFlagsMatchStats])) then
			_ArrayConcatenate($avLine[$eNotifyFlagsMatchStats], $avHeader[$eNotifyFlagsMatchStats])
		else
			$avLine[$eNotifyFlagsMatchStats] = $avHeader[$eNotifyFlagsMatchStats]
		endif
	endif
endfunc

; Parses the text between the brackets of a group header.
func NotifierGroupParseHeader($sHeader, byref $avHeader, byref $iHeaderFlags)
	redim $avHeader[0]
	redim $avHeader[$eNotifyFlagsLast]

	if (not NotifierParseLine($sHeader, $avHeader, $iHeaderFlags)) then
		$iHeaderFlags = 0
	endif
endfunc
#EndRegion

func NotifierCompile()
	if (not $g_bNotifyCompile) then return
	$g_bNotifyCompile = False
	$g_bNotifierChanged = True

	redim $g_asNotifierErrors[0]
	$g_iNotifierErrorCount = 0

	local $asLines = StringSplit(_GUI_Option("notify-text"), @LF)
	local $iLines = $asLines[0]

	redim $g_avNotifyCompile[0][0]
	redim $g_avNotifyCompile[$iLines][$eNotifyFlagsLast]

	redim $g_aiFlagsCountPerLine[0]
	redim $g_aiFlagsCountPerLine[$iLines]

	local $avRet[0], $avHeader[0]
	local $iCount = 0, $iFlagsCount = 0, $iHeaderFlags = 0
	local $iGroupDepth = 0, $bPendingGroup = False
	local $iHeaderKind = 0
	local $sHeaderText = "", $sRest = "", $sLine

	for $i = 1 to $iLines
		$sLine = NotifierTrim($asLines[$i])
		if ($sLine == "") then continueloop

		if ($iGroupDepth > 0) then
			if (NotifierIsGroupClose($sLine)) then
				$iGroupDepth -= 1
				if ($iGroupDepth == 0) then
					redim $avHeader[$eNotifyFlagsLast]
					$iHeaderFlags = 0
				endif
				continueloop
			endif

			; Nested groups are not supported: keep the brace bookkeeping so the
			; outer group still closes on the right line, but drop the header.
			$iHeaderKind = ($sLine == "{") ? 1 : NotifierGroupHeader($sLine, $sHeaderText, $sRest)
			if ($iHeaderKind) then
				NotifierLogError(StringFormat("Groups cannot be nested (line %d). The inner header is ignored.", $i))
				if ($iHeaderKind == 1) then $iGroupDepth += 1
				continueloop
			endif

			if (NotifierParseLine($sLine, $avRet, $iFlagsCount)) then
				NotifierGroupApply($avRet, $avHeader)

				$g_aiFlagsCountPerLine[$iCount] = $iFlagsCount + $iHeaderFlags
				for $j = 0 to $eNotifyFlagsLast - 1
					$g_avNotifyCompile[$iCount][$j] = $avRet[$j]
				next
				$iCount += 1
			endif
			continueloop
		endif

		if ($bPendingGroup) then
			if ($sLine == "{") then
				$bPendingGroup = False
				$iGroupDepth = 1
				continueloop
			endif

			NotifierLogError(StringFormat("Group header '[%s]' has no body (line %d).", $sHeaderText, $i))
			$bPendingGroup = False
		endif

		$iHeaderKind = NotifierGroupHeader($sLine, $sHeaderText, $sRest)
		if ($iHeaderKind) then
			NotifierGroupParseHeader($sHeaderText, $avHeader, $iHeaderFlags)

			if ($sRest <> "" and $sRest <> "{") then
				NotifierLogError(StringFormat("Unexpected '%s' after the group header '[%s]'.", $sRest, $sHeaderText))
			endif

			$iGroupDepth = $iHeaderKind == 1 ? 1 : 0
			$bPendingGroup = $iHeaderKind == 2
			continueloop
		endif

		if (NotifierParseLine($sLine, $avRet, $iFlagsCount)) then
			$g_aiFlagsCountPerLine[$iCount] = $iFlagsCount
			for $j = 0 to $eNotifyFlagsLast - 1
				$g_avNotifyCompile[$iCount][$j] = $avRet[$j]
			next
			$iCount += 1
		endif
	next

	if ($iGroupDepth > 0 or $bPendingGroup) then
		NotifierLogError("The notifier rules end inside a group. Add the closing '}'.")
	endif

	redim $g_aiFlagsCountPerLine[$iCount]
	redim $g_avNotifyCompile[$iCount][$eNotifyFlagsLast]

	NotifierFlushErrors()
endfunc

func NotifierHelp($sInput)
	NotifierCache()

	local $iItems = UBound($g_avNotifyCache)
	local $asMatches[$iItems][2]
	local $iCount = 0
	local $iFlagsCount = 0

	local $avRet[0]

	redim $g_asNotifierErrors[0]
	$g_iNotifierErrorCount = 0

	if (NotifierParseLine($sInput, $avRet, $iFlagsCount)) then
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
	NotifierFlushErrors()
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
	local $iFlagsTier, $iFlagsQuality, $iFlagsMisc, $iFlagsSocket, $iFlagsColour, $iFlagsSound, $iFlagsDisplayName, $iFlagsDisplayStat
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
						$iFlagsSocket = $g_avNotifyCompile[$j][$eNotifyFlagsSocket]
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
						if ($iFlagsSocket) then
							local $iSocketCount = GetUnitStat($pCurrentUnit, 0xC2)
							if ($iSocketCount < 0 or $iSocketCount > 6) then $iSocketCount = 0
							if (not BitAND($iFlagsSocket, BitRotate(1, $iSocketCount, "D"))) then continueloop
						endif

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
						$oItemFlags.add('$bCanHaveSockets', $g_avNotifyCache[$iClass][3])
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
		local $bCanHaveSockets = $oFlags.item('$bCanHaveSockets')
		local $iQuality = $oFlags.item('$iQuality')
		local $bShowItemName = $oFlags.item('$bShowItemName')
		local $iLvl = $oFlags.item('$iLvl')

		local $bIsMatchByStats = False

		local $asItem = GetItemName($pCurrentUnit)
		local $asItemName = UBound($asItem) == 3 ? $asItem[2] : ""
        local $asItemType = (IsArray($asItem) and UBound($asItem) >= 2) ? $asItem[1] : ""
        local $asItemStats = ""
		local $iQualityColor = $ePrintWhite
		if ($iQuality >= 0 and $iQuality < UBound($g_iQualityColor)) then
			$iQualityColor = $g_iQualityColor[$iQuality]
		endif
		; No notifier color: use the in-game ÿc code (name, then type). Consumables
		; and runes are both "not equipment" but white vs orange in game.
		local $iItemColor = GetD2TextPrintColor($asItemName, GetD2TextPrintColor($asItemType, $iQualityColor))
        local $sPreName = ""
		
        ; collect a reversed 2d array of stats and color
        ; to display as notifications per line
        if (UBound($asStatGroups) or $bDisplayItemStats) then
			local $sGetItemStats = GetItemStats($pCurrentUnit)
			; Game formatter often omits sockets; keep the line for {socketed} filters and the stat flag.
			; Skip classes that can never socket (rings, amulets, gems, consumables).
			if $bCanHaveSockets and StringInStr($sGetItemStats, "Socketed") == 0 then
				$sGetItemStats = "Socketed (" & GetUnitStat($pCurrentUnit, 0xC2) & ")" & @CRLF & $sGetItemStats
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

		$asItemName = StripD2ColorCodes($asItemName)
		$asItemType = StripD2ColorCodes($asItemType)

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

func GetD2StatPrintColor($sStat)
	return GetD2TextPrintColor($sStat, $ePrintBlue)
endfunc

func HighlightStats($sGetItemStats, $asStatGroups, byref $bIsMatchByStats)
	local $asStats = StringSplit($sGetItemStats, @LF)
	local $aPlainStats[$asStats[0]][3]
	local $aColoredStats[$asStats[0]][3]
	local $iMatchCounter = 0

    for $k = 1 to $asStats[0]
        local $sStat = $asStats[$k]
		local $sStatText = StripD2ColorCodes($sStat)
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
; Keyword metadata for the rule editor, as "category:keyword" entries joined with |.
; The category tells the editor how to color the keyword and how to group the
; completion popup.
func NotifierKeywordList()
	local $asCategory[$eNotifyFlagsLast]
	$asCategory[$eNotifyFlagsTier] = "tier"
	$asCategory[$eNotifyFlagsQuality] = "quality"
	$asCategory[$eNotifyFlagsMisc] = "misc"
	$asCategory[$eNotifyFlagsSocket] = "socket"
	$asCategory[$eNotifyFlagsColour] = "color"
	$asCategory[$eNotifyFlagsSound] = "sound"
	$asCategory[$eNotifyFlagsName] = "display"
	$asCategory[$eNotifyFlagsStat] = "display"

	local $sList = "", $sWord
	local $i, $j

	for $i = 0 to $eNotifyFlagsLast - 1
		if ($asCategory[$i] == "") then continueloop

		for $j = 0 to UBound($g_asNotifyFlags, $UBOUND_COLUMNS) - 1
			$sWord = $g_asNotifyFlags[$i][$j]
			if ($sWord == "") then exitloop
			$sList &= (StringLen($sList) ? "|" : "") & $asCategory[$i] & ":" & $sWord
		next
	next

	return $sList
endfunc

func NotifierPushKeywords()
	if ($g_hUiDll == -1) then return
	Ui_SetNotifierKeywords(NotifierKeywordList())
endfunc

; Base type / unique name list used by the editor's quoted pattern completion.
; Only available after the in-game item cache has been read.
func NotifierPushItemNames()
	if ($g_hUiDll == -1) then return
	if (UBound($g_avNotifyCache) == 0) then return

	local $oSeen = ObjCreate("Scripting.Dictionary")
	local $sList = "", $sPart, $asParts
	local $i, $j

	for $i = 0 to UBound($g_avNotifyCache) - 1
		$asParts = StringSplit($g_avNotifyCache[$i][0], "|")

		for $j = 1 to $asParts[0]
			$sPart = StringStripWS($asParts[$j], BitOR($STR_STRIPLEADING, $STR_STRIPTRAILING))
			if (StringLen($sPart) < 2) then continueloop
			if ($oSeen.Exists(StringLower($sPart))) then continueloop

			$oSeen.Add(StringLower($sPart), 1)
			$sList &= (StringLen($sList) ? "|" : "") & $sPart
		next
	next

	Ui_AddNotifierItemNames($sList)
endfunc

; Quoted item patterns harvested from every rule file. Names that already live in
; the user's filters (unique names included) can be completed before the game
; cache is built, and without typing the whole name again.
func NotifierPushRuleNames()
	if ($g_hUiDll == -1) then return

	local $aFiles = _FileListToArray($g_sNotifierRulesDirectory, "*" & $g_sNotifierRulesExtension, $FLTA_FILES, True)
	if (@error <> 0 or not IsArray($aFiles)) then return

	local $oSeen = ObjCreate("Scripting.Dictionary")
	local $sList = "", $sText, $sName, $sPart, $asMatches, $asParts
	local $i, $j, $k

	for $i = 1 to $aFiles[0]
		$sText = FileRead($aFiles[$i])
		if (@error) then continueloop

		$asMatches = StringRegExp($sText, '"((?:\\.|[^"\\])*)"', $STR_REGEXPARRAYGLOBALMATCH)
		if (@error) then continueloop

		for $j = 0 to UBound($asMatches) - 1
			; Names inside an alternation ("^(A|B|C)$") are separate suggestions.
			$asParts = StringSplit($asMatches[$j], "|", 2)
			if (@error) then
				local $aSingle[1] = [$asMatches[$j]]
				$asParts = $aSingle
			endif

			for $k = 0 to UBound($asParts) - 1
				$sName = StringReplace($asParts[$k], '\"', '"')
				$sName = StringRegExpReplace($sName, "^[\^\(]+|[\$\)]+$", "")
				$sName = StringStripWS($sName, BitOR($STR_STRIPLEADING, $STR_STRIPTRAILING))
				if (StringLen($sName) < 2) then continueloop

				; Only plain names make useful completions, regex fragments do not.
				if (StringRegExp($sName, '[\\\[\]\(\)\|\^\$\*\+\?\{\}]')) then continueloop
				if ($oSeen.Exists(StringLower($sName))) then continueloop

				$oSeen.Add(StringLower($sName), 1)
				$sList &= (StringLen($sList) ? "|" : "") & $sName
			next
		next
	next

	if ($sList <> "") then Ui_AddNotifierItemNames($sList)
endfunc

func OnChange_NotifyRulesCombo()
	if (Ui_IsNotifierDirty()) then
		local $iButton = MsgBox(BitOR($MB_ICONQUESTION, $MB_YESNO), "D2Stats", "There are unsaved changes in the current notifier rules. Save?", 0, $g_hGUI)
		if ($iButton == $IDYES) then
			SaveCurrentNotifierRulesToFile(_GUI_Option("selectedNotifierRulesName"))
		endif
	endif
	
	local $sSelectedNofitierRules = Ui_GetNotifyRulesSelected()
	
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

	Ui_SetNotifierText($sNotifierRules)

	_GUI_Option("selectedNotifierRulesName", $sSelectedNofitierRules)
	_GUI_Option("notify-text", $sNotifierRules)
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
	local $sOldNotifierRulesName = Ui_GetNotifyRulesSelected()
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
	local $sSelectedNofitierRules = Ui_GetNotifyRulesSelected()

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
	SaveCurrentNotifierRulesToFile(Ui_GetNotifyRulesSelected())
endfunc

func OnClick_NotifyReset()
	Ui_SetNotifierText(_GUI_Option("notify-text"))
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
		'> socketed_any, socketed0 .. socketed6 - Socket count of the item.', _
		'   socketed_any matches any count and overrides a socket filter from a group.', _
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
        'This would match every sacred item with 0 or 6 sockets', _
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
		'Groups:', _
		'A group is a rule without a body. Everything between [ and ] is shared:', _
		'  ["Amulet|Ring$" rare sound2] {', _
		'    {(2[5-9]|[3-9]\d) to all Attributes}', _
		'    {[3-9] to All Skills}', _
		'  }', _
		'Both lines become rare amulet/ring rules with sound 2. Each line inside', _
		'the block inherits whatever it does not write itself (name, flags and stat', _
		'patterns); stat patterns are added to the ones in the header.', _
		'Flags written on the line win over the header, eg. "normal red" above.', _
		'The block may be closed with "}" or with "} ]".', _
		'', _
		'Editor:', _
		'Ctrl+Space opens the autocomplete list (Tab or Enter inserts, Esc closes).', _
		'Hover an underlined word to see what is wrong with it.', _
		'Ctrl+S saves, Ctrl+Z / Ctrl+Y undo and redo, Tab indents the selection.', _
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
	Ui_SetNotifierEdit($g_sNotifyTextDefault)
endfunc

func OnChange_NotifyEdit()
endfunc

func GetNotifierRulesName($sNotifierRulesFilePath)
	return StringReplace(StringMid($sNotifierRulesFilePath, StringInStr($sNotifierRulesFilePath, "\", 2, -1) + 1), $g_sNotifierRulesExtension, "", -1)
endfunc

func GetNotifierRulesFilePath($sNotifierRulesName)
	return $g_sNotifierRulesDirectory & "\" & $sNotifierRulesName & $g_sNotifierRulesExtension
endfunc

func SaveCurrentNotifierRulesToFile($sNotifierRulesName)
	local $sNotifyEditContents = Ui_GetNotifierText()
	CreateNotifierRulesFile(GetNotifierRulesFilePath($sNotifierRulesName), $sNotifyEditContents)
	_GUI_Option("selectedNotifierRulesName", $sNotifierRulesName)
	_GUI_Option("notify-text", $sNotifyEditContents)
	Ui_SetNotifierText($sNotifyEditContents)
	NotifierPushRuleNames()
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

	Ui_SetNotifyRules(StringTrimLeft($sComboData, 1), $sDefaultSelectedNotifierRules)
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
	NotifierPushKeywords()
	NotifierPushRuleNames()
	RefreshNotifyRulesCombo(_GUI_Option("selectedNotifierRulesName"))
endfunc

func Notifier_CreateSoundsTab()
	local $i
	for $i = 0 to $g_iNumSounds - 1
		_GUI_Volume($i, 5)
	next
	LoadGUIVolume()
endfunc
#EndRegion
