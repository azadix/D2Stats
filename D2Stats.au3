#RequireAdmin
#include <Array.au3>
#include <File.au3>
#include <GuiEdit.au3>
#include <GuiSlider.au3>
#include <HotKey.au3>
#include <HotKeyInput.au3>
#include <GuiListView.au3>
#include <ListViewConstants.au3>
#include <Misc.au3>
#include <NomadMemory.au3>
#include <WinAPI.au3>

#include <AutoItConstants.au3>
#include <ComboConstants.au3>
#include <FileConstants.au3>
#include <GUIConstantsEx.au3>
#include <MemoryConstants.au3>
#include <MsgBoxConstants.au3>
#include <StringConstants.au3>
#include <StaticConstants.au3>
#include <TabConstants.au3>
#include <WindowsConstants.au3>

#include "src/defaultNotifyText.au3"
#include "src/d2StatDescriptions.au3"

#pragma compile(Icon, Assets/icon.ico)
#pragma compile(FileDescription, Diablo II Stats reader)
#pragma compile(ProductName, D2Stats)
#pragma compile(ProductVersion, {{version}})
#pragma compile(FileVersion, {{version}})
#pragma compile(Comments, {{buildTime}})
#pragma compile(inputboxres, True)


if ($CmdLine[0] == 4 and $CmdLine[1] == "sound") then ; Notifier sounds
	SoundSetWaveVolume($CmdLine[3])
	SoundPlay(StringFormat("%s\Sounds\%s.%s", @ScriptDir, $CmdLine[2], $CmdLine[4]), $SOUND_WAIT)
	SoundPlay("")
	exit
elseif (not _Singleton("D2Stats-Singleton")) then
	exit
elseif (@AutoItExe == @DesktopDir or @AutoItExe == @DesktopCommonDir) then
	MsgBox($MB_ICONERROR, "D2Stats", "Don't place D2Stats.exe on the desktop.")
	exit
elseif (not IsAdmin()) then
	MsgBox($MB_ICONERROR, "D2Stats", "Admin rights needed!")
	exit
elseif (not @Compiled) then
	HotKeySet("+{INS}", "HotKey_CopyStatsToClipboard")
	HotKeySet("+{PgUp}", "HotKey_CopyItemsToClipboard")
endif

Opt("MustDeclareVars", 1)
Opt("GUICloseOnESC", 0)
Opt("GUIOnEventMode", 1)
Opt("GUIResizeMode", BitOR($GUI_DOCKAUTO, $GUI_DOCKHEIGHT))

#Region Global Variables
func DefineGlobals()
	global $g_sLog = ""

	global const $HK_FLAG_D2STATS = BitOR($HK_FLAG_DEFAULT, $HK_FLAG_NOUNHOOK)

	Global $g_idOptionsScrollArea, $idScrollUp, $idScrollDown
	Global $g_aOptionsControls[0] ; Array to store option control IDs
	Global $g_iOptionsScrollPos = 0
	Global $g_iOptionsVisibleLines = 12 ; Adjust based on your UI size

	; Color array for ui elements
	global $g_iColorArray[12] = [0xFFFFFF, 0xFF0000, 0x15FF00, 0x7878F5, 0x808000, 0x808080, 0x000000, 0xFF00FF, 0xFFBF00, 0xFFFF00, 0x008000, 0xA020F0]

	global enum $ePrintWhite, $ePrintRed, $ePrintLime, $ePrintBlue, $ePrintGold, $ePrintGrey, $ePrintBlack, $ePrintPink, $ePrintOrange, $ePrintYellow, $ePrintGreen, $ePrintPurple
	global enum $eQualityNone, $eQualityLow, $eQualityNormal, $eQualitySuperior, $eQualityMagic, $eQualitySet, $eQualityRare, $eQualityUnique, $eQualityCraft, $eQualityHonorific
	global $g_iQualityColor[] = [0x0, $ePrintWhite, $ePrintWhite, $ePrintWhite, $ePrintBlue, $ePrintLime, $ePrintYellow, $ePrintGold, $ePrintOrange, $ePrintGreen]

	global $g_avGUI[256][3] = [[0]]			; Text, X, Control [0] Count
	global $g_avGUIOption[32][3] = [[0]]	; Option, Control, Function [0] Count

	global const $g_sAppDir = @ScriptDir
	global const $g_sSettingsIni = $g_sAppDir & "\D2Stats.exe.ini"
	global const $g_sLogFile = $g_sAppDir & "\D2Stats-log.txt"

	global const $g_iNumStats = 512

	global $g_asDLL[] = ["D2Client.dll", "D2Common.dll", "D2Win.dll", "D2Lang.dll", "D2Sigma.dll"]
	; Game tooltip formatter strcpy's into this with no length. 0x1000 (2048 wchar)
	; overflowed on long MXL items; keep alloc/zero/read sizes in sync.
	global const $g_iD2InjectStringBytes = 0x8000
	global const $g_iD2InjectStringWChars = $g_iD2InjectStringBytes / 2

	global const $g_iGUIOptionsGeneral = 16
	global const $g_iGUIOptionsHotkey = 4

	global $g_avGUIOptionList[][6] = [ _
		["nopickup", 0, "cb", "Automatically enable /nopickup", "", "General"], _
		["notify-enabled", 1, "cb", "Enable notifier", "", "Notifier"], _
		["unique-tier", 1, "cb", "Show sacred tier of unique (SU/SSU/SSSU)", "", "Notifier"], _
		["notify-superior", 0, "cb", "Notifier prefixes superior items with 'Superior'", "", "Notifier"], _
		["notify-only-filtered", 0, "cb", "Only show filtered stats", "", "Notifier"], _
		["oneline-name", 0, "cb", "One line item name and base type notification style", "", "Notifier"], _
		["oneline-stats", 0, "cb", "One line item stats notification style", "", "Notifier"], _
		["debug-notifier", 0, "cb", "Debug item notifications with match criteria and matching rule", "", "Notifier"], _
		["overlay-x", 10, "int", "Overlay X offset", "OnChange_OverlaySettings", "Overlay"], _
		["overlay-y", 30, "int", "Overlay Y offset", "OnChange_OverlaySettings", "Overlay"], _
		["overlay-fontsize", 12, "int", "Overlay font size", "OnChange_OverlaySettings", "Overlay"], _
		["overlay-font", "Courier New", "str", "Overlay font", "OnChange_OverlayFont", "Overlay"], _
		["overlay-timeout", 7500, "int", "Notification timeout (ms)", "OnChange_OverlaySettings", "Overlay"], _
		["overlay-contrast", 1, "cb", "Draw black background behind overlay text", "", "Overlay"], _
		["goblin-alert", 1, "cb", "Play sound (sound 6) when goblins are nearby.", "", "Sounds"], _
		["use-wav", 0, "cb", "Use .wav instead of .mp3 for sounds (For Linux Compatibility)", "", "Sounds"], _
		["copy", 0x002D, "hk", "Copy item text", "HotKey_CopyItem", ""], _
		["copy-name", 0, "cb", "Only copy item name", "", ""], _
		["readstats", 0x0000, "hk", "Read stats without tabbing out of the game", "HotKey_ReadStats", ""], _
		["show-notifier-log", 0x00DC, "hk", "Show notifier log", "HotKey_ShowNotifierLog", ""], _
		["notify-text", $g_sNotifyTextDefault, "tx", "", "", ""], _
		["selectedNotifierRulesName", "Default", "tx", "", "", ""] _
	]
endfunc
#EndRegion

DefineGlobals()

#include "src/GameMemory.au3"
#include "src/Overlay.au3"
#include "src/StatsRead.au3"
#include "src/Notifier.au3"
#include "src/Compare.au3"
#include "src/Hotkeys.au3"
#include "src/SpeedCalc.au3"
#include "src/UiBridge.au3"

OnAutoItExitRegister("_Exit")

CreateGUI()
Main()

#Region Main
func Main()
	_HotKey_Disable($HK_FLAG_D2STATS)

	local $hTimerUpdateDelay = TimerInit()
	local $bIsIngame

	while 1
		Sleep(16)

		if (not Ui_Tick()) then _Exit()
		Ui_DrainEvents()

		if (TimerDiff($hTimerUpdateDelay) > 250) then
			OverlayMain()
			$hTimerUpdateDelay = TimerInit()

			UpdateHandle()
			UpdateGUIOptions()

			if (IsIngame()) then
				; why inject every frame if we can just inject once?
				if (not $bIsIngame) then 
					$g_bNotifyCache = True
					InjectFunctions()
				endif

				if (_GUI_Option("nopickup") and not $bIsIngame) then _MemoryWrite($g_hD2Client + 0x11C2F0, $g_ahD2Handle, 1, "byte")

				if (_GUI_Option("notify-enabled")) then NotifierMain()

				$bIsIngame = True
				
			else
				$bIsIngame = False
				$g_hTimerCopyName = 0
			endif

			if (Ui_GetActiveTab() == $g_iTabSpeedCalc) then SpeedCalc_Refresh()

			if ($g_hTimerCopyName and TimerDiff($g_hTimerCopyName) > 10000) then
				$g_hTimerCopyName = 0

				if ($bIsIngame) then PrintString("Item name multi-copy expired.")
			endif
		endif
	wend
endfunc

func _Exit()
	if (Ui_IsNotifierDirty()) then
		local $iButton = MsgBox(BitOR($MB_ICONQUESTION, $MB_YESNO), "D2Stats", "There are unsaved changes in the notifier rules. Save?", 0, $g_hGUI)
		if ($iButton == $IDYES) then OnClick_NotifySave()
	endif

	if ($g_bCompareDirty) then SaveGUICompare()

	OnAutoItExitUnRegister("_Exit")
	_GUICtrlHKI_Release()
	Ui_Shutdown()
	_CloseHandle()
	_LogSave()
	exit
endfunc

func _Debug($sFuncName, $sMessage, $iError = @error, $iExtended = @extended)
	_Log($sFuncName, $sMessage, $iError, $iExtended)
	PrintString($sMessage, $ePrintRed)
endfunc

func _Log($sFuncName, $sMessage, $iError = @error, $iExtended = @extended)
	$g_sLog &= StringFormat("[%s] %s (error: %s; extended: %s)%s", $sFuncName, $sMessage, $iError, $iExtended, @CRLF)

	if ($g_iUpdateFailCounter >= 200) then
		MsgBox($MB_ICONERROR, "D2Stats", "Failed too many times in a row. Check log for details. Closing D2Stats...", 0, $g_hGUI)
		exit
	endif
endfunc

func _LogSave()
	if ($g_sLog <> "") then
		local $hFile = FileOpen($g_sLogFile, $FO_OVERWRITE)
		if ($hFile == -1) then return
		FileWrite($hFile, $g_sLog)
		FileFlush($hFile)
		FileClose($hFile)
	endif
endfunc
#EndRegion

#Region GUI helper functions
func _GUI_StringWidth($sText)
	return 2 + 7 * StringLen($sText)
endfunc

func _GUI_LineY($iLine)
	return 48 + 15*$iLine
endfunc

func _GUI_GroupX($iX = default)
	if ($iX <> default) then $g_avGUI[0][1] = $iX
	return $g_avGUI[0][1]
endfunc

func _GUI_GroupFirst()
	$g_avGUI[0][1] = $g_iGroupXStart
endfunc

func _GUI_GroupNext()
	$g_avGUI[0][1] += $g_iGroupWidth
endfunc

func _GUI_ItemCount()
	return $g_avGUI[0][0]
endfunc

func _GUI_StatGroup()
	local $iGroup = Int((_GUI_GroupX() - $g_iGroupXStart) / $g_iGroupWidth)
	if ($iGroup < 0) then $iGroup = 0
	return $iGroup
endfunc

func _GUI_NewItem($iLine, $sText, $sTip = default, $iColor = default)
	$g_avGUI[0][0] += 1
	local $iCount = $g_avGUI[0][0]
	local $sTooltip = ($sTip = default) ? "" : StringReplace($sTip, "|", @LF)
	local $iCol = ($iColor = default) ? -1 : $iColor
	$g_avGUI[$iCount][0] = $sText
	$g_avGUI[$iCount][1] = _GUI_StatGroup()
	$g_avGUI[$iCount][2] = Ui_AddStat($g_iCurrentStatTab, _GUI_StatGroup(), $iLine, $sText, $sTooltip, $iCol, False)
endfunc

func _GUI_NewText($iLine, $sText, $sTip = default, $iColor = default)
	local $sTooltip = ($sTip = default) ? "" : StringReplace($sTip, "|", @LF)
	local $iCol = ($iColor = default) ? -1 : $iColor
	Ui_AddStat($g_iCurrentStatTab, _GUI_StatGroup(), $iLine, $sText, $sTooltip, $iCol, True)
endfunc

func _GUI_NewTextBasic($iLine, $sText, $bCentered = True)
	#forceref $iLine, $sText, $bCentered
endfunc

func _GUI_ItemByRef($iItem, byref $sText, byref $iX, byref $idControl)
	$sText = $g_avGUI[$iItem][0]
	$iX = $g_avGUI[$iItem][1]
	$idControl = $g_avGUI[$iItem][2]
endfunc

func _GUI_OptionCount()
	return $g_avGUIOption[0][0]
endfunc

func _GUI_NewOption($iLine, $sOption, $sText, $sFunc = "")
    local $iY = _GUI_LineY($iLine)*2 - _GUI_LineY(0)
    local $aControls[2] = [0, 0] ; Initialize array: [0]=label, [1]=control
    local $sOptionType = _GUI_OptionType($sOption)

	switch $sOptionType
		case ""
			_Log("_GUI_NewOption", "Invalid option '" & $sOption & "'")
			return $aControls
		case "hk"
			Call($sFunc, True)
			if (@error == 0xDEAD and @extended == 0xBEEF) then
				_Log("_GUI_NewOption", StringFormat("No hotkey function '%s' for option '%s'", $sFunc, $sOption))
				return $aControls
			endif

			local $iKeyCode = _GUI_Option($sOption)
			if ($iKeyCode) then
				_KeyLock($iKeyCode)
				_HotKey_Assign($iKeyCode, $sFunc, $HK_FLAG_D2STATS, "[CLASS:Diablo II]")
			endif

			$aControls[0] = _GUICtrlHKI_Create($iKeyCode, _GUI_GroupX(), $iY, 120, 22)
			GUICtrlCreateLabel($sText, _GUI_GroupX() + 124, $iY + 4)
			$aControls[1] = 0
		case "cb"
            $aControls[0] = GUICtrlCreateCheckbox($sText, 10, $iY, Default, 22)
            GUICtrlSetState($aControls[0], _GUI_Option($sOption) ? $GUI_CHECKED : $GUI_UNCHECKED)
            $aControls[1] = 0
		case "int"
            $aControls[0] = GUICtrlCreateInput(Int(_GUI_Option($sOption)), 10, $iY, 50, 22)
			GUICtrlSetOnEvent($aControls[0], $sFunc)
            $aControls[1] = GUICtrlCreateLabel($sText, 70, $iY + 4, Default, 22)
		case "str"
			$aControls[0] = GUICtrlCreateCombo("", 10, $iY, 200, 22, BitOR($CBS_DROPDOWNLIST, $WS_VSCROLL))
			GUICtrlSetData($aControls[0], "|" & _ArrayToString(OverlayGetMonospaceFonts(), "|"))
			GUICtrlSetData($aControls[0], OverlayFont())
			GUICtrlSetOnEvent($aControls[0], $sFunc)
			$aControls[1] = GUICtrlCreateLabel($sText, 218, $iY + 4, Default, 22)
		case else
			_Log("_GUI_NewOption", "Invalid option type '" & $sOptionType & "'")
			return $aControls
	endswitch
    
    $g_avGUIOption[0][0] += 1
    local $iIndex = $g_avGUIOption[0][0]
    $g_avGUIOption[$iIndex][0] = $sOption
    $g_avGUIOption[$iIndex][1] = ($aControls[1] <> 0) ? $aControls[1] : $aControls[0] ; Main control
    $g_avGUIOption[$iIndex][2] = $sFunc

    Return $aControls
endfunc

Func OnChange_OverlaySettings()
    Local $idCtrl = @GUI_CtrlId
    Local $sOptionKey = ""

    ; Find the matching option key for this control
    For $i = 0 To UBound($g_aOptionsControls) - 1
        If $g_aOptionsControls[$i][1] = $idCtrl Then
            $sOptionKey = $g_avGUIOptionList[$i][0]
            ExitLoop
        EndIf
    Next

    If $sOptionKey <> "" Then
        Local $iValue = ClampOverlayInt($sOptionKey, GUICtrlRead($idCtrl))
        If String($iValue) <> GUICtrlRead($idCtrl) Then GUICtrlSetData($idCtrl, $iValue)
        _GUI_Option($sOptionKey, $iValue)
        If $sOptionKey = "overlay-fontsize" Then $g_sOverlayMetricsKey = ""

        If StringInStr($sOptionKey, "overlay-") And $g_hOverlayGUI Then
            ; Reposition only. Do not GUIDelete — that drops live overlay messages.
            UpdateOverlayPosition()
        EndIf
    EndIf
EndFunc

Func OnChange_OverlayFont()
	Local $sFont = GUICtrlRead(@GUI_CtrlId)
	If $sFont <> "" Then _GUI_Option("overlay-font", $sFont)
	$g_sOverlayMetricsKey = ""
EndFunc

func ClampOverlayInt($sOption, $vValue)
	local $iValue = Int($vValue)
	switch $sOption
		case "overlay-x", "overlay-y"
			if ($iValue < 1) then $iValue = 1
		case "overlay-timeout"
			if ($iValue < 500) then $iValue = 500
			if ($iValue > 120000) then $iValue = 120000
	endswitch
	return $iValue
endfunc

func OverlayInt($sOption)
	return ClampOverlayInt($sOption, _GUI_Option($sOption))
endfunc


func _GUI_OptionByRef($iOption, byref $sOption, byref $idControl, byref $sFunc)
	$sOption = $g_avGUIOption[$iOption][0]
	$idControl = $g_avGUIOption[$iOption][1]
	$sFunc = $g_avGUIOption[$iOption][2]
endfunc

func _GUI_OptionExists($sOption)
	for $i = 0 to UBound($g_avGUIOptionList) - 1
		if ($g_avGUIOptionList[$i][0] == $sOption) then return True
	next
	return False
endfunc

func _GUI_OptionID($sOption)
	for $i = 0 to UBound($g_avGUIOptionList) - 1
		if ($g_avGUIOptionList[$i][0] == $sOption) then return $i
	next
	_Log("_GUI_OptionID", "Invalid option '" & $sOption & "'")
	return SetError(1, 0, -1)
endfunc

func _GUI_OptionType($sOption)
	local $iOption = _GUI_OptionID($sOption)
	if ($iOption < 0) then return SetError(@error, 0, "")
	return $g_avGUIOptionList[$iOption][2]
endfunc

func _GUI_Option($sOption, $vValue = null)
	local $iOption = _GUI_OptionID($sOption)
	if ($iOption < 0) then return SetError(@error, 0, "")
	local $vOld = $g_avGUIOptionList[$iOption][1]

	if not ($vValue == null or $vValue == $vOld) then
		$g_avGUIOptionList[$iOption][1] = $vValue
		SaveGUISettings()
	endif

	return $vOld
endfunc

func _GUI_Volume($iIndex, $iValue = default)
	if not ($iValue == default) then Ui_SetVolume($iIndex, $iValue)
	return Ui_GetVolume($iIndex)
endfunc

func WM_GETMINMAXINFO($hWnd, $MsgID, $wParam, $lParam)
	;Credits: iCode
    ;https://www.autoitscript.com/forum/topic/159947-resize-tabs-relative-to-gui-width/
	#forceref $MsgID, $wParam
    If Not IsHWnd($hWnd) Then Return $GUI_RUNDEFMSG

    Local $minmaxinfo = DllStructCreate("int;int;int;int;int;int;int;int;int;int", $lParam)

    DllStructSetData($minmaxinfo, 7, $g_WindowPos[2]) ; enforce a minimum width for the gui (min width will be the initial width of the gui)
    DllStructSetData($minmaxinfo, 8, $g_WindowPos[3]) ; enforce a minimum height for the gui (min height will be the initial height of the gui)

    Return $GUI_RUNDEFMSG
endfunc
#EndRegion

#Region GUI
func UpdateGUI()
	local $sText, $iX, $idControl
	local $asMatches, $iMatches, $iWidth, $iColor, $iStatValue

	for $i = 1 to _GUI_ItemCount()
		_GUI_ItemByRef($i, $sText, $iX, $idControl)
		$iColor = 0

		$asMatches = StringRegExp($sText, "(\[(\d+):(\d+)/(\d+)\])", $STR_REGEXPARRAYGLOBALMATCH)
		$iMatches = UBound($asMatches)

		if ($iMatches <> 0 and $iMatches <> 4) then
			_Log("UpdateGUI", "Invalid coloring pattern '" & $sText & "'")
			continueloop
		elseif ($iMatches == 4) then
			$sText = StringReplace($sText, $asMatches[0], "")
			$iColor = $g_iColorArray[$ePrintRed]

			$iStatValue = GetStatValue($asMatches[1])
			if ($iStatValue >= $asMatches[2]) then
				$iColor = $g_iColorArray[$ePrintGreen]
			elseif ($iStatValue >= $asMatches[3]) then
				$iColor = $g_iColorArray[$ePrintGold]
			endif
		endif

		$asMatches = StringRegExp($sText, "({(\d+)})", $STR_REGEXPARRAYGLOBALMATCH)
		for $j = 0 to UBound($asMatches) - 1 step 2
			$sText = StringReplace($sText, $asMatches[$j+0], GetStatValue($asMatches[$j+1]))
		next

		$sText = StringStripWS($sText, BitOR($STR_STRIPLEADING, $STR_STRIPTRAILING, $STR_STRIPSPACES))
		Ui_UpdateStat($idControl, $sText, $iColor == 0 ? -1 : $iColor)
	next
endfunc

func OnClick_ReadStats()
	UpdateStatValues()
	UpdateGUI()
	$g_aiStatsCacheCopy = $g_aiStatsCache
	SpeedCalc_Refresh(True)
endfunc

func OnClick_Tab()
	if (Ui_GetActiveTab() == $g_iTabSpeedCalc) then SpeedCalc_Refresh(True)
endfunc

func OnClick_Forum()
	ShellExecute("https://forum.median-xl.com/viewtopic.php?f=4&t=85654")
endfunc

Func OptionsScrollUp()
    If $g_iOptionsScrollPos > 0 Then
        $g_iOptionsScrollPos -= 1
        UpdateVisibleOptions()
    EndIf
EndFunc

Func OptionsScrollDown()
    If $g_iOptionsScrollPos < $g_iGUIOptionsGeneral - $g_iOptionsVisibleLines Then
        $g_iOptionsScrollPos += 1
        UpdateVisibleOptions()
    EndIf
EndFunc

Func UpdateVisibleOptions()
    For $i = 0 To UBound($g_aOptionsControls) - 1
        Local $bVisible = ($i >= $g_iOptionsScrollPos And $i < $g_iOptionsScrollPos + $g_iOptionsVisibleLines)
        Local $iYPos = _GUI_LineY(0) + ($i - $g_iOptionsScrollPos) * 25

        For $j = 0 To 1
            If $g_aOptionsControls[$i][$j] Then
                GUICtrlSetState($g_aOptionsControls[$i][$j], $bVisible ? $GUI_SHOW : $GUI_HIDE)
                If $bVisible Then
                    Local $aPos = ControlGetPos($g_hGUI, "", $g_aOptionsControls[$i][$j])
                    GUICtrlSetPos($g_aOptionsControls[$i][$j], $aPos[0], $iYPos)
                EndIf
            EndIf
        Next
    Next
    UpdateOptionsScrollButtons()
EndFunc

Func UpdateOptionsScrollButtons()
    GUICtrlSetState($idScrollUp, $g_iOptionsScrollPos > 0 ? $GUI_ENABLE : $GUI_DISABLE)
    GUICtrlSetState($idScrollDown, $g_iOptionsScrollPos < $g_iGUIOptionsGeneral - $g_iOptionsVisibleLines ? $GUI_ENABLE : $GUI_DISABLE)
EndFunc

Func WM_MOUSEWHEEL($hWnd, $iMsg, $wParam, $lParam)
    ; Only process if mouse is over our options tab
    Local $aPos = WinGetPos($g_hGUI)
    Local $iMouseX = BitAND($lParam, 0xFFFF)
    Local $iMouseY = BitShift($lParam, 16)
    
    If $iMouseX >= $aPos[0] And $iMouseX <= $aPos[0] + $aPos[2] And _
       $iMouseY >= $aPos[1] + _GUI_LineY(0) And $iMouseY <= $aPos[1] + $aPos[3] - 60 Then
        
        Local $iDelta = BitShift($wParam, 16)
        If $iDelta > 0 Then
            OptionsScrollUp()
        ElseIf $iDelta < 0 Then
            OptionsScrollDown()
        EndIf
    EndIf
    Return $GUI_RUNDEFMSG
EndFunc

func CreateGUI()
	global $g_iGroupWidth = 135
	global $g_iGroupXStart = 8
	global $g_iGUIWidth = 32 + 4 * $g_iGroupWidth
	global $g_iGUIHeight = 370

	local $sTitle = not @Compiled ? "Test" : StringFormat("D2Stats %s - [%s]", FileGetVersion(@AutoItExe, "FileVersion"), FileGetVersion(@AutoItExe, "Comments"))

	LoadGUISettings()
	LoadNotifierColors()
	Ui_Init($sTitle, $g_iGUIWidth, $g_iGUIHeight)

	StatsRead_CreateTabs()
	UpdateGUI()
	Ui_PushOptions()
	Ui_PushNotifierColors()
	Ui_AssignHotkeys()
	Ui_ApplyOverlayConfig()

	Notifier_CreateTab()
	SpeedCalc_CreateTab()
	Compare_CreateTab()
	LoadGUIVolume()
	local $iVol
	for $iVol = 0 to $g_iNumSounds - 1
		Ui_SetVolume($iVol, _GUI_Volume($iVol))
	next
endfunc

func UpdateGUIOptions()
	local $bEnable = IsIngame()
	if ($bEnable <> $g_bHotkeysEnabled) then
		if ($bEnable) then
			_HotKey_Enable()
		else
			_HotKey_Disable($HK_FLAG_D2STATS)
		endif
		$g_bHotkeysEnabled = $bEnable
	endif
endfunc

func SaveGUISettings()
	local $sWrite = "", $vValue
	for $i = 0 to UBound($g_avGUIOptionList) - 1
		$vValue = $g_avGUIOptionList[$i][1]

		switch $g_avGUIOptionList[$i][2]
			case "tx"
				$vValue = StringToBinary($vValue)
			case "int"
				$vValue = Int($vValue)
			case "str"
				$vValue = String($vValue)
		endswitch
		
		$sWrite &= StringFormat("%s=%s%s", $g_avGUIOptionList[$i][0], $vValue, @LF)
	next
	IniWriteSection($g_sSettingsIni, "General", $sWrite)
endfunc

func LoadGUISettings()
	local $asIniGeneral = IniReadSection($g_sSettingsIni, "General")
	if (not @error) then
		local $vValue
		for $i = 1 to $asIniGeneral[0][0]
			if (_GUI_OptionExists($asIniGeneral[$i][0])) then
				$vValue = $asIniGeneral[$i][1]
				local $sType = _GUI_OptionType($asIniGeneral[$i][0])
				if ($sType == "tx") then
					$vValue = BinaryToString($vValue)
				elseif ($sType == "str") then
					$vValue = String($vValue)
				else
					$vValue = Int($vValue)
				endif
				if (StringInStr($asIniGeneral[$i][0], "overlay-") == 1 and $sType <> "str") then $vValue = ClampOverlayInt($asIniGeneral[$i][0], $vValue)
				_GUI_Option($asIniGeneral[$i][0], $vValue)
			endif
		next

		local $bConflict = False
		local $iEnd = UBound($g_avGUIOptionList) - 1

		for $i = 0 to $iEnd
			if ($g_avGUIOptionList[$i][2] <> "hk" or $g_avGUIOptionList[$i][1] == 0x0000) then continueloop

			for $j = $i+1 to $iEnd
				if ($g_avGUIOptionList[$j][2] <> "hk") then continueloop

				if ($g_avGUIOptionList[$i][1] == $g_avGUIOptionList[$j][1]) then
					$g_avGUIOptionList[$j][1] = 0
					$bConflict = True
				endif
			next
		next

		if ($bConflict) then MsgBox($MB_ICONWARNING, "D2Stats", "Hotkey conflict! One or more hotkeys disabled.")
	endif
endfunc

func SaveGUIVolume()
	local $sWrite = ""
	for $i = 0 to $g_iNumSounds - 1
		$sWrite &= StringFormat("%s=%s%s", $i, _GUI_Volume($i), @LF)
	next
	IniWriteSection($g_sSettingsIni, "Volume", $sWrite)
endfunc

func LoadGUIVolume()
	local $asIniVolume = IniReadSection($g_sSettingsIni, "Volume")
	if (not @error) then
		local $iIndex, $iValue
		for $i = 1 to $asIniVolume[0][0]
			$iIndex = Int($asIniVolume[$i][0])
			$iValue = Int($asIniVolume[$i][1])
			if ($iIndex < $g_iNumSounds) then _GUI_Volume($iIndex, $iValue)
		next
	endif
endfunc

Func WM_COMMAND($hWnd, $iMsg, $wParam, $lParam)
	Local $iIDFrom = BitAND($wParam, 0xFFFF)
	Local $iCode = BitShift($wParam, 16)

	If $iCode = $EN_CHANGE Then
		Switch $iIDFrom
			Case $g_idNotifyEdit
				OnChange_NotifyEdit()
			Case $g_idCompareFilter
				OnChange_CompareFilter()
		EndSwitch
	EndIf
EndFunc

Func WM_NOTIFY($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg, $wParam
	Local $tNMHDR = DllStructCreate($tagNMHDR, $lParam)
	If DllStructGetData($tNMHDR, "Code") = $NM_CUSTOMDRAW Then
		Local $iScDraw = SpeedCalc_ListViewNotify($lParam)
		If $iScDraw <> $GUI_RUNDEFMSG Then Return $iScDraw
	EndIf

	If $g_bCompareSaveSuspend Or $g_idCompareList = 0 Then Return $GUI_RUNDEFMSG

	If HWnd(DllStructGetData($tNMHDR, "hWndFrom")) <> GUICtrlGetHandle($g_idCompareList) Then Return $GUI_RUNDEFMSG
	If DllStructGetData($tNMHDR, "Code") <> $LVN_ITEMCHANGED Then Return $GUI_RUNDEFMSG

	Local $tInfo = DllStructCreate($tagNMLISTVIEW, $lParam)
	If Not BitAND(DllStructGetData($tInfo, "Changed"), $LVIF_STATE) Then Return $GUI_RUNDEFMSG

	Local $iNewState = DllStructGetData($tInfo, "NewState")
	Local $iOldState = DllStructGetData($tInfo, "OldState")
	If BitAND($iNewState, $LVIS_STATEIMAGEMASK) = BitAND($iOldState, $LVIS_STATEIMAGEMASK) Then Return $GUI_RUNDEFMSG
	If Not (_IsPressed("01") Or _IsPressed("20")) Then Return $GUI_RUNDEFMSG

	Local $iStatId = GetCompareListStatId(DllStructGetData($tInfo, "Item"))
	If $iStatId < 0 Or $iStatId >= $g_iNumStats Then Return $GUI_RUNDEFMSG

	$g_abCompareEnabled[$iStatId] = (BitShift(BitAND($iNewState, $LVIS_STATEIMAGEMASK), 12) = 2)
	$g_bCompareDirty = True
	SaveGUICompare()
	Return $GUI_RUNDEFMSG
EndFunc

Func _GetDPI()
    Local $avRet[3]
    Local $iDPI, $iDPIRat, $hWnd = 0
    Local $hDC = DllCall("user32.dll", "long", "GetDC", "long", $hWnd)
    Local $aResult = DllCall("gdi32.dll", "long", "GetDeviceCaps", "long", $hDC[0], "long", 90)
    DllCall("user32.dll", "long", "ReleaseDC", "long", $hWnd, "long", $hDC)
    $iDPI = $aResult[0]

    Select
        Case $iDPI = 0
            $iDPI = 96
            $iDPIRat = 94
        Case $iDPI < 84
            $iDPIRat = $iDPI / 105
        Case $iDPI < 121
            $iDPIRat = $iDPI / 96
        Case $iDPI < 145
            $iDPIRat = $iDPI / 95
        Case Else
            $iDPIRat = $iDPI / 94
    EndSelect

    $avRet[0] = 2
    $avRet[1] = $iDPI
    $avRet[2] = $iDPIRat

    Return $avRet
EndFunc
#EndRegion
