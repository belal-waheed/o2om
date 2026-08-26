; ---------------------------------------------------------------------------
; O2om — Redesigned Modern Dashboard View (Hero Action & Obsidian Dark Cards)
; ---------------------------------------------------------------------------

#Include ../Controls/ModernCard.ahk

class O2omDashboardView {
    static Build(g, appInstance, controlsList) {
        ; Mode Selector Pills (y54)
        m := appInstance.settings.mode
        btnModeStandup := O2omCardButton.Create(g, "x25 y54 w115 h28", O2omLang.Get("mode_standup"), (m == "standup"), (*) => appInstance.ChangeMode("standup"))
        appInstance.btnModeStandup := btnModeStandup
        controlsList.Push(btnModeStandup)

        btnModeEye := O2omCardButton.Create(g, "x150 y54 w120 h28", O2omLang.Get("mode_eyeguard"), (m == "eyeguard"), (*) => appInstance.ChangeMode("eyeguard"))
        appInstance.btnModeEye := btnModeEye
        controlsList.Push(btnModeEye)

        btnModePomodoro := O2omCardButton.Create(g, "x280 y54 w115 h28", O2omLang.Get("mode_pomodoro"), (m == "pomodoro"), (*) => appInstance.ChangeMode("pomodoro"))
        appInstance.btnModePomodoro := btnModePomodoro
        controlsList.Push(btnModePomodoro)

        ; Daily Goal & Streak Summary Badge (y90)
        badgeTxt := g.AddText("x20 y90 w380 h20 Center c" O2omTheme.ACCENT_BREAK, "")
        badgeTxt.SetFont("s9 Bold", O2omTheme.FONT_PRIMARY)
        appInstance.badgeText := badgeTxt
        controlsList.Push(badgeTxt)

        ; Cycle & Status Subtitle (y114)
        st := g.AddText("x20 y114 w380 h20 Center c" O2omTheme.TEXT_MUTED, "")
        st.SetFont("s9", O2omTheme.FONT_PRIMARY)
        appInstance.statusText := st
        controlsList.Push(st)

        ; Tabular Large Countdown Timer (y138)
        ct := g.AddText("x20 y138 w380 h64 Center c" O2omTheme.TEXT_PRIMARY, "00:00")
        ct.SetFont("s42 Bold", O2omTheme.FONT_DISPLAY)
        appInstance.countdownText := ct
        controlsList.Push(ct)

        ; Visual Progress Line (y210)
        pb := g.AddProgress("x40 y210 w340 h4 Background" O2omTheme.BG_CARD " c" O2omTheme.ACCENT_FOCUS, 0)
        appInstance.progressBar := pb
        controlsList.Push(pb)

        ; -------------------------------------------------------------------
        ; Action Center: Hero Controls (y226)
        ; -------------------------------------------------------------------

        ; Normal State: Reset & Pause Card Buttons (side-by-side)
        btnReset := O2omCardButton.Create(g, "x40 y226 w165 h42", O2omLang.Get("btn_reset"), false, (*) => appInstance.ResetTimer())
        appInstance.btnReset := btnReset
        controlsList.Push(btnReset)

        btnPause := O2omCardButton.Create(g, "x215 y226 w165 h42", O2omLang.Get("btn_pause"), true, (*) => appInstance.TogglePauseTimer())
        appInstance.btnPause := btnPause
        controlsList.Push(btnPause)

        ; Wait Work State: Single Prominent Hero Button
        btnStartWork := O2omCardButton.Create(g, "x40 y226 w340 h44", O2omLang.Get("btn_start_work"), true, (*) => appInstance.StartWorkMode())
        btnStartWork.Visible := false
        appInstance.btnStartWork := btnStartWork
        controlsList.Push(btnStartWork)

        ; Wait Break State: Large Prominent Stretches Hero Button
        btnStartExercises := O2omCardButton.Create(g, "x40 y226 w340 h44", O2omLang.Get("btn_start_exercises"), true, (*) => appInstance.StartBreakMode(true))
        btnStartExercises.Opt("Background" O2omTheme.ACCENT_BREAK " cFFFFFF") ; Bright Emerald Hero
        btnStartExercises.Visible := false
        appInstance.btnStartExercises := btnStartExercises
        controlsList.Push(btnStartExercises)

        ; Wait Break Secondary Action Chips (y280)
        btnQuietBreak := O2omCardButton.Create(g, "x40 y280 w165 h34", O2omLang.Get("btn_quiet_break"), false, (*) => appInstance.StartBreakMode(false))
        btnQuietBreak.Visible := false
        appInstance.btnQuietBreak := btnQuietBreak
        controlsList.Push(btnQuietBreak)

        btnSnoozeChip := O2omCardButton.Create(g, "x215 y280 w165 h34", O2omLang.Get("btn_snooze_chip"), false, (*) => appInstance.SnoozeTimer())
        btnSnoozeChip.Visible := false
        appInstance.btnSnoozeChip := btnSnoozeChip
        controlsList.Push(btnSnoozeChip)

        ; Dock to Mini-Pill Button (y340)
        btnDock := O2omCardButton.Create(g, "x40 y340 w340 h32", O2omLang.Get("btn_dock_pill"), false, (*) => appInstance.ActivateMiniPill())
        appInstance.btnDock := btnDock
        controlsList.Push(btnDock)

        ; Startup Checkbox (y390)
        isStartup := (appInstance.settings.startWithWindows == 1)
        chkStart := g.AddCheckbox("x40 y390 w340 h24 c" O2omTheme.TEXT_PRIMARY " " (isStartup ? "Checked" : ""), O2omLang.Get("chk_startup"))
        chkStart.SetFont("s9", O2omTheme.FONT_PRIMARY)
        chkStart.OnEvent("Click", (ctrl, *) => appInstance.OnStartupToggle(ctrl.Value))
        appInstance.startupCheck := chkStart
        controlsList.Push(chkStart)
    }
}
