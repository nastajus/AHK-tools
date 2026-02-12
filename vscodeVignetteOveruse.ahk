#Requires AutoHotkey v2.0
#SingleInstance Force

A_IconTip := "VS Code Vignette Alert"

; ===== CONFIG =====
rampToMaxMs := 45 * 60 * 1000        ; reach full vignette after 45 min focused
pollMs := 250
mode := "pause"                       ; "pause" or "reset" when focus is lost
steps := 14                           ; more steps = smoother vignette gradient
bandPx := 24                          ; thickness of each step layer
maxAlpha := 170                       ; final outer opacity (0-255)
alertBeepEveryMs := 300000            ; beep every 5 min after full intensity
alertBeepFreq := 1900
alertBeepDurMs := 180

; ===== STATE =====
timerOn := true
elapsedMs := 0
wasFocused := false
overMaxAlertMs := 0
overlays := []

InitOverlays()
SetTimer(Tick, pollMs)
OnExit(Cleanup)
OnMessage(0x007E, OnDisplayChange) ; WM_DISPLAYCHANGE
UpdateVignette(0.0)
UpdateStatusIconTip(false, elapsedMs, rampToMaxMs, 0.0)

Tick() {
    global timerOn, elapsedMs, wasFocused, overMaxAlertMs
    global pollMs, mode, rampToMaxMs
    global alertBeepEveryMs, alertBeepFreq, alertBeepDurMs

    if !timerOn {
        UpdateVignette(0.0)
        UpdateStatusIconTip(false, elapsedMs, rampToMaxMs, 0.0)
        return
    }

    focused := IsVSCodeFocused()

    if (wasFocused && !focused && mode = "reset") {
        elapsedMs := 0
        overMaxAlertMs := 0
    }

    if focused {
        elapsedMs += pollMs
    }

    intensity := Min(elapsedMs / rampToMaxMs, 1.0)
    UpdateVignette(intensity)
    UpdateStatusIconTip(focused, elapsedMs, rampToMaxMs, intensity)

    if (focused && intensity >= 1.0 && alertBeepEveryMs > 0) {
        overMaxAlertMs += pollMs
        if (overMaxAlertMs >= alertBeepEveryMs) {
            overMaxAlertMs := 0
            SoundBeep(alertBeepFreq, alertBeepDurMs)
        }
    } else if (intensity < 1.0) {
        overMaxAlertMs := 0
    }

    wasFocused := focused
}

IsVSCodeFocused() {
    return WinActive("ahk_exe Code.exe") || WinActive("ahk_exe Code - Insiders.exe")
}

InitOverlays() {
    global overlays, steps, bandPx
    Cleanup()

    left := SysGet(76)
    top := SysGet(77)
    width := SysGet(78)
    height := SysGet(79)

    overlays := []
    Loop steps {
        step := A_Index
        inset := (step - 1) * bandPx
        thick := bandPx
        weight := ((steps - step + 1) / steps) ** 2

        ; Top edge band
        AddOverlay(overlays, left + inset, top + inset, width - 2 * inset, thick, weight)
        ; Bottom edge band
        AddOverlay(overlays, left + inset, top + height - inset - thick, width - 2 * inset, thick, weight)
        ; Left edge band (excluding corners to reduce double-darkening)
        AddOverlay(overlays, left + inset, top + inset + thick, thick, height - 2 * (inset + thick), weight)
        ; Right edge band
        AddOverlay(overlays, left + width - inset - thick, top + inset + thick, thick, height - 2 * (inset + thick), weight)
    }
}

AddOverlay(ByRef arr, x, y, w, h, weight) {
    if (w <= 0 || h <= 0)
        return

    g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +E0x08000000")
    g.BackColor := "Black"
    g.Show("NA x" x " y" y " w" w " h" h)

    hwnd := g.Hwnd
    ex := DllCall("GetWindowLongPtrW", "Ptr", hwnd, "Int", -20, "Ptr")
    ex := ex | 0x80000 | 0x20 | 0x80 | 0x08000000 ; WS_EX_LAYERED|TRANSPARENT|TOOLWINDOW|NOACTIVATE
    DllCall("SetWindowLongPtrW", "Ptr", hwnd, "Int", -20, "Ptr", ex, "Ptr")
    DllCall("SetLayeredWindowAttributes", "Ptr", hwnd, "UInt", 0, "UChar", 0, "UInt", 0x2)

    arr.Push({ gui: g, hwnd: hwnd, weight: weight })
}

UpdateVignette(intensity) {
    global overlays, maxAlpha

    for item in overlays {
        alpha := Round(maxAlpha * intensity * item.weight)
        DllCall("SetLayeredWindowAttributes", "Ptr", item.hwnd, "UInt", 0, "UChar", alpha, "UInt", 0x2)
    }
}

UpdateStatusIconTip(isFocused, elapsedMs, rampMs, intensity) {
    symbol := isFocused ? "?" : "?"
    remainingMs := Max(rampMs - elapsedMs, 0)
    pct := Round(intensity * 100)
    A_IconTip := "VS Code Vignette Alert`n" symbol " | " FormatDurationMs(elapsedMs) " | " FormatDurationMs(remainingMs) " | " pct "%"
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

OnDisplayChange(*) {
    InitOverlays()
}

; Ctrl+Shift+Alt+V toggles the vignette timer.
^+!v:: {
    global timerOn, elapsedMs, rampToMaxMs
    timerOn := !timerOn
    if timerOn {
        TrayTip("VS Code Vignette", "Running", 2)
    } else {
        TrayTip("VS Code Vignette", "Paused", 2)
        UpdateVignette(0.0)
    }
    UpdateStatusIconTip(false, elapsedMs, rampToMaxMs, Min(elapsedMs / rampToMaxMs, 1.0))
}

Cleanup(*) {
    global overlays
    for item in overlays {
        try item.gui.Destroy()
    }
    overlays := []
}
