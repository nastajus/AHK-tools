#Requires AutoHotkey v2.0
#SingleInstance Force

; In Microsoft Photos, use the wheel to trigger previous/next only when the
; pointer is hovering in the same side-edge zones where the on-screen arrows
; normally appear. Everywhere else, the wheel is left alone so native zoom
; behavior keeps working.
; Edge-zone wheel direction:
;   WheelUp/backward   -> next
;   WheelDown/forward  -> last/previous
;
; In Photos only, Up/Down send wheel events from the image center. This keeps
; keyboard zoom working even when the pointer is parked over a side nav zone.
; Alt+Left/Right clicks the side navigation buttons to force previous/next even
; while zoomed in, where normal arrow keys pan instead.
; Shift+arrow tries to pan a zoomed image by simulating a short drag.
; Ctrl+Shift+arrow uses the same pan gesture at 5x distance.

leftZoneWidthPct := 0.16
rightZoneWidthPct := 0.16
zoneTopPct := 0.24
zoneBottomPct := 0.76
sideClickInsetPct := 0.035
wheelBypassSafePct := 0.22
wheelBypassYPct := 0.88

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
    Send "{Right}" ; wheel backward -> next
}

WheelDown:: {
    Send "{Left}" ; wheel forward -> last/previous
}

#HotIf

#HotIf IsPhotosActive()

Up:: {
    SendPhotosCenterWheel("Up")
}

Down:: {
    SendPhotosCenterWheel("Down")
}

!Left:: {
    ClickPhotosSideNav(-1)
}

!Right:: {
    ClickPhotosSideNav(1)
}

+Up:: {
    DragPhotosImage(0, 120)
}

+Down:: {
    DragPhotosImage(0, -120)
}

+Left:: {
    DragPhotosImage(120, 0)
}

+Right:: {
    DragPhotosImage(-120, 0)
}

^+Up:: {
    DragPhotosImage(0, 600)
}

^+Down:: {
    DragPhotosImage(0, -600)
}

^+Left:: {
    DragPhotosImage(600, 0)
}

^+Right:: {
    DragPhotosImage(-600, 0)
}

#HotIf

SendPhotosCenterWheel(direction) {
    global leftZoneWidthPct, rightZoneWidthPct, zoneTopPct, zoneBottomPct, wheelBypassSafePct, wheelBypassYPct

    try {
        CoordMode "Mouse", "Screen"
        MouseGetPos(&startX, &startY)
        WinGetPos(&winX, &winY, &winW, &winH, "A")
    } catch {
        return
    }

    if (winW <= 0 || winH <= 0)
        return

    targetX := startX
    targetY := startY

    leftLimit := winX + Round(winW * leftZoneWidthPct)
    rightLimit := winX + winW - Round(winW * rightZoneWidthPct)
    topLimit := winY + Round(winH * zoneTopPct)
    bottomLimit := winY + Round(winH * zoneBottomPct)

    ; If parked over a side nav zone, move inward and downward to a nearby
    ; safe image area. Photos can swallow wheel events near the visible arrows.
    ; The Photos arrow control appears to consume wheel events near the edge,
    ; so the tiny-threshold offset was not enough.
    if (startY >= topLimit && startY <= bottomLimit) {
        targetY := winY + Round(winH * wheelBypassYPct)

        if (startX <= leftLimit)
            targetX := winX + Round(winW * wheelBypassSafePct)
        else if (startX >= rightLimit)
            targetX := winX + winW - Round(winW * wheelBypassSafePct)
    }

    MouseMove targetX, targetY, 0
    Sleep 20
    Send (direction = "Up") ? "{WheelUp}" : "{WheelDown}"
    Sleep 20
    MouseMove startX, startY, 0
}

DragPhotosImage(dx, dy) {
    CoordMode "Mouse", "Screen"
    MouseGetPos(&startX, &startY)

    Send "{LButton down}"
    Sleep 30
    MouseMove dx, dy, 8, "R"
    Sleep 30
    Send "{LButton up}"

    MouseMove startX, startY, 0
}

ClickPhotosSideNav(direction) {
    global sideClickInsetPct

    try {
        CoordMode "Mouse", "Screen"
        MouseGetPos(&startX, &startY)
        WinGetPos(&winX, &winY, &winW, &winH, "A")
    } catch {
        return
    }

    if (winW <= 0 || winH <= 0)
        return

    clickY := winY + Round(winH * 0.5)
    inset := Max(Round(winW * sideClickInsetPct), 32)
    clickX := (direction < 0)
        ? winX + inset
        : winX + winW - inset

    ; Move first so Photos reveals the side arrow, then click it.
    MouseMove clickX, clickY, 0
    Sleep 80
    Click
    Sleep 40
    MouseMove startX, startY, 0
}
