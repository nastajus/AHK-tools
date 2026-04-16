#Requires AutoHotkey v2.0
#SingleInstance Force

; In Microsoft Photos, use the wheel to trigger previous/next only when the
; pointer is hovering in the same side-edge zones where the on-screen arrows
; normally appear. Everywhere else, the wheel is left alone so native zoom
; behavior keeps working.

leftZoneWidthPct := 0.16
rightZoneWidthPct := 0.16
zoneTopPct := 0.24
zoneBottomPct := 0.76

IsPhotosActive() {
    try {
        return (StrLower(WinGetProcessName("A")) = "photos.exe")
    } catch {
        return false
    }
}

GetPhotosArrowZone() {
    global leftZoneWidthPct, rightZoneWidthPct, zoneTopPct, zoneBottomPct

    if !IsPhotosActive()
        return 0

    try {
        WinGetPos(&winX, &winY, &winW, &winH, "A")
        MouseGetPos(&mouseX, &mouseY)
    } catch {
        return 0
    }

    if (winW <= 0 || winH <= 0)
        return 0

    leftLimit := winX + Round(winW * leftZoneWidthPct)
    rightLimit := winX + winW - Round(winW * rightZoneWidthPct)
    topLimit := winY + Round(winH * zoneTopPct)
    bottomLimit := winY + Round(winH * zoneBottomPct)

    if (mouseY < topLimit || mouseY > bottomLimit)
        return 0

    if (mouseX <= leftLimit)
        return -1

    if (mouseX >= rightLimit)
        return 1

    return 0
}

#HotIf GetPhotosArrowZone() != 0

WheelUp:: {
    Send "{Left}"
}

WheelDown:: {
    Send "{Right}"
}

#HotIf
