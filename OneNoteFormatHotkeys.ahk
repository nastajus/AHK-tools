#Requires AutoHotkey v2.0
#SingleInstance Force

; OneNote formatting shortcuts.
; Ctrl+Shift+F sets the current selection/block font to Calibri.
; Ctrl+Shift+Alt+F sets the current selection/block to Calibri 16pt.
; Ctrl+Shift+S toggles the OneNote navigation/sidebar by clicking the
; Navigation button near the upper-left of the OneNote window. Microsoft
; documents that this button toggles the pane, but does not list a dedicated
; keyboard shortcut for it in the shortcut reference.

SetOneNoteFont(fontName, fontSize := "") {
    Send "^d"
    Sleep 80
    SendText fontName
    Send "{Enter}"

    if (fontSize != "") {
        Sleep 60
        Send "^+p"
        Sleep 60
        SendText fontSize
        Send "{Enter}"
    }
}

ToggleOneNoteSidebar() {
    CoordMode "Mouse", "Screen"

    try {
        MouseGetPos(&startX, &startY)
        WinGetPos(&winX, &winY, &winW, &winH, "A")
    } catch {
        return
    }

    ; Navigation button location in the refreshed desktop layout. This is a
    ; fixed top-left UI element, so a small absolute offset is more stable
    ; than a percentage of the full window size.
    clickX := winX + 28
    clickY := winY + 84

    MouseMove clickX, clickY, 0
    Sleep 40
    Click
    Sleep 40
    MouseMove startX, startY, 0
}

#HotIf WinActive("ahk_exe ONENOTE.EXE")

+^f:: {
    SetOneNoteFont("Calibri")
}

^!+f:: {
    SetOneNoteFont("Calibri", "16")
}

+^s:: {
    ToggleOneNoteSidebar()
}

#HotIf
