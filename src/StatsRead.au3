#include-once

#Region StatsRead globals
global $g_aiStatsCache[2][$g_iNumStats]
global $g_aiStatsCacheCopy[2][$g_iNumStats]
#EndRegion

#Region Stat reading
func GetUnitToRead()
	local $bMercenary = BitAND(GUICtrlRead($g_idReadMercenary), $GUI_CHECKED) ? True : False
	return $g_hD2Client + ($bMercenary ? 0x10A80C : 0x11BBFC)
endfunc

func UpdateStatValueMem($iVector)
	if ($iVector <> 0 and $iVector <> 1) then _Debug("UpdateStatValueMem", "Invalid $iVector value.")

	local $pUnitAddress = GetUnitToRead()

	local $aiOffsets[3] = [0, 0x5C, ($iVector+1)*0x24]
	local $pStatList = _MemoryPointerRead($pUnitAddress, $g_ahD2Handle, $aiOffsets)

	$aiOffsets[2] += 0x4
	local $iStatCount = _MemoryPointerRead($pUnitAddress, $g_ahD2Handle, $aiOffsets, "word") - 1

	local $tagStat = "word wSubIndex;word wStatIndex;int dwStatValue;", $tagStatsAll
	for $i = 0 to $iStatCount
		$tagStatsAll &= $tagStat
	next

	local $tStats = DllStructCreate($tagStatsAll)
	_WinAPI_ReadProcessMemory($g_ahD2Handle[1], $pStatList, DllStructGetPtr($tStats), DllStructGetSize($tStats), 0)

	local $iStatIndex, $iStatValue

	for $i = 0 to $iStatCount
		$iStatIndex = DllStructGetData($tStats, 2 + (3 * $i))
		if ($iStatIndex >= $g_iNumStats) then
			continueloop ; Should never happen
		endif

		$iStatValue = DllStructGetData($tStats, 3 + (3 * $i))
		switch $iStatIndex
			case 6 to 11
				$g_aiStatsCache[$iVector][$iStatIndex] += $iStatValue / 256
			case else
				$g_aiStatsCache[$iVector][$iStatIndex] += $iStatValue
		endswitch
	next
endfunc

func UpdateStatValues()
	for $i = 0 to $g_iNumStats - 1
		$g_aiStatsCache[0][$i] = 0
		$g_aiStatsCache[1][$i] = 0
	next

	if (IsIngame()) then
		UpdateStatValueMem(0)
		UpdateStatValueMem(1)
		FixStats()
		CalculateWeaponDamage()

		; Poison damage to damage/second
		$g_aiStatsCache[1][57] *= (25/256)
		$g_aiStatsCache[1][58] *= (25/256)

		; Bonus stats from items; str, dex, vit, ene
		local $aiStats[] = [0, 359, 2, 360, 3, 362, 1, 361]
		local $iBase, $iTotal, $iPercent

		for $i = 0 to 3
			$iBase = GetStatValue($aiStats[$i*2 + 0])
			$iTotal = GetStatValue($aiStats[$i*2 + 0], 1)
			$iPercent = GetStatValue($aiStats[$i*2 + 1])

			$g_aiStatsCache[1][240+$i] = Ceiling($iTotal / (1 + $iPercent / 100) - $iBase)
		next

		; Factor cap
		local $iFactor = Floor((GetStatValue(278) * GetStatValue(0, 1) + GetStatValue(485) * GetStatValue(1, 1)) / 3e6 * 100)
		$g_aiStatsCache[1][244] = $iFactor > 100 ? 100 : $iFactor
	endif
endfunc

func GetUnitWeapon($pUnit)
	local $pInventory = _MemoryRead($pUnit + 0x60, $g_ahD2Handle)

	local $pItem = _MemoryRead($pInventory + 0x0C, $g_ahD2Handle)
	local $iWeaponID = _MemoryRead($pInventory + 0x1C, $g_ahD2Handle)

	local $pItemData, $pWeapon = 0

	while $pItem
		if ($iWeaponID == _MemoryRead($pItem + 0x0C, $g_ahD2Handle)) then
			$pWeapon = $pItem
			exitloop
		endif

		$pItemData = _MemoryRead($pItem + 0x14, $g_ahD2Handle)
		$pItem = _MemoryRead($pItemData + 0x64, $g_ahD2Handle)
	wend

	return $pWeapon
endfunc

func CalculateWeaponDamage()
	local $pUnitAddress = GetUnitToRead()
	local $pUnit = _MemoryRead($pUnitAddress, $g_ahD2Handle)

	local $pWeapon = GetUnitWeapon($pUnit)
	if (not $pWeapon) then return

	local $iWeaponClass = _MemoryRead($pWeapon + 0x04, $g_ahD2Handle)
	local $pItemsTxt = _MemoryRead($g_hD2Common + 0x9FB98, $g_ahD2Handle)
	local $pBaseAddr = $pItemsTxt + 0x1A8 * $iWeaponClass

	local $iStrBonus = _MemoryRead($pBaseAddr + 0x106, $g_ahD2Handle, "word")
	local $iDexBonus = _MemoryRead($pBaseAddr + 0x108, $g_ahD2Handle, "word")

	local $bIs2H = _MemoryRead($pBaseAddr + 0x11C, $g_ahD2Handle, "byte")
	local $bIs1H = $bIs2H ? _MemoryRead($pBaseAddr + 0x13D, $g_ahD2Handle, "byte") : 1

	local $iMinDamage1 = 0, $iMinDamage2 = 0, $iMaxDamage1 = 0, $iMaxDamage2 = 0

	if ($bIs2H) then
		; 2h weapon
		$iMinDamage2 = GetStatValue(23)
		$iMaxDamage2 = GetStatValue(24)
	endif

	if ($bIs1H) then
		; 1h weapon
		$iMinDamage1 = GetStatValue(21)
		$iMaxDamage1 = GetStatValue(22)

		if (not $bIs2H) then
			; thrown weapon
			$iMinDamage2 = GetStatValue(159)
			$iMaxDamage2 = GetStatValue(160)
		endif
	endif

	if ($iMaxDamage1 < $iMinDamage1) then $iMaxDamage1 = $iMinDamage1 + 1
	if ($iMaxDamage2 < $iMinDamage2) then $iMaxDamage2 = $iMinDamage2 + 1

	local $iStatBonus = Floor((GetStatValue(0, 1) * $iStrBonus + GetStatValue(2, 1) * $iDexBonus) / 100) - 1
	local $iEWD = GetStatValue(25) + GetStatValue(343) ; global EWD, itemtype-specific EWD
	local $fTotalMult = 1 + $iEWD / 100 + $iStatBonus / 100

	local $aiDamage[4] = [$iMinDamage1, $iMaxDamage1, $iMinDamage2, $iMaxDamage2]
	for $i = 0 to 3
		$g_aiStatsCache[1][21+$i] = Floor($aiDamage[$i] * $fTotalMult)
	next
endfunc

func FixStats() ; This game is stupid
	for $i = 67 to 69 ; Velocities
		$g_aiStatsCache[1][$i] = 0
	next
	$g_aiStatsCache[1][343] = 0 ; itemtype-specific EWD (Elfin Weapons, Shadow Dancer)
	$g_aiStatsCache[1][74] = $g_aiStatsCache[1][74] / 10 ;Life regen
	
	local $pSkillsTxt = _MemoryRead($g_pD2sgpt + 0xB98, $g_ahD2Handle)
	local $iSkillID, $pStats, $iStatCount, $pSkill, $iStatIndex, $iStatValue, $iOwnerType, $iStateID

	local $pItemTypesTxt = _MemoryRead($g_pD2sgpt + 0xBF8, $g_ahD2Handle)
	local $pItemsTxt = _MemoryRead($g_hD2Common + 0x9FB98, $g_ahD2Handle)
	local $iWeaponClass, $pWeapon, $iWeaponType, $iItemType

	local $pUnitAddress = GetUnitToRead()
	local $pUnit = _MemoryRead($pUnitAddress, $g_ahD2Handle)

	local $aiOffsets[3] = [0, 0x5C, 0x3C]
	local $pStatList = _MemoryPointerRead($pUnitAddress, $g_ahD2Handle, $aiOffsets)

	while $pStatList
		$iOwnerType = _MemoryRead($pStatList + 0x08, $g_ahD2Handle)
		$pStats = _MemoryRead($pStatList + 0x24, $g_ahD2Handle)
		$iStatCount = _MemoryRead($pStatList + 0x28, $g_ahD2Handle, "word")
		$pStatList = _MemoryRead($pStatList + 0x2C, $g_ahD2Handle)

		$iSkillID = 0

		for $i = 0 to $iStatCount - 1
			$iStatIndex = _MemoryRead($pStats + $i*8 + 2, $g_ahD2Handle, "word")
			$iStatValue = _MemoryRead($pStats + $i*8 + 4, $g_ahD2Handle, "int")

			if ($iStatIndex == 350 and $iStatValue <> 511) then $iSkillID = $iStatValue
			if ($iOwnerType == 4 and $iStatIndex == 67) then $g_aiStatsCache[1][$iStatIndex] += $iStatValue ; Armor FRW penalty
		next

		if ($iOwnerType == 4) then continueloop

		$iStateID = _MemoryRead($pStatList + 0x14, $g_ahD2Handle)
		switch $iStateID
			case 195 ; Dark Power, Tome of Possession aura
				$iSkillID = 687 ; Dark Power
		endswitch

		local $bHasVelocity[3] = [False,False,False]
		if ($iSkillID) then ; Game doesn't even bother setting the skill id for some skills, so we'll just have to hope the state is correct or the stat list isn't lying...
			$pSkill = $pSkillsTxt + 0x23C*$iSkillID

			for $i = 0 to 4
				$iStatIndex = _MemoryRead($pSkill + 0x98 + $i*2, $g_ahD2Handle, "word")

				switch $iStatIndex
					case 67 to 69
						$bHasVelocity[$iStatIndex-67] = True
				endswitch
			next

			for $i = 0 to 5
				$iStatIndex = _MemoryRead($pSkill + 0x54 + $i*2, $g_ahD2Handle, "word")

				switch $iStatIndex
					case 67 to 69
						$bHasVelocity[$iStatIndex-67] = True
				endswitch
			next
		endif

		for $i = 0 to $iStatCount - 1
			$iStatIndex = _MemoryRead($pStats + $i*8 + 2, $g_ahD2Handle, "word")
			$iStatValue = _MemoryRead($pStats + $i*8 + 4, $g_ahD2Handle, "int")

			switch $iStatIndex
				case 67 to 69
					if (not $iSkillID or $bHasVelocity[$iStatIndex-67]) then $g_aiStatsCache[1][$iStatIndex] += $iStatValue
				case 343
					$iItemType = _MemoryRead($pStats + $i*8 + 0, $g_ahD2Handle, "word")
					$pWeapon = GetUnitWeapon($pUnit)
					if (not $pWeapon or not $iItemType) then continueloop

					$iWeaponClass = _MemoryRead($pWeapon + 0x04, $g_ahD2Handle)
					$iWeaponType = _MemoryRead($pItemsTxt + 0x1A8 * $iWeaponClass + 0x11E, $g_ahD2Handle, "word")

					local $bApply = False
					local $aiItemTypes[256] = [1, $iWeaponType]
					local $iEquiv
					local $j = 1

					while ($j <= $aiItemTypes[0])
						if ($aiItemTypes[$j] == $iItemType) then
							$bApply = True
							exitloop
						endif

						for $k = 0 to 1
							$iEquiv = _MemoryRead($pItemTypesTxt + 0xE4 * $aiItemTypes[$j] + 0x04 + $k*2, $g_ahD2Handle, "word")
							if ($iEquiv) then
								$aiItemTypes[0] += 1
								$aiItemTypes[ $aiItemTypes[0] ] = $iEquiv
							endif
						next

						$j += 1
					wend

					if ($bApply) then $g_aiStatsCache[1][343] += $iStatValue
			endswitch
		next
	wend
endfunc

func GetStatValue($iStatID, $iVector = default)
	if ($iVector == default) then $iVector = $iStatID < 4 ? 0 : 1
	local $iStatValue = $g_aiStatsCache[$iVector][$iStatID]
	return Floor($iStatValue ? $iStatValue : 0)
endfunc

func IsProcessPtr($p)
	return ($p >= 0x10000 and $p <= 0x7FFFFFFF)
endfunc

func MemAscii($p, $iLen)
	if (not IsProcessPtr($p) or not IsArray($g_ahD2Handle)) then return ""
	local $s = _MemoryRead($p, $g_ahD2Handle, "char[" & $iLen & "]")
	local $sOut = "", $i, $sChar, $iAsc
	for $i = 1 to StringLen($s)
		$sChar = StringMid($s, $i, 1)
		$iAsc = Asc($sChar)
		if ($iAsc == 0) then exitloop
		if ($iAsc >= 32 and $iAsc <= 126) then
			$sOut &= $sChar
		else
			$sOut &= "."
		endif
	next
	return $sOut
endfunc

func IsPlausibleCof($s)
	if (StringLen($s) < 6 or StringLen($s) > 8) then return False
	return StringRegExp($s, "^[A-Za-z0-9~]{2}[A-Z]{2}[A-Z0-9]{3,4}$") ? True : False
endfunc

func GetUnitCofString($pUnit)
	if (not $pUnit or not IsArray($g_ahD2Handle)) then return ""
	local $aiOff[2] = [0x50, 0x54]
	local $n, $p, $p2, $s, $iAdd, $aiAdd[3] = [0, 4, 8]
	for $n = 0 to 1
		$p = _MemoryRead($pUnit + $aiOff[$n], $g_ahD2Handle)
		if (not IsProcessPtr($p)) then continueloop
		for $iAdd = 0 to 2
			$s = StringUpper(MemAscii($p + $aiAdd[$iAdd], 8))
			if (IsPlausibleCof($s)) then return $s
		next
		$p2 = _MemoryRead($p, $g_ahD2Handle)
		if (IsProcessPtr($p2)) then
			$s = StringUpper(MemAscii($p2, 8))
			if (IsPlausibleCof($s)) then return $s
		endif
	next
	return ""
endfunc

func GetUnitMorphToken($pUnit)
	local $sCof = GetUnitCofString($pUnit)
	if ($sCof == "") then return ""
	return StringLeft($sCof, 2)
endfunc

func MorphNameFromToken($sTok)
	if ($sTok == "") then return ""
	local $j
	for $j = 0 to UBound($g_avScMorphs) - 1
		if ($g_avScMorphs[$j][1] == $sTok) then return $g_avScMorphs[$j][0]
	next
	return ""
endfunc

; Extra StatList nodes at StatListEx+0x3C. Read state from the current node, then follow +0x2C.
; Columns: state, skill, owner type.
func GetUnitExtraStatLists()
	if (not IsIngame() or not IsArray($g_ahD2Handle)) then return 0

	local $pUnitAddress = GetUnitToRead()
	local $aiOffsets[3] = [0, 0x5C, 0x3C]
	local $pStatList = _MemoryPointerRead($pUnitAddress, $g_ahD2Handle, $aiOffsets)
	if (not $pStatList) then return 0

	local $avList[1][3]
	local $iCount = 0, $iGuard = 0
	local $iOwnerType, $iStateID, $iSkillID, $pStats, $iStatCount, $pNext, $i, $iStatIndex, $iStatValue
	local $sSeen = "|"

	while $pStatList
		$iGuard += 1
		if ($iGuard > 256) then exitloop
		if (StringInStr($sSeen, "|" & $pStatList & "|")) then exitloop
		$sSeen &= $pStatList & "|"

		$iOwnerType = _MemoryRead($pStatList + 0x08, $g_ahD2Handle)
		$iStateID = _MemoryRead($pStatList + 0x14, $g_ahD2Handle)
		$pStats = _MemoryRead($pStatList + 0x24, $g_ahD2Handle)
		$iStatCount = _MemoryRead($pStatList + 0x28, $g_ahD2Handle, "word")
		$pNext = _MemoryRead($pStatList + 0x2C, $g_ahD2Handle)

		; Owner 4 = item lists. State 0 = run-start extra list, not a form.
		if ($iOwnerType <> 4 and $iStateID > 0) then
			$iSkillID = 0
			if ($pStats and $iStatCount > 0 and $iStatCount < 512) then
				for $i = 0 to $iStatCount - 1
					$iStatIndex = _MemoryRead($pStats + $i * 8 + 2, $g_ahD2Handle, "word")
					$iStatValue = _MemoryRead($pStats + $i * 8 + 4, $g_ahD2Handle, "int")
					if ($iStatIndex == 350 and $iStatValue <> 511) then
						$iSkillID = $iStatValue
						exitloop
					endif
				next
			endif
			$iCount += 1
			ReDim $avList[$iCount][3]
			$avList[$iCount - 1][0] = $iStateID
			$avList[$iCount - 1][1] = $iSkillID
			$avList[$iCount - 1][2] = $iOwnerType
		endif

		if (not $pNext or $pNext == $pStatList) then exitloop
		$pStatList = $pNext
	wend

	if ($iCount == 0) then return 0
	return $avList
endfunc

func GetSkillTxtName($iSkillID)
	if ($iSkillID <= 0 or $iSkillID == 511) then return ""
	if (not $g_pD2sgpt or not IsArray($g_ahD2Handle)) then return ""

	local $pSkillsTxt = _MemoryRead($g_pD2sgpt + 0xB98, $g_ahD2Handle)
	if (not $pSkillsTxt) then return ""

	local $iCount = _MemoryRead($g_pD2sgpt + 0xB9C, $g_ahD2Handle)
	if ($iCount < 1 or $iCount > 8192) then $iCount = 8192
	if ($iSkillID >= $iCount) then return ""

	local $pRecord = $pSkillsTxt + 0x23C * $iSkillID
	local $sName = StringStripWS(_MemoryRead($pRecord, $g_ahD2Handle, "char[32]"), 3)
	if (IsPlausibleSkillName($sName)) then return $sName

	local $pName = _MemoryRead($pRecord, $g_ahD2Handle)
	if ($pName >= 0x10000 and $pName <= 0x7FFFFFFF) then
		$sName = StringStripWS(_MemoryRead($pName, $g_ahD2Handle, "char[32]"), 3)
		if (IsPlausibleSkillName($sName)) then return $sName
	endif
	return ""
endfunc

func IsPlausibleSkillName($sName)
	if ($sName == "" or StringLen($sName) < 3 or StringLen($sName) > 32) then return False
	return StringRegExp($sName, "^[A-Za-z][A-Za-z0-9_ ]*$") ? True : False
endfunc

func MorphSkillNameMatches($sMorph, $sSkill, $bLoose = False)
	if ($sMorph == "" or $sSkill == "") then return False
	if (StringCompare($sMorph, $sSkill, $STR_NOCASESENSEBASIC) == 0) then return True
	local $sA = StringStripWS(StringReplace($sMorph, " ", ""), 8)
	local $sB = StringStripWS(StringReplace($sSkill, " ", ""), 8)
	if (StringCompare($sA, $sB, $STR_NOCASESENSEBASIC) == 0) then return True
	if ($bLoose) then return StringInStr($sSkill, $sMorph, $STR_NOCASESENSEBASIC) <> 0
	return False
endfunc

func CacheMorphSkillIds()
	if ($g_bScMorphSkillsCached) then return
	$g_bScMorphSkillsCached = True
	if (not $g_pD2sgpt or not IsArray($g_ahD2Handle)) then return

	local $pSkillsTxt = _MemoryRead($g_pD2sgpt + 0xB98, $g_ahD2Handle)
	local $iCount = _MemoryRead($g_pD2sgpt + 0xB9C, $g_ahD2Handle)
	if (not $pSkillsTxt or $iCount < 1 or $iCount > 8192) then return

	local $i, $j, $sName, $bNeed
	$bNeed = False
	for $j = 0 to UBound($g_avScMorphs) - 1
		if ($g_avScMorphs[$j][4] < 0) then $bNeed = True
	next
	if (not $bNeed) then return

	for $i = 1 to $iCount - 1
		$sName = GetSkillTxtName($i)
		if ($sName == "") then continueloop
		for $j = 0 to UBound($g_avScMorphs) - 1
			if ($g_avScMorphs[$j][4] >= 0) then continueloop
			if (MorphSkillNameMatches($g_avScMorphs[$j][0], $sName)) then $g_avScMorphs[$j][4] = $i
		next
	next
endfunc

func DetectUnitMorph()
	CacheMorphSkillIds()
	local $pUnit = _MemoryRead(GetUnitToRead(), $g_ahD2Handle)
	local $avList = GetUnitExtraStatLists()
	local $sTok = GetUnitMorphToken($pUnit)

	local $sName = MorphNameFromToken($sTok)
	if ($sName <> "") then return $sName

	local $i, $j, $iState, $iSkill
	if (not IsArray($avList)) then return ""

	for $i = 0 to UBound($avList) - 1
		$iState = $avList[$i][0]
		for $j = 0 to UBound($g_avScMorphs) - 1
			if ($g_avScMorphs[$j][3] >= 0 and $g_avScMorphs[$j][3] == $iState) then return $g_avScMorphs[$j][0]
		next
	next

	for $i = 0 to UBound($avList) - 1
		$iSkill = $avList[$i][1]
		if ($iSkill <= 0) then continueloop
		for $j = 0 to UBound($g_avScMorphs) - 1
			if ($g_avScMorphs[$j][4] >= 0 and $g_avScMorphs[$j][4] == $iSkill) then
				if ($g_avScMorphs[$j][3] < 0 and $avList[$i][0] > 0) then $g_avScMorphs[$j][3] = $avList[$i][0]
				return $g_avScMorphs[$j][0]
			endif
		next
	next

	for $i = 0 to UBound($avList) - 1
		$iSkill = $avList[$i][1]
		$sName = GetSkillTxtName($iSkill)
		if ($sName == "") then continueloop
		for $j = 0 to UBound($g_avScMorphs) - 1
			if (MorphSkillNameMatches($g_avScMorphs[$j][0], $sName, True)) then
				$g_avScMorphs[$j][4] = $iSkill
				if ($g_avScMorphs[$j][3] < 0 and $avList[$i][0] > 0) then $g_avScMorphs[$j][3] = $avList[$i][0]
				return $g_avScMorphs[$j][0]
			endif
		next
	next
	return ""
endfunc
#EndRegion

#Region Stats
func StatsRead_CreateTabs()
	GUICtrlCreateTabItem("Basic")
	_GUI_GroupFirst()
	_GUI_NewText(00, "Character data")
	_GUI_NewItem(01, "Level: {012}")
	_GUI_NewItem(02, "Exp: {013}")

	_GUI_NewItem(04, "Gold: {014}", "Current gold on character.||Max gold on character calculated from the following formula:|(CharacterLevel*10,000)")
	_GUI_NewItem(05, "Stash: {015} [015:2500000/1000000]", "Current gold in stash||Max gold in stash is constant:|2,500,000")

	_GUI_NewItem(07, "Signets: {185}/400 [185:400/400]", "Signets of Learning.|Each grants 1 stat point. Catalyst is not used up in craft. Can't mix sets and uniques while disenchanting.||Cube recipes:|Any sacred unique item x1-10 + Catalyst of Learning ? Signet of Learning x1-10|Any set item x1-10 + Catalyst of Learning ? Signet of Learning x1-10|Unique ring/amulet/jewel/quiver + Catalyst of Learning ? Signet of Learning")
	_GUI_NewItem(08, "Charms: {356}/97 [356:97/97]", "Charm counter|Value calculated by the following formula: (Charms+Relics)*2||Exceptions:|Ennead charm - 1pt|Sunstone of the Twin Seas - 1pt, +1pt for all 3 scrolls|Riftwalker - 2pt for base, +1pt for each upgrade (max 6pt)|Sleep - gives 2pt only after full upgrade (Awakening), otherwise 0pt|Tome of Posession - increases by 2pt despite not being a charm")

	_GUI_GroupNext()
	_GUI_GroupNext()
	_GUI_NewItem(00, "M.Find: {080}%", "Magic Find")
	_GUI_NewItem(01, "G.Find: {079}%", "Gold Find")
	_GUI_NewItem(02, "Exp.Gain: +{085}%")
	_GUI_NewItem(03, "M.Skill: +{479}", "Maximum Skill Level")

	GUICtrlCreateTabItem("Page 1")
	_GUI_GroupFirst()
	_GUI_NewText(00, "Base stats")
	_GUI_NewItem(01, "Str: {000}", "Strength")
	_GUI_NewItem(02, "Dex: {002}", "Dexterity")
	_GUI_NewItem(03, "Vit: {003}", "Vitality")
	_GUI_NewItem(04, "Ene: {001}", "Energy")

	_GUI_GroupNext()
	_GUI_NewText(00, "Bonus stats")
	_GUI_NewItem(01, "{359}%/{240}", "Strength")
	_GUI_NewItem(02, "{360}%/{241}", "Dexterity")
	_GUI_NewItem(03, "{362}%/{242}", "Vitality")
	_GUI_NewItem(04, "{361}%/{243}", "Energy")

	_GUI_NewText(06, "Item/Skill", "Speed from items and skills behave differently. Use SpeedCalc to find your breakpoints")
	_GUI_NewItem(07, "IAS: {093}%/{068}%", "Increased Attack Speed")
	_GUI_NewItem(08, "FHR: {099}%/{069}%", "Faster Hit Recovery")
	_GUI_NewItem(09, "FBR: {102}%/{069}%", "Faster Block Rate")
	_GUI_NewItem(10, "FRW: {096}%/{067}%", "Faster Run/Walk")
	_GUI_NewItem(11, "FCR: {105}%/0%", "Faster Cast Rate")

	_GUI_GroupNext()
	_GUI_NewItem(00, "Life: {076}%", "Maximum Life")
	_GUI_NewItem(01, "Mana: {077}%", "Maximum Mana")
	_GUI_NewItem(02, "EWD: {025}%", "Enchanced Weapon Damage")
	_GUI_NewItem(03, "TCD: {171}% ", "Total Character Defense")
	_GUI_NewItem(04, "AR: {119}% ", "Attack Rating")
	_GUI_NewItem(05, "PDR: {034}", "Physical Damage taken Reduction")
	_GUI_NewItem(06, "MDR: {035}", "Magic Damage taken Reduction")
	_GUI_NewItem(07, "Grit: {184}%", "Damage reduction from all sources (mostly from Grit)")
	_GUI_NewItem(08, "Dodge: {338}%", "Chance to avoid melee attacks while standing still")
	_GUI_NewItem(09, "Avoid: {339}%", "Chance to avoid projectiles while standing still")
	_GUI_NewItem(10, "Evade: {340}%", "Chance to avoid any attack while moving")

	_GUI_NewItem(12, "CB: {136}%", "Crushing Blow. Chance to deal physical damage based on target's current health")
	_GUI_NewItem(13, "DS: {141}%", "Deadly Strike. Chance to double physical damage of attack")
	_GUI_NewItem(14, "Crit: {344}%", "Critical Strike. Chance to double physical damage of attack")

	_GUI_GroupNext()
	_GUI_NewText(00, "Resistance")
	_GUI_NewItem(01, "{039}%", "Fire", $g_iColorArray[$ePrintRed])
	_GUI_NewItem(02, "{043}%", "Cold", $g_iColorArray[$ePrintBlue])
	_GUI_NewItem(03, "{041}%", "Lightning", $g_iColorArray[$ePrintGold])
	_GUI_NewItem(04, "{045}%", "Poison", $g_iColorArray[$ePrintGreen])
	_GUI_NewItem(05, "{037}%", "Magic", $g_iColorArray[$ePrintPink])
	_GUI_NewItem(06, "{036}%", "Physical")

	_GUI_NewText(07, "Damage/Pierce", "Spell damage / -Enemy resist")
	_GUI_NewItem(08, "{329}%/{333}%", "Fire", $g_iColorArray[$ePrintRed])
	_GUI_NewItem(09, "{331}%/{335}%", "Cold", $g_iColorArray[$ePrintBlue])
	_GUI_NewItem(10, "{330}%/{334}%", "Lightning", $g_iColorArray[$ePrintGold])
	_GUI_NewItem(11, "{332}%/{336}%", "Poison", $g_iColorArray[$ePrintGreen])
	_GUI_NewItem(12, "{431}% PSD", "Poison Skill Duration", $g_iColorArray[$ePrintGreen])
	_GUI_NewItem(13, "{357}%/0%", "Physical/Magic", $g_iColorArray[$ePrintPink])

	GUICtrlCreateTabItem("Page 2")
	_GUI_GroupFirst()
	_GUI_NewItem(00, "SF: {485}", "Spell Focus")
	_GUI_NewItem(01, "SF.Cap: {244}%", "Spell Focus cap. 100% means you don't benefit from more spell focus")
	_GUI_NewItem(02, "Buff.Dur: {409}%", "Buff/Debuff/Cold Skill Duration")
	_GUI_NewItem(03, "Life Reg: {074}", "Life Regenerated per Second")
	_GUI_NewItem(04, "Mana Reg: {027}%", "% Mana Regeneration per Second")
	_GUI_NewItem(05, "CLR: {109}%", "Curse Length Reduction")
	_GUI_NewItem(06, "PLR: {110}%", "Poison Length Reduction")
	_GUI_NewItem(07, "TTAD: {489}", "Target Takes Additional Damage")
	_GUI_NewItem(08, "DtD: {121}%", "Damage to Demons")
	_GUI_NewItem(09, "DtU: {122}%", "Damage to Undead")

	_GUI_NewText(11, "Slow")
	_GUI_NewItem(12, "Tgt.: {150}%/{376}%", "Slows Target / Slows Melee Target")
	_GUI_NewItem(13, "Att.: {363}%/{493}%", "Slows Attacker / Slows Ranged Attacker")

	_GUI_GroupNext()
	_GUI_NewText(00, "Minions")
	_GUI_NewItem(01, "Life: {444}%")
	_GUI_NewItem(02, "Damage: {470}%")
	_GUI_NewItem(03, "Resist: {487}%")
	_GUI_NewItem(04, "AR: {500}%", "Attack Rating")

	_GUI_NewText(06, "Life/Mana")
	_GUI_NewItem(07, "Leech: {060}%/{062}%", "Life/Mana Stolen per Hit")
	_GUI_NewItem(08, "*aeK: {086}/{138}", "Life/Mana after each Kill")
	_GUI_NewItem(09, "*oS: {208}/{209}", "Life/Mana on Striking")
	_GUI_NewItem(10, "*oA: {210}/{295}", "Life/Mana on Attack")

	_GUI_GroupNext()
	_GUI_NewText(00, "Weapon Damage")
	_GUI_NewItem(01, "{048}-{049}", "Fire", $g_iColorArray[$ePrintRed])
	_GUI_NewItem(02, "{054}-{055}", "Cold", $g_iColorArray[$ePrintBlue])
	_GUI_NewItem(03, "{050}-{051}", "Lightning", $g_iColorArray[$ePrintGold])
	_GUI_NewItem(04, "{057}-{058}/s", "Poison/sec", $g_iColorArray[$ePrintGreen])
	_GUI_NewItem(05, "{052}-{053}", "Magic", $g_iColorArray[$ePrintPink])
	_GUI_NewItem(06, "{021}-{022}", "One-hand physical damage. Estimated; may be inaccurate, especially when dual wielding")
	_GUI_NewItem(07, "{023}-{024}", "Two-hand/Ranged physical damage. Estimated; may be inaccurate, especially when dual wielding")

	_GUI_GroupNext()
	_GUI_NewText(00, "Abs/Flat", "Absorb / Flat absorb")
	_GUI_NewItem(01, "{142}%/{143}", "Fire", $g_iColorArray[$ePrintRed])
	_GUI_NewItem(02, "{148}%/{149}", "Cold", $g_iColorArray[$ePrintBlue])
	_GUI_NewItem(03, "{144}%/{145}", "Lightning", $g_iColorArray[$ePrintGold])
	_GUI_NewItem(04, "{146}%/{147}", "Magic", $g_iColorArray[$ePrintPink])

	_GUI_NewItem(06, "RIP [108:1/1]", "Slain Monsters Rest In Peace|Nullifies Reanimates from monsters and you")
	_GUI_NewItem(07, "Half freeze [118:1/1]", "Half freeze duration")
	_GUI_NewItem(08, "Cannot be Frozen [153:1/1]")
endfunc
#EndRegion
