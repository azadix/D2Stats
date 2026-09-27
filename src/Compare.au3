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
        ; Create our own dialog instead of using _ArrayDisplay
        ShowStatDiffDialog($g_statDiff)
    else
        PrintString("No stat differences found.", $ePrintBlue)
    endif
    
    if ($bReplaceSnapshot) then
        $g_aiStatsCacheCopy = $g_aiStatsCache
    endif
endfunc

func ShowStatDiffDialog($aStats)
    ; Store current option settings
    Local $oldOptGUIOnEventMode = Opt("GUIOnEventMode", 0)
    Local $oldOptGUICloseOnESC = Opt("GUICloseOnESC", 1)

    ; Check overlay state before creating dialog
    Local $bOverlayWasVisible = ($g_hOverlayGUI <> 0 And WinExists($g_hOverlayGUI))    
    Local $hDiffGUI = GUICreate("Stat Differences", 860, 600, -1, -1, BitOR($WS_CAPTION, $WS_POPUPWINDOW, $WS_SIZEBOX), $WS_EX_TOOLWINDOW, $g_hGUI)
    
    If $hDiffGUI = 0 Then
        Opt("GUIOnEventMode", $oldOptGUIOnEventMode)
        Opt("GUICloseOnESC", $oldOptGUICloseOnESC)
        Return
    EndIf

    GUISetFont(10, 400, 0, "Courier New")
    GUISetBkColor(0xFFFFFF)
    
    Local $idList = GUICtrlCreateListView("ID|Name|Old|New|Diff", 10, 10, 840, 550)
    GUICtrlSetFont(-1, 10, 400, 0, "Courier New")
    GUICtrlSetBkColor(-1, 0xFFFFFF)
    
    _GUICtrlListView_SetExtendedListViewStyle($idList, BitOR($LVS_EX_GRIDLINES, $LVS_EX_FULLROWSELECT))

    ; Set column widths
    _GUICtrlListView_SetColumnWidth($idList, 0, 60)   ; Stat ID
    _GUICtrlListView_SetColumnWidth($idList, 1, 450)  ; Name
    _GUICtrlListView_SetColumnWidth($idList, 2, 80)   ; Old
    _GUICtrlListView_SetColumnWidth($idList, 3, 80)   ; New
    _GUICtrlListView_SetColumnWidth($idList, 4, 80)   ; Diff

    ; Add data to listview
    For $i = 0 To UBound($aStats) - 1
        GUICtrlCreateListViewItem($aStats[$i][0] & "|" & $aStats[$i][1] & "|" & $aStats[$i][2] & "|" & $aStats[$i][3] & "|" & $aStats[$i][4], $idList)
    Next

    Local $idClose = GUICtrlCreateButton("Close", 380, 570, 100, 25)

    GUISetState(@SW_SHOW, $hDiffGUI)
    WinActivate($hDiffGUI)
    
    ; Message loop
	Local $iMsg = 0
	Local $iLoopCount = 0

	While WinExists($hDiffGUI)
		; Only process messages occasionally to reduce CPU usage
		If Mod($iLoopCount, 5) = 0 Then
			$iMsg = GUIGetMsg(1)
			
			If $iMsg[0] <> 0 And $iMsg[1] = $hDiffGUI Then
				
				Switch $iMsg[0]
					Case $GUI_EVENT_CLOSE
						ExitLoop
					Case $idClose
						ExitLoop
				EndSwitch
			EndIf
		EndIf
		
		; Check for ESC key
		If _IsPressed("1B") Then ; ESC key
			ExitLoop
		EndIf
		
		$iLoopCount += 1
		Sleep(5)
	WEnd

    ; Cleanup
	GUIDelete($hDiffGUI)

    ; Restore original options
    Opt("GUIOnEventMode", $oldOptGUIOnEventMode)
    Opt("GUICloseOnESC", $oldOptGUICloseOnESC)
    
    ; Call overlay recovery
    RecoverOverlay()

    If Not $g_bCleanupRunning Then
		AdlibRegister("CleanUpExpiredText", 100)
		$g_bCleanupRunning = True
	EndIf
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
	local $sFilter = GUICtrlRead($g_idCompareFilter)
	local $sName, $iIndex
	local $hList = GetCompareListHandle()

	AdlibUnRegister("EnableCompareSave")
	$g_bCompareSaveSuspend = True
	_GUICtrlListView_BeginUpdate($hList)
	; Native DeleteAllItems treats ItemParam as a control ID and can delete tab items.
	_SendMessage($hList, $LVM_DELETEALLITEMS)

	for $i = 0 to $g_iNumStats - 1
		$sName = GetCompareStatName($i)
		if ($sFilter <> "") then
			if (StringInStr($sName, $sFilter, $STR_NOCASESENSEBASIC) == 0 and StringInStr(String($i), $sFilter) == 0) then continueloop
		endif
		$iIndex = _GUICtrlListView_AddItem($hList, $i)
		_GUICtrlListView_AddSubItem($hList, $iIndex, $sName, 1)
		_GUICtrlListView_SetItemChecked($hList, $iIndex, $g_abCompareEnabled[$i])
	next

	_GUICtrlListView_EndUpdate($hList)
	AdlibRegister("EnableCompareSave", 100)
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
	local $iCount = _GUICtrlListView_GetItemCount($g_idCompareList)
	local $iStatId

	$g_bCompareSaveSuspend = True
	for $i = 0 to $iCount - 1
		$iStatId = GetCompareListStatId($i)
		if ($iStatId >= 0 and $iStatId < $g_iNumStats) then $g_abCompareEnabled[$iStatId] = $bEnabled
		_GUICtrlListView_SetItemChecked($g_idCompareList, $i, $bEnabled)
	next
	$g_bCompareSaveSuspend = False
	SaveGUICompare()
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
	local $iBottomButtonCoords = $g_iGUIHeight - 30
	GUICtrlCreateTabItem("Compare")
	$g_iTabCompare = GUICtrlSendMsg($g_idTab, $TCM_GETITEMCOUNT, 0, 0) - 1
	local $iFilterY = _GUI_LineY(0)
	local $iCompareBtnW = 50
	local $iFilterW = $g_iGUIWidth - 8 - 2 * $iCompareBtnW - 8
	$g_idCompareFilter = GUICtrlCreateInput("", 4, $iFilterY, $iFilterW, 22)
	GUICtrlCreateButton("All", 4 + $iFilterW + 4, $iFilterY, $iCompareBtnW, 22)
	GUICtrlSetOnEvent(-1, "OnClick_CompareAll")
	GUICtrlCreateButton("None", 4 + $iFilterW + 8 + $iCompareBtnW, $iFilterY, $iCompareBtnW, 22)
	GUICtrlSetOnEvent(-1, "OnClick_CompareNone")

	local $iListY = $iFilterY + 26
	local $iListH = $iBottomButtonCoords - $iListY - 5
	$g_idCompareList = GUICtrlCreateListView("ID|Name", 4, $iListY, $g_iGUIWidth - 8, $iListH, BitOR($LVS_REPORT, $GUI_SS_DEFAULT_LISTVIEW, $LVS_NOSORTHEADER))
	_GUICtrlListView_SetExtendedListViewStyle($g_idCompareList, BitOR($LVS_EX_CHECKBOXES, $LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, $LVS_EX_DOUBLEBUFFER))
	_GUICtrlListView_SetColumnWidth($g_idCompareList, 0, 50)
	_GUICtrlListView_SetColumnWidth($g_idCompareList, 1, $g_iGUIWidth - 90)
	LoadGUICompare()
	RefreshCompareList()
endfunc
#EndRegion
