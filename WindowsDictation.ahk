#Requires AutoHotkey v2.0

SendWinH() {
    SendInput("{LWin down}h{LWin up}")
}

; Optional fallback hotkey
^`::SendWinH()

; While holding Left Mouse (drag/select works normally), click Right Mouse:
; -> Trigger dictation AND suppress the context menu.
; Otherwise, Right Mouse works normally.
$*RButton::
{
    if GetKeyState("LButton", "P") {
        SendWinH()
        return  ; suppress the right-click => no context menu
    }

    ; Normal right click when LButton is NOT held
    SendInput("{RButton}")
}
