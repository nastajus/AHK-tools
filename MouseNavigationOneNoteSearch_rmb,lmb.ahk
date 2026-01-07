#Requires AutoHotkey v2.0

; ============================================================
; Script Name: OneNote_RMB_LMB_Search.ahk
; Version:     1.0
; Description:
;   In Microsoft OneNote only:
;   Holding RIGHT mouse button and then clicking LEFT mouse
;   will invoke Ctrl+E (Search) instead of normal mouse behavior.
;
;   Normal right-click context menu is suppressed for this combo.
;
; Requirements:
;   - AutoHotkey v2.0+
;   - Microsoft OneNote desktop app
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; ------------------------------------------------------------
; Context-sensitive hotkeys:
; Only active when OneNote is the foreground window
; ------------------------------------------------------------
#HotIf WinActive("ahk_exe ONENOTE.EXE")

; ------------------------------------------------------------
; RMB → LMB chord
; ~RButton allows OneNote to receive the initial right-click
; LButton checks if RButton is currently held
; ------------------------------------------------------------
~LButton::
{
    if GetKeyState("RButton", "P")
    {
        ; Suppress default behavior
        BlockInput true

        ; Invoke OneNote Search (Ctrl + E)
        Send "^e"

        ; Small delay to avoid event bleed-through
        Sleep 50

        BlockInput false
        return
    }
}

#HotIf
