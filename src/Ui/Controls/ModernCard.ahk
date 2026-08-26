; ---------------------------------------------------------------------------
; O2om — Modern Dark Card & Button Control Helper
; ---------------------------------------------------------------------------

class O2omCardButton {
    static Create(g, opts, text, isPrimary := false, onClick := "") {
        bgColor := isPrimary ? O2omTheme.ACCENT_FOCUS : O2omTheme.BG_CARD
        textColor := isPrimary ? "FFFFFF" : O2omTheme.TEXT_PRIMARY

        ctrlOpts := opts " Center 0x200 Background" bgColor " c" textColor
        ctrl := g.AddText(ctrlOpts, text)
        ctrl.SetFont((isPrimary ? "s10 Bold" : "s9 Bold"), O2omTheme.FONT_PRIMARY)

        if (onClick != "")
            ctrl.OnEvent("Click", onClick)

        return ctrl
    }

    static SetState(ctrl, isPrimary := false) {
        bgColor := isPrimary ? O2omTheme.ACCENT_FOCUS : O2omTheme.BG_CARD
        textColor := isPrimary ? "FFFFFF" : O2omTheme.TEXT_PRIMARY
        try {
            ctrl.Opt("Background" bgColor " c" textColor)
        }
    }
}
