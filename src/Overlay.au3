#include-once
#include <WinAPIGdi.au3>

#Region Overlay globals
global $g_hOverlayGUI = 0
global $g_NotifierColorArray[12] = [0xFFFFFF, 0xFF0000, 0x15FF00, 0x7878F5, 0xF0CD8C, 0x9D9D9D, 0x000000, 0xFF00FF, 0xFFBF00, 0xFFFF00, 0x008000, 0x9D00FF]
global $g_aOverlayHistory[0][3]  ; [text, color, gapAfter]
global $g_bOverlayHistoryMode = False
global $g_bOverlayHistoryGroup = False
global $g_iOverlayHistoryGroupLen = 0
global $g_asOverlayMonoFonts[0]
global $g_sOverlayMetricsKey = ""
global $g_iOverlayCharWidth = 1
global $g_iOverlayRowHeight = 20
#EndRegion

#Region Overlay fonts
Func OverlayGetMonospaceFonts()
	If UBound($g_asOverlayMonoFonts) > 0 Then Return $g_asOverlayMonoFonts

	Local $aNames[0]
	Local $aEnum = _WinAPI_EnumFontFamilies(0, "", $DEFAULT_CHARSET, $TRUETYPE_FONTTYPE)
	If Not @error And IsArray($aEnum) Then
		Local $hDC = _WinAPI_CreateCompatibleDC(0)
		If $hDC Then
			For $i = 1 To $aEnum[0][0]
				Local $sFace = $aEnum[$i][0]
				If $sFace = "" Or StringLeft($sFace, 1) = "@" Then ContinueLoop
				If _ArraySearch($aNames, $sFace) >= 0 Then ContinueLoop
				If OverlayIsMonospaceFace($hDC, $sFace) Then
					ReDim $aNames[UBound($aNames) + 1]
					$aNames[UBound($aNames) - 1] = $sFace
				EndIf
			Next
			_WinAPI_DeleteDC($hDC)
		EndIf
	EndIf

	If UBound($aNames) = 0 Then
		ReDim $aNames[1]
		$aNames[0] = "Courier New"
	EndIf
	_ArraySort($aNames)
	$g_asOverlayMonoFonts = $aNames
	Return $g_asOverlayMonoFonts
EndFunc

Func OverlayIsMonospaceFace($hDC, $sFace)
	Local $hFont = OverlayCreateGdiFont($hDC, $sFace, 12)
	If Not $hFont Then Return False

	Local $hPrev = _WinAPI_SelectObject($hDC, $hFont)
	Local $tTM = _WinAPI_GetTextMetrics($hDC)
	Local $iErr = @error
	_WinAPI_SelectObject($hDC, $hPrev)
	_WinAPI_DeleteObject($hFont)
	If $iErr Or Not IsDllStruct($tTM) Then Return False

	; TMPF_FIXED_PITCH is inverted: bit set means proportional.
	Return BitAND(DllStructGetData($tTM, "tmPitchAndFamily"), $TMPF_FIXED_PITCH) = 0
EndFunc

Func OverlayCreateGdiFont($hDC, $sFace, $iPointSize)
	If $iPointSize < 1 Then $iPointSize = 1
	Local $iLogPixels = _WinAPI_GetDeviceCaps($hDC, $LOGPIXELSY)
	If $iLogPixels < 1 Then $iLogPixels = 96
	Local $iHeight = -Round($iPointSize * $iLogPixels / 72)
	If $iHeight = 0 Then $iHeight = -12
	Local $hFont = _WinAPI_CreateFont($iHeight, 0, 0, 0, $FW_NORMAL, False, False, False, $DEFAULT_CHARSET, $OUT_DEFAULT_PRECIS, $CLIP_DEFAULT_PRECIS, $NONANTIALIASED_QUALITY, 0, $sFace)
	If @error Or Not $hFont Then Return 0
	Return $hFont
EndFunc

Func OverlayFontInList($aFonts, $sFace)
	If $sFace = "" Or Not IsArray($aFonts) Then Return False
	Return _ArraySearch($aFonts, $sFace) >= 0
EndFunc

Func OverlayFont()
	Local $aFonts = OverlayGetMonospaceFonts()
	Local $sSaved = _GUI_Option("overlay-font")
	If OverlayFontInList($aFonts, $sSaved) Then Return $sSaved
	If OverlayFontInList($aFonts, "Courier New") Then Return "Courier New"
	Return $aFonts[0]
EndFunc

Func OverlayGetMetrics()
	Local $sFont = OverlayFont()
	Local $iSize = OverlayInt("overlay-fontsize")
	If $iSize < 1 Then $iSize = 1
	Local $sKey = $sFont & "|" & $iSize
	If $sKey == $g_sOverlayMetricsKey Then Return

	Local $iCharW = 1
	Local $iRowH = Floor($iSize * 1.65)
	If $iRowH < 1 Then $iRowH = 1

	Local $hDC = _WinAPI_CreateCompatibleDC(0)
	If $hDC Then
		Local $hFont = OverlayCreateGdiFont($hDC, $sFont, $iSize)
		If $hFont Then
			Local $hPrev = _WinAPI_SelectObject($hDC, $hFont)
			Local $tSize = _WinAPI_GetTextExtentPoint32($hDC, "M")
			If Not @error And IsDllStruct($tSize) Then
				$iCharW = DllStructGetData($tSize, "X")
				If $iCharW < 1 Then $iCharW = 1
			EndIf
			Local $tTM = _WinAPI_GetTextMetrics($hDC)
			If Not @error And IsDllStruct($tTM) Then
				$iRowH = DllStructGetData($tTM, "tmHeight") + DllStructGetData($tTM, "tmExternalLeading")
				If $iRowH < 1 Then $iRowH = 1
			EndIf
			_WinAPI_SelectObject($hDC, $hPrev)
			_WinAPI_DeleteObject($hFont)
		EndIf
		_WinAPI_DeleteDC($hDC)
	EndIf

	$g_iOverlayCharWidth = $iCharW
	$g_iOverlayRowHeight = $iRowH
	$g_sOverlayMetricsKey = $sKey
EndFunc

Func OverlayCharWidth()
	OverlayGetMetrics()
	Return $g_iOverlayCharWidth
EndFunc

Func OverlayRowHeight()
	OverlayGetMetrics()
	Return $g_iOverlayRowHeight
EndFunc
#EndRegion

#Region Overlay
Func IsGameWindowPresent()
	Local $hGameWindow = WinGetHandle("[CLASS:Diablo II]")
	If Not $hGameWindow Then Return False
	If Not WinExists($hGameWindow) Or Not WinGetState($hGameWindow) Then Return False
	Local $iStyle = _WinAPI_GetWindowLong($hGameWindow, $GWL_STYLE)
	If BitAND($iStyle, $WS_MINIMIZE) Then Return False
	Local $aPos = WinGetPos($hGameWindow)
	If @error Or $aPos[0] <= -32000 Or $aPos[1] <= -32000 Then Return False
	Return True
EndFunc

Func OverlayGameRect()
	Local $a[4] = [0, 0, 0, 0]
	Local $hGameWindow = WinGetHandle("[CLASS:Diablo II]")
	If Not $hGameWindow Then Return $a
	Local $aPos = WinGetPos($hGameWindow)
	If @error Then Return $a
	$a[0] = $aPos[0] + OverlayInt("overlay-x")
	$a[1] = $aPos[1] + OverlayInt("overlay-y")
	$a[2] = $aPos[2] - OverlayInt("overlay-x")
	$a[3] = $aPos[3] - OverlayInt("overlay-y")
	If $a[2] < 1 Then $a[2] = 1
	If $a[3] < 1 Then $a[3] = 1
	Return $a
EndFunc

Func UpdateOverlayPosition()
	If Not IsGameWindowPresent() Then
		Ui_OverlaySetTarget(0, 0, 0, 0, False)
		$g_hOverlayGUI = 0
		Return
	EndIf
	Local $a = OverlayGameRect()
	Ui_OverlaySetTarget($a[0], $a[1], $a[2], $a[3], True)
	$g_hOverlayGUI = 1
EndFunc

Func RecoverOverlay()
	Ui_OverlayClear()
	UpdateOverlayPosition()
EndFunc

Func PrintString($sText, $iColor = $ePrintWhite)
	If Not IsGameWindowPresent() Then Return
	UpdateOverlayPosition()

	Local $iTextColor = $g_NotifierColorArray[$iColor]
	Local $aOverlayPos = OverlayGameRect()
	Local $iTextWidth = $aOverlayPos[2]
	$sText = StripD2ColorCodes($sText)

	Local $aSplitText = _SplitTextToWidth($sText, $iTextWidth)
	Local $iRowHeight = OverlayRowHeight()
	Local $iTimeout = $g_bOverlayHistoryMode ? 0 : OverlayInt("overlay-timeout")
	Local $iNewLines = 0
	Local $iHistoryGapIndex = 0

	If Not $g_bOverlayHistoryMode Then
		Local $iMaxLines = Floor($aOverlayPos[3] / $iRowHeight)
		Local $iHistorySize = UBound($g_aOverlayHistory)
		$iNewLines = 0
		For $i = 0 To UBound($aSplitText) - 1
			If $aSplitText[$i] <> "" Then $iNewLines += 1
		Next

		If $iNewLines > 0 Then
			Local $iInsert = 0
			If $g_bOverlayHistoryGroup Then $iInsert = $g_iOverlayHistoryGroupLen
			ReDim $g_aOverlayHistory[$iHistorySize + $iNewLines][3]
			For $j = $iHistorySize + $iNewLines - 1 To $iInsert + $iNewLines Step -1
				$g_aOverlayHistory[$j][0] = $g_aOverlayHistory[$j - $iNewLines][0]
				$g_aOverlayHistory[$j][1] = $g_aOverlayHistory[$j - $iNewLines][1]
				$g_aOverlayHistory[$j][2] = $g_aOverlayHistory[$j - $iNewLines][2]
			Next
			Local $iStored = 0
			For $i = 0 To UBound($aSplitText) - 1
				Local $sLine = $aSplitText[$i]
				If $sLine = "" Then ContinueLoop
				$g_aOverlayHistory[$iInsert + $iStored][0] = $sLine
				$g_aOverlayHistory[$iInsert + $iStored][1] = $iColor
				$g_aOverlayHistory[$iInsert + $iStored][2] = 0
				$iStored += 1
			Next
			If $g_bOverlayHistoryGroup Then $g_iOverlayHistoryGroupLen += $iNewLines
			$iHistoryGapIndex = $iInsert + $iNewLines - 1
		EndIf

		If UBound($g_aOverlayHistory) > $iMaxLines Then
			ReDim $g_aOverlayHistory[$iMaxLines][3]
			If $g_bOverlayHistoryGroup And $g_iOverlayHistoryGroupLen > $iMaxLines Then
				$g_iOverlayHistoryGroupLen = $iMaxLines
			EndIf
		EndIf
	EndIf

	Local $iPrinted = 0
	For $i = 0 To UBound($aSplitText) - 1
		Local $sLine = $aSplitText[$i]
		If $sLine = "" Then ContinueLoop
		Ui_Print($sLine, $iTextColor, $iTimeout)
		$iPrinted += 1
	Next

	If $iPrinted > 0 And Not $g_bOverlayHistoryGroup And Not $g_bOverlayHistoryMode Then OverlayAddItemGap($iHistoryGapIndex)
EndFunc

Func OverlayAddItemGap($iHistoryIndex = -1)
	Ui_OverlayAddGap()
	If $g_bOverlayHistoryMode Then Return
	If $iHistoryIndex < 0 Then $iHistoryIndex = 0
	If $iHistoryIndex < UBound($g_aOverlayHistory) Then $g_aOverlayHistory[$iHistoryIndex][2] = 1
EndFunc

Func _SplitTextToWidth($sText, $iMaxWidth)
	Local $aLines[0]
	Local $iCharWidth = OverlayCharWidth()
	If $iCharWidth < 1 Then $iCharWidth = 1
	Local $iMaxChars = Floor($iMaxWidth / $iCharWidth)
	If $iMaxChars < 1 Then $iMaxChars = 1

	Local $aParagraphs = StringSplit($sText, @CRLF, $STR_ENTIRESPLIT + $STR_NOCOUNT)
	For $sParagraph In $aParagraphs
		$sParagraph = StringStripWS($sParagraph, $STR_STRIPLEADING + $STR_STRIPTRAILING)
		If $sParagraph = "" Then
			ReDim $aLines[UBound($aLines) + 1]
			$aLines[UBound($aLines) - 1] = ""
			ContinueLoop
		EndIf

		While StringLen($sParagraph) > 0
			If StringLen($sParagraph) <= $iMaxChars Then
				ReDim $aLines[UBound($aLines) + 1]
				$aLines[UBound($aLines) - 1] = $sParagraph
				ExitLoop
			EndIf

			Local $sSegment = StringLeft($sParagraph, $iMaxChars)
			Local $iSplitPos = StringInStr($sSegment, " ", 0, -1)
			If $iSplitPos = 0 Then $iSplitPos = $iMaxChars
			Local $sLine = StringLeft($sParagraph, $iSplitPos)
			$sParagraph = StringTrimLeft($sParagraph, $iSplitPos)
			$sLine = StringStripWS($sLine, $STR_STRIPTRAILING)
			$sParagraph = StringStripWS($sParagraph, $STR_STRIPLEADING)
			ReDim $aLines[UBound($aLines) + 1]
			$aLines[UBound($aLines) - 1] = $sLine
		WEnd
	Next
	Return $aLines
EndFunc

Func OverlayMain()
	If IsGameWindowPresent() Then
		Static $hLastPos = 0
		If TimerDiff($hLastPos) > 1000 Or $hLastPos = 0 Then
			UpdateOverlayPosition()
			$hLastPos = TimerInit()
		EndIf
	Else
		Ui_OverlaySetTarget(0, 0, 0, 0, False)
		$g_hOverlayGUI = 0
	EndIf
EndFunc
#EndRegion
