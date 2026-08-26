; ---------------------------------------------------------------------------
; O2om — Dashboard & Timer View
; ---------------------------------------------------------------------------

class O2omDashboardView {
    static Build(g, appInstance, controlsList) {
        ; Cycle Badge Text (e.g. Cycle 1 of 4)
        cycleTxt := g.AddText("x20 y58 w345 h18 Center c" O2omStyles.COLOR_SUBTEXT, "")
        cycleTxt.SetFont("s9", O2omStyles.FONT_PRIMARY)
        appInstance.cycleText := cycleTxt
        controlsList.Push(cycleTxt)

        ; Status Text
        st := g.AddText("x20 y76 w345 h20 Center c" O2omStyles.COLOR_PRIMARY, "")
        st.SetFont("s10 Bold", O2omStyles.FONT_PRIMARY)
        appInstance.statusText := st
        controlsList.Push(st)

        ; Countdown Timer Text (h64 with s38 bold fits cleanly)
        ct := g.AddText("x20 y98 w345 h64 Center c" O2omStyles.COLOR_TEXT, "00:00")
        ct.SetFont("s38 Bold", O2omStyles.FONT_TITLE)
        appInstance.countdownText := ct
        controlsList.Push(ct)

        ; Progress Bar (4px sleek accent line)
        pb := g.AddProgress("x43 y164 w300 h4 Background" O2omStyles.COLOR_CARD " c" O2omStyles.COLOR_PRIMARY, 0)
        appInstance.progressBar := pb
        controlsList.Push(pb)

        ; Action Buttons (Slot 1 at y176: Reset & Pause side-by-side, or StartWork / StartExercises)
        btnReset := g.AddButton("x43 y176 w145 h34", O2omLang.Get("btn_reset"))
        btnReset.SetFont("s10 Bold", O2omStyles.FONT_PRIMARY)
        btnReset.OnEvent("Click", (*) => appInstance.ResetTimer())
        appInstance.btnReset := btnReset
        controlsList.Push(btnReset)

        btnPause := g.AddButton("x198 y176 w145 h34", O2omLang.Get("btn_pause"))
        btnPause.SetFont("s10 Bold", O2omStyles.FONT_PRIMARY)
        btnPause.OnEvent("Click", (*) => appInstance.TogglePauseTimer())
        appInstance.btnPause := btnPause
        controlsList.Push(btnPause)

        btnStartWork := g.AddButton("x43 y176 w300 h34", O2omLang.Get("btn_start_work"))
        btnStartWork.SetFont("s10 Bold", O2omStyles.FONT_PRIMARY)
        btnStartWork.OnEvent("Click", (*) => appInstance.StartWorkMode())
        btnStartWork.Visible := false
        appInstance.btnStartWork := btnStartWork
        controlsList.Push(btnStartWork)

        btnStartExercises := g.AddButton("x43 y176 w300 h34", O2omLang.Get("btn_start_exercises"))
        btnStartExercises.SetFont("s9 Bold", O2omStyles.FONT_PRIMARY)
        btnStartExercises.OnEvent("Click", (*) => appInstance.StartBreakMode(true))
        btnStartExercises.Visible := false
        appInstance.btnStartExercises := btnStartExercises
        controlsList.Push(btnStartExercises)

        btnStartBreak := g.AddButton("x43 y216 w300 h34", O2omLang.Get("btn_start_break"))
        btnStartBreak.SetFont("s9 Bold", O2omStyles.FONT_PRIMARY)
        btnStartBreak.OnEvent("Click", (*) => appInstance.StartBreakMode(false))
        btnStartBreak.Visible := false
        appInstance.btnStartBreak := btnStartBreak
        controlsList.Push(btnStartBreak)

        btnSnooze := g.AddButton("x43 y256 w300 h34", O2omLang.Get("btn_snooze"))
        btnSnooze.SetFont("s9 Bold", O2omStyles.FONT_PRIMARY)
        btnSnooze.OnEvent("Click", (*) => appInstance.SnoozeTimer())
        btnSnooze.Visible := false
        appInstance.btnSnooze := btnSnooze
        controlsList.Push(btnSnooze)

        ; Auto-start Checkbox (At y304)
        isStartup := (appInstance.settings.startWithWindows == 1)
        chkStart := g.AddCheckbox("x43 y304 w300 h24 c" O2omStyles.COLOR_TEXT " " (isStartup ? "Checked" : ""), O2omLang.Get("chk_startup"))
        chkStart.SetFont("s9", O2omStyles.FONT_PRIMARY)
        chkStart.OnEvent("Click", (ctrl, *) => appInstance.OnStartupToggle(ctrl.Value))
        appInstance.startupCheck := chkStart
        controlsList.Push(chkStart)
    }
}
