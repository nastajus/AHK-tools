#Requires AutoHotkey v2.0
#SingleInstance Force

; Reapply Windows Accessibility > Text size when Windows starts with the saved
; percentage visible in Settings but not actually reflected across the shell.
;
; Ctrl+Alt+Shift+F12:
;   1. Read and preserve the current text scale.
;   2. Apply a nearby value (normally current + 5%).
;   3. Wait for Windows and applications to process the change.
;   4. Restore and reapply the original value.

global textScaleResetInProgress := false
global accessibilityKey := "HKEY_CURRENT_USER\Software\Microsoft\Accessibility"
global textScaleValueName := "TextScaleFactor"
global applySettleMs := 5000

^!+F12::ResetWindowsTextScale()

; --run is useful for launching the reset directly from a shortcut or terminal.
if (A_Args.Length > 0 && A_Args[1] = "--run")
    SetTimer(ResetWindowsTextScale, -100)

ResetWindowsTextScale() {
    global textScaleResetInProgress, accessibilityKey, textScaleValueName, applySettleMs

    if textScaleResetInProgress
        return

    textScaleResetInProgress := true
    originalScale := ""

    try {
        originalScale := RegRead(accessibilityKey, textScaleValueName, 100)
        if (!IsInteger(originalScale) || originalScale < 100 || originalScale > 225)
            throw Error("Unexpected text scale value: " originalScale)

        temporaryScale := (originalScale <= 220)
            ? originalScale + 5
            : originalScale - 5

        ToolTip("Reapplying Windows text size: " originalScale "% -> " temporaryScale "%")
        ApplyTextScale(temporaryScale)
        Sleep(applySettleMs)

        ToolTip("Restoring Windows text size to " originalScale "%")
        ApplyTextScale(originalScale)
        Sleep(applySettleMs)

        ShowTemporaryStatus("Windows text size restored to " originalScale "%")
    } catch as err {
        ; Always make a best effort to restore the user's starting value.
        if (originalScale != "") {
            try ApplyTextScale(originalScale)
        }
        ShowTemporaryStatus("Text-size reset failed: " err.Message, 5000)
    } finally {
        textScaleResetInProgress := false
    }
}

ApplyTextScale(scalePercent) {
    global accessibilityKey, textScaleValueName

    RegWrite(scalePercent, "REG_DWORD", accessibilityKey, textScaleValueName)

    ; Notify top-level windows that an accessibility setting changed. The
    ; timeout prevents one hung application from blocking the reset forever.
    broadcastResult := 0
    DllCall(
        "SendMessageTimeoutW",
        "Ptr", 0xFFFF,             ; HWND_BROADCAST
        "UInt", 0x001A,            ; WM_SETTINGCHANGE
        "Ptr", 0,
        "Str", "Accessibility",
        "UInt", 0x0003,            ; SMTO_BLOCK | SMTO_ABORTIFHUNG
        "UInt", 5000,
        "Ptr*", &broadcastResult
    )
}

ShowTemporaryStatus(message, durationMs := 3000) {
    ToolTip(message)
    SetTimer(() => ToolTip(), -durationMs)
}
