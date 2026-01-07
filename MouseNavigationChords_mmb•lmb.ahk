#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; Mouse chord navigation (reliable version)
;
; Middle then Left  -> Alt + Left
; Left then Middle  -> Alt + Right
;
; Implementation:
; - On the SECOND button press, check whether the FIRST is down.
; - Uses GetKeyState("...","P") (physical state) for reliability.
; ============================================================

; If you press Left while Middle is physically held -> Back (Alt+Left)
~LButton::
{
    if GetKeyState("MButton", "P")
        Send("!{Left}")
}

; If you press Middle while Left is physically held -> Forward (Alt+Right)
~MButton::
{
    if GetKeyState("LButton", "P")
        Send("!{Right}")
}
