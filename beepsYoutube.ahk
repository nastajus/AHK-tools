#Requires AutoHotkey v2.0
#SingleInstance Force

A_IconTip := "YouTube Playback Timer"

; ===== SETTINGS =====
beepEveryMs := 900000        ; 15 minutes
pollMs := 250                ; check 4x/sec
beepFreq := 1400             ; higher pitch
beepDurMs := 250             ; short beep

playingNeedleA := "YT"
playingNeedleB := "PLAYING"
asmrNeedle := "ASMR"         ; case-insensitive match
browserExeList := ["chrome.exe", "msedge.exe", "firefox.exe", "brave.exe"]

; ===== STATE =====
timerOn := true
elapsedMs := 0
wasCounting := false
inactiveStartStamp := ""

SetTimer(Tick, pollMs)
UpdateStatusIconTip(false, elapsedMs, beepEveryMs)

Tick() {
    global timerOn, elapsedMs, wasCounting, inactiveStartStamp
    global beepEveryMs, pollMs, beepFreq, beepDurMs
    global playingNeedleA, playingNeedleB, asmrNeedle, browserExeList

    isCounting := false

    if timerOn {
        info := GetActiveBrowserTitle(browserExeList)
        if info.ok {
            title := info.title

            if InStr(title, asmrNeedle, false) {
                elapsedMs := 0
            } else if (InStr(title, playingNeedleA, true) && InStr(title, playingNeedleB, true)) {
                isCounting := true
            }
        }
    }

    if (wasCounting && !isCounting) {
        inactiveStartStamp := A_Now
    }

    if (!wasCounting && isCounting) {
        if ShouldResetAfterOvernightAway(inactiveStartStamp, A_Now)
            elapsedMs := 0
        inactiveStartStamp := ""
    }

    if isCounting {
        elapsedMs += pollMs
        if (elapsedMs >= beepEveryMs) {
            elapsedMs := 0
            SoundBeep(beepFreq, beepDurMs)
        }
    }

    UpdateStatusIconTip(isCounting, elapsedMs, beepEveryMs)
    wasCounting := isCounting
}

GetActiveBrowserTitle(exeList) {
    try {
        hwnd := WinExist("A")
        if !hwnd
            return { ok: false }

        exe := WinGetProcessName(hwnd)
        if !IsInListCI(exeList, exe)
            return { ok: false }

        return { ok: true, title: WinGetTitle(hwnd) }
    } catch {
        return { ok: false }
    }
}

IsInListCI(list, value) {
    value := StrLower(value)
    for item in list {
        if (StrLower(item) = value)
            return true
    }
    return false
}

; Ctrl + Shift + Q toggles the whole system
^+q::ToggleTimer()

ToggleTimer() {
    global timerOn, elapsedMs, beepEveryMs
    timerOn := !timerOn
    TrayTip("YouTube Timer", timerOn ? "Running" : "Paused (manual)", 2)
    UpdateStatusIconTip(false, elapsedMs, beepEveryMs)
}

UpdateStatusIconTip(isPlaying, elapsedMs, intervalMs) {
    state := isPlaying ? "PLAY" : "PAUSE"
    remainingMs := Max(intervalMs - elapsedMs, 0)
    A_IconTip := "YouTube Playback Timer`n" state " | " FormatDurationMs(elapsedMs) " | " FormatDurationMs(remainingMs)
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
