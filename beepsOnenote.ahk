#Requires AutoHotkey v2.0
#SingleInstance Force

A_IconTip := "OneNote Focus Timer"

; ===== SETTINGS =====
beepEveryMs := 5000       ; 5 seconds for testing (set to 900000 for 15 minutes)
; beepEveryMs := 900000   ; 15 minutes

pollMs := 250             ; how often we check focus (250ms is plenty)
mode := "pause"           ; "pause" or "reset"

; Your chosen sound:
beepFreq := 100
beepDurMs := 1000

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

    focused := WinActive("ahk_exe ONENOTE.EXE")

    ; If we just LOST focus:
    if (wasFocused && !focused) {
        if (mode = "reset")
            elapsedMs := 0
    }

    ; Only accumulate time while focused
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

; Ctrl + Shift + Q toggles the whole system
^+q::ToggleTimer()

ToggleTimer() {
    global timerOn, elapsedMs, beepEveryMs
    timerOn := !timerOn
    if timerOn {
        TrayTip("OneNote Timer", "Running", 2)
    } else {
        TrayTip("OneNote Timer", "Paused (manual)", 2)
    }

    UpdateStatusIconTip(timerOn && WinActive("ahk_exe ONENOTE.EXE"), elapsedMs, beepEveryMs)
}

UpdateStatusIconTip(isPlaying, elapsedMs, intervalMs) {
    symbol := isPlaying ? "▶" : "⏸"
    remainingMs := Max(intervalMs - elapsedMs, 0)
    A_IconTip := "OneNote Focus Timer`n" symbol " | " FormatDurationMs(elapsedMs) " | " FormatDurationMs(remainingMs)
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
