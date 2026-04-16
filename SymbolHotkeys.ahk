#Requires AutoHotkey v2.0
#SingleInstance Force

; Symbol shortcuts.
;
; AHK hotkey shorthand used below:
; ^  = Ctrl
; !  = Alt
; +  = Shift
; ^'    means Ctrl+'
; ^!,   means Ctrl+Alt+,
; ^!.,  means Ctrl+Alt+.
; ^!+,  means Ctrl+Alt+Shift+,  which is Ctrl+Alt+<
; ^!+.  means Ctrl+Alt+Shift+.  which is Ctrl+Alt+>
; ^+/   means Ctrl+Shift+/      which is Ctrl+?
; ^!=   means Ctrl+Alt+=
; ^!+=  means Ctrl+Alt+Shift+=
; ^*    means Ctrl+Shift+8      which is Ctrl+*
; sc028 is the physical apostrophe/quote key on a US keyboard. Using the scan
; code avoids layout/text-service character translation issues in OneNote.
;
; Active mappings:
; Ctrl+'                          -> ‘|’
; Ctrl+Shift+apostrophe key       -> “|”
; Ctrl+Alt+,                      -> ⟨
; Ctrl+Alt+.                      -> ⟩
; Ctrl+Alt+<                      -> ⟨.⟩
; Ctrl+Alt+>                      -> ⟨.⟩
; Ctrl+?                          -> ¿
; Ctrl+Alt+=                      -> ≈
; Ctrl+Alt+Shift+=                -> ≅
; Ctrl+*                          -> °

InsertWrappedPair(leftChar, rightChar) {
    SendText(leftChar rightChar)
    Send "{Left}"
}

^':: {
    InsertWrappedPair("‘", "’")
}

; Physical-key binding avoids layout/app translation issues that were causing
; the character-based Ctrl+Shift+' hotkey to misfire in OneNote.
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
