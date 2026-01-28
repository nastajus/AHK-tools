#Requires AutoHotkey v2.0
#SingleInstance Force

A_IconTip := "YouTube Play Timer Running"

; ===== SETTINGS =====
beepEveryMs := 900000        ; 15 minutes
pollMs      := 250           ; check 4x/sec
beepFreq    := 1400          ; higher pitch
beepDurMs   := 250           ; short beep

playingNeedle := "[YT ▶ PLAYING]"
asmrNeedle    := "ASMR"      ; case-insensitive match

browserExeList := ["chrome.exe", "msedge.exe", "firefox.exe", "brave.exe"]

; ===== STATE =====
timerOn   := true
elapsedMs := 0

SetTimer(Tick, pollMs)

Tick() {
    global timerOn, elapsedMs
    global beepEveryMs, pollMs, beepFreq, beepDurMs
    global playingNeedle, asmrNeedle, browserExeList

    if !timerOn
        return

    info := GetActiveBrowserTitle(browserExeList)
    if !info.ok
        return

    title := info.title

    ; ---- HARD RESET RULE ----
    if InStr(title, asmrNeedle, false) { ; case-insensitive
        elapsedMs := 0
        return
    }

    ; ---- NORMAL PLAYBACK COUNTING ----
    if InStr(title, playingNeedle, true) {
        elapsedMs += pollMs
        if (elapsedMs >= beepEveryMs) {
            elapsedMs := 0
            SoundBeep(beepFreq, beepDurMs)
        }
    }
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
    global timerOn
    timerOn := !timerOn
    TrayTip(
        "YouTube Timer",
        timerOn ? "Running" : "Paused (manual)",
        2
    )
}
