#Requires AutoHotkey v2.0
#SingleInstance Force

A_IconTip := "YouTube Play Timer"

; ===== SETTINGS =====
beepEveryMs := 900000        ; 15 minutes
pollMs      := 250           ; check 4x/sec
beepFreq    := 1400          ; higher pitch
beepDurMs   := 250           ; short beep

playingNeedleA := "YT"
playingNeedleB := "PLAYING"
asmrNeedle    := "ASMR"      ; case-insensitive match

browserExeList := ["chrome.exe", "msedge.exe", "firefox.exe", "brave.exe"]

; ===== STATE =====
timerOn   := true
elapsedMs := 0

SetTimer(Tick, pollMs)
UpdateStatusIconTip(false, elapsedMs, beepEveryMs)

Tick() {
    global timerOn, elapsedMs
    global beepEveryMs, pollMs, beepFreq, beepDurMs
    global playingNeedleA, playingNeedleB, asmrNeedle, browserExeList

    isPlaying := false

    if timerOn {
        info := GetActiveBrowserTitle(browserExeList)
        if info.ok {
            title := info.title

            ; ---- HARD RESET RULE ----
            if InStr(title, asmrNeedle, false) { ; case-insensitive
                elapsedMs := 0
            } else if (InStr(title, playingNeedleA, true) && InStr(title, playingNeedleB, true)) {
                ; ---- NORMAL PLAYBACK COUNTING ----
                isPlaying := true
                elapsedMs += pollMs
                if (elapsedMs >= beepEveryMs) {
                    elapsedMs := 0
                    SoundBeep(beepFreq, beepDurMs)
                }
            }
        }
    }

    UpdateStatusIconTip(isPlaying, elapsedMs, beepEveryMs)
}

GetActiveBrowserTitle(exeList) {
    try {
        hwnd := WinExist("A")
        if !hwnd
            return { ok: false }

        exe := WinGetProcessName(hwnd)
        if !IsInListCI(exeList, exe)
            return { ok: false }

        return {
            ok: true,
            title: WinGetTitle(hwnd)
        }
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
    TrayTip(
        "YouTube Timer",
        timerOn ? "Running" : "Paused (manual)",
        2
    )

    UpdateStatusIconTip(false, elapsedMs, beepEveryMs)
}

UpdateStatusIconTip(isPlaying, elapsedMs, intervalMs) {
    symbol := isPlaying ? "▶" : "⏸"
    remainingMs := Max(intervalMs - elapsedMs, 0)
    A_IconTip := "YouTube Play Timer`n" symbol " | " FormatDurationMs(elapsedMs) " | " FormatDurationMs(remainingMs)
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
