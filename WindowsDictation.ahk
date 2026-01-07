#Requires AutoHotkey v2.0

SendWinH() {
    SendInput("{LWin down}h{LWin up}")
}

; Optional fallback hotkey
^`::SendWinH()

; Version 2.1:
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
;; // January 6 2026, Version 2.1
;; // I think this is good now. Left click holding and dragging works. 
;; // usage: Left click first, then right click and release left click soon after.
;; // that's it. seems to work.


; #Requires AutoHotkey v2.0
; 
; SendWinH() {
;     SendInput("{LWin down}h{LWin up}")
; }
; 
; ; Optional: your old hotkey still works
; ^`::SendWinH()
; 
; ; ---- LButton + RButton chord (either order), suppresses context menu ----
; global chordFired := false
; global chordWindowMs := 90  ; adjust 60–150ms to taste
; 
; ChordMaybeFire() {
;     global chordFired
;     if chordFired
;         return false
; 
;     if GetKeyState("LButton", "P") && GetKeyState("RButton", "P") {
;         chordFired := true
;         SendWinH()
;         ; wait until both released so it doesn't retrigger while held
;         while GetKeyState("LButton","P") || GetKeyState("RButton","P")
;             Sleep 10
;         chordFired := false
;         return true
;     }
;     return false
; }
; 
; ; Right button handler: allow normal right-click unless chord happens
; *RButton::
; {
;     start := A_TickCount
;     ; give a tiny window for LButton to already be down or become down
;     while (A_TickCount - start) < chordWindowMs {
;         if ChordMaybeFire()
;             return  ; chord fired: DO NOT send right click => no context menu
;         Sleep 5
;     }
;     ; no chord => normal right click
;     SendInput("{RButton}")
; }
; 
; ; Left button handler: same idea, supports the reverse order (L then R)
; *LButton::
; {
;     start := A_TickCount
;     while (A_TickCount - start) < chordWindowMs {
;         if ChordMaybeFire()
;             return  ; chord fired: suppress left click too (prevents accidental click)
;         Sleep 5
;     }
;     SendInput("{LButton}")
; }
; ;; // January 6 2026, Version 2.0
; ;; // https://chatgpt.com/c/695e7c58-72bc-8327-854c-cf0901237dac
; ;; // seems like most stable ordering is left then right. Adjust habits accordingly.
; ;; // however, Breaks normal left click selecting.



; #Requires AutoHotkey v2.0
; 
; SendWinH() {
;     SendInput("{LWin down}h{LWin up}")
; }
; 
; ; How long to keep Ctrl logically "up" after triggering (milliseconds).
; ; Increase if Ctrl still cancels dictation for you (try 250–600).
; global CtrlGraceMs := 1000
; 
; ; Optional fallback hotkey
; ^`::SendWinH()
; 
; ; Ctrl + Right Click => Dictation, suppress context menu, and make Ctrl-hold forgiving
; *^RButton::
; {
;     global CtrlGraceMs
; 
;     ; Record whether user is physically holding left/right Ctrl
;     lPhys := GetKeyState("LCtrl", "P")
;     rPhys := GetKeyState("RCtrl", "P")
; 
;     ; Force Ctrl logically up so it doesn't interfere with Win+H / dictation start
;     SendInput("{LCtrl up}{RCtrl up}")
; 
;     ; Trigger dictation
;     SendWinH()
; 
;     ; After a short grace period, restore Ctrl logically if user is STILL physically ; holding it
;     SetTimer(() => RestoreCtrlIfStillHeld(lPhys, rPhys), -CtrlGraceMs)
; 
;     return  ; suppress the normal right-click (no context menu)
; }
; 
; RestoreCtrlIfStillHeld(lWasDown, rWasDown) {
;     ; Only re-apply Ctrl if the user is still physically holding it now
;     if (lWasDown && GetKeyState("LCtrl", "P"))
;         SendInput("{LCtrl down}")
;     if (rWasDown && GetKeyState("RCtrl", "P"))
;         SendInput("{RCtrl down}")
; }
; ;; // January 6 2026, Version 4
; ;; // buggy as well, holding central disables dictation immediately also. no diff.



; #Requires AutoHotkey v2.0
; 
; SendWinH() {
;     SendInput("{LWin down}h{LWin up}")
; }
; 
; ; Optional fallback hotkey
; ^`::SendWinH()
; 
; ; Ctrl + Right Click → Dictation (NO context menu)
; *^RButton::
; {
;     SendWinH()
;     return  ; suppress RButton so menu never appears
; }
; ;; // January 6 2026, Version 3 
; ;; // Determined Has a bug, canceling Windows transcription if control is held



; #Requires AutoHotkey v2.0
; 
; ; Triggers Windows Voice Typing / Dictation (Win+H)
; SendWinH() {
;     SendInput("{LWin down}h{LWin up}")
; }
; 
; ; CTRL + backtick
; ^`::SendWinH()
; 
; ; Either order: Forward + LeftClick
; XButton2 & LButton::SendWinH()
; ~LButton & XButton2::SendWinH()
; 
; ; Keep Forward button working normally when pressed by itself
; XButton2::SendInput("{XButton2}")
; ;; // January 1 2026
; ;; // the above works sufficiently well, just ergonomically a bit annoying 



; #Requires AutoHotkey v2.0
; ; CTRL + backtick 
; ^`::SendInput("{LWin down}h{LWin up}")
; ;; // July 16 2025