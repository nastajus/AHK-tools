; Use Ctrl + Alt + M to toggle primary monitor

multiTool := "C:\tools\multimonitortool\MultiMonitorTool.exe" ; Your path

^!m:: {
    tempFile := A_ScriptDir . "\temp_monitors.csv"
    cmdLine := multiTool . ' /scomma "' . tempFile . '"'

    ; Export monitor info
    RunWait cmdLine, , "Hide"

    if !FileExist(tempFile) {
        MsgBox "Monitor list file not found."
        return
    }

    output := FileRead(tempFile)
    FileDelete tempFile

    lines := StrSplit(output, "`n")
    primaryID := ""
    otherID := ""
    primaryName := ""
    otherName := ""

    for line in lines {
        line := Trim(line)
        if (line = "") || InStr(line, "Resolution")
            continue

        fields := StrSplit(line, ",")

        if fields.Length >= 23 {
            monitorID := Trim(fields[15])       ; Column 15 = \\.\DISPLAY#
            isPrimary := Trim(fields[8])        ; Column 8 = Primary (Yes/No)
            monitorName := Trim(fields[23])     ; Column 23 = Friendly Monitor Name

            if (isPrimary = "Yes") {
                primaryID := monitorID
                primaryName := monitorName
            } else if (otherID = "") {
                otherID := monitorID
                otherName := monitorName
            }
        }
    }

    if (primaryID != "" && otherID != "") {
        newPrimaryCmd := multiTool . ' /SetPrimary "' . otherID . '"'
        Run newPrimaryCmd, , "Hide"
        
        ShowFlashMessage("Switched to " otherName)

        ;;;; !!!! ;;;; MsgBox "Switched primary monitor to:`n" otherID "`n(" otherName ")"
    } else {
        MsgBox "Could not detect both monitors to toggle.`nPrimary: " primaryID " (" primaryName ")`nOther: " otherID " (" otherName ")"
    }
}



ShowFlashMessage(text, duration := 2000) {
    static overlay := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20") ; click-through
    overlay.BackColor := "Black"
    overlay.SetFont("s20 cWhite", "Segoe UI")

    ; Clear previous controls
    overlay.Destroy()
    overlay := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
    overlay.BackColor := "Black"
    overlay.SetFont("s20 cWhite", "Segoe UI")
    overlay.AddText("Center vCenter", text)

    overlay.Show("AutoSize Center")
    SetTimer () => overlay.Hide(), -duration
}