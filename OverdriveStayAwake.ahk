#Requires AutoHotkey v2.0
#SingleInstance Force

A_IconTip := "OverDrive Stay Awake"

; ===== CONFIG =====
pollMs := 1500
needle := "OverDrive"
watchExeList := ["firefox.exe", "chrome.exe", "msedge.exe", "brave.exe"]
logFile := A_ScriptDir "\OverDriveStayAwake.log"

; ===== STATE =====
global keepAwake := false
global _busy := false

OnError(LogError)
OnExit(ClearWakeRequest)
SetTimer(WatchOverDrive, pollMs)

WatchOverDrive() {
    global _busy, keepAwake
    if _busy
        return

    _busy := true
    try {
        shouldStayAwake := IsOverDriveWindowPresent()
        if (shouldStayAwake && !keepAwake) {
            SetWakeRequest(true)
            keepAwake := true
            TrayTip("OverDrive Stay Awake", "Enabled", 1)
        } else if (!shouldStayAwake && keepAwake) {
            SetWakeRequest(false)
            keepAwake := false
            TrayTip("OverDrive Stay Awake", "Disabled", 1)
        }
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
    global keepAwake
    try SetWakeRequest(false)
    keepAwake := false
}

LogError(e, mode := "") {
    global logFile
    try {
        ts := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
        FileAppend(ts " | " Type(e) " | " e.Message "`n", logFile, "UTF-8")
    }
    return true
}
