; ============================================================
; Script:   MButton + RButton -> Win + .
; Version:  1.0
;
; Behavior:
;   While holding the mouse wheel button (MButton),
;   pressing right click (RButton) will:
;     - suppress the normal context menu
;     - open the Windows Emoji panel (Win + .)
;
; Notes:
;   - This only triggers when MButton is physically down.
;   - Normal right click works normally otherwise.
;   - If the emoji panel doesn't appear in some apps, try
;     clicking into a text field first (Windows limitation).
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; Only when MButton is held down:
#HotIf GetKeyState("MButton", "P")

; Intercept right-click so the context menu does NOT appear,
; then open the emoji panel (Win + .).
RButton::
{
    ; Suppress the right-click's native behavior
    ; and replace it with Win + .
    Send "#{.}"
}

#HotIf
