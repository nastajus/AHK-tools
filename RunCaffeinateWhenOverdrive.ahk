#Requires AutoHotkey v2.0
#SingleInstance Force

; ===== CONFIG =====
caffeinatePath := "C:\tools\caffeine\caffeine64.exe"
caffeinateArgs := ""                            ; e.g. "--no-display-sleep"
pollMs := 300                                   ; slightly faster helps avoid "in-between" states
needle := "OverDrive"

; ===== STATE =====
global caffeinatePID := 0
global _busy := false

; If anything unexpected happens, log it instead of crashing.
OnError(LogError)

SetTimer(WatchFirefoxTitle, pollMs)
return

WatchFirefoxTitle() {
    global _busy
    if (_busy)
        return
    _busy := true
    try {
        hwnd := 0
        try hwnd := WinGetID("A")
        catch {
            EnsureCaffeinateOff()
            return
        }

        ; If hwnd is missing, bail safely
        if (!hwnd) {
            EnsureCaffeinateOff()
            return
        }

        procName := ""
        title := ""

        try procName := WinGetProcessName(hwnd)
        catch {
            EnsureCaffeinateOff()
            return
        }

        ; Some transient windows can have empty titles during Alt-Tab
        try title := WinGetTitle(hwnd)
        catch {
            EnsureCaffeinateOff()
            return
        }

        isFirefox := (procName = "firefox.exe")
        hasNeedle := (InStr(title, needle) > 0)

        if (isFirefox && hasNeedle)
            EnsureCaffeinateOn()
        else
            EnsureCaffeinateOff()

    } catch as e {
        ; Absolute last line of defense: never die from the timer.
        LogError(e)
    } finally {
        _busy := false
    }
}

EnsureCaffeinateOn() {
    global caffeinatePID, caffeinatePath, caffeinateArgs

    ; Verify existing PID
    if (caffeinatePID) {
        try {
            if ProcessExist(caffeinatePID)
                return
        } catch {
            ; ignore
        }
        caffeinatePID := 0
    }

    if !FileExist(caffeinatePath)
        return

    try {
        Run('"' caffeinatePath '" ' caffeinateArgs, , , &pid)
        caffeinatePID := pid
    } catch as e {
        LogError(e)
    }
}

EnsureCaffeinateOff() {
    global caffeinatePID

    if (!caffeinatePID)
        return

    try {
        if ProcessExist(caffeinatePID) {
            try ProcessClose(caffeinatePID)
        }
    } catch as e {
        LogError(e)
    } finally {
        caffeinatePID := 0
    }
}

LogError(e, mode := "") {
    ; Writes errors to a log file so you can see what happened.
    ; (This avoids silent failures AND avoids crashing.)
    try {
        ts := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
        msg := ts " | " Type(e) " | " e.Message "`n"
        FileAppend(msg, A_ScriptDir "\OverDriveCaffeinate.log", "UTF-8")
    }
    ; Return true to suppress default error dialog (and keep script alive).
    return true
}
