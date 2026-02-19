#Requires AutoHotkey v2.0
#SingleInstance Force

A_IconTip := "ActivityWatch Watchdog"

; ===== HOTKEYS =====
; Ctrl+Shift+Alt+K : Simulate watcher crash (kills aw-watcher-window.exe)
; Ctrl+Shift+Alt+H : Force immediate recovery cycle test

; ===== CONFIG =====
bucketId := "aw-watcher-window_AURA"
apiBase := "http://127.0.0.1:5600/api/0"
pollMs := 5000
staleAfterSec := 10
incidentCooldownSec := 120
logFile := A_ScriptDir "\ActivityWatchWatchdog.log"
localAppData := EnvGet("LOCALAPPDATA")
defaultAwQtPath := localAppData "\Programs\ActivityWatch\aw-qt.exe"
defaultWatcherPath := localAppData "\Programs\ActivityWatch\aw-watcher-window\aw-watcher-window.exe"

; ===== STATE =====
lastRecoveryUtc := ""
isRecovering := false
awQtPath := ResolveProcessPath("aw-qt.exe", defaultAwQtPath)
watcherPath := ResolveProcessPath("aw-watcher-window.exe", defaultWatcherPath)

SetTimer(CheckWatcher, pollMs)
CheckWatcher()

^+!k::SimulateWatcherCrash()
^+!h::ForceRecoveryTest()

CheckWatcher() {
    global bucketId, staleAfterSec, incidentCooldownSec, lastRecoveryUtc, isRecovering

    if isRecovering
        return

    health := GetWatcherHealth(bucketId, staleAfterSec)
    if health.ok {
        A_IconTip := "ActivityWatch Watchdog`nHEALTHY | age " health.ageSec "s"
        return
    }

    A_IconTip := "ActivityWatch Watchdog`nUNHEALTHY | " health.reason

    if !ShouldAttemptRecovery(lastRecoveryUtc, incidentCooldownSec)
        return

    lastRecoveryUtc := A_NowUTC
    isRecovering := true
    try {
        RecoverWatcher(health.reason)
    } finally {
        isRecovering := false
    }
}

GetWatcherHealth(bucket, staleSec) {
    global apiBase

    bucketsRes := HttpGet(apiBase "/buckets/")
    if !bucketsRes.ok
        return { ok: false, reason: "api unreachable" }

    if !InStr(bucketsRes.body, '"' bucket '"')
        return { ok: false, reason: "bucket missing: " bucket }

    eventsRes := HttpGet(apiBase "/buckets/" bucket "/events?limit=1")
    if !eventsRes.ok
        return { ok: false, reason: "events endpoint unavailable" }

    tsIso := ExtractLastTimestamp(eventsRes.body)
    if (tsIso = "")
        return { ok: false, reason: "last event timestamp missing" }

    tsUtc := IsoToUtcStamp(tsIso)
    if (tsUtc = "")
        return { ok: false, reason: "last event timestamp parse failed" }

    ageSec := DateDiff(A_NowUTC, tsUtc, "Seconds")
    if (ageSec > staleSec)
        return { ok: false, reason: "bucket stale: " ageSec "s" }

    return { ok: true, ageSec: ageSec }
}

RecoverWatcher(reason) {
    global bucketId

    LogIncident("DETECTED", reason)
    ShowFlashMessage("ActivityWatch watcher issue detected", 2200)
    PlayAlertPattern("down")

    if !RestartWatcherWindow() {
        LogIncident("WARN", "watcher restart launch failed")
    }

    Sleep 4500
    healthAfterWatcherRestart := GetWatcherHealth(bucketId, 120)
    if healthAfterWatcherRestart.ok {
        LogIncident("RECOVERED", "watcher restart succeeded")
        ShowFlashMessage("ActivityWatch watcher restored", 1800)
        PlayAlertPattern("up")
        return
    }

    LogIncident("WARN", "watcher restart insufficient, restarting ActivityWatch stack")
    if !RestartActivityWatchStack() {
        LogIncident("FAILED", "ActivityWatch stack restart launch failed")
        ShowFlashMessage("ActivityWatch restart failed to launch", 2500)
        SoundBeep(900, 220)
        return
    }

    Sleep 7000
    healthAfterStackRestart := GetWatcherHealth(bucketId, 150)
    if healthAfterStackRestart.ok {
        LogIncident("RECOVERED", "stack restart succeeded")
        ShowFlashMessage("ActivityWatch restored after full restart", 2200)
        PlayAlertPattern("up")
    } else {
        LogIncident("FAILED", "still unhealthy after full restart: " healthAfterStackRestart.reason)
        ShowFlashMessage("ActivityWatch still unhealthy", 2500)
        SoundBeep(900, 220)
        SoundBeep(800, 220)
    }
}

RestartWatcherWindow() {
    global watcherPath

    CloseProcessByName("aw-watcher-window.exe")
    Sleep 250

    if !FileExist(watcherPath) {
        watcherPath := ResolveProcessPath("aw-watcher-window.exe", watcherPath)
    }

    if !FileExist(watcherPath)
        return false

    try {
        Run('"' watcherPath '"', , "Hide")
        return true
    } catch {
        return false
    }
}

RestartActivityWatchStack() {
    global awQtPath

    CloseAwProcesses()
    Sleep 500

    if !FileExist(awQtPath) {
        awQtPath := ResolveProcessPath("aw-qt.exe", awQtPath)
    }

    if !FileExist(awQtPath)
        return false

    try {
        Run('"' awQtPath '"', , "Hide")
        return true
    } catch {
        return false
    }
}

CloseAwProcesses() {
    names := [
        "aw-watcher-window.exe",
        "aw-watcher-afk.exe",
        "aw-server.exe",
        "aw-qt.exe"
    ]

    for name in names {
        CloseProcessByName(name)
    }
}

CloseProcessByName(name) {
    loop 8 {
        pid := ProcessExist(name)
        if !pid
            break
        try ProcessClose(pid)
        Sleep 120
    }
}

ResolveProcessPath(processName, fallbackPath := "") {
    try {
        query := "SELECT ExecutablePath FROM Win32_Process WHERE Name='" processName "'"
        for proc in ComObjGet("winmgmts:").ExecQuery(query) {
            if (proc.ExecutablePath != "")
                return proc.ExecutablePath
        }
    } catch {
    }

    return fallbackPath
}

ShouldAttemptRecovery(lastStampUtc, cooldownSec) {
    if (lastStampUtc = "")
        return true
    return DateDiff(A_NowUTC, lastStampUtc, "Seconds") >= cooldownSec
}

HttpGet(url, timeoutMs := 3000) {
    req := ComObject("WinHttp.WinHttpRequest.5.1")
    try {
        req.Open("GET", url, false)
        req.SetRequestHeader("Accept", "application/json")
        req.SetTimeouts(timeoutMs, timeoutMs, timeoutMs, timeoutMs)
        req.Send()

        status := req.Status
        body := req.ResponseText
        if (status >= 200 && status < 300)
            return { ok: true, status: status, body: body }

        return { ok: false, status: status, body: body, error: "HTTP " status }
    } catch as e {
        return { ok: false, error: e.Message }
    }
}

ExtractLastTimestamp(json) {
    ; Uses the first timestamp field in the JSON payload (limit=1 request).
    if RegExMatch(json, '"timestamp"\s*:\s*"([^"]+)"', &m)
        return m[1]
    return ""
}

IsoToUtcStamp(iso) {
    ; Example: 2026-02-19T16:36:32.430000+00:00
    pattern := "^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d+)?(?:([+-])(\d{2}):(\d{2})|Z)?$"
    if !RegExMatch(iso, pattern, &m)
        return ""

    stamp := m[1] m[2] m[3] m[4] m[5] m[6]

    if (m[7] = "")
        return stamp

    offsetMin := (m[8] + 0) * 60 + (m[9] + 0)
    if (m[7] = "+")
        return DateAdd(stamp, -offsetMin, "Minutes")

    return DateAdd(stamp, offsetMin, "Minutes")
}

LogIncident(level, message) {
    global logFile
    line := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") " | " level " | " message "`n"
    FileAppend(line, logFile, "UTF-8")
}

SimulateWatcherCrash() {
    LogIncident("TEST", "manual simulation triggered")
    ShowFlashMessage("Test: killing aw-watcher-window", 1800)
    CloseProcessByName("aw-watcher-window.exe")
}

ForceRecoveryTest() {
    global lastRecoveryUtc
    LogIncident("TEST", "forced recovery test triggered")
    ShowFlashMessage("Test: forcing ActivityWatch recovery", 1800)
    CloseProcessByName("aw-watcher-window.exe")
    lastRecoveryUtc := ""
    RecoverWatcher("forced test")
}

PlayAlertPattern(direction) {
    if (direction = "down") {
        ; Failure tone: descending
        SoundBeep(1800, 90)
        Sleep 40
        SoundBeep(1400, 90)
        return
    }

    ; Recovery tone: ascending
    SoundBeep(1400, 90)
    Sleep 40
    SoundBeep(1800, 90)
}

; Same visual cue style used in monitor script: non-blocking centered flash.
ShowFlashMessage(text, duration := 2000) {
    static overlay := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")

    overlay.Destroy()
    overlay := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
    overlay.BackColor := "Black"
    overlay.SetFont("s20 cWhite", "Segoe UI")
    overlay.AddText("Center vCenter", text)

    overlay.Show("AutoSize Center")
    SetTimer(() => overlay.Hide(), -duration)
}
