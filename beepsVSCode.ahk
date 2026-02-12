#Requires AutoHotkey v2.0
#SingleInstance Force

A_IconTip := "VS Code Focus Timer"

; ===== SETTINGS =====
beepEveryMs := 900000        ; 15 minutes
pollMs := 250                ; how often we check focus
mode := "pause"              ; "pause" or "reset"
beepFreq := 1700             ; slightly higher than YouTube timer
beepDurMs := 300

; ===== STATE =====
timerOn := true
elapsedMs := 0
wasFocused := false

SetTimer(Tick, pollMs)
UpdateStatusIconTip(false, elapsedMs, beepEveryMs)

Tick() {
    global timerOn, elapsedMs, wasFocused
    global beepEveryMs, mode, beepFreq, beepDurMs

    if !timerOn {
        UpdateStatusIconTip(false, elapsedMs, beepEveryMs)
        return
    }

    focused := IsVSCodeFocused()

    if (wasFocused && !focused) {
        if (mode = "reset")
            elapsedMs := 0
    }

    if focused {
        elapsedMs += pollMs
        if (elapsedMs >= beepEveryMs) {
            elapsedMs := 0
            SoundBeep(beepFreq, beepDurMs)
        }
    }

    UpdateStatusIconTip(focused, elapsedMs, beepEveryMs)
    wasFocused := focused
}

IsVSCodeFocused() {
    return WinActive("ahk_exe Code.exe") || WinActive("ahk_exe Code - Insiders.exe")
}

; Ctrl + Shift + Q toggles this timer
^+q::ToggleTimer()

ToggleTimer() {
    global timerOn, elapsedMs, beepEveryMs
    timerOn := !timerOn
    if timerOn {
        TrayTip("VS Code Timer", "Running", 2)
    } else {
        TrayTip("VS Code Timer", "Paused (manual)", 2)
    }

    UpdateStatusIconTip(timerOn && IsVSCodeFocused(), elapsedMs, beepEveryMs)
}

UpdateStatusIconTip(isPlaying, elapsedMs, intervalMs) {
    symbol := isPlaying ? "▶" : "⏸"
    remainingMs := Max(intervalMs - elapsedMs, 0)
    A_IconTip := "VS Code Focus Timer`n" symbol " | " FormatDurationMs(elapsedMs) " | " FormatDurationMs(remainingMs)
}

FormatDurationMs(ms) {
    totalSeconds := Floor(ms / 1000)
    hours := Floor(totalSeconds / 3600)
    minutes := Floor(Mod(totalSeconds, 3600) / 60)
    seconds := Mod(totalSeconds, 60)
    if (hours > 0)
        return Format("{1:02}:{2:02}:{3:02}", hours, minutes, seconds)
    return Format("{1:02}:{2:02}", minutes, seconds)
}
