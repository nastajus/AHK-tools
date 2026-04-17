#Requires AutoHotkey v2.0
#SingleInstance Force

; Accidental hotkey suppressions.
; Kept together for now so these "do nothing" overrides are easy to find.
; Later, app-specific suppressions can be split into separate scripts if needed.

; Suppress Win+G globally.
; Windows uses this shortcut for the Xbox/Game Bar gaming overlay, which is
; easy to trigger accidentally and not useful in this workflow.
#g:: {
    return
}

; Suppress Ctrl+T in OneNote only.
; OneNote uses it to create a new section, which is easy to hit by accident.
#HotIf WinActive("ahk_exe ONENOTE.EXE")
^t:: {
    return
}
#HotIf
