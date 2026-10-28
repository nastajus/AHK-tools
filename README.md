# AHK Tools

Small AutoHotkey v2 scripts I use for mouse chords, one-handed dictation, focus timers, and other quality-of-life improvements in Windows. A couple have become everyday gestures: holding the left mouse button and clicking the right one starts Windows speech input without reaching across the keyboard, while holding the right mouse button and scrolling turns Windows Magnifier into a quick, mouse-driven zoom control. The rest grew around the same idea—small, focused adjustments that make frequently used apps behave more naturally.

## Quick Start

- Install AutoHotkey v2.
- Run `[_MASTER_].ahk` to launch the set of scripts in this folder.
- Use `Ctrl+Alt+R` inside `[_MASTER_].ahk` to reload all child scripts.

## Scripts

- `WindowsDictation.ahk`: LButton + RButton triggers Windows speech input; Ctrl+CapsLock is a keyboard alternative.
- `MouseEmojiPanel.ahk`: MButton + RButton opens the emoji panel.
- `MouseNavigationOneNoteSearch_rmb,lmb.ahk`: OneNote-only RMB+LMB invokes search.
- `MouseNavigationChords_mmb•lmb.ahk`: MButton/LButton chords for back/forward.
- `beepsOnenote.ahk`: focus timer beeps while OneNote is active.
- `beepsYoutube.ahk`: playback timer beeps for YouTube.
- `beepsVSCode.ahk`: focus timer beeps while VS Code is active.
- `ActivityWatchWatchdog.ahk`: monitors `aw-watcher-window_AURA`, auto-recovers on failure, and logs incidents.
- `vscodeVignetteOveruse.ahk`: experimental click-through edge vignette that ramps with VS Code focus time.
- `OverdriveStayAwake.ahk`: temporarily keeps the display awake while focused on OverDrive.
- `MouseScrollZoom.ahk`: RButton + wheel controls Windows Magnifier zoom.
- `TextScaleResetWidnows.ahk`: Ctrl+Alt+Shift+F12 reapplies the saved Windows Accessibility text size.
- `MultiMonitorToggle_stateful.ahk`: Ctrl+Alt+M toggles the primary display.
