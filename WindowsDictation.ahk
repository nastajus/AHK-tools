#Requires AutoHotkey v2.0
#SingleInstance Force

SendWinH() {
    SendInput("{LWin down}h{LWin up}")
}

; Older keyboard fallbacks, disabled because they conflict with other apps.
; ^`::SendWinH()

; Left-hand keyboard fallbacks that preserve the existing CapsLock state.
^CapsLock::TriggerDictationPreservingCapsLock()
#CapsLock::TriggerDictationPreservingCapsLock()

TriggerDictationPreservingCapsLock() {
    wasOn := GetKeyState("CapsLock", "T")
    SendWinH()
    Sleep 50
    SetCapsLockState wasOn ? "On" : "Off"
}

; ^!z::SendWinH()

; While holding Left Mouse (drag/select works normally), click Right Mouse:
; -> Trigger dictation AND suppress the context menu.
; Otherwise, Right Mouse works normally.
#HotIf GetKeyState("LButton", "P")

$*RButton::
{
    SendWinH()
}

#HotIf
