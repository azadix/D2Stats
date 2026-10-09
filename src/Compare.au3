#include-once

#Region Compare globals
global $g_abCompareEnabled[$g_iNumStats]
global $g_idCompareList = 0, $g_idCompareFilter = 0
global $g_iTabCompare = -1
global $g_bCompareSaveSuspend = False
global $g_bCompareDirty = False
#EndRegion

#Region Compare
func OnClick_ShowDiff()
	CompareStats(False)
endfunc

func OnClick_ShowDiffAndReplace()
	CompareStats(True)
endfunc

func CompareStats($bReplaceSnapshot = True)
    UpdateStatValues()
    UpdateGUI()
    
    ;Compare stats
    local $statDiffCount = 0
    local $g_statDiff[0][5]
    local $sName
    for $i = 0 To $g_iNumStats - 1
        if (not $g_abCompareEnabled[$i]) then continueloop

        if ($g_aiStatsCacheCopy[0][$i] <> $g_aiStatsCache[0][$i]) then
            $sName = $g_d2StatNames[$i][1]
            _ArrayAdd($g_statDiff, $i & "|" & _
                                $sName & "|" & _
                                $g_aiStatsCacheCopy[0][$i] & "|" & _
                                $g_aiStatsCache[0][$i] & "|" & _
                                $g_aiStatsCache[0][$i]-$g_aiStatsCacheCopy[0][$i])
            $statDiffCount += 1
        endif
        if ($g_aiStatsCacheCopy[1][$i] <> $g_aiStatsCache[1][$i]) then
            $sName = $g_d2StatNames[$i][3]
            _ArrayAdd($g_statDiff, $i & "|" & _
                                $sName & "|" & _
                                $g_aiStatsCacheCopy[1][$i] & "|" & _
                                $g_aiStatsCache[1][$i] & "|" & _
                                $g_aiStatsCache[1][$i]-$g_aiStatsCacheCopy[1][$i])
            $statDiffCount += 1
        endif
    next
    
    if ($statDiffCount > 0) then
        ShowStatDiffDialog($g_statDiff)
    else
        PrintString("No stat differences found.", $ePrintBlue)
    endif
    
    if ($bReplaceSnapshot) then
        $g_aiStatsCacheCopy = $g_aiStatsCache
    endif
endfunc

func ShowStatDiffDialog($aStats)
	Ui_ClearDiff()
	Local $i
	For $i = 0 To UBound($aStats) - 1
		Ui_AddDiffRow($aStats[$i][0], $aStats[$i][1], $aStats[$i][2], $aStats[$i][3], $aStats[$i][4])
	Next
	Ui_ShowDiff(True)
EndFunc

func GetCompareStatName($iStat)
	local $sName1 = $g_d2StatNames[$iStat][1]
	local $sName2 = $g_d2StatNames[$iStat][3]
	if ($sName1 <> "" and $sName2 <> "") then return $sName1 & " / " & $sName2
	if ($sName2 <> "") then return $sName2
	if ($sName1 <> "") then return $sName1
	return ""
endfunc

func GetCompareListHandle()
	return GUICtrlGetHandle($g_idCompareList)
endfunc

func GetCompareListStatId($iIndex)
	return Int(_GUICtrlListView_GetItemText($g_idCompareList, $iIndex, 0))
endfunc

func RefreshCompareList()
	local $sFilter = $g_sCompareFilter
	local $sName
	Ui_ClearCompareList()
	for $i = 0 to $g_iNumStats - 1
		$sName = GetCompareStatName($i)
		if ($sFilter <> "") then
			if (StringInStr($sName, $sFilter, $STR_NOCASESENSEBASIC) == 0 and StringInStr(String($i), $sFilter) == 0) then continueloop
		endif
		Ui_AddCompareItem($i, $sName, $g_abCompareEnabled[$i])
	next
endfunc

func EnableCompareSave()
	AdlibUnRegister("EnableCompareSave")
	$g_bCompareSaveSuspend = False
endfunc

func OnChange_CompareFilter()
	RefreshCompareList()
endfunc

func OnClick_CompareAll()
	SetVisibleCompareEnabled(True)
endfunc

func OnClick_CompareNone()
	SetVisibleCompareEnabled(False)
endfunc

func SetVisibleCompareEnabled($bEnabled)
	local $sFilter = $g_sCompareFilter
	local $sName, $i
	for $i = 0 to $g_iNumStats - 1
		$sName = GetCompareStatName($i)
		if ($sFilter <> "") then
			if (StringInStr($sName, $sFilter, $STR_NOCASESENSEBASIC) == 0 and StringInStr(String($i), $sFilter) == 0) then continueloop
		endif
		$g_abCompareEnabled[$i] = $bEnabled
	next
	SaveGUICompare()
	RefreshCompareList()
endfunc

func SaveGUICompare()
	IniWriteSection($g_sSettingsIni, "Compare", "off=" & CompareDisabledToString())
	$g_bCompareDirty = False
endfunc

func LoadGUICompare()
	local $i
	for $i = 0 to $g_iNumStats - 1
		$g_abCompareEnabled[$i] = True
	next

	local $asIniCompare = IniReadSection($g_sSettingsIni, "Compare")
	if (@error) then return

	local $sKey, $sValue, $iIndex, $bOldFormat = False
	for $i = 1 to $asIniCompare[0][0]
		$sKey = $asIniCompare[$i][0]
		$sValue = $asIniCompare[$i][1]
		if ($sKey = "off" or $sKey = "disabled") then
			ApplyCompareDisabledString($sValue)
		else
			$iIndex = Int($sKey)
			if (StringIsDigit($sKey) and $iIndex >= 0 and $iIndex < $g_iNumStats) then
				$g_abCompareEnabled[$iIndex] = (Int($sValue) <> 0)
				$bOldFormat = True
			endif
		endif
	next

	if ($bOldFormat) then SaveGUICompare()
endfunc

func CompareDisabledToString()
	local $sOut = ""
	local $iStart = -1
	local $bOff, $i

	for $i = 0 to $g_iNumStats
		$bOff = ($i < $g_iNumStats and not $g_abCompareEnabled[$i])
		if ($bOff) then
			if ($iStart < 0) then $iStart = $i
		elseif ($iStart >= 0) then
			if ($sOut <> "") then $sOut &= ","
			if ($iStart = $i - 1) then
				$sOut &= $iStart
			else
				$sOut &= $iStart & "-" & ($i - 1)
			endif
			$iStart = -1
		endif
	next

	return $sOut
endfunc

func ApplyCompareDisabledString($sOff)
	if ($sOff = "") then return

	local $aParts = StringSplit($sOff, ",", $STR_NOCOUNT)
	local $sPart, $aRange, $iFrom, $iTo, $i, $j

	for $i = 0 to UBound($aParts) - 1
		$sPart = StringStripWS($aParts[$i], BitOR($STR_STRIPLEADING, $STR_STRIPTRAILING))
		if ($sPart = "") then continueloop

		if (StringInStr($sPart, "-")) then
			$aRange = StringSplit($sPart, "-", $STR_NOCOUNT)
			if (UBound($aRange) < 2) then continueloop
			$iFrom = Int($aRange[0])
			$iTo = Int($aRange[1])
		else
			$iFrom = Int($sPart)
			$iTo = $iFrom
		endif

		if ($iFrom > $iTo) then
			$j = $iFrom
			$iFrom = $iTo
			$iTo = $j
		endif
		if ($iFrom < 0) then $iFrom = 0
		if ($iTo >= $g_iNumStats) then $iTo = $g_iNumStats - 1

		for $j = $iFrom to $iTo
			$g_abCompareEnabled[$j] = False
		next
	next
endfunc

func Compare_CreateTab()
	$g_iTabCompare = 5
	LoadGUICompare()
	RefreshCompareList()
endfunc
#EndRegion
