#Requires AutoHotkey v2.0
#SingleInstance Force

; Symbol shortcuts.
;
; AHK hotkey shorthand used below:

;    + Shift
;    ^ Ctrl     ! Alt

; ^sc028 Ctrl + physical apostrophe/quote key
; ^!,  Ctrl Alt ,
; ^!., Ctrl Alt .

; ^!+, Ctrl Alt Shift ,  which is Ctrl Alt <
; ^!+. Ctrl Alt Shift .  which is Ctrl Alt >
; ^+/  Ctrl Shift /      which is Ctrl ?
; ^*   Ctrl Shift 8      which is Ctrl *

; ^!=  Ctrl Alt =
; ^!+= Ctrl Alt Shift =

; sc028 is the physical apostrophe/quote key on a US keyboard. Using the scan
; code avoids layout/text-service character translation issues in OneNote.
; This is used for quote hotkeys because character-based quote bindings can be
; triggered by unrelated physical keys when OneNote/Windows temporarily reports
; a translated character instead of the key's stable physical identity.
;
; Active mappings:
; Ctrl+apostrophe key         -> ‘|’
; Ctrl+Shift+apostrophe key   -> “|”
; Ctrl+Alt+,                  -> ⟨
; Ctrl+Alt+.                  -> ⟩
; Ctrl+Alt+<                  -> ⟨.⟩
; Ctrl+Alt+>                  -> ⟨.⟩
; Ctrl+?                      -> ¿
; Ctrl+Alt+=                  -> ≈
; Ctrl+Alt+Shift+=            -> ≅
; Ctrl+*                      -> °

InsertWrappedPair(leftChar, rightChar) {
    SendText(leftChar rightChar)
    Send "{Left}"
}

^sc028:: {
    InsertWrappedPair("‘", "’")
}

^+sc028:: {
    InsertWrappedPair("“", "”")
}

; Old bracket bindings kept here for reference because OneNote appears to
; intercept these keystrokes before the symbol hotkey can act.
; ^[:: {
;     SendText("⟨")
; }
;
; ^]:: {
;     SendText("⟩")
; }

^!,:: {
    SendText("⟨")
}

^!.:: {
    SendText("⟩")
}

^!+,:: {
    SendText("⟨.⟩")
}

^!+.:: {
    SendText("⟨.⟩")
}

^+/:: {
    SendText("¿")
}

^!=:: {
    SendText("≈")
}

^!+=:: {
    SendText("≅")
}

^*:: {
    SendText("°")
}
