---
name: autohotkey-v2-gui-patterns
description: Conventions and patterns for building robust, flicker-free, localized AutoHotkey v2 desktop GUI applications.
---

# AutoHotkey v2 GUI Engineering Patterns

## 1. Eliminating Redraw Flicker (`WS_CLIPCHILDREN`)
When updating text controls periodically (e.g. every second in a timer tick), Windows erases the parent window background under child controls, causing noticeable screen flickering.
- **Fix**: Pass `+0x02000000` (`WS_CLIPCHILDREN`) in the Gui constructor options:
  ```autohotkey
  g := Gui("+MinimizeBox -MaximizeBox +0x02000000", "App Title")
  ```

## 2. Preventing Visibility Ghosting & Coordinate Overlaps
- **Visibility Ghosting**: Toggling control visibility (`ctrl.Visible := false`) on overlapping controls in Windows GDI leaves painted artifacts ("ghosting"). Call `WinRedraw`:
  ```autohotkey
  ctrl.Visible := false
  if (gui && gui.Hwnd)
      try WinRedraw("ahk_id " gui.Hwnd)
  ```
- **Coordinate Overlaps**: Never place two controls (such as a Progress bar separator and a Text label) at the exact same Y position. Overlapping controls cause GDI mouse cursor flickering and repaint churn.

## 3. Mouse Loading Cursor Release (`IDC_ARROW`)
When showing a new window or restoring from tray, Windows may retain the `IDC_APPSTARTING` loading spinner cursor until input is processed.
- **Fix**: Explicitly reset the cursor to normal arrow on window display:
  ```autohotkey
  try DllCall("SetCursor", "Ptr", DllCall("LoadCursor", "Ptr", 0, "Int", 32512, "Ptr"))
  ```

## 4. Standalone Binary Asset Bundling (`FileInstall`)
When distributing standalone compiled `.exe` files, direct relative asset paths (`A_ScriptDir "\assets\..."`) fail on other machines.
- **Fix**: Use a `ResourceManager` class with `FileInstall` to embed assets into the binary and extract them to `%APPDATA%\<App>\assets\` at runtime:
  ```autohotkey
  class AppResources {
      static Init() {
          appDataAssets := A_AppData "\MyApp\assets"
          try DirCreate(appDataAssets)
          target := appDataAssets "\image.png"
          if !FileExist(target)
              try FileInstall("assets\image.png", target, 1)
      }
  }
  ```

## 5. Clean Windows Action Center Toast Notifications (Without Blue Icon)
Windows 10/11 draws a large blue standard `(i)` circle icon if option `1` is passed.
- **Fix**: Call `try TrayTip()` to clear previous toasts, and pass `"Mute"` to render a clean toast without the blue icon or duplicate beep:
  ```autohotkey
  try TrayTip()
  try TrayTip(message, title, "Mute")
  ```

## 6. Exception Guarding & Defensive Parsing
- Wrap control property updates in `try` blocks to prevent crashes during GUI reconstruction:
  ```autohotkey
  try countdownText.Value := timeStr
  ```
- Validate all user text inputs with `IsInteger()` / safe parsing before updating settings.
- Guard secondary/modal windows with `if (this.modalGui && IsObject(this.modalGui))` before invoking methods.

## 7. Native RTL (Right-to-Left) Layout
For Arabic or Hebrew GUI applications:
- **Fix**: Append `+E0x400000` (`WS_EX_LAYOUTRTL`) to the GUI options:
  ```autohotkey
  if (isRTL)
      guiOpts .= " +E0x400000"
  ```
  Windows automatically mirrors control positioning, title bar, checkboxes, and text flow natively.

## 8. DropDownList Popup Height (`rN`)
`AddDropDownList` without an explicit row parameter collapses the popup menu list.
- **Fix**: Always specify `r2` or `r5`:
  ```autohotkey
  ddl := g.AddDropDownList("x260 y56 w100 r2 Choose1", ["العربية", "English"])
  ```

## 9. Headless Compilation Automation via Ahk2Exe CLI
```powershell
pwsh -NoProfile -Command "Start-Process 'C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe' -ArgumentList '/in \"<Source.ahk>\" /out \"<Target.exe>\" /icon \"<Icon.ico>\" /base \"C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe\" /silent' -Wait"
```
