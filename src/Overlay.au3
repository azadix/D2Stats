#include-once

#Region Overlay globals
global $g_hScriptStartTime = TimerInit()
global $g_hOverlayGUI = 0
global $g_aMessages[0][4] ; Stores [GUI handle, GUI bg handle, expire time, height]
global $g_bCleanupRunning = False
global $g_iNextYPos
global $g_NotifierColorArray[12] = [0xFFFFFF, 0xFF0000, 0x15FF00, 0x7878F5, 0xF0CD8C, 0x9D9D9D, 0x000000, 0xFF00FF, 0xFFBF00, 0xFFFF00, 0x008000, 0x9D00FF]
global $g_aOverlayHistory[0][2]  ; [text, color] - stores last overlay messages (max visible lines)
global $g_bOverlayHistoryMode = False  ; Flag to indicate we're in history display mode
global $g_bOverlayHistoryGroup = False  ; Group consecutive PrintString calls (one item notification)
global $g_iOverlayHistoryGroupLen = 0  ; Lines already stored in the current group
#EndRegion

#Region Overlay
Func IsGameWindowPresent()
    Local $hGameWindow = WinGetHandle("[CLASS:Diablo II]")
    If Not $hGameWindow Then Return False
    
    ; Check if window exists and is visible
    If Not WinExists($hGameWindow) Or Not WinGetState($hGameWindow) Then Return False
    
    ; Check if window is minimized or hidden
    Local $iStyle = _WinAPI_GetWindowLong($hGameWindow, $GWL_STYLE)
    If BitAND($iStyle, $WS_MINIMIZE) Then Return False
    
    ; Additional check for fullscreen (window position off-screen)
    Local $aPos = WinGetPos($hGameWindow)
    If @error Or $aPos[0] <= -32000 Or $aPos[1] <= -32000 Then Return False
    
    Return True
EndFunc

Func CreateOverlayWindow()
    If $g_hOverlayGUI <> 0 Then Return
    
    Local $hGameWindow = WinGetHandle("[CLASS:Diablo II]")
    If Not $hGameWindow Then Return
    
    Local $aPos = WinGetPos($hGameWindow)
    If @error Then Return
    
    ; Create overlay covering full game width with small margins
    $g_hOverlayGUI = GUICreate("D2StatsOverlay", _
                                $aPos[2] - OverlayInt("overlay-x"), _
                                $aPos[3] - OverlayInt("overlay-y"), _
                                $aPos[0] + OverlayInt("overlay-x"), _
                                $aPos[1] + OverlayInt("overlay-y"), _
                                $WS_POPUP, BitOR($WS_EX_LAYERED, $WS_EX_TOPMOST, $WS_EX_TOOLWINDOW, $WS_EX_TRANSPARENT))
    
    If @error Or $g_hOverlayGUI = 0 Then
        $g_hOverlayGUI = 0
        Return
    EndIf
    GUISetBkColor(0xABCDEF)
    _WinAPI_SetLayeredWindowAttributes($g_hOverlayGUI, 0xABCDEF, 255)
    GUISetState(@SW_SHOWNOACTIVATE, $g_hOverlayGUI)
    WinSetOnTop($g_hOverlayGUI, "", 1)
EndFunc

Func RecoverOverlay()
    ; Always completely recreate the overlay after modal dialogs
    If $g_hOverlayGUI <> 0 Then
        GUIDelete($g_hOverlayGUI)
    EndIf
    
    ; Reset state
    $g_hOverlayGUI = 0
    $g_iNextYPos = 0
    ReDim $g_aMessages[0][4]
    $g_bCleanupRunning = False
    AdlibUnRegister("CleanUpExpiredText")
    
    ; Create new overlay
    CreateOverlayWindow()
    
    ; Restart cleanup timer
    If $g_hOverlayGUI <> 0 Then
        AdlibRegister("CleanUpExpiredText", 100)
        $g_bCleanupRunning = True
    EndIf
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
	; Calculate row height based on font size
	local $iRowHeight = Floor(OverlayInt("overlay-fontsize") * 1.65)
	
	; Store in overlay history (keep max visible lines) - but not when in history mode
	; Do this once per message, not per line
	If Not $g_bOverlayHistoryMode Then
		; Calculate max lines based on overlay height
		Local $iMaxLines = Floor($aOverlayPos[3] / $iRowHeight)
		Local $iHistorySize = UBound($g_aOverlayHistory)

		; Count only lines that will actually be stored
		Local $iNewLines = 0
		For $i = 0 To UBound($aSplitText) - 1
			If $aSplitText[$i] <> "" Then $iNewLines += 1
		Next

		If $iNewLines > 0 Then
			; Insert after lines already in this notification group (or at 0 for a new message)
			Local $iInsert = 0
			If $g_bOverlayHistoryGroup Then $iInsert = $g_iOverlayHistoryGroupLen

			ReDim $g_aOverlayHistory[$iHistorySize + $iNewLines][2]

			; Shift existing messages down from the insert point
			For $j = $iHistorySize + $iNewLines - 1 To $iInsert + $iNewLines Step -1
				$g_aOverlayHistory[$j][0] = $g_aOverlayHistory[$j - $iNewLines][0]
				$g_aOverlayHistory[$j][1] = $g_aOverlayHistory[$j - $iNewLines][1]
			Next

			; Add new message lines in original order
			Local $iStored = 0
			For $i = 0 To UBound($aSplitText) - 1
				Local $sLine = $aSplitText[$i]
				If $sLine = "" Then ContinueLoop ; Skip empty lines

				$g_aOverlayHistory[$iInsert + $iStored][0] = $sLine
				$g_aOverlayHistory[$iInsert + $iStored][1] = $iColor
				$iStored += 1
			Next

			If $g_bOverlayHistoryGroup Then $g_iOverlayHistoryGroupLen += $iNewLines
		EndIf

		; Trim to max lines if we exceed the limit
		If UBound($g_aOverlayHistory) > $iMaxLines Then
			ReDim $g_aOverlayHistory[$iMaxLines][2]
			If $g_bOverlayHistoryGroup And $g_iOverlayHistoryGroupLen > $iMaxLines Then
				$g_iOverlayHistoryGroupLen = $iMaxLines
			EndIf
		EndIf
	EndIf
	
    ; Create labels for each line
    For $i = 0 To UBound($aSplitText) - 1
        Local $sLine = $aSplitText[$i]
        If $sLine = "" Then ContinueLoop ; Skip empty lines
		
        ; Background (black outline) for contrast
        Local $idLabelBg = 0
        If _GUI_Option("overlay-contrast") Then
            $idLabelBg = GUICtrlCreateLabel(StringRegExpReplace($sLine & " ", "(?s).", "█"), 0, $g_iNextYPos, $iTextWidth, $iRowHeight)
            GUICtrlSetColor($idLabelBg, 0x0A0A0A)
            GUICtrlSetBkColor($idLabelBg, $GUI_BKCOLOR_TRANSPARENT)
            GUICtrlSetFont($idLabelBg, OverlayInt("overlay-fontsize"), $FW_NORMAL, $GUI_FONTNORMAL, "Courier New", $ANTIALIASED_QUALITY)
        EndIf

        ; Foreground (colored text)
        Local $idLabel = GUICtrlCreateLabel($sLine, 0, $g_iNextYPos, $iTextWidth, $iRowHeight)
        GUICtrlSetColor($idLabel, $iTextColor)
        GUICtrlSetBkColor($idLabel, $GUI_BKCOLOR_TRANSPARENT)
        GUICtrlSetFont($idLabel, OverlayInt("overlay-fontsize"), $FW_NORMAL, $GUI_FONTNORMAL, "Courier New", $ANTIALIASED_QUALITY)

		Local $iUBound = UBound($g_aMessages)
        ReDim $g_aMessages[$iUBound + 1][4]
        $g_aMessages[$iUBound][0] = $idLabelBg
        $g_aMessages[$iUBound][1] = $idLabel
        ; Set timestamp to 0 for history mode (never expires) or normal timestamp
        $g_aMessages[$iUBound][2] = $g_bOverlayHistoryMode ? 0 : TimerDiff($g_hScriptStartTime)
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
    Local $iCharWidth = Floor((OverlayInt("overlay-fontsize") * _GetDPI()[2]) * 0.85)
    If $iCharWidth < 1 Then $iCharWidth = 1
    Local $iMaxChars = Floor($iMaxWidth / $iCharWidth)
    If $iMaxChars < 1 Then $iMaxChars = 1
    
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
        If $g_aMessages[$i][2] <> 0 And TimerDiff($g_hScriptStartTime) >= $g_aMessages[$i][2] + OverlayInt("overlay-timeout") Then
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
        ; Check if overlay window still exists - only recover if window actually disappeared
        If Not WinExists($g_hOverlayGUI) Then
            ; Overlay handle exists but window doesn't - recover it
            RecoverOverlay()
            Return
        EndIf
        
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
            ; Update overlay position and visibility (less frequently)
            Static $iLastPositionUpdate = 0
            If TimerDiff($iLastPositionUpdate) > 1000 Then  ; Only update position every 1 second
                UpdateOverlayPosition()
                $iLastPositionUpdate = TimerInit()
            EndIf
            
            ; Ensure overlay stays on top (less frequently)
            Static $iLastStateCheck = 0
            If TimerDiff($iLastStateCheck) > 60000 Then  ; Only check state every 1 minute
                If WinGetState($g_hOverlayGUI) <> @SW_SHOWNOACTIVATE Then
                    WinSetState($g_hOverlayGUI, "", @SW_SHOWNOACTIVATE)
                EndIf
                WinSetOnTop($g_hOverlayGUI, "", 1)
                $iLastStateCheck = TimerInit()
            EndIf
        EndIf
    EndIf
EndFunc
#EndRegion
