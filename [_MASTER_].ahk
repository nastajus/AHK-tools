#Requires AutoHotkey v2.0+

childScripts := [
    "C:\tools\ahk\WindowsDictation.ahk",
    "C:\tools\ahk\beepsOnenote.ahk",
    "C:\tools\ahk\beepsYoutube.ahk",
    "C:\tools\ahk\beepsVSCode.ahk",
    "C:\tools\ahk\MultiMonitorToggle_stateful.ahk",
    "C:\tools\ahk\MouseNavigationChords_mmb•lmb.ahk",
    "C:\tools\ahk\MouseNavigationOneNoteSearch_rmb,lmb.ahk",
    "C:\tools\ahk\MouseEmojiPanel.ahk",
    "C:\tools\ahk\ScrollZoomWindows.ahk",

    ;; buggy
    ; "C:\tools\ahk\BetterHistory.ahk",
    ; "C:\tools\ahk\PhotosZoomKeys.ahk"
]

; Launch all scripts initially
for script in childScripts
    Run(script, , "Hide")

; Reload all on Ctrl+Alt+R
^!r:: {
    for script in childScripts {
        ; Close any old copies
        RunWait("taskkill /FI `"WINDOWTITLE eq " script " - AutoHotkey v2`" /F", , "Hide")

        ; Relaunch
        Run(script, , "Hide")
    }
    MsgBox("Scripts reloaded.")
}
