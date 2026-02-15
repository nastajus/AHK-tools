#Requires AutoHotkey v2.0
#SingleInstance Force

A_IconTip := "OneNote Focus Timer"

; ===== SETTINGS =====
; beepEveryMs := 5000       ; 5 seconds for testing (set to 900000 for 15 minutes)
beepEveryMs := 900000        ; 15 minutes
pollMs := 250                ; how often we check focus (250ms is plenty)
mode := "pause"              ; "pause" or "reset"

; Your chosen sound:
beepFreq := 100
beepDurMs := 1000

; ===== STATE =====
timerOn := true
elapsedMs := 0
wasFocused := false
inactiveStartStamp := ""

SetTimer(Tick, pollMs)
UpdateStatusIconTip(false, elapsedMs, beepEveryMs)

Tick() {
    global timerOn, elapsedMs, wasFocused, inactiveStartStamp
    global beepEveryMs, pollMs, mode, beepFreq, beepDurMs

    if !timerOn {
        UpdateStatusIconTip(false, elapsedMs, beepEveryMs)
        return
    }

    focused := WinActive("ahk_exe ONENOTE.EXE")

    ; If we just lost focus, start away tracking.
    if (wasFocused && !focused) {
        inactiveStartStamp := A_Now
        if (mode = "reset")
            elapsedMs := 0
    }

    ; If we just regained focus, apply overnight-away reset rule.
    if (!wasFocused && focused) {
        if ShouldResetAfterOvernightAway(inactiveStartStamp, A_Now)
            elapsedMs := 0
        inactiveStartStamp := ""
    }

    ; Only accumulate time while focused.
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

UpdateStatusIconTip(isFocused, elapsedMs, intervalMs) {
    state := isFocused ? "FOCUS" : "IDLE"
    remainingMs := Max(intervalMs - elapsedMs, 0)
    A_IconTip := "OneNote Focus Timer`n" state " | " FormatDurationMs(elapsedMs) " | " FormatDurationMs(remainingMs)
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

ShouldResetAfterOvernightAway(startStamp, endStamp) {
    if (startStamp = "")
        return false
    if (DateDiff(endStamp, startStamp, "Seconds") < 14400)
        return false
    return IntervalTouchesWindow(startStamp, endStamp, "030000", "050000")
}

IntervalTouchesWindow(startStamp, endStamp, windowStartHHMMSS, windowEndHHMMSS) {
    day := SubStr(startStamp, 1, 8)
    endDay := SubStr(endStamp, 1, 8)

    loop {
        windowStart := day windowStartHHMMSS
        windowEnd := day windowEndHHMMSS
        overlapStart := MaxStamp(startStamp, windowStart)
        overlapEnd := MinStamp(endStamp, windowEnd)

        if (DateDiff(overlapEnd, overlapStart, "Seconds") > 0)
            return true
        if (day = endDay)
            break

        day := FormatTime(DateAdd(day "000000", 1, "Days"), "yyyyMMdd")
    }

    return false
}

MaxStamp(a, b) {
    return (a > b) ? a : b
}

MinStamp(a, b) {
    return (a < b) ? a : b
}
