#include-once
#include "speedcalcData.au3"

#Region SpeedCalc globals
global $g_oScCof = 0
global $g_bScCofReady = False

global $g_idScClass, $g_idScMorph, $g_idScWeaponType, $g_idScWeaponBase, $g_idScDebuff
global $g_idScIas, $g_idScSkillIas, $g_idScFcr, $g_idScFhr, $g_idScFbr
global $g_idScDualWield, $g_idScThrowing, $g_idScStatus
global $g_idScTable[4]

global $g_sScClassList = ""
global $g_sScWeaponTypeList = ""
global $g_sScWeaponBaseList = ""
global $g_sScDebuffList = ""
global $g_asScWeaponTypeTokens[1]
global $g_aiScWeaponBaseIndex[1]
global $g_bScLastMerc = False
global $g_sScLastCharToken = ""
global $g_sScLastFamilyToken = ""
global $g_iScLastBaseCatalogCount = -1
global $g_sScLastTableSig = ""

global $g_iScLiveClass = 0
global $g_iScLiveMercType = -1
global $g_iScLiveUnitType = 0
global $g_sScLiveWclass = ""
global $g_sScLiveFamily = ""
global $g_iScLiveWsm = 0
global $g_iScLiveFileIndex = 0
global $g_sScLiveWeaponName = ""
global $g_iScLiveIas = 0
global $g_iScLiveSkillIas = 0
global $g_iScLiveFcr = 0
global $g_iScLiveFhr = 0
global $g_iScLiveSkillFhr = 0
global $g_iScLiveFbr = 0

global $g_avScWeaponBases[1][6]
global $g_iScWeaponBaseCount = 0
global $g_bScCatalogReady = False

global $g_avScClasses[][3] = [ _
	[0, "Amazon", "AM"], _
	[1, "Sorceress", "SO"], _
	[2, "Necromancer", "NE"], _
	[3, "Paladin", "PA"], _
	[4, "Barbarian", "BA"], _
	[5, "Druid", "DZ"], _
	[6, "Assassin", "AI"] _
]

global $g_avScMorphs[][3] = [ _
	["Werewolf", "40", "DZ"], _
	["Werebear", "TG", "DZ"], _
	["Wereowl", "OW", "DZ"], _
	["Superbeast", "~Z", "PA"], _
	["Deathlord", "0N", "NE"], _
	["Treewarden", "TH", "BA"] _
]

global $g_avScMercs[][3] = [ _
	[0, "Rogue (Act 1)", "RG"], _
	[1, "Town Guard (Act 2)", "GU"], _
	[2, "Shapeshifter (Act 2)", "GU"], _
	[3, "Iron Wolf (Act 3)", "IW"], _
	[4, "Son of Harrogath (Act 5)", "0A"] _
]

global $g_avScDebuffs[][2] = [ _
	["None", 0], _
	["Decrepify", -20], _
	["Phoboss", -20], _
	["Uldyssian", -30], _
	["Chill", -50] _
]

global $g_avScWeaponTypes[][4] = [ _
	["swor", "One-Handed Swords", "1HS", "1HS"], _
	["crsd", "Crystal Swords", "1HS", "1HS"], _
	["2hsd", "Two-Handed Swords", "2HS", "1HS"], _
	["axe", "One-Handed Axes", "1HS", "1HS"], _
	["2hax", "Two-Handed Axes", "STF", "1HS"], _
	["mace", "Maces", "1HS", "1HS"], _
	["hamm", "Hammers", "STF", "1HS"], _
	["scep", "Sceptres", "1HS", "1HS"], _
	["jave", "Javelins", "1HT", "1HT"], _
	["spea", "Spears", "2HT", "1HS"], _
	["scyh", "Scythes", "STF", "1HS"], _
	["knif", "Daggers", "1HT", "1HT"], _
	["tkni", "Throwing Knives", "1HT", "1HT"], _
	["taxe", "Throwing Axes", "1HS", "1HS"], _
	["staf", "Staves", "STF", "1HS"], _
	["bow", "Bows", "BOW", "1HS"], _
	["xbow", "Crossbows", "XBW", "1HS"], _
	["abow", "Amazon Bows", "BOW", "1HS"], _
	["aspe", "Amazon Spears", "2HT", "1HS"], _
	["ajav", "Amazon Javelins", "1HT", "1HT"], _
	["h2h", "Assassin Claws", "HT1", "HT1"], _
	["nagi", "Assassin Naginatas", "STF", "1HS"], _
	["bswd", "Barbarian Swords", "1HS", "1HS"], _
	["baxe", "Barbarian One-Handed Axes", "1HS", "1HS"], _
	["2hbx", "Barbarian Two-Handed Axes", "STF", "1HS"], _
	["dbow", "Druid Bows", "BOW", "1HS"], _
	["dstf", "Druid Staves", "STF", "1HS"], _
	["nscy", "Necromancer Scythes", "STF", "1HS"], _
	["nstf", "Necromancer Staves", "STF", "1HS"], _
	["nknf", "Necromancer Daggers", "1HT", "1HT"], _
	["nxbw", "Necromancer Crossbows", "XBW", "1HS"], _
	["wand", "Necromancer Wands", "1HS", "1HS"], _
	["pclb", "Paladin Clubs", "1HS", "1HS"], _
	["pmac", "Paladin Maces", "1HS", "1HS"], _
	["pham", "Paladin Hammers", "STF", "1HS"], _
	["pspe", "Paladin Spears", "2HT", "1HS"], _
	["orb", "Sorceress Orbs", "1HS", "1HS"], _
	["scrd", "Sorceress Crystal Swords", "1HS", "1HS"] _
]

global $g_asScAnimTypes[4] = ["A1", "SC", "GH", "BL"]
global $g_asScAnimLabels[4] = ["Attack Speed", "Cast Speed", "Hit Recovery", "Block Speed"]
#EndRegion

#Region SpeedCalc lookup helpers
func SpeedCalc_InitCof()
	if ($g_bScCofReady) then return
	$g_oScCof = ObjCreate("Scripting.Dictionary")
	if (IsObj($g_oScCof)) then
		local $i
		for $i = 0 to UBound($g_avSpeedcalcData) - 1
			if (not $g_oScCof.Exists($g_avSpeedcalcData[$i][0])) then $g_oScCof.Add($g_avSpeedcalcData[$i][0], $i)
		next
	endif
	$g_bScCofReady = True
endfunc

func SpeedCalc_LookupCof($sKey, byref $iFrames, byref $iAnimSpeed)
	$iFrames = 0
	$iAnimSpeed = 0
	local $i = -1
	if (IsObj($g_oScCof) and $g_oScCof.Exists($sKey)) then
		$i = $g_oScCof.Item($sKey)
	else
		local $j
		for $j = 0 to UBound($g_avSpeedcalcData) - 1
			if ($g_avSpeedcalcData[$j][0] == $sKey) then
				$i = $j
				exitloop
			endif
		next
	endif
	if ($i < 0) then return False
	$iFrames = $g_avSpeedcalcData[$i][1]
	$iAnimSpeed = $g_avSpeedcalcData[$i][2]
	return True
endfunc

func SpeedCalc_WeaponTypeByToken($sToken)
	$sToken = StringLower($sToken)
	local $i
	for $i = 0 to UBound($g_avScWeaponTypes) - 1
		if ($g_avScWeaponTypes[$i][0] == $sToken) then return $i
	next
	return -1
endfunc

func SpeedCalc_ClassToken($iId)
	if ($iId >= 0 and $iId < UBound($g_avScClasses)) then return $g_avScClasses[$iId][2]
	return "AM"
endfunc

func SpeedCalc_ClassName($iId)
	if ($iId >= 0 and $iId < UBound($g_avScClasses)) then return $g_avScClasses[$iId][1]
	return "Unknown"
endfunc

func SpeedCalc_MercToken($iId)
	if ($iId >= 0 and $iId < UBound($g_avScMercs)) then return $g_avScMercs[$iId][2]
	return "RG"
endfunc

func SpeedCalc_MercName($iId)
	if ($iId >= 0 and $iId < UBound($g_avScMercs)) then return $g_avScMercs[$iId][1]
	return "Unknown"
endfunc

func SpeedCalc_ClassifyMerc($iClass)
	switch $iClass
		case 271
			return 0
		case 338
			return 1
		case 359
			return 3
		case 561
			return 4
	endswitch
	return -1
endfunc

func SpeedCalc_IsClassSpecific($sToken)
	switch $sToken
		case "abow", "aspe", "ajav", "h2h", "nagi", "bswd", "baxe", "2hbx", "dbow", "dstf", "nscy", "nstf", "nknf", "nxbw", "wand", "pclb", "pmac", "pham", "pspe", "orb", "scrd"
			return True
	endswitch
	return False
endfunc

func SpeedCalc_ClassSpecificOk($sCharToken, $sWeaponToken)
	switch $sCharToken
		case "AM"
			return ($sWeaponToken == "abow" or $sWeaponToken == "aspe" or $sWeaponToken == "ajav")
		case "AI"
			return ($sWeaponToken == "h2h" or $sWeaponToken == "nagi")
		case "BA"
			return ($sWeaponToken == "bswd" or $sWeaponToken == "baxe" or $sWeaponToken == "2hbx")
		case "DZ"
			return ($sWeaponToken == "dbow" or $sWeaponToken == "dstf")
		case "NE"
			return ($sWeaponToken == "nscy" or $sWeaponToken == "nstf" or $sWeaponToken == "nknf" or $sWeaponToken == "nxbw" or $sWeaponToken == "wand")
		case "PA"
			return ($sWeaponToken == "pclb" or $sWeaponToken == "pmac" or $sWeaponToken == "pham" or $sWeaponToken == "pspe")
		case "SO"
			return ($sWeaponToken == "orb" or $sWeaponToken == "scrd")
	endswitch
	return False
endfunc

func SpeedCalc_MercWeaponOk($sCharToken, $sWeaponToken)
	switch $sCharToken
		case "RG"
			return ($sWeaponToken == "bow" or $sWeaponToken == "abow")
		case "GU"
			return ($sWeaponToken == "jave" or $sWeaponToken == "spea" or $sWeaponToken == "scyh" or $sWeaponToken == "pspe")
		case "IW"
			return ($sWeaponToken == "swor" or $sWeaponToken == "crsd")
		case "0A"
			return ($sWeaponToken == "swor" or $sWeaponToken == "crsd" or $sWeaponToken == "2hsd" or $sWeaponToken == "bswd")
	endswitch
	return False
endfunc

func SpeedCalc_IsMercToken($sCharToken)
	switch $sCharToken
		case "RG", "GU", "IW", "0A"
			return True
	endswitch
	return False
endfunc

func SpeedCalc_WeaponAllowed($sCharToken, $sWeaponToken)
	if (SpeedCalc_IsMercToken($sCharToken)) then return SpeedCalc_MercWeaponOk($sCharToken, $sWeaponToken)
	if (not SpeedCalc_IsClassSpecific($sWeaponToken)) then return True
	return SpeedCalc_ClassSpecificOk($sCharToken, $sWeaponToken)
endfunc

func SpeedCalc_PreferredToken($sCharToken, $sAnim)
	switch $sCharToken
		case "AM"
			switch $sAnim
				case "BOW"
					return "abow"
				case "2HT"
					return "aspe"
				case "1HT"
					return "ajav"
			endswitch
		case "AI"
			switch $sAnim
				case "HT1"
					return "h2h"
				case "STF"
					return "nagi"
			endswitch
		case "BA"
			if ($sAnim == "1HS") then return "bswd"
		case "DZ"
			switch $sAnim
				case "BOW"
					return "dbow"
				case "STF"
					return "dstf"
			endswitch
		case "NE"
			switch $sAnim
				case "1HT"
					return "nknf"
				case "STF"
					return "nscy"
				case "XBW"
					return "nxbw"
			endswitch
		case "PA"
			switch $sAnim
				case "1HS"
					return "pclb"
				case "2HT"
					return "pspe"
				case "STF"
					return "pham"
			endswitch
		case "SO"
			if ($sAnim == "1HS") then return "scrd"
	endswitch
	return ""
endfunc

func SpeedCalc_FindWeaponType($sCharToken, $sWclass, $sFamilyCodes)
	local $i, $iIdx
	if ($sFamilyCodes <> "") then
		local $as = StringSplit($sFamilyCodes, ",", $STR_NOCOUNT)
		if (IsArray($as)) then
			for $i = 0 to UBound($as) - 1
				$iIdx = SpeedCalc_WeaponTypeByToken($as[$i])
				if ($iIdx >= 0) then return $iIdx
			next
		endif
	endif
	local $sAnim = StringUpper($sWclass)
	local $sPref = SpeedCalc_PreferredToken($sCharToken, $sAnim)
	if ($sPref <> "") then
		$iIdx = SpeedCalc_WeaponTypeByToken($sPref)
		if ($iIdx >= 0) then return $iIdx
	endif
	for $i = 0 to UBound($g_avScWeaponTypes) - 1
		if (SpeedCalc_WeaponAllowed($sCharToken, $g_avScWeaponTypes[$i][0]) and $g_avScWeaponTypes[$i][2] == $sAnim) then return $i
	next
	return -1
endfunc

func SpeedCalc_CharOverride($sToken, byref $sAllAnims, byref $sCastPrefix, byref $sBlPrefix, byref $iBlAnimSpeed)
	$sAllAnims = ""
	$sCastPrefix = ""
	$sBlPrefix = ""
	$iBlAnimSpeed = -1
	switch $sToken
		case "40", "OW", "RG", "GU"
			$sAllAnims = "HTH"
			return True
		case "TG"
			$sAllAnims = "HTH"
			$iBlAnimSpeed = 200
			return True
		case "~Z"
			$sAllAnims = "HTH"
			$sBlPrefix = "GH"
			return True
		case "0N", "TH"
			$sAllAnims = "HTH"
			$sCastPrefix = "A1"
			$sBlPrefix = "GH"
			return True
	endswitch
	return False
endfunc

func SpeedCalc_DwAnim($sCharToken, $sAnimType)
	if ($sCharToken == "BA") then
		switch $sAnimType
			case "SC", "GH"
				return "1SS"
			case "BL"
				return "SUPPRESS"
		endswitch
	elseif ($sCharToken == "AI") then
		switch $sAnimType
			case "SC", "GH", "BL"
				return "HT2"
		endswitch
	endif
	return ""
endfunc

func SpeedCalc_HasStartingFrame($sCharToken, $sPrimaryAnim, $bOverride, $bThrowing)
	if ($bOverride or $bThrowing) then return False
	if ($sCharToken <> "AM" and $sCharToken <> "SO") then return False
	switch $sPrimaryAnim
		case "1HS", "1HT", "2HS", "STF"
			return True
	endswitch
	return False
endfunc

func SpeedCalc_IsThrowingFamily($sToken)
	switch $sToken
		case "tkni", "jave", "ajav", "taxe"
			return True
	endswitch
	return False
endfunc

func SpeedCalc_ThrowingDisallowed($sCharToken)
	switch $sCharToken
		case "RG", "GU", "IW", "0A", "40", "TG", "OW", "~Z", "0N", "TH"
			return True
	endswitch
	return False
endfunc

func SpeedCalc_BarbDwExcluded($sToken)
	switch $sToken
		case "spea", "aspe", "pspe", "scyh", "nscy", "staf", "dstf", "nstf", "bow", "abow", "dbow", "xbow", "nxbw", "nagi", "wand", "orb"
			return True
	endswitch
	return False
endfunc

func SpeedCalc_EffectiveAnim($iWeaponIdx, $iWsm, $sAnimType)
	if ($iWeaponIdx < 0) then return "1HS"
	if ($g_avScWeaponTypes[$iWeaponIdx][0] == "hamm" and $iWsm == 10) then
		if ($sAnimType == "BL") then return $g_avScWeaponTypes[$iWeaponIdx][3]
		return "1HS"
	endif
	if ($sAnimType == "BL") then return $g_avScWeaponTypes[$iWeaponIdx][3]
	return $g_avScWeaponTypes[$iWeaponIdx][2]
endfunc

func SpeedCalc_Min($a, $b)
	return ($a < $b) ? $a : $b
endfunc

func SpeedCalc_Diminishing($iStat)
	if (120 + $iStat == 0) then return 0
	return Floor((120 * $iStat) / (120 + $iStat))
endfunc

func SpeedCalc_StripTier($sName)
	return StringStripWS(StringRegExpReplace($sName, "\s*\((?:[1-4]|Sacred|Angelic|Mastercrafted)\)\s*$", ""), 3)
endfunc

func SpeedCalc_PackedCode($iRaw)
	local $s = "", $i, $iByte
	for $i = 0 to 3
		$iByte = BitAND(BitShift($iRaw, 8 * $i), 0xFF)
		if ($iByte == 0 or $iByte == 0x20) then exitloop
		$s &= Chr($iByte)
	next
	return StringUpper($s)
endfunc
#EndRegion

#Region SpeedCalc FPA math
func SpeedCalc_AttackFpa($iFrames, $iAnimSpeed, $iIas, $iWsm, $iSkillIas, $iSkillSlow, $bStartingFrame, $iThrowingPenalty)
	local $iEffFrames = $bStartingFrame ? $iFrames - 2 : $iFrames
	local $iEias = SpeedCalc_Diminishing($iIas)
	local $iEffective = SpeedCalc_Min($iEias + $iSkillIas - $iWsm + $iSkillSlow, 75) - $iThrowingPenalty
	local $iDivisor = Floor(($iAnimSpeed * (100 + $iEffective)) / 100)
	if ($iDivisor <= 0) then return $iEffFrames
	return Ceiling((256 * $iEffFrames) / $iDivisor) - 1
endfunc

func SpeedCalc_CastFpa($iFrames, $iAnimSpeed, $iFcr, $iSkillSlow)
	local $iEfcr = SpeedCalc_Min(SpeedCalc_Diminishing($iFcr) + $iSkillSlow, 75)
	local $iDivisor = Floor(($iAnimSpeed * (100 + $iEfcr)) / 100)
	if ($iDivisor <= 0) then return $iFrames
	return Ceiling((256 * $iFrames) / $iDivisor) - 1
endfunc

func SpeedCalc_DefensiveFpa($iFrames, $iAnimSpeed, $iStat, $iSkillStat, $iSkillSlow)
	local $iEstat = SpeedCalc_Diminishing($iStat)
	local $iDivisor = Floor(($iAnimSpeed * (50 + $iEstat + $iSkillStat + $iSkillSlow)) / 100)
	if ($iDivisor <= 0) then return $iFrames
	return Ceiling((256 * $iFrames) / $iDivisor) - 1
endfunc

func SpeedCalc_FindRequired($iTargetFpa, $sAnimType, $iFrames, $iAnimSpeed, $iWsm, $iSkillIas, $iSkillFhr, $iSkillSlow, $bStartingFrame, $iThrowingPenalty)
	local $iLo = 0, $iHi = 500, $iMid
	local $iBase = SpeedCalc_CalcFpaForStat(0, $sAnimType, $iFrames, $iAnimSpeed, $iWsm, $iSkillIas, $iSkillFhr, $iSkillSlow, $bStartingFrame, $iThrowingPenalty)
	if ($iBase <= $iTargetFpa) then return 0
	if (SpeedCalc_CalcFpaForStat($iHi, $sAnimType, $iFrames, $iAnimSpeed, $iWsm, $iSkillIas, $iSkillFhr, $iSkillSlow, $bStartingFrame, $iThrowingPenalty) > $iTargetFpa) then return -1
	while $iLo < $iHi
		$iMid = Floor(($iLo + $iHi) / 2)
		if (SpeedCalc_CalcFpaForStat($iMid, $sAnimType, $iFrames, $iAnimSpeed, $iWsm, $iSkillIas, $iSkillFhr, $iSkillSlow, $bStartingFrame, $iThrowingPenalty) <= $iTargetFpa) then
			$iHi = $iMid
		else
			$iLo = $iMid + 1
		endif
	wend
	return $iLo
endfunc

func SpeedCalc_CalcFpaForStat($iStat, $sAnimType, $iFrames, $iAnimSpeed, $iWsm, $iSkillIas, $iSkillFhr, $iSkillSlow, $bStartingFrame, $iThrowingPenalty)
	switch $sAnimType
		case "A1"
			return SpeedCalc_AttackFpa($iFrames, $iAnimSpeed, $iStat, $iWsm, $iSkillIas, $iSkillSlow, $bStartingFrame, $iThrowingPenalty)
		case "SC"
			return SpeedCalc_CastFpa($iFrames, $iAnimSpeed, $iStat, $iSkillSlow)
		case "GH"
			return SpeedCalc_DefensiveFpa($iFrames, $iAnimSpeed, $iStat, $iSkillFhr, $iSkillSlow)
		case "BL"
			return SpeedCalc_DefensiveFpa($iFrames, $iAnimSpeed, $iStat, $iSkillFhr, $iSkillSlow)
	endswitch
	return $iFrames
endfunc

func SpeedCalc_ResolveAnim($sCharToken, $sAnimType, $sPrimaryAnim, $sBlockAnim, $bDualWield, $bThrowing, byref $sAnimPrefix, byref $sWeaponAnim)
	$sAnimPrefix = $sAnimType
	$sWeaponAnim = $sPrimaryAnim
	local $sAllAnims, $sCastPrefix, $sBlPrefix, $iBlAnimSpeed
	local $bOverride = SpeedCalc_CharOverride($sCharToken, $sAllAnims, $sCastPrefix, $sBlPrefix, $iBlAnimSpeed)

	if ($bOverride) then
		$sWeaponAnim = $sAllAnims
	elseif ($sAnimType == "BL") then
		$sWeaponAnim = $sBlockAnim
	else
		$sWeaponAnim = $sPrimaryAnim
	endif

	if ($bDualWield and not $bOverride) then
		local $sDw = SpeedCalc_DwAnim($sCharToken, $sAnimType)
		if ($sDw == "SUPPRESS") then return False
		if ($sDw <> "") then $sWeaponAnim = $sDw
	endif

	if ($bOverride and $sCastPrefix <> "" and $sAnimType == "SC") then
		$sAnimPrefix = $sCastPrefix
	elseif ($bOverride and $sBlPrefix <> "" and $sAnimType == "BL") then
		$sAnimPrefix = $sBlPrefix
	endif

	if ($bThrowing and $sAnimType == "A1" and not $bOverride) then
		local $iFrames, $iAnimSpeed
		if (SpeedCalc_LookupCof($sCharToken & "TH" & $sWeaponAnim, $iFrames, $iAnimSpeed)) then $sAnimPrefix = "TH"
	endif
	return True
endfunc
#EndRegion

#Region SpeedCalc memory
func SpeedCalc_ReadLive()
	$g_iScLiveClass = 0
	$g_iScLiveMercType = -1
	$g_iScLiveUnitType = 0
	$g_sScLiveWclass = ""
	$g_sScLiveFamily = ""
	$g_iScLiveWsm = 0
	$g_iScLiveFileIndex = 0
	$g_sScLiveWeaponName = ""
	$g_iScLiveIas = 0
	$g_iScLiveSkillIas = 0
	$g_iScLiveFcr = 0
	$g_iScLiveFhr = 0
	$g_iScLiveSkillFhr = 0
	$g_iScLiveFbr = 0

	if (not IsIngame() or not $g_ahD2Handle) then return False

	$g_iScLiveIas = GetStatValue(93)
	$g_iScLiveSkillIas = GetStatValue(68)
	$g_iScLiveFcr = GetStatValue(105)
	$g_iScLiveFhr = GetStatValue(99)
	$g_iScLiveSkillFhr = GetStatValue(69)
	$g_iScLiveFbr = GetStatValue(102)

	local $pUnitAddress = GetUnitToRead()
	local $pUnit = _MemoryRead($pUnitAddress, $g_ahD2Handle)
	if (not $pUnit) then return False

	$g_iScLiveUnitType = _MemoryRead($pUnit + 0x00, $g_ahD2Handle)
	local $iClass = _MemoryRead($pUnit + 0x04, $g_ahD2Handle)
	if ($g_iScLiveUnitType == 1) then
		$g_iScLiveMercType = SpeedCalc_ClassifyMerc($iClass)
	else
		if ($iClass >= 0 and $iClass <= 6) then $g_iScLiveClass = $iClass
	endif

	SpeedCalc_ReadEquippedWeapon($pUnit)
	return True
endfunc

func SpeedCalc_ReadEquippedWeapon($pUnit)
	local $pWeapon = GetUnitWeapon($pUnit)
	if (not $pWeapon) then return

	local $iFileIndex = _MemoryRead($pWeapon + 0x04, $g_ahD2Handle)
	$g_iScLiveFileIndex = $iFileIndex

	local $pItemsTxt = _MemoryRead($g_hD2Common + 0x9FB98, $g_ahD2Handle)
	if (not $pItemsTxt) then return
	local $pRecord = $pItemsTxt + 0x1A8 * $iFileIndex

	$g_sScLiveWclass = SpeedCalc_PackedCode(_MemoryRead($pRecord + 0xC0, $g_ahD2Handle))
	$g_iScLiveWsm = _MemoryRead($pRecord + 0xD8, $g_ahD2Handle, "int")
	local $iType0 = _MemoryRead($pRecord + 0x11E, $g_ahD2Handle, "word")
	$g_sScLiveFamily = SpeedCalc_ItemTypeChain($iType0)

	local $iNameID = _MemoryRead($pRecord + 0xF4, $g_ahD2Handle, "word")
	$g_sScLiveWeaponName = SpeedCalc_ItemName($iFileIndex, $iNameID)
endfunc

func SpeedCalc_ItemName($iFileIndex, $iNameID)
	if ($iFileIndex >= 0 and $iFileIndex < UBound($g_avNotifyCache) and $g_avNotifyCache[$iFileIndex][2] <> "") then
		return SpeedCalc_StripTier($g_avNotifyCache[$iFileIndex][2])
	endif
	if (not $iNameID or not $g_pD2InjectGetString) then return ""
	local $pName = RemoteThread($g_pD2InjectGetString, $iNameID)
	if (@error or not $pName) then return ""
	local $sName = _MemoryRead($pName, $g_ahD2Handle, "wchar[100]")
	$sName = StringRegExpReplace($sName, "ÿc.", "")
	local $as = StringSplit($sName, @LF)
	local $i, $sLast = ""
	for $i = 1 to $as[0]
		local $sLine = StringStripWS($as[$i], 3)
		if ($sLine <> "") then $sLast = $sLine
	next
	return SpeedCalc_StripTier($sLast)
endfunc

func SpeedCalc_ItemTypeChain($iTypeIdx)
	local $sChain = ""
	if ($iTypeIdx == 0 or not $g_pD2sgpt) then return $sChain

	local $pItemTypes = _MemoryRead($g_pD2sgpt + 0xBF8, $g_ahD2Handle)
	local $iCount = _MemoryRead($g_pD2sgpt + 0xBFC, $g_ahD2Handle)
	if (not $pItemTypes or $iCount <= 0) then return $sChain

	local $iCur = $iTypeIdx, $iHop, $sVisited = "|"
	for $iHop = 1 to 6
		if ($iCur <= 0 or $iCur >= $iCount) then exitloop
		if (StringInStr($sVisited, "|" & $iCur & "|")) then exitloop
		$sVisited &= $iCur & "|"
		local $pRecord = $pItemTypes + $iCur * 0xE4
		local $sCode = StringLower(SpeedCalc_PackedCode(_MemoryRead($pRecord + 0x00, $g_ahD2Handle)))
		if ($sCode == "") then exitloop
		if ($sChain <> "") then $sChain &= ","
		$sChain &= $sCode
		$iCur = _MemoryRead($pRecord + 0x04, $g_ahD2Handle, "short")
	next
	return $sChain
endfunc

func SpeedCalc_EnsureWeaponCatalog()
	if ($g_bScCatalogReady) then return
	if (not IsIngame() or not $g_hD2Common) then return

	local $iItemsTxt = _MemoryRead($g_hD2Common + 0x9FB94, $g_ahD2Handle)
	local $pItemsTxt = _MemoryRead($g_hD2Common + 0x9FB98, $g_ahD2Handle)
	if (not $iItemsTxt or not $pItemsTxt) then return

	if (SpeedCalc_LoadWeaponCache($iItemsTxt)) then
		$g_bScCatalogReady = True
		return
	endif

	$g_iScWeaponBaseCount = 0
	ReDim $g_avScWeaponBases[1][6]

	local $iClass, $pRecord, $iWclassRaw, $sWclass, $iWsm, $iType0, $sFamily, $sToken, $iNameID, $sName
	for $iClass = 0 to $iItemsTxt - 1
		$pRecord = $pItemsTxt + 0x1A8 * $iClass
		$iWclassRaw = _MemoryRead($pRecord + 0xC0, $g_ahD2Handle)
		if ($iWclassRaw == 0) then continueloop

		$sWclass = SpeedCalc_PackedCode($iWclassRaw)
		$iWsm = _MemoryRead($pRecord + 0xD8, $g_ahD2Handle, "int")
		$iType0 = _MemoryRead($pRecord + 0x11E, $g_ahD2Handle, "word")
		$sFamily = SpeedCalc_ItemTypeChain($iType0)
		$sToken = SpeedCalc_FamilyToken($sFamily)
		if ($sToken == "") then continueloop

		$iNameID = _MemoryRead($pRecord + 0xF4, $g_ahD2Handle, "word")
		$sName = SpeedCalc_ItemName($iClass, $iNameID)
		if ($sName == "") then $sName = "Base " & $iClass

		$g_iScWeaponBaseCount += 1
		ReDim $g_avScWeaponBases[$g_iScWeaponBaseCount][6]
		local $iRow = $g_iScWeaponBaseCount - 1
		$g_avScWeaponBases[$iRow][0] = $iClass
		$g_avScWeaponBases[$iRow][1] = $sName
		$g_avScWeaponBases[$iRow][2] = $sWclass
		$g_avScWeaponBases[$iRow][3] = $iWsm
		$g_avScWeaponBases[$iRow][4] = $sFamily
		$g_avScWeaponBases[$iRow][5] = $sToken
	next

	SpeedCalc_SaveWeaponCache($iItemsTxt)
	$g_bScCatalogReady = True
endfunc

func SpeedCalc_FamilyToken($sFamilyCodes)
	if ($sFamilyCodes == "") then return ""
	local $as = StringSplit($sFamilyCodes, ",", $STR_NOCOUNT)
	if (not IsArray($as)) then return ""
	local $i, $iIdx
	for $i = 0 to UBound($as) - 1
		$iIdx = SpeedCalc_WeaponTypeByToken($as[$i])
		if ($iIdx >= 0) then return $g_avScWeaponTypes[$iIdx][0]
	next
	return ""
endfunc

func SpeedCalc_CachePath()
	return $g_sAppDir & "\speedcalc-weapons.txt"
endfunc

func SpeedCalc_LoadWeaponCache($iItemsTxt)
	local $sPath = SpeedCalc_CachePath()
	if (not FileExists($sPath)) then return False
	local $h = FileOpen($sPath, BitOR($FO_READ, $FO_UTF8))
	if ($h == -1) then return False
	local $sHeader = FileReadLine($h)
	if (not StringRegExp($sHeader, "^#count=" & $iItemsTxt & "$")) then
		FileClose($h)
		return False
	endif
	$g_iScWeaponBaseCount = 0
	ReDim $g_avScWeaponBases[1][6]
	while 1
		local $sLine = FileReadLine($h)
		if (@error) then exitloop
		local $as = StringSplit($sLine, @TAB, $STR_NOCOUNT)
		if (not IsArray($as) or UBound($as) < 6) then continueloop
		$g_iScWeaponBaseCount += 1
		ReDim $g_avScWeaponBases[$g_iScWeaponBaseCount][6]
		local $iRow = $g_iScWeaponBaseCount - 1
		$g_avScWeaponBases[$iRow][0] = Int($as[0])
		$g_avScWeaponBases[$iRow][1] = $as[1]
		$g_avScWeaponBases[$iRow][2] = $as[2]
		$g_avScWeaponBases[$iRow][3] = Int($as[3])
		$g_avScWeaponBases[$iRow][4] = $as[4]
		$g_avScWeaponBases[$iRow][5] = $as[5]
	wend
	FileClose($h)
	return $g_iScWeaponBaseCount > 0
endfunc

func SpeedCalc_SaveWeaponCache($iItemsTxt)
	local $h = FileOpen(SpeedCalc_CachePath(), BitOR($FO_OVERWRITE, $FO_UTF8_NOBOM))
	if ($h == -1) then return
	FileWriteLine($h, "#count=" & $iItemsTxt)
	local $i
	for $i = 0 to $g_iScWeaponBaseCount - 1
		FileWriteLine($h, $g_avScWeaponBases[$i][0] & @TAB & $g_avScWeaponBases[$i][1] & @TAB & $g_avScWeaponBases[$i][2] & @TAB & $g_avScWeaponBases[$i][3] & @TAB & $g_avScWeaponBases[$i][4] & @TAB & $g_avScWeaponBases[$i][5])
	next
	FileClose($h)
endfunc
#EndRegion

#Region SpeedCalc GUI
func SpeedCalc_CreateTab()
	SpeedCalc_InitCof()

	GUICtrlCreateTabItem("Speedcalc")
	$g_iTabSpeedCalc = GUICtrlSendMsg($g_idTab, $TCM_GETITEMCOUNT, 0, 0) - 1

	local $iW = $g_iGUIWidth
	local $iC1 = 110, $iC2 = 123, $iC3 = 116
	local $iX1 = 6, $iX2 = $iX1 + $iC1 + 6, $iX3 = $iX2 + $iC2 + 6
	local $iX4 = $iX3 + $iC3 + 6
	local $iC4 = $iW - $iX4 - 6
	local $iY = 48
	GUICtrlCreateLabel("Class", $iX1, $iY, $iC1, 14)
	GUICtrlCreateLabel("Morph", $iX2, $iY, $iC2, 14)
	GUICtrlCreateLabel("Weapon Type", $iX3, $iY, $iC3, 14)
	GUICtrlCreateLabel("Weapon Base", $iX4, $iY, $iC4, 14)

	$iY = 62
	$g_idScClass = GUICtrlCreateCombo("", $iX1, $iY, $iC1, 22, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	GUICtrlSetOnEvent(-1, "SpeedCalc_OnControl")
	$g_idScMorph = GUICtrlCreateCombo("", $iX2, $iY, $iC2, 22, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	GUICtrlSetOnEvent(-1, "SpeedCalc_OnControl")
	$g_idScWeaponType = GUICtrlCreateCombo("", $iX3, $iY, $iC3, 22, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	GUICtrlSetOnEvent(-1, "SpeedCalc_OnControl")
	$g_idScWeaponBase = GUICtrlCreateCombo("", $iX4, $iY, $iC4, 22, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	GUICtrlSetOnEvent(-1, "SpeedCalc_OnControl")

	local $iSlowW = 112
	local $iSlowX = 304
	$iY = 86
	GUICtrlCreateLabel("IAS", 6, $iY, 54, 14)
	GUICtrlCreateLabel("Skill IAS", 62, $iY, 70, 14)
	GUICtrlCreateLabel("FCR", 134, $iY, 54, 14)
	GUICtrlCreateLabel("FHR", 190, $iY, 54, 14)
	GUICtrlCreateLabel("FBR", 246, $iY, 54, 14)
	GUICtrlCreateLabel("Debuff", $iSlowX, $iY, $iSlowW, 14)

	$iY = 100
	$g_idScIas = GUICtrlCreateInput("", 6, $iY, 52, 20)
	GUICtrlSetOnEvent(-1, "SpeedCalc_OnControl")
	$g_idScSkillIas = GUICtrlCreateInput("", 62, $iY, 68, 20)
	GUICtrlSetOnEvent(-1, "SpeedCalc_OnControl")
	$g_idScFcr = GUICtrlCreateInput("", 134, $iY, 52, 20)
	GUICtrlSetOnEvent(-1, "SpeedCalc_OnControl")
	$g_idScFhr = GUICtrlCreateInput("", 190, $iY, 52, 20)
	GUICtrlSetOnEvent(-1, "SpeedCalc_OnControl")
	$g_idScFbr = GUICtrlCreateInput("", 246, $iY, 52, 20)
	GUICtrlSetOnEvent(-1, "SpeedCalc_OnControl")
	$g_idScDebuff = GUICtrlCreateCombo("", $iSlowX, $iY, $iSlowW, 22, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
	GUICtrlSetOnEvent(-1, "SpeedCalc_OnControl")
	$g_idScDualWield = GUICtrlCreateCheckbox("Dual Wield", $iSlowX + $iSlowW + 6, $iY, 82, 20)
	GUICtrlSetOnEvent(-1, "SpeedCalc_OnControl")
	$g_idScThrowing = GUICtrlCreateCheckbox("Throw", $iSlowX + $iSlowW + 94, $iY, 70, 20)
	GUICtrlSetOnEvent(-1, "SpeedCalc_OnControl")
	GUICtrlSetState($g_idScDualWield, $GUI_HIDE)
	GUICtrlSetState($g_idScThrowing, $GUI_HIDE)

	$g_idScStatus = GUICtrlCreateLabel("Empty fields use live item/skill stats. Auto follows equipped class and weapon.", 6, 124, $iW - 12, 14)
	GUICtrlSetColor(-1, 0x555555)

	local $iTableW = 135
	local $iTableH = 160
	local $iGapX = 4
	local $iTitleH = 14
	local $iTableTop = 140
	local $i, $iX
	for $i = 0 to 3
		$iX = 6 + $i * ($iTableW + $iGapX)
		GUICtrlCreateLabel($g_asScAnimLabels[$i], $iX, $iTableTop, $iTableW, $iTitleH)
		$g_idScTable[$i] = GUICtrlCreateListView("Frames|Value", $iX, $iTableTop + $iTitleH, $iTableW, $iTableH, BitOR($LVS_REPORT, $LVS_NOSORTHEADER, $LVS_SINGLESEL))
		_GUICtrlListView_SetExtendedListViewStyle($g_idScTable[$i], BitOR($LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))
		_GUICtrlListView_SetColumnWidth($g_idScTable[$i], 0, 55)
		_GUICtrlListView_SetColumnWidth($g_idScTable[$i], 1, 55)
	next

	SpeedCalc_RebuildClassCombo(False)
	SpeedCalc_RebuildMorphCombo()
	SpeedCalc_RebuildDebuffCombo()
	GUICtrlSetOnEvent($g_idReadMercenary, "SpeedCalc_OnMercenary")
endfunc

func SpeedCalc_OnMercenary()
	SpeedCalc_Refresh(True)
endfunc

func SpeedCalc_OnControl()
	SpeedCalc_Refresh(True)
endfunc

func SpeedCalc_IsMercChecked()
	return BitAND(GUICtrlRead($g_idReadMercenary), $GUI_CHECKED) <> 0
endfunc

func SpeedCalc_RebuildClassCombo($bMerc)
	local $sData = "Auto"
	local $i
	if ($bMerc) then
		for $i = 0 to UBound($g_avScMercs) - 1
			$sData &= "|" & $g_avScMercs[$i][1]
		next
		GUICtrlSetState($g_idScMorph, $GUI_DISABLE)
		GUICtrlSetData($g_idScMorph, "None", "None")
	else
		for $i = 0 to UBound($g_avScClasses) - 1
			$sData &= "|" & $g_avScClasses[$i][1]
		next
		GUICtrlSetState($g_idScMorph, $GUI_ENABLE)
	endif
	if ($sData <> $g_sScClassList) then
		GUICtrlSetData($g_idScClass, "")
		GUICtrlSetData($g_idScClass, $sData, "Auto")
		$g_sScClassList = $sData
	endif
endfunc

func SpeedCalc_RebuildMorphCombo()
	local $sData = "None", $i
	for $i = 0 to UBound($g_avScMorphs) - 1
		$sData &= "|" & $g_avScMorphs[$i][0]
	next
	GUICtrlSetData($g_idScMorph, "")
	GUICtrlSetData($g_idScMorph, $sData, "None")
endfunc

func SpeedCalc_RebuildDebuffCombo($sKeep = "")
	local $sData = "", $i, $sSelect = ""
	for $i = 0 to UBound($g_avScDebuffs) - 1
		if ($i) then $sData &= "|"
		$sData &= SpeedCalc_DebuffLabel($g_avScDebuffs[$i][0], $g_avScDebuffs[$i][1])
	next
	if ($sKeep <> "" and StringInStr("|" & $sData & "|", "|" & $sKeep & "|")) then
		$sSelect = $sKeep
	else
		$sSelect = SpeedCalc_DebuffLabel($g_avScDebuffs[0][0], $g_avScDebuffs[0][1])
	endif
	GUICtrlSetData($g_idScDebuff, "")
	GUICtrlSetData($g_idScDebuff, $sData, $sSelect)
	$g_sScDebuffList = $sData
endfunc

func SpeedCalc_DebuffLabel($sName, $iValue)
	return $sName & " (" & $iValue & ")"
endfunc

func SpeedCalc_SelectedDebuffValue()
	local $sSel = GUICtrlRead($g_idScDebuff)
	local $i
	for $i = 0 to UBound($g_avScDebuffs) - 1
		if (SpeedCalc_DebuffLabel($g_avScDebuffs[$i][0], $g_avScDebuffs[$i][1]) == $sSel) then return $g_avScDebuffs[$i][1]
	next
	return 0
endfunc

func SpeedCalc_ReadOverride($id)
	local $s = StringStripWS(GUICtrlRead($id), 3)
	if ($s == "") then return Default
	return Int($s)
endfunc

func SpeedCalc_CurrentCharToken()
	local $bMerc = SpeedCalc_IsMercChecked()
	if (not $bMerc) then
		local $sMorph = GUICtrlRead($g_idScMorph)
		local $i
		for $i = 0 to UBound($g_avScMorphs) - 1
			if ($g_avScMorphs[$i][0] == $sMorph) then return $g_avScMorphs[$i][1]
		next
	endif

	local $sClass = GUICtrlRead($g_idScClass)
	if ($sClass <> "Auto" and $sClass <> "") then
		local $j
		if ($bMerc) then
			for $j = 0 to UBound($g_avScMercs) - 1
				if ($g_avScMercs[$j][1] == $sClass) then return $g_avScMercs[$j][2]
			next
		else
			for $j = 0 to UBound($g_avScClasses) - 1
				if ($g_avScClasses[$j][1] == $sClass) then return $g_avScClasses[$j][2]
			next
		endif
	endif

	if ($bMerc) then
		if ($g_iScLiveMercType >= 0) then return SpeedCalc_MercToken($g_iScLiveMercType)
		return "RG"
	endif
	return SpeedCalc_ClassToken($g_iScLiveClass)
endfunc

func SpeedCalc_DisplayClassName($sCharToken)
	local $sMorph = GUICtrlRead($g_idScMorph)
	if (not SpeedCalc_IsMercChecked() and $sMorph <> "None" and $sMorph <> "") then return $sMorph
	local $i
	if (SpeedCalc_IsMercChecked()) then
		local $sClass = GUICtrlRead($g_idScClass)
		if ($sClass <> "Auto" and $sClass <> "") then return $sClass
		if ($g_iScLiveMercType >= 0) then return SpeedCalc_MercName($g_iScLiveMercType)
		return "Mercenary"
	endif
	for $i = 0 to UBound($g_avScClasses) - 1
		if ($g_avScClasses[$i][2] == $sCharToken) then return $g_avScClasses[$i][1]
	next
	return SpeedCalc_ClassName($g_iScLiveClass)
endfunc

func SpeedCalc_RebuildWeaponTypeCombo($sCharToken)
	local $sData = "Auto"
	local $i, $iCount = 0
	ReDim $g_asScWeaponTypeTokens[1]
	for $i = 0 to UBound($g_avScWeaponTypes) - 1
		if (not SpeedCalc_WeaponAllowed($sCharToken, $g_avScWeaponTypes[$i][0])) then continueloop
		$sData &= "|" & $g_avScWeaponTypes[$i][1]
		$iCount += 1
		ReDim $g_asScWeaponTypeTokens[$iCount]
		$g_asScWeaponTypeTokens[$iCount - 1] = $g_avScWeaponTypes[$i][0]
	next
	if ($sData <> $g_sScWeaponTypeList) then
		GUICtrlSetData($g_idScWeaponType, "")
		GUICtrlSetData($g_idScWeaponType, $sData, "Auto")
		$g_sScWeaponTypeList = $sData
	endif
endfunc

func SpeedCalc_SelectedWeaponTypeIndex($sCharToken)
	local $sSel = GUICtrlRead($g_idScWeaponType)
	local $i, $iIdx
	if ($sSel <> "Auto" and $sSel <> "") then
		for $i = 0 to UBound($g_avScWeaponTypes) - 1
			if ($g_avScWeaponTypes[$i][1] == $sSel) then return $i
		next
	endif
	$iIdx = SpeedCalc_FindWeaponType($sCharToken, $g_sScLiveWclass, $g_sScLiveFamily)
	if ($iIdx >= 0 and SpeedCalc_WeaponAllowed($sCharToken, $g_avScWeaponTypes[$iIdx][0])) then return $iIdx
	for $i = 0 to UBound($g_avScWeaponTypes) - 1
		if (SpeedCalc_WeaponAllowed($sCharToken, $g_avScWeaponTypes[$i][0])) then return $i
	next
	return -1
endfunc

func SpeedCalc_RebuildWeaponBaseCombo($sFamilyToken)
	local $sData = "Auto"
	local $i, $iCount = 0
	ReDim $g_aiScWeaponBaseIndex[1]
	local $asSeen[1] = [0]
	if ($sFamilyToken <> "") then
		local $avList[1][3]
		local $iList = 0
		for $i = 0 to $g_iScWeaponBaseCount - 1
			if ($g_avScWeaponBases[$i][5] <> $sFamilyToken) then continueloop
			local $sName = SpeedCalc_StripTier($g_avScWeaponBases[$i][1])
			if ($sName == "") then continueloop
			$iList += 1
			ReDim $avList[$iList][3]
			$avList[$iList - 1][0] = $g_avScWeaponBases[$i][3]
			$avList[$iList - 1][1] = $sName
			$avList[$iList - 1][2] = $i
		next
		if ($iList > 1) then _ArraySort($avList, 0, 0, 0, 0)
		for $i = 0 to $iList - 1
			local $sName2 = $avList[$i][1]
			if (SpeedCalc_SeenHas($asSeen, $sName2)) then continueloop
			$asSeen[0] += 1
			ReDim $asSeen[$asSeen[0] + 1]
			$asSeen[$asSeen[0]] = $sName2
			$sData &= "|" & $sName2 & " (" & $avList[$i][0] & ")"
			$iCount += 1
			ReDim $g_aiScWeaponBaseIndex[$iCount]
			$g_aiScWeaponBaseIndex[$iCount - 1] = $avList[$i][2]
		next
	endif
	if ($sData <> $g_sScWeaponBaseList) then
		GUICtrlSetData($g_idScWeaponBase, "")
		GUICtrlSetData($g_idScWeaponBase, $sData, "Auto")
		$g_sScWeaponBaseList = $sData
	endif
endfunc

func SpeedCalc_SeenHas(byref $asSeen, $sName)
	local $i
	for $i = 1 to $asSeen[0]
		if ($asSeen[$i] == $sName) then return True
	next
	return False
endfunc

func SpeedCalc_SelectedWsm($iWeaponIdx)
	local $sSel = GUICtrlRead($g_idScWeaponBase)
	local $i
	if ($sSel <> "Auto" and $sSel <> "") then
		for $i = 0 to UBound($g_aiScWeaponBaseIndex) - 1
			local $iRow = $g_aiScWeaponBaseIndex[$i]
			local $sLabel = SpeedCalc_StripTier($g_avScWeaponBases[$iRow][1]) & " (" & $g_avScWeaponBases[$iRow][3] & ")"
			if ($sLabel == $sSel) then return $g_avScWeaponBases[$iRow][3]
		next
	endif
	if ($g_iScLiveFileIndex and $g_iScWeaponBaseCount) then
		for $i = 0 to $g_iScWeaponBaseCount - 1
			if ($g_avScWeaponBases[$i][0] == $g_iScLiveFileIndex) then return $g_avScWeaponBases[$i][3]
		next
		if ($g_sScLiveWeaponName <> "" and $iWeaponIdx >= 0) then
			local $sFamily = $g_avScWeaponTypes[$iWeaponIdx][0]
			for $i = 0 to $g_iScWeaponBaseCount - 1
				if ($g_avScWeaponBases[$i][5] == $sFamily and SpeedCalc_StripTier($g_avScWeaponBases[$i][1]) == $g_sScLiveWeaponName) then return $g_avScWeaponBases[$i][3]
			next
		endif
	endif
	return $g_iScLiveWsm
endfunc

func SpeedCalc_SelectedBaseName($iWsm)
	local $sSel = GUICtrlRead($g_idScWeaponBase)
	if ($sSel <> "Auto" and $sSel <> "") then return $sSel
	if ($g_sScLiveWeaponName <> "") then return $g_sScLiveWeaponName & " (" & $iWsm & ")"
	return "WSM " & $iWsm
endfunc

func SpeedCalc_Refresh($bForce = False)
	if (not $g_idScClass) then return
	SpeedCalc_InitCof()

	local $bMerc = SpeedCalc_IsMercChecked()
	if ($bMerc <> $g_bScLastMerc) then
		SpeedCalc_RebuildClassCombo($bMerc)
		$g_bScLastMerc = $bMerc
		$bForce = True
	endif

	SpeedCalc_ReadLive()
	SpeedCalc_EnsureWeaponCatalog()

	local $sCharToken = SpeedCalc_CurrentCharToken()
	if ($sCharToken <> $g_sScLastCharToken) then
		SpeedCalc_RebuildWeaponTypeCombo($sCharToken)
		$g_sScLastCharToken = $sCharToken
		$bForce = True
	endif

	local $iWeaponIdx = SpeedCalc_SelectedWeaponTypeIndex($sCharToken)
	local $sFamilyToken = ($iWeaponIdx >= 0) ? $g_avScWeaponTypes[$iWeaponIdx][0] : ""
	if ($sFamilyToken <> $g_sScLastFamilyToken or $g_iScWeaponBaseCount <> $g_iScLastBaseCatalogCount) then
		SpeedCalc_RebuildWeaponBaseCombo($sFamilyToken)
		$g_sScLastFamilyToken = $sFamilyToken
		$g_iScLastBaseCatalogCount = $g_iScWeaponBaseCount
		$bForce = True
	endif

	local $bCanDw = False, $bCanThrow = False
	if (not $bMerc and $iWeaponIdx >= 0) then
		if ($sCharToken == "AI") then
			$bCanDw = ($sFamilyToken == "h2h")
		elseif ($sCharToken == "BA") then
			$bCanDw = not SpeedCalc_BarbDwExcluded($sFamilyToken)
		endif
		$bCanThrow = SpeedCalc_IsThrowingFamily($sFamilyToken) and not SpeedCalc_ThrowingDisallowed($sCharToken)
	endif
	if ($bCanDw) then
		GUICtrlSetState($g_idScDualWield, $GUI_SHOW)
	else
		GUICtrlSetState($g_idScDualWield, $GUI_UNCHECKED)
		GUICtrlSetState($g_idScDualWield, $GUI_HIDE)
	endif
	if ($bCanThrow) then
		GUICtrlSetState($g_idScThrowing, $GUI_SHOW)
	else
		GUICtrlSetState($g_idScThrowing, $GUI_UNCHECKED)
		GUICtrlSetState($g_idScThrowing, $GUI_HIDE)
	endif

	local $iWsm = SpeedCalc_SelectedWsm($iWeaponIdx)
	local $iIas = SpeedCalc_ReadOverride($g_idScIas)
	if ($iIas == Default) then $iIas = $g_iScLiveIas
	local $iSkillIas = SpeedCalc_ReadOverride($g_idScSkillIas)
	if ($iSkillIas == Default) then $iSkillIas = $g_iScLiveSkillIas
	local $iFcr = SpeedCalc_ReadOverride($g_idScFcr)
	if ($iFcr == Default) then $iFcr = $g_iScLiveFcr
	local $iFhr = SpeedCalc_ReadOverride($g_idScFhr)
	if ($iFhr == Default) then $iFhr = $g_iScLiveFhr
	local $iFbr = SpeedCalc_ReadOverride($g_idScFbr)
	if ($iFbr == Default) then $iFbr = $g_iScLiveFbr
	local $iSkillFhr = $g_iScLiveSkillFhr
	local $iSlow = SpeedCalc_SelectedDebuffValue()
	local $bDw = $bCanDw and BitAND(GUICtrlRead($g_idScDualWield), $GUI_CHECKED)
	local $bTh = $bCanThrow and BitAND(GUICtrlRead($g_idScThrowing), $GUI_CHECKED)

	local $sWeaponName = ($iWeaponIdx >= 0) ? $g_avScWeaponTypes[$iWeaponIdx][1] : "?"
	local $sStatus = SpeedCalc_DisplayClassName($sCharToken) & " | " & $sWeaponName & " | " & SpeedCalc_SelectedBaseName($iWsm)
	$sStatus &= " | IAS " & $iIas & "/" & $iSkillIas & " FCR " & $iFcr & " FHR " & $iFhr & "/" & $iSkillFhr & " FBR " & $iFbr
	GUICtrlSetData($g_idScStatus, $sStatus)

	local $sSig = $sCharToken & "|" & $iWeaponIdx & "|" & $iWsm & "|" & $iIas & "|" & $iSkillIas & "|" & $iFcr & "|" & $iFhr & "|" & $iFbr & "|" & $iSkillFhr & "|" & $iSlow & "|" & $bDw & "|" & $bTh
	if (not $bForce and $sSig == $g_sScLastTableSig) then return
	$g_sScLastTableSig = $sSig

	local $sPrimary = SpeedCalc_EffectiveAnim($iWeaponIdx, $iWsm, "A1")
	local $sBlock = ($iWeaponIdx >= 0) ? $g_avScWeaponTypes[$iWeaponIdx][3] : "1HS"
	local $sAllAnims, $sCastPrefix, $sBlPrefix, $iBlAnimSpeed
	local $bOverride = SpeedCalc_CharOverride($sCharToken, $sAllAnims, $sCastPrefix, $sBlPrefix, $iBlAnimSpeed)

	local $iAnim
	for $iAnim = 0 to 3
		SpeedCalc_FillTable($iAnim, $sCharToken, $g_asScAnimTypes[$iAnim], $sPrimary, $sBlock, $iWsm, $iIas, $iSkillIas, $iFcr, $iFhr, $iFbr, $iSkillFhr, $iSlow, $bDw, $bTh, $bOverride, $iBlAnimSpeed)
	next
endfunc

func SpeedCalc_FillTable($iAnim, $sCharToken, $sAnimType, $sPrimary, $sBlock, $iWsm, $iIas, $iSkillIas, $iFcr, $iFhr, $iFbr, $iSkillFhr, $iSlow, $bDw, $bTh, $bOverride, $iBlAnimSpeed)
	local $id = $g_idScTable[$iAnim]
	_GUICtrlListView_BeginUpdate($id)
	_GUICtrlListView_DeleteAllItems($id)

	local $sPrefix, $sWeaponAnim
	if (not SpeedCalc_ResolveAnim($sCharToken, $sAnimType, $sPrimary, $sBlock, $bDw, $bTh, $sPrefix, $sWeaponAnim)) then
		_GUICtrlListView_AddItem($id, "-")
		_GUICtrlListView_AddSubItem($id, 0, "n/a", 1)
		_GUICtrlListView_EndUpdate($id)
		return
	endif

	local $iFrames, $iAnimSpeed
	if (not SpeedCalc_LookupCof($sCharToken & $sPrefix & $sWeaponAnim, $iFrames, $iAnimSpeed)) then
		_GUICtrlListView_AddItem($id, "-")
		_GUICtrlListView_AddSubItem($id, 0, "no COF", 1)
		_GUICtrlListView_EndUpdate($id)
		return
	endif
	if ($sAnimType == "BL" and $iBlAnimSpeed >= 0) then $iAnimSpeed = $iBlAnimSpeed

	local $bStart = SpeedCalc_HasStartingFrame($sCharToken, $sPrimary, $bOverride, $bTh)
	local $iThrowPen = ($sAnimType == "A1" and $bTh and $sPrefix <> "TH") ? 30 : 0
	local $iCurrentStat
	switch $sAnimType
		case "A1"
			$iCurrentStat = $iIas
		case "SC"
			$iCurrentStat = $iFcr
		case "GH"
			$iCurrentStat = $iFhr
		case "BL"
			$iCurrentStat = $iFbr
	endswitch

	local $iMaxFpa = SpeedCalc_CalcFpaForStat(0, $sAnimType, $iFrames, $iAnimSpeed, $iWsm, $iSkillIas, $iSkillFhr, $iSlow, $bStart, $iThrowPen)
	local $iMinFpa = SpeedCalc_CalcFpaForStat(500, $sAnimType, $iFrames, $iAnimSpeed, $iWsm, $iSkillIas, $iSkillFhr, $iSlow, $bStart, $iThrowPen)
	local $iCurrentFpa = SpeedCalc_CalcFpaForStat($iCurrentStat, $sAnimType, $iFrames, $iAnimSpeed, $iWsm, $iSkillIas, $iSkillFhr, $iSlow, $bStart, $iThrowPen)

	local $avRows[1][2]
	local $iCount = 0, $iCurrentIdx = -1
	local $iFpa, $iReq, $iPrevFpa = -1, $iPrevReq = -1
	for $iFpa = $iMaxFpa to $iMinFpa step -1
		$iReq = SpeedCalc_FindRequired($iFpa, $sAnimType, $iFrames, $iAnimSpeed, $iWsm, $iSkillIas, $iSkillFhr, $iSlow, $bStart, $iThrowPen)
		if ($iReq < 0) then continueloop
		if ($iFpa == $iPrevFpa) then continueloop
		local $iActual = SpeedCalc_CalcFpaForStat($iReq, $sAnimType, $iFrames, $iAnimSpeed, $iWsm, $iSkillIas, $iSkillFhr, $iSlow, $bStart, $iThrowPen)
		if ($iActual <> $iFpa) then continueloop
		if ($iReq == $iPrevReq) then continueloop

		$iCount += 1
		ReDim $avRows[$iCount][2]
		$avRows[$iCount - 1][0] = $iFpa
		$avRows[$iCount - 1][1] = $iReq
		if ($iFpa == $iCurrentFpa) then $iCurrentIdx = $iCount - 1
		$iPrevFpa = $iFpa
		$iPrevReq = $iReq
	next

	local $iStart = ($iCurrentIdx >= 0) ? $iCurrentIdx : 0
	local $k, $iIdx, $sReq, $iRow = 0
	for $k = 0 to $iCount - 1
		$iIdx = Mod($iStart + $k, $iCount)
		$sReq = $avRows[$iIdx][1]
		if ($k == 1 and $avRows[$iIdx][0] < $iCurrentFpa and $avRows[$iIdx][1] > $iCurrentStat) then
			$sReq &= " +" & ($avRows[$iIdx][1] - $iCurrentStat)
		endif
		_GUICtrlListView_AddItem($id, $avRows[$iIdx][0])
		_GUICtrlListView_AddSubItem($id, $iRow, $sReq, 1)
		$iRow += 1
	next

	if ($iCount > 0) then _GUICtrlListView_SetItemSelected($id, 0, True, True)
	_GUICtrlListView_EndUpdate($id)
endfunc
#EndRegion
