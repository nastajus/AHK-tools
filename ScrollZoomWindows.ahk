#Requires AutoHotkey v2.0
#SingleInstance Force

global gUsedWheelWhileRButton := false

IsYouTubeActive() {
    return InStr(WinGetTitle("A"), "YouTube")
}

DismissContextLike() {
    if IsYouTubeActive() {
        Click "Left"     ; avoid Esc (can exit fullscreen on YouTube)
    } else {
        Send "{Esc}"     ; elsewhere Esc is fine
    }
}

~RButton:: {
    global gUsedWheelWhileRButton
    gUsedWheelWhileRButton := false
}

#HotIf GetKeyState("RButton", "P")

WheelUp:: {
    global gUsedWheelWhileRButton
    if !gUsedWheelWhileRButton {
        gUsedWheelWhileRButton := true
        DismissContextLike()   ; dismiss immediately on first wheel tick
    }
    Send "{LWin down}{NumpadAdd}{LWin up}"
}

WheelDown:: {
    global gUsedWheelWhileRButton
    if !gUsedWheelWhileRButton {
        gUsedWheelWhileRButton := true
        DismissContextLike()
    }
    Send "{LWin down}{NumpadSub}{LWin up}"
}

#HotIf

; Insurance close on release ONLY for non-YouTube
~RButton Up:: {
    global gUsedWheelWhileRButton
    if gUsedWheelWhileRButton && !IsYouTubeActive() {
        SetTimer(() => Send("{Esc}"), -20)
    }
}
