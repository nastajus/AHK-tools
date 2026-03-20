#Requires AutoHotkey v2.0
#SingleInstance Force

; Tracks whether right-button zooming used the wheel during the current hold.
global gUsedWheelWhileRButton := false

; Reads the active window title safely. This can fail during lock/unlock or
; desktop transitions, so callers get an empty string instead of a hard error.
GetActiveWindowTitle() {
    try {
        return WinGetTitle("A")
    } catch {
        return ""
    }
}

; Reads the active window process safely for app-specific behavior.
GetActiveProcessName() {
    try {
        return WinGetProcessName("A")
    } catch {
        return ""
    }
}

; YouTube needs left-click dismissal because Esc can exit fullscreen.
IsYouTubeActive() {
    return InStr(GetActiveWindowTitle(), "YouTube") > 0
}

; Stremio treats Esc as an exit/back action, so avoid sending it there too.
IsStremioActive() {
    proc := StrLower(GetActiveProcessName())
    return (proc = "stremio.exe" || proc = "stremio-runtime.exe")
}

; Some apps need click-based dismissal instead of Esc after the context menu opens.
ShouldUseClickDismiss() {
    return IsYouTubeActive()
}

; Dismiss the context-style popup created by right-click before sending zoom keys.
; Stremio gets no synthetic dismissal at all because both Esc and a left click
; can have strong player actions there.
DismissContextLike() {
    if IsStremioActive() {
        return
    }

    if ShouldUseClickDismiss() {
        Click "Left"     ; avoid Esc in apps where Esc has stronger side effects
    } else {
        Send "{Esc}"     ; elsewhere Esc is fine
    }
}

; In Stremio, swallow the native right-click entirely. This preserves the
; physical-button-held state for wheel zoom, but prevents the player from
; treating the right click as a back/exit action.
#HotIf IsStremioActive()

RButton:: {
    global gUsedWheelWhileRButton
    gUsedWheelWhileRButton := false
    KeyWait "RButton"
}

#HotIf

; Start a fresh zoom gesture every time right-click goes down everywhere else.
; The tilde preserves native right-click behavior outside the Stremio special case.
#HotIf !IsStremioActive()

~RButton:: {
    global gUsedWheelWhileRButton
    gUsedWheelWhileRButton := false
}

#HotIf

; Only remap the wheel while the right button is physically held down.
#HotIf GetKeyState("RButton", "P")

WheelUp:: {
    global gUsedWheelWhileRButton
    if !gUsedWheelWhileRButton {
        gUsedWheelWhileRButton := true
        DismissContextLike()   ; dismiss immediately on the first zoom tick
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

; Cleanup on release only for apps where Esc is safe. YouTube uses click-based
; dismissal above, and Stremio gets no synthetic dismissal at all.
~RButton Up:: {
    global gUsedWheelWhileRButton
    if gUsedWheelWhileRButton && !ShouldUseClickDismiss() && !IsStremioActive() {
        SetTimer(() => Send("{Esc}"), -20)
    }
}
