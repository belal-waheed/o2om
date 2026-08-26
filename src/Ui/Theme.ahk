; ---------------------------------------------------------------------------
; O2om — Visual Design Tokens & Windows DWM Dark Mode Adapter
; ---------------------------------------------------------------------------

class O2omTheme {
    ; Modern Obsidian Dark Palette
    static BG_ROOT         := "0D0E15"  ; Deep void background
    static BG_SURFACE      := "161822"  ; Elevated panel
    static BG_CARD         := "1F2333"  ; Card background & input fill
    static BORDER_SUBTLE   := "2A3048"  ; Card border / Separator
    static BORDER_ACTIVE   := "6366F1"  ; Focused border

    ; Semantic Accents
    static ACCENT_FOCUS    := "6366F1"  ; Indigo / Deep focus
    static ACCENT_BREAK    := "10B981"  ; Emerald / Rest & Health
    static ACCENT_WARN     := "F59E0B"  ; Amber / Warning
    static ACCENT_URGENT   := "F43F5E"  ; Rose / Auto reset
    static ACCENT_EYES     := "06B6D4"  ; Cyan / Eye Guard

    ; Typography Colors
    static TEXT_PRIMARY    := "F1F5F9"  ; High contrast text
    static TEXT_MUTED      := "94A3B8"  ; Subtitle / Muted text
    static TEXT_HINT       := "64748B"  ; Secondary hint

    ; Font Families
    static FONT_PRIMARY    := "Segoe UI"
    static FONT_DISPLAY    := "Segoe UI Variable Display"
    static FONT_TEXT       := "Segoe UI Variable Text"

    ; Window Dimensions
    static WIN_WIDTH       := 420
    static WIN_HEIGHT      := 470
    static PILL_WIDTH      := 160
    static PILL_HEIGHT     := 46

    ; Enables native dark title bar on Windows 10/11
    static EnableDarkTitleBar(hwnd) {
        if (!hwnd)
            return

        ; DWMWA_USE_IMMERSIVE_DARK_MODE (20 on Win 10 20H1+ and Win 11, 19 on earlier builds)
        try {
            val := 1
            hr := DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "Int", 20, "Int*", val, "Int", 4)
            if (hr != 0)
                DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "Int", 19, "Int*", val, "Int", 4)
        }
    }
}
