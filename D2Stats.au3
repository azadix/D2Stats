#RequireAdmin
#include <Array.au3>
#include <File.au3>
#include <GuiEdit.au3>
#include <GuiSlider.au3>
#include <HotKey.au3>
#include <HotKeyInput.au3>
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

#include "defaultNotifyText.au3"
#include "d2StatDescriptions.au3"

#pragma compile(Icon, Assets/icon.ico)
#pragma compile(FileDescription, Diablo II Stats reader)
#pragma compile(ProductName, D2Stats)
#pragma compile(ProductVersion, {{version}})
#pragma compile(FileVersion, {{version}})
#pragma compile(Comments, {{buildTime}})
#pragma compile(UPX, True) ;compression
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

	global $g_hScriptStartTime = TimerInit()
	global $g_hOverlayGUI = 0
	global $g_aMessages[0][4] ; Stores [GUI handle, GUI bg handle, expire time, height]
	global $g_bCleanupRunning = False
	global $g_iNextYPos;

	Global $g_idOptionsScrollArea, $idScrollUp, $idScrollDown
	Global $g_aOptionsControls[0] ; Array to store option control IDs
	Global $g_iOptionsScrollPos = 0
	Global $g_iOptionsVisibleLines = 12 ; Adjust based on your UI size

	; Color array for ui elements
	global $g_iColorArray[12] = [0xFFFFFF, 0xFF0000, 0x15FF00, 0x7878F5, 0x808000, 0x808080, 0x000000, 0xFF00FF, 0xFFBF00, 0xFFFF00, 0x008000, 0xA020F0]
	; Color array for notifier overlay
	global $g_NotifierColorArray[12] = [0xFFFFFF, 0xFF0000, 0x15FF00, 0x7878F5, 0xF0CD8C, 0x9D9D9D, 0x000000, 0xFF00FF, 0xFFBF00, 0xFFFF00, 0x008000, 0x9D00FF]

	global enum $ePrintWhite, $ePrintRed, $ePrintLime, $ePrintBlue, $ePrintGold, $ePrintGrey, $ePrintBlack, $ePrintPink, $ePrintOrange, $ePrintYellow, $ePrintGreen, $ePrintPurple
	global enum $eQualityNone, $eQualityLow, $eQualityNormal, $eQualitySuperior, $eQualityMagic, $eQualitySet, $eQualityRare, $eQualityUnique, $eQualityCraft, $eQualityHonorific
	global $g_iQualityColor[] = [0x0, $ePrintWhite, $ePrintWhite, $ePrintWhite, $ePrintBlue, $ePrintLime, $ePrintYellow, $ePrintGold, $ePrintOrange, $ePrintGreen]

	global $g_avGUI[256][3] = [[0]]			; Text, X, Control [0] Count
	global $g_avGUIOption[32][3] = [[0]]	; Option, Control, Function [0] Count

	global enum $eNotifyFlagsTier, $eNotifyFlagsQuality, $eNotifyFlagsMisc, $eNotifyFlagsNoMask, $eNotifyFlagsColour, $eNotifyFlagsSound, $eNotifyFlagsName, $eNotifyFlagsStat, $eNotifyFlagsMatchStats, $eNotifyFlagsMatch, $eNotifyFlagsLast
	global $g_asNotifyFlags[$eNotifyFlagsLast][32] = [ _
		[ "0", "1", "2", "3", "4", "sacred", "angelic", "master" ], _
		[ "low", "normal", "superior", "magic", "set", "rare", "unique", "craft", "honor" ], _
		[ "eth" ], _
		[], _
		[ "transparent", "white", "red", "lime", "blue", "gold", "grey", "black", "pink", "orange", "yellow", "green", "purple" ], _
		[ "sound_none" ], _
		[ "name" ], _
		[ "stat" ] _
	]
	global $g_aiFlagsCountPerLine[0]

	global const $g_iNumSounds = 6 ; Max 31
	global $g_idVolumeSlider

	for $i = 1 to $g_iNumSounds
		$g_asNotifyFlags[$eNotifyFlagsSound][$i] = "sound" & $i
	next

	global const $g_sNotifierRulesDirectory = @WorkingDir & "\NotifierRules"
	global const $g_sNotifierRulesExtension = ".rules"
	global $g_avNotifyCache[0][3]					; Name, Tier flag, Last line of name
	global $g_avNotifyCompile[0][$eNotifyFlagsLast]	; Flags, Regex
	global $g_bNotifyCache = True
	global $g_bNotifyCompile = True
	global $g_bNotifierChanged = False

	global const $g_iNumStats = 1024
	global $g_aiStatsCache[2][$g_iNumStats]
	global $g_aiStatsCacheCopy[2][$g_iNumStats]

	global $g_asDLL[] = ["D2Client.dll", "D2Common.dll", "D2Win.dll", "D2Lang.dll", "D2Sigma.dll"]
	global $g_hD2Client, $g_hD2Common, $g_hD2Win, $g_hD2Lang, $g_hD2Sigma
	global $g_ahD2Handle

	global $g_iD2pid, $g_iUpdateFailCounter

	global $g_pD2sgpt, $g_pD2InjectPrint, $g_pD2InjectString, $g_pD2InjectParams, $g_pD2InjectGetString, $g_pD2Client_GetItemName, $g_pD2Client_GetItemStat, $g_pD2Common_GetUnitStat

	global $g_bHotkeysEnabled = False
	global $g_hTimerCopyName = 0
	global $g_sCopyName = ""

	global const $g_iGUIOptionsGeneral = 14
	global const $g_iGUIOptionsHotkey = 3

	global $g_avGUIOptionList[][5] = [ _
		["nopickup", 0, "cb", "Automatically enable /nopickup"], _
		["goblin-alert", 1, "cb", "Play sound (sound 6) when goblins are nearby."], _
		["unique-tier", 1, "cb", "Show sacred tier of unique (SU/SSU/SSSU)"], _
		["notify-enabled", 1, "cb", "Enable notifier"], _
		["notify-superior", 0, "cb", "Notifier prefixes superior items with 'Superior'"], _
		["notify-only-filtered", 0, "cb", "Only show filtered stats"], _
		["oneline-name", 0, "cb", "One line item name and base type notification style"], _
		["oneline-stats", 0, "cb", "One line item stats notification style"], _
		["overlay-x", 10, "int", "Overlay X offset", "OnChange_OverlaySettings"], _
		["overlay-y", 30, "int", "Overlay Y offset", "OnChange_OverlaySettings"], _
		["overlay-fontsize", 12, "int", "Overlay font size", "OnChange_OverlaySettings"], _
		["overlay-timeout", 7500, "int", "Notification timeout (ms)", "OnChange_OverlaySettings"], _
		["debug-notifier", 0, "cb", "Debug item notifications with match criteria and matching rule"], _
		["use-wav", 0, "cb", "Use .wav instead of .mp3 for sounds (For Linux Compatibility)"], _
		["copy", 0x002D, "hk", "Copy item text", "HotKey_CopyItem"], _
		["copy-name", 0, "cb", "Only copy item name"], _
		["readstats", 0x0000, "hk", "Read stats without tabbing out of the game", "HotKey_ReadStats"], _
		["notify-text", $g_sNotifyTextDefault, "tx"], _
		["selectedNotifierRulesName", "Default", "tx"] _
	]

	global $g_goblinIds = [2774, 2775, 2776, 2779, 2780, 2781, 2784, 2785, 2786, 2787, 2788, 2789, 2790, 2791, 2792, 2793, 2794, 2795, 2799, 2802, 2803, 2805]
	global $g_goblinBuffer[] = []
endfunc
#EndRegion

DefineGlobals()

OnAutoItExitRegister("_Exit")

CreateGUI()
Main()

#Region Main
func Main()
	_HotKey_Disable($HK_FLAG_D2STATS)

	local $hTimerUpdateDelay = TimerInit()
	local $bIsIngame

	while 1
		Sleep(20)

		OverlayMain()

		if (TimerDiff($hTimerUpdateDelay) > 250) then
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

			if ($g_hTimerCopyName and TimerDiff($g_hTimerCopyName) > 10000) then
				$g_hTimerCopyName = 0

				if ($bIsIngame) then PrintString("Item name multi-copy expired.")
			endif
		endif
	wend
endfunc

func _Exit()
	if (IsDeclared("g_idNotifySave") and BitAND(GUICtrlGetState($g_idNotifySave), $GUI_ENABLE)) then
		local $iButton = MsgBox(BitOR($MB_ICONQUESTION, $MB_YESNO), "D2Stats", "There are unsaved changes in the notifier rules. Save?", 0, $g_hGUI)
		if ($iButton == $IDYES) then OnClick_NotifySave()
	endif

	OnAutoItExitUnRegister("_Exit")
	_GUICtrlHKI_Release()
	GUIDelete()
	_CloseHandle()
	_LogSave()
	exit
endfunc

func _CloseHandle()
	if ($g_ahD2Handle) then
		_MemoryClose($g_ahD2Handle)
		$g_ahD2Handle = 0
		$g_iD2pid = 0
	endif
endfunc

func UpdateHandle()
	local $hWnd = WinGetHandle("[CLASS:Diablo II]")
	local $iPID = WinGetProcess($hWnd)

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
endfunc

func IsIngame()
	if (not $g_iD2pid) then return False
	return _MemoryRead($g_hD2Client + 0x11BBFC, $g_ahD2Handle) <> 0
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
		local $hFile = FileOpen("D2Stats-log.txt", $FO_OVERWRITE)
		FileWrite($hFile, $g_sLog)
		FileFlush($hFile)
		FileClose($hFile)
	endif
endfunc
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
	local $aiOffsets[2] = [0, 0]

	while ($sOutput == "" and TimerDiff($hTimerRetry) < 10)
		$sOutput = _MemoryPointerRead($g_hD2Win + 0x1191F, $g_ahD2Handle, $aiOffsets, "wchar[8192]")
		;$sOutput = _MemoryRead(0x00191FA4, $g_ahD2Handle, "wchar[2048]") ; Magic?
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

func CompareStats()
	UpdateStatValues()
	UpdateGUI()
	
	;Compare stats
	local $statDiffCount = 0
	local $g_statDiff[0][5]
	for $i = 0 To $g_iNumStats - 1	
		if (($g_aiStatsCacheCopy[0][$i] <> $g_aiStatsCache[0][$i]) AND $g_d2StatNames[$i][2] == True) then
			_ArrayAdd($g_statDiff,$i &"|"& _
								$g_d2StatNames[$i][1] &"|"& _
								$g_aiStatsCacheCopy[0][$i] &"|"& _
								$g_aiStatsCache[0][$i] &"|"& _
								$g_aiStatsCache[0][$i]-$g_aiStatsCacheCopy[0][$i])
			$statDiffCount += 1
		endif
		if (($g_aiStatsCacheCopy[1][$i] <> $g_aiStatsCache[1][$i]) AND $g_d2StatNames[$i][4] == True) then
			_ArrayAdd($g_statDiff,$i &"|"& _
								$g_d2StatNames[$i][3] &"|"& _
								$g_aiStatsCacheCopy[1][$i] &"|"& _
								$g_aiStatsCache[1][$i] &"|"& _
								$g_aiStatsCache[1][$i]-$g_aiStatsCacheCopy[1][$i])
			$statDiffCount += 1
		endif
	next
	
	if ($statDiffCount > 0) then
		_ArrayDisplay($g_statDiff, "Stat diff", default, 32, @LF, "Stat ID|Name|Old|New|Diff")
	endif
	
	$g_aiStatsCacheCopy = $g_aiStatsCache
endfunc
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

			$g_aiStatsCache[1][900+$i] = Ceiling($iTotal / (1 + $iPercent / 100) - $iBase)
		next

		; Factor cap
		local $iFactor = Floor((GetStatValue(278) * GetStatValue(0, 1) + GetStatValue(485) * GetStatValue(1, 1)) / 3e6 * 100)
		$g_aiStatsCache[1][904] = $iFactor > 100 ? 100 : $iFactor
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

	local $pBaseAddr, $iNameID, $sName, $asMatch, $sTier

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
					MsgBox($MB_OK+$MB_ICONWARNING, "D2Stats NotifierCache error", StringFormat("Error while parsing item: '%s'", $sName))
					_Debug("NotifierCache", StringFormat("Error while parsing item: '%s'", $sName))
					exit
				endif

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

		$g_avNotifyCache[$iClass][0] = $sName
		$g_avNotifyCache[$iClass][1] = NotifierFlag($sTier)
		$g_avNotifyCache[$iClass][2] = StringRegExpReplace($sName, ".+\|", "")
		
		if (@error) then
			_Debug("NotifierCache", StringFormat("Invalid tier flag '%s'", $sTier))
			exit
		endif
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
	local $sType, $sText

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

						; On the ground display flags
						local $bHideItem = $iFlagsColour == NotifierFlag("hide")
						local $bShowItem = $iFlagsColour == NotifierFlag("show")

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

						; Collecting flags per item. We need them to display items on ground
						; and to show notifications
						$oItemFlags.add('$bHideItem', $bHideItem)
						$oItemFlags.add('$bShowItem', $bShowItem)
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
				ProcessItems($aOnGroundDisplayPool)
			endif
		wend

		$g_bNotifierChanged = False
	next
endfunc

func ProcessItems(byref $aOnGroundDisplayPool)
	local $asNotificationsPool[0][4]

	local $bDelayedHideItem = False

	local $asPreNotificationsPool = OnGroundFilterItems($aOnGroundDisplayPool, $bDelayedHideItem)
	
	; $asNotificationsPool represents an array of notifications per item base
	$asNotificationsPool = FormatNotifications($asPreNotificationsPool, $bDelayedHideItem)
	
	; Display notifications from pool
	DisplayNotification($asNotificationsPool)
endfunc

func DisplayItemOnGround($pUnitData, $iShow)
	_MemoryWrite($pUnitData + 0x48, $g_ahD2Handle, $iShow ? 1 : 2, "byte")		
endfunc

func OnGroundFilterItems(byref $aOnGroundDisplayPool, byref $bDelayedHideItem)
	if (UBound($aOnGroundDisplayPool) == 0) then return

	local $asPreNotificationsPool[0][4]
	local $pUnitData

	local $bShowOnGround = False
	local $bHideCompletely = False
	local $bDisplayNotification = False
	local $bWithStatGroups = False
	
	for $i = 0 to UBound($aOnGroundDisplayPool) - 1
		local $asType = $aOnGroundDisplayPool[$i][0]
		local $oFlags = $aOnGroundDisplayPool[$i][1]
		local $aNotification[1][4] = [[$asType, $oFlags]]
		local $bStatGroupsExists = UBound($oFlags.item('$asStatGroups')) > 0
		
		$pUnitData = $oFlags.item('$pUnitData')

		if ($bStatGroupsExists) then
			$bWithStatGroups = True
		endif

		if ($oFlags.item('$bShowItem')) then
			$bShowOnGround = True
		elseif ($oFlags.item('$bHideItem')) then
			$bHideCompletely = True
		else
			if (not $bStatGroupsExists) then $bDisplayNotification = True
			_ArrayAdd($asPreNotificationsPool, $aNotification)
		endif
	next

	; Clean "on ground" pool after items on ground display processing
	redim $aOnGroundDisplayPool[0][4]

	select
        case $bDisplayNotification
			; Return pool of notifications if at least one rule without "show" or "hide" flags present
			return $asPreNotificationsPool

        case $bShowOnGround
			DisplayItemOnGround($pUnitData, true)
	        if ($bWithStatGroups) then return $asPreNotificationsPool

        case $bHideCompletely
			; if rule with "hide" flag is present and we have item stats matching group "in {} brackets"
			; then we need to delay hiding the item until the stats check is completed (look in FormatNotifications)			
			if ($bWithStatGroups) then
				$bDelayedHideItem = True
		        return $asPreNotificationsPool
			else
				DisplayItemOnGround($pUnitData, false)
			endif

        case $bWithStatGroups
			return $asPreNotificationsPool
    endselect
endfunc

func FormatNotifications(byref $asPreNotificationsPool, $bDelayedHideItem)
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
		local $bShowItem = $oFlags.item('$bShowItem')
		local $bShowItemName = $oFlags.item('$bShowItemName')
		local $pUnitData = $oFlags.item('$pUnitData')
		local $iLvl = $oFlags.item('$iLvl')

		local $bIsMatchByStats = False

		local $asItem = GetItemName($pCurrentUnit)
		local $asItemName = UBound($asItem) == 3 ? $asItem[2] : ""
        local $asItemType = $asItem[1]
        local $asItemStats = ""
        local $iItemColor = $bNotEquipment ? $ePrintOrange : $g_iQualityColor[$iQuality]
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
            if ($bDelayedHideItem) then
                ; if "hide" flag exist -> hide item from ground -> clean pool -> stop processing item
                DisplayItemOnGround($pUnitData, False)
                redim $asPreNotificationsPool[0][4]
                exitloop
            endif
            ; else just skip item
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

    ; Display name and type
    ShowIfAvailable($asName)
    ShowIfAvailable($asType)

    ; Show stats
    DisplayStats($asStats)

    ; Debug info
    if (_GUI_Option("debug-notifier")) then
        PrintString("rule - " & $sMatchingLine, $ePrintRed)
    endif
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

    for $n = 0 to UBound($asStats) - 1
        local $statText = $asStats[$n][0]
        local $statColor = $asStats[$n][1]

        if ($statText == "") then continueLoop

        if (_GUI_Option("oneline-stats")) then
			;Skip prefixes and suffixes when pringing oneline stat style
			if StringInStr($statText, "Prefixes") = 0 AND StringInStr($statText, "Suffixes") = 0 then
				if (ShouldPrintStat($statColor)) then
					$asCombinedStats &= $statText & ", "
				endif
			endif
        else
            if (ShouldPrintStat($statColor)) then
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
func ShouldPrintStat($color)
    if (_GUI_Option("notify-only-filtered")) then
        return $color == $ePrintRed
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

func HighlightStats($sGetItemStats, $asStatGroups, byref $bIsMatchByStats)
	local $asStats = StringSplit($sGetItemStats, @LF)
	local $aPlainStats[$asStats[0]][2]
	local $aColoredStats[$asStats[0]][2]
	local $iMatchCounter = 0

    for $k = 1 to $asStats[0]
        local $sStat = $asStats[$k]
		
		$aColoredStats[$asStats[0] - $k][0] = $sStat
        $aColoredStats[$asStats[0] - $k][1] = $ePrintBlue
		
        $aPlainStats[$asStats[0] - $k][0] = $sStat
        $aPlainStats[$asStats[0] - $k][1] = $ePrintBlue
		
        for $i = 0 to UBound($asStatGroups) - 1
            if ($asStatGroups[$i] == "" or $aColoredStats[$asStats[0] - $k][1] == $ePrintRed) then
                continueloop
            endif

            if (StringRegExp(StringLower($sStat), StringLower($asStatGroups[$i]))) then
                $aColoredStats[$asStats[0] - $k][1] = $ePrintRed
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

#Region GUI helper functions
func _GUI_StringWidth($sText)
	return 2 + 7 * StringLen($sText)
endfunc

func _GUI_LineY($iLine)
	return 28 + 15*$iLine
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

func _GUI_NewItem($iLine, $sText, $sTip = default, $iColor = default)
	$g_avGUI[0][0] += 1
	local $iCount = $g_avGUI[0][0]

	$g_avGUI[$iCount][0] = $sText
	$g_avGUI[$iCount][1] = _GUI_GroupX()
	$g_avGUI[$iCount][2] = _GUI_NewText($iLine, $sText, $sTip, $iColor)
endfunc

func _GUI_NewText($iLine, $sText, $sTip = default, $iColor = default)
	local $idRet = _GUI_NewTextBasic($iLine, $sText, False)

	if ($sTip <> default) then
		GUICtrlSetTip(-1, StringReplace($sTip, "|", @LF), default, default, $TIP_CENTER)
	endif
	if ($iColor >= default) then
		GUICtrlSetColor(-1, $iColor)
	endif
	return $idRet
endfunc

func _GUI_NewTextBasic($iLine, $sText, $bCentered = True)
	local $iWidth = _GUI_StringWidth($sText)
	local $iX = _GUI_GroupX() - ($bCentered ? $iWidth/2 : 0)
	return GUICtrlCreateLabel($sText, $iX, _GUI_LineY($iLine), $iWidth, 15, $bCentered ? $SS_CENTER : $SS_LEFT)
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
		case null
			_Log("_GUI_NewOption", "Invalid option '" & $sOption & "'")
			exit
		case "hk"
			Call($sFunc, True)
			if (@error == 0xDEAD and @extended == 0xBEEF) then
				_Log("_GUI_NewOption", StringFormat("No hotkey function '%s' for option '%s'", $sFunc, $sOption))
				exit
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
		case else
			_Log("_GUI_NewOption", "Invalid option type '" & $sOptionType & "'")
			exit
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

    ; If we found a valid key, update the value
    If $sOptionKey <> "" Then
        Local $sValue = GUICtrlRead($idCtrl)
        _GUI_Option($sOptionKey, $sValue)

        ; Special handling for overlay options
        If StringInStr($sOptionKey, "overlay-") Then
            If $g_hOverlayGUI Then
                GUIDelete($g_hOverlayGUI)
                $g_hOverlayGUI = 0
            EndIf
        EndIf
    EndIf
EndFunc


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
	exit
endfunc

func _GUI_OptionType($sOption)
	return $g_avGUIOptionList[ _GUI_OptionID($sOption) ][2]
endfunc

func _GUI_Option($sOption, $vValue = null)
	local $iOption = _GUI_OptionID($sOption)
	local $vOld = $g_avGUIOptionList[$iOption][1]

	if not ($vValue == null or $vValue == $vOld) then
		$g_avGUIOptionList[$iOption][1] = $vValue
		SaveGUISettings()
	endif

	return $vOld
endfunc

func _GUI_Volume($iIndex, $iValue = default)
	local $id = $g_idVolumeSlider + $iIndex * 3

	if not ($iValue == default) then GUICtrlSetData($id, $iValue)

	return GUICtrlRead($id)
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
			exit
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
		GUICtrlSetData($idControl, $sText)
		if ($iColor <> 0) then GUICtrlSetColor($idControl, $iColor)

		$iWidth = _GUI_StringWidth($sText)
		GUICtrlSetPos($idControl, $iX, default, $iWidth, default)
	next
endfunc

func OnClick_ReadStats()
	UpdateStatValues()
	UpdateGUI()
	$g_aiStatsCacheCopy = $g_aiStatsCache
endfunc

func OnClick_Tab()
	local $iState = GUICtrlRead($g_idTab) < 3 ? $GUI_SHOW : $GUI_HIDE
	GUICtrlSetState($g_idReadStats, $iState)
	GUICtrlSetState($g_idShowDiff, $iState)
	GUICtrlSetState($g_idReadMercenary, $iState)
endfunc

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

func OnClick_Forum()
	ShellExecute("https://forum.median-xl.com/viewtopic.php?f=4&t=83520")
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
        Local $iYPos = 30 + ($i - $g_iOptionsScrollPos) * 25

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
       $iMouseY >= $aPos[1] + 25 And $iMouseY <= $aPos[1] + $aPos[3] - 60 Then
        
        Local $iDelta = BitShift($wParam, 16)
        If $iDelta > 0 Then
            OptionsScrollUp()
        ElseIf $iDelta < 0 Then
            OptionsScrollDown()
        EndIf
    EndIf
    Return $GUI_RUNDEFMSG
EndFunc

#Region Overlay
Func IsGameWindowPresent()
    Local $hGameWindow = WinGetHandle("[CLASS:Diablo II]")
    If Not $hGameWindow Then Return False
    
    ; Check if window is minimized
    Local $iStyle = _WinAPI_GetWindowLong($hGameWindow, $GWL_STYLE)
    If BitAND($iStyle, $WS_MINIMIZE) Then Return False
    
    Return True
EndFunc

Func CreateOverlayWindow()
    If $g_hOverlayGUI <> 0 Then Return
    
    Local $hGameWindow = WinGetHandle("[CLASS:Diablo II]")
    If Not $hGameWindow Then Return
    
    Local $aPos = WinGetPos($hGameWindow)
    If @error Then Return
    $g_iNextYPos = 0

    ; Create overlay covering full game width with small margins
    $g_hOverlayGUI = GUICreate("D2StatsOverlay", _
								$aPos[2] - _GUI_Option("overlay-x"), _
								$aPos[3] - _GUI_Option("overlay-y"), _
								$aPos[0] + _GUI_Option("overlay-x"), _
								$aPos[1] + _GUI_Option("overlay-y"), _
								$WS_POPUP, BitOR($WS_EX_LAYERED, $WS_EX_TOPMOST, $WS_EX_TOOLWINDOW))
	
    GUISetBkColor(0xABCDEF)
    _WinAPI_SetLayeredWindowAttributes($g_hOverlayGUI, 0xABCDEF, 255)
    GUISetState(@SW_SHOWNOACTIVATE, $g_hOverlayGUI)
EndFunc

Func UpdateOverlayPosition()
    Local $hGameWindow = WinGetHandle("[CLASS:Diablo II]")
    If Not $hGameWindow Then Return
    
    Local $aPos = WinGetPos($hGameWindow)
    If Not @error Then
        ; Update overlay to match game window dimensions with margins
        WinMove($g_hOverlayGUI, "", _
				$aPos[0] + _GUI_Option("overlay-x"), _
				$aPos[1] + _GUI_Option("overlay-y"), _
				$aPos[2] - _GUI_Option("overlay-x"), _
				$aPos[3] - _GUI_Option("overlay-y"))
    EndIf
EndFunc

Func PrintString($sText, $iColor = $ePrintWhite)
    If $g_hOverlayGUI = 0 Then 
        CreateOverlayWindow()
        If $g_hOverlayGUI = 0 Then Return ; Still failed to create
    EndIf

    Local $iTextColor = $g_NotifierColorArray[$iColor]
    Local $aOverlayPos = WinGetPos($g_hOverlayGUI)
    Local $iTextWidth = $aOverlayPos[2]
    
    ; Remove Diablo II color codes (ÿcX)
    $sText = StringRegExpReplace($sText, "ÿc.", "")

    ; Split text into lines
    Local $aSplitText = _SplitTextToWidth($sText, $iTextWidth)

    ; Create labels for each line
    For $i = 0 To UBound($aSplitText) - 1
        Local $sLine = $aSplitText[$i]
        If $sLine = "" Then ContinueLoop ; Skip empty lines
		
		local $iRowHeight = Floor(_GUI_Option("overlay-fontsize") * 1.65)
        ; Background (black outline)
        Local $idLabelBg = GUICtrlCreateLabel(StringRegExpReplace($sLine & " ", "(?s).", "█"), 0, $g_iNextYPos, $iTextWidth, $iRowHeight)
        GUICtrlSetColor($idLabelBg, 0x0A0A0A)
        GUICtrlSetBkColor($idLabelBg, $GUI_BKCOLOR_TRANSPARENT)
        GUICtrlSetFont($idLabelBg, _GUI_Option("overlay-fontsize"), $FW_NORMAL, $GUI_FONTNORMAL, "Courier New", $ANTIALIASED_QUALITY)

        ; Foreground (colored text)
        Local $idLabel = GUICtrlCreateLabel($sLine, 0, $g_iNextYPos, $iTextWidth, $iRowHeight)
        GUICtrlSetColor($idLabel, $iTextColor)
        GUICtrlSetBkColor($idLabel, $GUI_BKCOLOR_TRANSPARENT)
        GUICtrlSetFont($idLabel, _GUI_Option("overlay-fontsize"), $FW_NORMAL, $GUI_FONTNORMAL, "Courier New", $ANTIALIASED_QUALITY)

		Local $iUBound = UBound($g_aMessages)
        ReDim $g_aMessages[$iUBound + 1][4]
        $g_aMessages[$iUBound][0] = $idLabelBg
        $g_aMessages[$iUBound][1] = $idLabel
        $g_aMessages[$iUBound][2] = TimerDiff($g_hScriptStartTime)
        $g_aMessages[$iUBound][3] = $iRowHeight

        $g_iNextYPos += $iRowHeight
    Next

    ; Start cleanup timer if needed
    If Not $g_bCleanupRunning And IsArray($g_aMessages) And UBound($g_aMessages) > 0 Then
        $g_bCleanupRunning = True
        AdlibRegister("CleanUpExpiredText", 100)
    EndIf
EndFunc

Func _SplitTextToWidth($sText, $iMaxWidth)
    Local $aLines[0]
    
    ; Get average char width (monospace)
    Local $iCharWidth = Floor((_GUI_Option("overlay-fontsize") * _GetDPI()[2]) * 0.85)
    Local $iMaxChars = Floor($iMaxWidth / $iCharWidth)
    
    ; Split by paragraphs first
    Local $aParagraphs = StringSplit($sText, @CRLF, $STR_ENTIRESPLIT + $STR_NOCOUNT)

    For $sParagraph In $aParagraphs
        $sParagraph = StringStripWS($sParagraph, $STR_STRIPLEADING + $STR_STRIPTRAILING)
        If $sParagraph = "" Then
            ReDim $aLines[UBound($aLines) + 1]
            $aLines[UBound($aLines) - 1] = ""
            ContinueLoop
        EndIf

        While StringLen($sParagraph) > 0
            ; Check if remaining text fits in max width
            If StringLen($sParagraph) <= $iMaxChars Then
				ReDim $aLines[UBound($aLines) + 1]
                $aLines[UBound($aLines) - 1] = $sParagraph
                ExitLoop
            EndIf
            
            ; Get left part up to max chars
            Local $sSegment = StringLeft($sParagraph, $iMaxChars)
            
            ; Find the rightmost space character
            Local $iSplitPos = StringInStr($sSegment, " ", 0, -1)
            
            ; If no space found, split at max chars (break word)
            If $iSplitPos = 0 Then $iSplitPos = $iMaxChars
            
            ; Split the paragraph
            Local $sLine = StringLeft($sParagraph, $iSplitPos)
            $sParagraph = StringTrimLeft($sParagraph, $iSplitPos)
            
            ; Trim whitespace and add to lines array
            $sLine = StringStripWS($sLine, $STR_STRIPTRAILING)
            $sParagraph = StringStripWS($sParagraph, $STR_STRIPLEADING)
            
            ReDim $aLines[UBound($aLines) + 1]
            $aLines[UBound($aLines) - 1] = $sLine
        WEnd
    Next

    Return $aLines
EndFunc

Func CleanUpExpiredText()
    ; Only proceed if we have messages to process
    If UBound($g_aMessages) = 0 Then
        AdlibUnRegister("CleanUpExpiredText")
        $g_bCleanupRunning = False
        Return
    EndIf

    Local $aMessagesToKeep[0][4]  ; Changed to 4 columns to match the new structure
    Local $bMessagesRemoved = False
    Local $iNewYPos = 0

    For $i = 0 To UBound($g_aMessages) - 1
        ; Check if message should expire
        If $g_aMessages[$i][2] <> 0 And TimerDiff($g_hScriptStartTime) >= $g_aMessages[$i][2] + _GUI_Option("overlay-timeout") Then
            ; Message expired - delete it
            GUICtrlDelete($g_aMessages[$i][0])  ; Delete background label
            GUICtrlDelete($g_aMessages[$i][1])   ; Delete foreground label
            $bMessagesRemoved = True
        Else
            ; Message stays - keep it and reposition if needed
            If $bMessagesRemoved Then
                GUICtrlSetPos($g_aMessages[$i][0], 0, $iNewYPos)  ; Reposition background
                GUICtrlSetPos($g_aMessages[$i][1], 0, $iNewYPos)  ; Reposition foreground
            EndIf
            
            ; Add to new array
            ReDim $aMessagesToKeep[UBound($aMessagesToKeep) + 1][4]
            $aMessagesToKeep[UBound($aMessagesToKeep) - 1][0] = $g_aMessages[$i][0]  ; Background label
            $aMessagesToKeep[UBound($aMessagesToKeep) - 1][1] = $g_aMessages[$i][1]  ; Foreground label
            $aMessagesToKeep[UBound($aMessagesToKeep) - 1][2] = $g_aMessages[$i][2]  ; Timestamp
            $aMessagesToKeep[UBound($aMessagesToKeep) - 1][3] = $g_aMessages[$i][3]  ; Height
            
            $iNewYPos += $g_aMessages[$i][3]
        EndIf
    Next
    ; Update global array and positions if messages were removed
    If $bMessagesRemoved Then
        $g_aMessages = $aMessagesToKeep
        $g_iNextYPos = $iNewYPos
    EndIf

    ; Stop cleanup timer if no more messages
    If UBound($g_aMessages) = 0 Then
        $g_bCleanupRunning = False
        $g_iNextYPos = 0
        AdlibUnRegister("CleanUpExpiredText")
    EndIf
EndFunc

Func OverlayMain()
    ; Find the game window if we haven't already
    If $g_hOverlayGUI = 0 And IsGameWindowPresent() Then
        CreateOverlayWindow()
    ElseIf $g_hOverlayGUI <> 0 Then
        ; Check if game window still exists or is minimized
        If Not IsGameWindowPresent() Then
            GUIDelete($g_hOverlayGUI)
            $g_hOverlayGUI = 0
            ; Clear all messages
            For $i = 0 To UBound($g_aMessages) - 1
                GUICtrlDelete($g_aMessages[$i][0])  ; Delete background label
                GUICtrlDelete($g_aMessages[$i][1])   ; Delete foreground label
            Next

			ReDim $g_aMessages[0][4]

            $g_iNextYPos = 0
            $g_bCleanupRunning = False
            AdlibUnRegister("CleanUpExpiredText")
        Else
            ; Update overlay position and visibility
            UpdateOverlayPosition()
        EndIf
    EndIf
EndFunc
#EndRegion

func CreateGUI()
	global $g_iGroupWidth = 110
	global $g_iGroupXStart = 8
	global $g_iGUIWidth = 32 + 4 * $g_iGroupWidth
	global $g_iGUIHeight = 330

	local $sTitle = not @Compiled ? "Test" : StringFormat("D2Stats %s - [%s]", FileGetVersion(@AutoItExe, "FileVersion"), FileGetVersion(@AutoItExe, "Comments"))

	global $g_hGUI = GUICreate($sTitle, $g_iGUIWidth, $g_iGUIHeight, -1, -1, BitOR($GUI_SS_DEFAULT_GUI,$WS_SIZEBOX))
	GUISetFont(9 / _GetDPI()[2], 0, 0, "Courier New")
	GUISetOnEvent($GUI_EVENT_CLOSE, "_Exit")
	global $g_WindowPos = WinGetPos($g_hGUI)
	
	local $iBottomButtonCoords = $g_iGUIHeight - 30

	global $g_idReadStats = GUICtrlCreateButton("Read", $g_iGroupXStart, $iBottomButtonCoords, 70, 25)
	GUICtrlSetOnEvent(-1, "OnClick_ReadStats")

	global $g_idShowDiff = GUICtrlCreateButton("Diff", $g_iGroupXStart + 78, $iBottomButtonCoords, 70, 25)
	GUICtrlSetOnEvent(-1, "CompareStats")

	global $g_idReadMercenary = GUICtrlCreateCheckbox("Mercenary", $g_iGroupXStart + 156, $iBottomButtonCoords + 1)

	global $g_idTab = GUICtrlCreateTab(0, 0, $g_iGUIWidth, 0, $TCS_FOCUSNEVER)
	GUICtrlSetResizing (-1, $GUI_DOCKMENUBAR)
	GUICtrlSetOnEvent(-1, "OnClick_Tab")

#Region Stats
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
	_GUI_NewItem(01, "{359}%/{900}", "Strength")
	_GUI_NewItem(02, "{360}%/{901}", "Dexterity")
	_GUI_NewItem(03, "{362}%/{902}", "Vitality")
	_GUI_NewItem(04, "{361}%/{903}", "Energy")

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
	_GUI_NewItem(01, "SF.Cap: {904}%", "Spell Focus cap. 100% means you don't benefit from more spell focus")
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
#EndRegion
	LoadGUISettings()
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

	_GUI_GroupX(8)

	GUICtrlCreateTabItem("Options")
    
    ; Create scroll buttons
    Local $idScrollUp = GUICtrlCreateButton("▲", $g_iGUIWidth - 20, 25, 18, 18)
    GUICtrlSetOnEvent(-1, "OptionsScrollUp")
    Local $idScrollDown = GUICtrlCreateButton("▼", $g_iGUIWidth - 20, $g_iGUIHeight - 20, 18, 18)
    GUICtrlSetOnEvent(-1, "OptionsScrollDown")
    
    ; Initialize options controls array
    ReDim $g_aOptionsControls[$g_iGUIOptionsGeneral][2]
    
    Local $iOption = 0
    For $i = 0 To $g_iGUIOptionsGeneral - 1
        Local $aControls = _GUI_NewOption($i, $g_avGUIOptionList[$iOption][0], $g_avGUIOptionList[$iOption][3], $g_avGUIOptionList[$iOption][4])
        $g_aOptionsControls[$i][0] = $aControls[1] ; Label
		$g_aOptionsControls[$i][1] = $aControls[0] ; Control
        
        ; Hide options outside visible range
        If $i >= $g_iOptionsVisibleLines Then
            For $j = 0 To 1
                If $g_aOptionsControls[$i][$j] Then
                    GUICtrlSetState($g_aOptionsControls[$i][$j], $GUI_HIDE)
                EndIf
            Next
        EndIf
        
        $iOption += 1
    Next
    UpdateOptionsScrollButtons()

	GUICtrlCreateTabItem("Hotkeys")
	for $i = 1 to $g_iGUIOptionsHotkey
		_GUI_NewOption($i-1, $g_avGUIOptionList[$iOption][0], $g_avGUIOptionList[$iOption][3], $g_avGUIOptionList[$iOption][4])
		$iOption += 1
	next

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

	GUICtrlCreateTabItem("About")
	_GUI_GroupX(8)
	_GUI_NewTextBasic(00, "Made by Wojen and Kyromyr, using Shaggi's offsets.", False)
	_GUI_NewTextBasic(01, "Layout help by krys.", False)
	_GUI_NewTextBasic(02, "Additional help by suchbalance and Quirinus.", False)
	_GUI_NewTextBasic(03, "Sounds by MurderManTX and Cromi38.", False)

	_GUI_NewTextBasic(05, "If you're unsure what any of the abbreviations mean, all of", False)
	_GUI_NewTextBasic(06, "them should have a tooltip when hovered over.", False)

	_GUI_NewTextBasic(08, "Hotkeys can be disabled by setting them to ESC.", False)

	GUICtrlCreateButton("Forum", $g_iGroupXStart, $iBottomButtonCoords, 70, 25)
	GUICtrlSetOnEvent(-1, "OnClick_Forum")

	GUICtrlCreateTabItem("")
	UpdateGUI()
	GUIRegisterMsg($WM_COMMAND, "WM_COMMAND")
	GUIRegisterMsg($WM_GETMINMAXINFO, "WM_GETMINMAXINFO")
	GUIRegisterMsg($WM_MOUSEWHEEL, "WM_MOUSEWHEEL")
	GUISetState(@SW_SHOW)
endfunc

func UpdateGUIOptions()
	local $sType, $sOption, $idControl, $sFunc, $vValue, $vOld

	for $i = 1 to _GUI_OptionCount()
		_GUI_OptionByRef($i, $sOption, $idControl, $sFunc)

		$sType = _GUI_OptionType($sOption)
		$vOld = _GUI_Option($sOption)
		$vValue = $vOld

		switch $sType
			case "hk"
				$vValue = _GUICtrlHKI_GetHotKey($idControl)
			case "cb"
				$vValue = BitAND(GUICtrlRead($idControl), $GUI_CHECKED) ? 1 : 0
		endswitch

		if not ($vOld == $vValue) then
			_GUI_Option($sOption, $vValue)

			if ($sType == "hk") then
				if ($vOld) then _HotKey_Assign($vOld, 0, $HK_FLAG_D2STATS)
				if ($vValue) then _HotKey_Assign($vValue, $sFunc, $HK_FLAG_D2STATS, "[CLASS:Diablo II]")
			endif
		endif
	next

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
		endswitch
		
		$sWrite &= StringFormat("%s=%s%s", $g_avGUIOptionList[$i][0], $vValue, @LF)
	next
	IniWriteSection(@AutoItExe & ".ini", "General", $sWrite)
endfunc

func LoadGUISettings()
	local $asIniGeneral = IniReadSection(@AutoItExe & ".ini", "General")
	if (not @error) then
		local $vValue
		for $i = 1 to $asIniGeneral[0][0]
			if (_GUI_OptionExists($asIniGeneral[$i][0])) then
				$vValue = $asIniGeneral[$i][1]
				$vValue = _GUI_OptionType($asIniGeneral[$i][0]) == "tx" ? BinaryToString($vValue) : Int($vValue)
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
	IniWriteSection(@AutoItExe & ".ini", "Volume", $sWrite)
endfunc

func LoadGUIVolume()
	local $asIniVolume = IniReadSection(@AutoItExe & ".ini", "Volume")
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
		EndSwitch
	EndIf
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


#cs
func PrintString($sString, $iColor = $ePrintWhite)
	if (not IsIngame()) then return
	if (not WriteWString($sString)) then return _Log("PrintString", "Failed to write string.")

	RemoteThread($g_pD2InjectPrint, $iColor)
	if (@error) then return _Log("PrintString", "Failed to create remote thread.")

	return True
endfunc
#ce

func GetItemName($pUnit)
	if (not IsIngame()) then return ""
	;~ clean before use
	_MemoryWrite($g_pD2InjectString, $g_ahD2Handle, 0, "byte[256]")
	RemoteThread($g_pD2Client_GetItemName, $pUnit)
	if (@error) then return _Log("GetItemName", "Failed to create remote thread.")
	return StringSplit(GetOutputString(256), @LF)
endfunc

func GetItemStats($pUnit)
	if (not IsIngame()) then return ""
	;~ clean before use
	_MemoryWrite($g_pD2InjectString, $g_ahD2Handle, 0, "byte[2048]")
	RemoteThread($g_pD2Client_GetItemStat, $pUnit)
	if (@error) then return _Log("GetItemStats", "Failed to create remote thread.")
	return GetOutputString(2048)
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

#cs
func WriteString($sString)
	if (not IsIngame()) then return _Log("WriteString", "Not ingame.")

	_MemoryWrite($g_pD2InjectString, $g_ahD2Handle, $sString, StringFormat("char[%s]", StringLen($sString) + 1))
	if (@error) then return _Log("WriteString", "Failed to write string.")

	return True
endfunc

func WriteWString($sString)
	if (not IsIngame()) then return _Log("WriteWString", "Not ingame.")
	
	_MemoryWrite($g_pD2InjectString, $g_ahD2Handle, $sString, StringFormat("wchar[%s]", StringLen($sString) + 1))
	if (@error) then return _Log("WriteWString", "Failed to write string.")

	return True
endfunc
#ce

#cs
D2Client.dll+CDE00 - 53                    - push ebx
D2Client.dll+CDE01 - 68 *                  - push D2Client.dll+CDE20
D2Client.dll+CDE06 - 31 C0                 - xor eax,eax
D2Client.dll+CDE08 - E8 *                  - call D2Client.dll+7D850
D2Client.dll+CDE0D - C3                    - ret

D2Client.dll+CDE10 - 8B CB                 - mov ecx,ebx
D2Client.dll+CDE12 - 31 C0                 - xor eax,eax
D2Client.dll+CDE14 - BB *                  - mov ebx,D2Lang.dll+9450
D2Client.dll+CDE19 - FF D3                 - call ebx
D2Client.dll+CDE1B - C3                    - ret
#ce

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

	return $bPrint and $bGetString and $bGetItemName and $bGetItemStat and $bGetUnitStat
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

	local $pD2Inject = $g_hD2Client + 0xCDE00
	$g_pD2InjectPrint = $pD2Inject + 0x01 ; memory alignment
	$g_pD2InjectGetString = $pD2Inject + 0x11
	$g_pD2Client_GetItemName = $pD2Inject + 0x21
	$g_pD2Client_GetItemStat = $pD2Inject + 0x3E
	$g_pD2Common_GetUnitStat = $pD2Inject + 0x54
	;~ make more room for full item description
	$g_pD2InjectString = _MemVirtualAllocEx($g_ahD2Handle[1], 0, 0x1000, BitOR($MEM_COMMIT, $MEM_RESERVE), $PAGE_EXECUTE_READWRITE)
	;~ make room for params array
	$g_pD2InjectParams = _MemVirtualAllocEx($g_ahD2Handle[1], 0, 0x100, BitOR($MEM_COMMIT, $MEM_RESERVE), $PAGE_EXECUTE_READWRITE)

	$g_pD2sgpt = _MemoryRead($g_hD2Common + 0x99E1C, $g_ahD2Handle)

	_MemVirtualFreeEx($g_ahD2Handle[1], $pAllocAddress, 0x100, $MEM_RELEASE)
	if (@error) then return _Debug("UpdateDllHandles", "Failed to free memory.")
	if ($bFailed) then return _Debug("UpdateDllHandles", "Couldn't retrieve dll addresses.")

	return True
endfunc
#EndRegion
