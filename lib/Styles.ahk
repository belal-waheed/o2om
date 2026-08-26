; ---------------------------------------------------------------------------
; O2om — Styles Shim (Forwarding to src/Ui/Theme.ahk)
; ---------------------------------------------------------------------------

#Include ../src/Ui/Theme.ahk

class O2omStyles extends O2omTheme {
    static COLOR_BG        := O2omTheme.BG_ROOT
    static COLOR_SURFACE   := O2omTheme.BG_SURFACE
    static COLOR_CARD      := O2omTheme.BG_CARD
    static COLOR_SEPARATOR := O2omTheme.BORDER_SUBTLE
    static COLOR_PRIMARY   := O2omTheme.ACCENT_FOCUS
    static COLOR_SECONDARY := O2omTheme.ACCENT_EYES
    static COLOR_SUCCESS   := O2omTheme.ACCENT_BREAK
    static COLOR_WARNING   := O2omTheme.ACCENT_WARN
    static COLOR_ERROR     := O2omTheme.ACCENT_URGENT
    static COLOR_TEXT      := O2omTheme.TEXT_PRIMARY
    static COLOR_SUBTEXT   := O2omTheme.TEXT_MUTED
}
