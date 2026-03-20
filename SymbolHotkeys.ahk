#Requires AutoHotkey v2.0
#SingleInstance Force

; Inserts paired symbols and leaves the caret between them.
; Ctrl+'        -> ‘|’
; Ctrl+Shift+'  -> “|”
; Ctrl+[        -> ⟨|⟩
; Ctrl+?        -> ¿

InsertWrappedPair(leftChar, rightChar) {
    SendText(leftChar rightChar)
    Send "{Left}"
}

^':: {
    InsertWrappedPair("‘", "’")
}

^+':: {
    InsertWrappedPair("“", "”")
}

^[:: {
    InsertWrappedPair("⟨", "⟩")
}

^+/:: {
    SendText("¿")
}
