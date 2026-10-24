#include-once

#Region UiBridge globals
global $g_hUiDll = -1
global $g_hGUI = 0
global $g_bReadMercenary = False
global $g_iCurrentStatTab = 0
global $g_iTabSpeedCalc = 4
global $g_iTabCompare = 5
global const $tagD2UiEvent = "int type;int i0;int i1;int i2;wchar key[64];wchar text[1024]"
global const $D2UI_EVT_CLOSE = 1
global const $D2UI_EVT_READ = 2
global const $D2UI_EVT_COMPARE = 3
global const $D2UI_EVT_COMPARE_REPLACE = 4
global const $D2UI_EVT_MERCENARY = 5
global const $D2UI_EVT_TAB = 6
global const $D2UI_EVT_OPTION = 7
global const $D2UI_EVT_NOTIFY_SAVE = 8
global const $D2UI_EVT_NOTIFY_RESET = 9
global const $D2UI_EVT_NOTIFY_HELP = 10
global const $D2UI_EVT_NOTIFY_DEFAULT = 11
global const $D2UI_EVT_NOTIFY_NEW = 12
global const $D2UI_EVT_NOTIFY_RENAME = 13
global const $D2UI_EVT_NOTIFY_DELETE = 14
global const $D2UI_EVT_NOTIFY_RULES = 15
global const $D2UI_EVT_VOLUME = 16
global const $D2UI_EVT_VOLUME_TEST = 17
global const $D2UI_EVT_FORUM = 18
global const $D2UI_EVT_COMPARE_FILTER = 19
global const $D2UI_EVT_COMPARE_TOGGLE = 20
global const $D2UI_EVT_COMPARE_ALL = 21
global const $D2UI_EVT_COMPARE_NONE = 22
global const $D2UI_EVT_SC_COMBO = 23
global const $D2UI_EVT_SC_INPUT = 24
global const $D2UI_EVT_SC_CHECK = 25
global const $D2UI_EVT_HOTKEY = 26
global const $D2UI_EVT_NOTIFIER_COLOR = 27
global $g_aiVolume[6] = [5, 5, 5, 5, 5, 5]
global $g_sCompareFilter = ""
#EndRegion

func Ui_DllPath()
	local $sPath = @ScriptDir & "\d2stats_ui.dll"
	if (FileExists($sPath)) then return $sPath
	return @ScriptDir & "\d2stats_ui.dll"
endfunc

func Ui_Init($sTitle, $iWidth, $iHeight)
	local $sDll = Ui_DllPath()
	$g_hUiDll = DllOpen($sDll)
	if ($g_hUiDll == -1) then
		MsgBox($MB_ICONERROR, "D2Stats", "Could not load d2stats_ui.dll. Build the ImGui UI library first (Compile.bat).")
		exit
	endif

	local $sIcon = @Compiled ? @AutoItExe : (@ScriptDir & "\Assets\icon.ico")
	local $aRet = DllCall($g_hUiDll, "int", "D2Ui_Init", "wstr", $sTitle, "int", $iWidth, "int", $iHeight, "wstr", $sIcon)
	if (@error or $aRet[0] == 0) then
		MsgBox($MB_ICONERROR, "D2Stats", "Failed to initialize the ImGui UI.")
		exit
	endif

	local $aHwnd = DllCall($g_hUiDll, "ptr", "D2Ui_GetMainHwnd")
	if (not @error) then $g_hGUI = HWnd($aHwnd[0])
endfunc

func Ui_Shutdown()
	if ($g_hUiDll <> -1) then
		DllCall($g_hUiDll, "none", "D2Ui_Shutdown")
		DllClose($g_hUiDll)
		$g_hUiDll = -1
	endif
	$g_hGUI = 0
endfunc

func Ui_Tick()
	if ($g_hUiDll == -1) then return False
	local $aRet = DllCall($g_hUiDll, "int", "D2Ui_Tick")
	if (@error) then return False
	return $aRet[0] <> 0
endfunc

func Ui_GetActiveTab()
	local $aRet = DllCall($g_hUiDll, "int", "D2Ui_GetActiveTab")
	if (@error) then return 0
	return $aRet[0]
endfunc

func Ui_Print($sText, $iColorRgb, $iTimeoutMs)
	DllCall($g_hUiDll, "none", "D2Ui_Print", "wstr", $sText, "dword", $iColorRgb, "int", $iTimeoutMs)
endfunc

func Ui_OverlayAddGap()
	DllCall($g_hUiDll, "none", "D2Ui_OverlayAddGap")
endfunc

func Ui_OverlayClear()
	DllCall($g_hUiDll, "none", "D2Ui_OverlayClear")
endfunc

func Ui_OverlaySetTarget($iX, $iY, $iW, $iH, $bVisible)
	DllCall($g_hUiDll, "none", "D2Ui_OverlaySetTarget", "int", $iX, "int", $iY, "int", $iW, "int", $iH, "int", $bVisible ? 1 : 0)
endfunc

func Ui_OverlayConfigure($sFont, $iSize, $iTimeout, $bContrast)
	DllCall($g_hUiDll, "none", "D2Ui_OverlayConfigure", "wstr", $sFont, "int", $iSize, "int", $iTimeout, "int", $bContrast ? 1 : 0)
endfunc

func Ui_OverlayIsVisible()
	local $aRet = DllCall($g_hUiDll, "int", "D2Ui_OverlayIsVisible")
	if (@error) then return False
	return $aRet[0] <> 0
endfunc

func Ui_ClearStats()
	DllCall($g_hUiDll, "none", "D2Ui_ClearStats")
endfunc

func Ui_AddStat($iTab, $iGroup, $iLine, $sText, $sTip, $iColor, $bHeader)
	local $aRet = DllCall($g_hUiDll, "int", "D2Ui_AddStat", "int", $iTab, "int", $iGroup, "int", $iLine, "wstr", $sText, "wstr", $sTip, "int", $iColor, "int", $bHeader ? 1 : 0)
	if (@error) then return -1
	return $aRet[0]
endfunc

func Ui_UpdateStat($iIndex, $sText, $iColor)
	DllCall($g_hUiDll, "none", "D2Ui_UpdateStat", "int", $iIndex, "wstr", $sText, "int", $iColor)
endfunc

func Ui_SetMercenary($bChecked)
	$g_bReadMercenary = $bChecked
	DllCall($g_hUiDll, "none", "D2Ui_SetMercenary", "int", $bChecked ? 1 : 0)
endfunc

func Ui_ClearOptions()
	DllCall($g_hUiDll, "none", "D2Ui_ClearOptions")
endfunc

func Ui_AddOption($iGroup, $sKey, $sType, $sLabel, $iInt, $sStr, $sSection = "")
	DllCall($g_hUiDll, "none", "D2Ui_AddOption", "int", $iGroup, "wstr", $sKey, "wstr", $sType, "wstr", $sLabel, "int", $iInt, "wstr", $sStr, "wstr", $sSection)
endfunc

func Ui_SetNotifierColor($iIndex, $iColor)
	DllCall($g_hUiDll, "none", "D2Ui_SetNotifierColor", "int", $iIndex, "dword", $iColor)
endfunc

func Ui_PushNotifierColors()
	local $i
	for $i = 0 to 11
		Ui_SetNotifierColor($i, $g_NotifierColorArray[$i])
	next
endfunc

func Ui_SetOptionChoices($sKey, $sPipe)
	DllCall($g_hUiDll, "none", "D2Ui_SetOptionChoices", "wstr", $sKey, "wstr", $sPipe)
endfunc

func Ui_SetNotifyRules($sPipe, $sSelected)
	DllCall($g_hUiDll, "none", "D2Ui_SetNotifyRules", "wstr", $sPipe, "wstr", $sSelected)
endfunc

func Ui_SetNotifierText($sText)
	DllCall($g_hUiDll, "none", "D2Ui_SetNotifierText", "wstr", $sText)
endfunc

func Ui_SetNotifierEdit($sText)
	DllCall($g_hUiDll, "none", "D2Ui_SetNotifierEdit", "wstr", $sText)
endfunc

func Ui_GetNotifierText()
	local $aLen = DllCall($g_hUiDll, "int", "D2Ui_GetNotifierText", "ptr", 0, "int", 0)
	local $iLen = (@error or $aLen[0] < 1) ? 1 : $aLen[0]
	local $t = DllStructCreate("wchar[" & ($iLen + 2) & "]")
	DllCall($g_hUiDll, "int", "D2Ui_GetNotifierText", "ptr", DllStructGetPtr($t), "int", $iLen + 2)
	if (@error) then return ""
	return DllStructGetData($t, 1)
endfunc

func Ui_IsNotifierDirty()
	local $aRet = DllCall($g_hUiDll, "int", "D2Ui_IsNotifierDirty")
	if (@error) then return False
	return $aRet[0] <> 0
endfunc

func Ui_GetNotifyRulesSelected()
	local $t = DllStructCreate("wchar[256]")
	DllCall($g_hUiDll, "int", "D2Ui_GetNotifyRulesSelected", "ptr", DllStructGetPtr($t), "int", 256)
	if (@error) then return ""
	return DllStructGetData($t, 1)
endfunc

func Ui_SetVolume($iIndex, $iValue)
	if ($iIndex >= 0 and $iIndex < 6) then $g_aiVolume[$iIndex] = $iValue
	DllCall($g_hUiDll, "none", "D2Ui_SetVolume", "int", $iIndex, "int", $iValue)
endfunc

func Ui_GetVolume($iIndex)
	if ($iIndex >= 0 and $iIndex < 6) then return $g_aiVolume[$iIndex]
	return 0
endfunc

func Ui_ClearCompareList()
	DllCall($g_hUiDll, "none", "D2Ui_ClearCompareList")
endfunc

func Ui_AddCompareItem($iStatId, $sName, $bEnabled)
	DllCall($g_hUiDll, "none", "D2Ui_AddCompareItem", "int", $iStatId, "wstr", $sName, "int", $bEnabled ? 1 : 0)
endfunc

func Ui_ShowDiff($bShow)
	DllCall($g_hUiDll, "none", "D2Ui_ShowDiff", "int", $bShow ? 1 : 0)
endfunc

func Ui_ClearDiff()
	DllCall($g_hUiDll, "none", "D2Ui_ClearDiff")
endfunc

func Ui_AddDiffRow($iStatId, $sName, $sOld, $sNew, $sDiff)
	DllCall($g_hUiDll, "none", "D2Ui_AddDiffRow", "int", $iStatId, "wstr", $sName, "wstr", $sOld, "wstr", $sNew, "wstr", $sDiff)
endfunc

func Ui_SetSpeedCalcCombo($iWhich, $sPipe, $sSelected)
	DllCall($g_hUiDll, "none", "D2Ui_SetSpeedCalcCombo", "int", $iWhich, "wstr", $sPipe, "wstr", $sSelected)
endfunc

func Ui_SetSpeedCalcInput($iWhich, $sValue)
	DllCall($g_hUiDll, "none", "D2Ui_SetSpeedCalcInput", "int", $iWhich, "wstr", $sValue)
endfunc

func Ui_SetSpeedCalcCheck($iWhich, $bChecked, $bVisible)
	DllCall($g_hUiDll, "none", "D2Ui_SetSpeedCalcCheck", "int", $iWhich, "int", $bChecked ? 1 : 0, "int", $bVisible ? 1 : 0)
endfunc

func Ui_SetSpeedCalcStatus($sStatus)
	DllCall($g_hUiDll, "none", "D2Ui_SetSpeedCalcStatus", "wstr", $sStatus)
endfunc

func Ui_SetSpeedCalcMorphEnabled($bEnabled)
	DllCall($g_hUiDll, "none", "D2Ui_SetSpeedCalcMorphEnabled", "int", $bEnabled ? 1 : 0)
endfunc

func Ui_ClearSpeedCalcTable($iTable)
	DllCall($g_hUiDll, "none", "D2Ui_ClearSpeedCalcTable", "int", $iTable)
endfunc

func Ui_AddSpeedCalcRow($iTable, $sFrm, $sValue)
	DllCall($g_hUiDll, "none", "D2Ui_AddSpeedCalcRow", "int", $iTable, "wstr", $sFrm, "wstr", $sValue)
endfunc

func Ui_SetSpeedCalcHighlight($iTable, $iRow)
	DllCall($g_hUiDll, "none", "D2Ui_SetSpeedCalcHighlight", "int", $iTable, "int", $iRow)
endfunc

func Ui_ApplyOverlayConfig()
	Ui_OverlayConfigure(OverlayFont(), OverlayInt("overlay-fontsize"), OverlayInt("overlay-timeout"), _GUI_Option("overlay-contrast"))
endfunc

func Ui_PushOptions()
	Ui_ClearOptions()
	local $i
	for $i = 0 to $g_iGUIOptionsGeneral - 1
		Ui_AddOption(0, $g_avGUIOptionList[$i][0], $g_avGUIOptionList[$i][2], $g_avGUIOptionList[$i][3], Int($g_avGUIOptionList[$i][1]), String($g_avGUIOptionList[$i][1]), String($g_avGUIOptionList[$i][5]))
	next
	local $iEnd = $g_iGUIOptionsGeneral + $g_iGUIOptionsHotkey - 1
	for $i = $g_iGUIOptionsGeneral to $iEnd
		Ui_AddOption(1, $g_avGUIOptionList[$i][0], $g_avGUIOptionList[$i][2], $g_avGUIOptionList[$i][3], Int($g_avGUIOptionList[$i][1]), String($g_avGUIOptionList[$i][1]), String($g_avGUIOptionList[$i][5]))
	next
	Ui_SetOptionChoices("overlay-font", _ArrayToString(OverlayGetMonospaceFonts(), "|"))
endfunc

func Ui_AssignHotkeys()
	local $i, $sOption, $sType, $sFunc, $iKey
	for $i = 0 to UBound($g_avGUIOptionList) - 1
		$sType = $g_avGUIOptionList[$i][2]
		if ($sType <> "hk") then continueloop
		$sOption = $g_avGUIOptionList[$i][0]
		$sFunc = $g_avGUIOptionList[$i][4]
		Call($sFunc, True)
		$iKey = Int(_GUI_Option($sOption))
		if ($iKey) then
			_KeyLock($iKey)
			_HotKey_Assign($iKey, $sFunc, $HK_FLAG_D2STATS, "[CLASS:Diablo II]")
		endif
	next
endfunc

func Ui_HandleOptionEvent($sKey, $iInt, $sStr)
	local $sType = _GUI_OptionType($sKey)
	if ($sType == "cb" or $sType == "int") then
		if ($sType == "int") then $iInt = ClampOverlayInt($sKey, $iInt)
		_GUI_Option($sKey, $iInt)
	elseif ($sType == "str") then
		_GUI_Option($sKey, $sStr)
	endif
	if (StringInStr($sKey, "overlay-") == 1) then
		if ($sKey == "overlay-fontsize" or $sKey == "overlay-font") then $g_sOverlayMetricsKey = ""
		Ui_ApplyOverlayConfig()
		UpdateOverlayPosition()
	endif
endfunc

func Ui_HandleHotkeyEvent($sKey, $iCode)
	local $iOption = _GUI_OptionID($sKey)
	if ($iOption < 0) then return
	local $sFunc = $g_avGUIOptionList[$iOption][4]
	local $iOld = Int(_GUI_Option($sKey))
	if ($iOld) then _HotKey_Assign($iOld, 0, $HK_FLAG_D2STATS)
	_GUI_Option($sKey, $iCode)
	if ($iCode) then _HotKey_Assign($iCode, $sFunc, $HK_FLAG_D2STATS, "[CLASS:Diablo II]")
endfunc

func Ui_DrainEvents()
	if ($g_hUiDll == -1) then return
	local $tEvt = DllStructCreate($tagD2UiEvent)
	while 1
		local $aRet = DllCall($g_hUiDll, "int", "D2Ui_PollEvent", "ptr", DllStructGetPtr($tEvt))
		if (@error or $aRet[0] == 0) then exitloop

		local $iType = DllStructGetData($tEvt, "type")
		local $i0 = DllStructGetData($tEvt, "i0")
		local $i1 = DllStructGetData($tEvt, "i1")
		local $sKey = DllStructGetData($tEvt, "key")
		local $sText = DllStructGetData($tEvt, "text")

		switch $iType
			case $D2UI_EVT_CLOSE
				_Exit()
			case $D2UI_EVT_READ
				OnClick_ReadStats()
			case $D2UI_EVT_COMPARE
				OnClick_ShowDiff()
			case $D2UI_EVT_COMPARE_REPLACE
				OnClick_ShowDiffAndReplace()
			case $D2UI_EVT_MERCENARY
				$g_bReadMercenary = $i0 <> 0
				SpeedCalc_OnMercenary()
			case $D2UI_EVT_TAB
				if ($i0 == $g_iTabSpeedCalc) then SpeedCalc_Refresh(True)
			case $D2UI_EVT_OPTION
				Ui_HandleOptionEvent($sKey, $i0, $sText)
			case $D2UI_EVT_HOTKEY
				Ui_HandleHotkeyEvent($sKey, $i0)
			case $D2UI_EVT_NOTIFY_SAVE
				OnClick_NotifySave()
			case $D2UI_EVT_NOTIFY_RESET
				OnClick_NotifyReset()
			case $D2UI_EVT_NOTIFY_HELP
				OnClick_NotifyHelp()
			case $D2UI_EVT_NOTIFY_DEFAULT
				OnClick_NotifyDefault()
			case $D2UI_EVT_NOTIFY_NEW
				OnClick_NotifyNew()
			case $D2UI_EVT_NOTIFY_RENAME
				OnClick_NotifyRename()
			case $D2UI_EVT_NOTIFY_DELETE
				OnClick_NotifyDelete()
			case $D2UI_EVT_NOTIFY_RULES
				OnChange_NotifyRulesCombo()
			case $D2UI_EVT_VOLUME
				Ui_SetVolume($i0, $i1)
				SaveGUIVolume()
			case $D2UI_EVT_VOLUME_TEST
				NotifierPlaySound($i0)
			case $D2UI_EVT_NOTIFIER_COLOR
				SetNotifierColor($i0, $i1)
			case $D2UI_EVT_FORUM
				OnClick_Forum()
			case $D2UI_EVT_COMPARE_FILTER
				$g_sCompareFilter = $sText
				RefreshCompareList()
			case $D2UI_EVT_COMPARE_TOGGLE
				if ($i0 >= 0 and $i0 < $g_iNumStats) then
					$g_abCompareEnabled[$i0] = $i1 <> 0
					$g_bCompareDirty = True
					SaveGUICompare()
				endif
			case $D2UI_EVT_COMPARE_ALL
				OnClick_CompareAll()
			case $D2UI_EVT_COMPARE_NONE
				OnClick_CompareNone()
			case $D2UI_EVT_SC_COMBO
				SpeedCalc_OnUiCombo($i0, $sText)
			case $D2UI_EVT_SC_INPUT
				SpeedCalc_OnUiInput($i0, $sText)
			case $D2UI_EVT_SC_CHECK
				SpeedCalc_OnUiCheck($i0, $i1 <> 0)
		endswitch
	wend
endfunc
