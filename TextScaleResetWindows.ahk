#Requires AutoHotkey v2.0
#SingleInstance Force

; Reapply Windows Accessibility > Text size when Windows starts with the saved
; 120% setting visible in Settings but desktop text does not reflect it.
;
; Ctrl+Alt+Shift+F12:
;   1. Open the native Text size Settings page.
;   2. Set 125% and invoke the real Windows Apply action.
;   3. Wait until Windows changes the desktop font metrics.
;   4. Set 120%, Apply again, and wait for the original metrics to return.

global textScaleResetInProgress := false
global normalTextScale := 120
global temporaryTextScale := 125
global settingsWindow := "Settings ahk_exe ApplicationFrameHost.exe"
global windowMetricsKey := "HKEY_CURRENT_USER\Control Panel\Desktop\WindowMetrics"

^!+F12::ResetWindowsTextScale()

; --run is useful for launching the reset directly from a shortcut or terminal.
if (A_Args.Length > 0 && A_Args[1] = "--run")
    SetTimer(ResetWindowsTextScale, -100)

ResetWindowsTextScale() {
    global textScaleResetInProgress, normalTextScale, temporaryTextScale
    global settingsWindow

    if textScaleResetInProgress
        return

    textScaleResetInProgress := true
    settingsWasOpen := WinExist(settingsWindow) != 0
    originalMetrics := ""

    try {
        originalMetrics := GetFontMetricsSignature()

        ToolTip("Applying Windows text size " temporaryTextScale "%")
        ApplyTextScaleThroughSettings(temporaryTextScale)
        if !WaitForFontMetrics(originalMetrics, false, 15000)
            throw Error("Windows did not apply " temporaryTextScale "% text size")

        ToolTip("Restoring Windows text size to " normalTextScale "%")
        ApplyTextScaleThroughSettings(normalTextScale)
        if !WaitForFontMetrics(originalMetrics, true, 15000)
            throw Error("Windows did not restore the original desktop fonts")

        ShowTemporaryStatus("Windows text size reapplied at " normalTextScale "%")
    } catch as err {
        ; Reopen Settings and make a best effort to leave the configured normal
        ; value applied even if the temporary step or completion check failed.
        try ApplyTextScaleThroughSettings(normalTextScale)
        ShowTemporaryStatus("Text-size reset failed: " err.Message, 5000)
    } finally {
        if !settingsWasOpen {
            try WinClose(settingsWindow)
        }
        textScaleResetInProgress := false
    }
}

ApplyTextScaleThroughSettings(scalePercent) {
    global settingsWindow

    if (scalePercent < 100 || scalePercent > 225)
        throw Error("Text size must be between 100% and 225%")

    Run("ms-settings:easeofaccess-display")
    if !WinWait(settingsWindow, , 10)
        throw Error("Windows Text size Settings did not open")

    WinActivate(settingsWindow)
    if !WinWaitActive(settingsWindow, , 5)
        throw Error("Windows Text size Settings could not be activated")

    ; Opening this Settings URI focuses the Text size slider. Home establishes
    ; the 100% minimum, then Right selects the exact requested percentage.
    Sleep(1200)
    Send("{Home}")
    steps := scalePercent - 100
    Loop steps {
        Send("{Right}")
        Sleep(5)
    }

    ; The next tab stop is Apply. Invoking the native button updates the desktop
    ; WindowMetrics fonts, which a registry-only TextScaleFactor write does not.
    Sleep(150)
    Send("{Tab}")
    Sleep(100)
    Send("{Enter}")
}

GetFontMetricsSignature() {
    global windowMetricsKey

    signature := ""
    for valueName in [
        "CaptionFont",
        "IconFont",
        "MenuFont",
        "MessageFont",
        "SmCaptionFont",
        "StatusFont"
    ] {
        ; RegRead represents REG_BINARY values as comparable hexadecimal text.
        signature .= RegRead(windowMetricsKey, valueName)
    }
    return signature
}

WaitForFontMetrics(expectedSignature, shouldEqual, timeoutMs) {
    deadline := A_TickCount + timeoutMs

    Loop {
        isEqual := GetFontMetricsSignature() = expectedSignature
        if (isEqual = shouldEqual)
            return true
        if (A_TickCount >= deadline)
            return false
        Sleep(250)
    }
}

ShowTemporaryStatus(message, durationMs := 3000) {
    ToolTip(message)
    SetTimer(() => ToolTip(), -durationMs)
}
