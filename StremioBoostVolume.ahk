#Requires AutoHotkey v2.0
#SingleInstance Force

; In Stremio only, remap Ctrl+Wheel to arrow keys so volume can use the
; player's own keyboard-driven boost path beyond the normal mouse-wheel limit.

IsStremioActive() {
    try {
        proc := StrLower(WinGetProcessName("A"))
        return (proc = "stremio.exe" || proc = "stremio-runtime.exe")
    } catch {
        return false
    }
}

#HotIf IsStremioActive()

^WheelUp::Send "{Up}"
^WheelDown::Send "{Down}"

#HotIf
