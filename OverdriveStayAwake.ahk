#Requires AutoHotkey v2.0
#SingleInstance Force

A_IconTip := "OverDrive Stay Awake"

; ===== CONFIG =====
pollMs := 1500
maxKeepAwakeMs := 60 * 60 * 1000
needle := "OverDrive"
watchExeList := ["firefox.exe", "chrome.exe", "msedge.exe", "brave.exe"]
logFile := A_ScriptDir "\OverDriveStayAwake.log"

; ===== STATE =====
global keepAwake := false
global _busy := false
global activeElapsedMs := 0
global timeoutReached := false
global lastTickMs := A_TickCount

OnError(LogError)
OnExit(ClearWakeRequest)
SetTimer(WatchOverDrive, pollMs)
UpdateIconTip(false)

WatchOverDrive() {
    global _busy, keepAwake, activeElapsedMs, timeoutReached, lastTickMs
    global pollMs, maxKeepAwakeMs
    if _busy
        return

    _busy := true
    try {
        nowTickMs := A_TickCount
        deltaMs := nowTickMs - lastTickMs
        if (deltaMs < 0 || deltaMs > 60000)
            deltaMs := pollMs
        lastTickMs := nowTickMs

        shouldStayAwake := IsOverDriveWindowPresent()

        if shouldStayAwake {
            if !timeoutReached {
                activeElapsedMs += deltaMs

                if (activeElapsedMs >= maxKeepAwakeMs) {
                    activeElapsedMs := maxKeepAwakeMs
                    timeoutReached := true
                    if keepAwake {
                        SetWakeRequest(false)
                        keepAwake := false
                    }
                } else if !keepAwake {
                    SetWakeRequest(true)
                    keepAwake := true
                }
            } else if keepAwake {
                ; Safety: timeout means wake lock should remain off.
                SetWakeRequest(false)
                keepAwake := false
            }
        } else {
            if keepAwake {
                SetWakeRequest(false)
                keepAwake := false
            }

            if (activeElapsedMs > 0 || timeoutReached) {
                activeElapsedMs := 0
                timeoutReached := false
            }
        }

        UpdateIconTip(shouldStayAwake)
    } catch as e {
        LogError(e)
    } finally {
        _busy := false
    }
}

IsOverDriveWindowPresent() {
    global watchExeList, needle

    try hwnd := WinExist("A")
    catch
        return false

    if !hwnd
        return false

    winSpec := "ahk_id " hwnd
    try {
        title := WinGetTitle(winSpec)
        if (title = "")
            return false

        proc := WinGetProcessName(winSpec)
        if !IsInListCI(watchExeList, proc)
            return false

        return InStr(title, needle, false) > 0
    } catch {
        return false
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

SetWakeRequest(enable) {
    ; ES_CONTINUOUS keeps flags active until explicitly cleared.
    flags := 0x80000000
    if enable
        flags := flags | 0x1 | 0x2 ; ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED

    result := DllCall("Kernel32\SetThreadExecutionState", "UInt", flags, "UInt")
    if (result = 0)
        throw Error("SetThreadExecutionState failed")
}

ClearWakeRequest(*) {
    global keepAwake, activeElapsedMs, timeoutReached
    try SetWakeRequest(false)
    keepAwake := false
    activeElapsedMs := 0
    timeoutReached := false
}

LogError(e, mode := "") {
    global logFile
    try {
        ts := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
        FileAppend(ts " | " Type(e) " | " e.Message "`n", logFile, "UTF-8")
    }
    return true
}

UpdateIconTip(isOverDriveFocused) {
    global keepAwake, activeElapsedMs, timeoutReached, maxKeepAwakeMs

    state := "OFF"
    if timeoutReached && isOverDriveFocused
        state := "LIMIT"
    else if keepAwake
        state := "ON"

    remainingMs := Max(maxKeepAwakeMs - activeElapsedMs, 0)
    A_IconTip := "OverDrive Stay Awake`n" state " | " FormatDurationMs(activeElapsedMs) " | " FormatDurationMs(remainingMs)
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
