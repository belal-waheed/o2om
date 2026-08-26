; ---------------------------------------------------------------------------
; O2om — Health & Productivity Stats View
; ---------------------------------------------------------------------------

class O2omStatsView {
    static Build(g, appInstance, controlsList) {
        h := appInstance.healthTracker

        ; Title (y60)
        lblTitle := g.AddText("x25 y60 w370 h24 Center c" O2omTheme.ACCENT_FOCUS, O2omLang.Get("stats_title"))
        lblTitle.SetFont("s11 Bold", O2omTheme.FONT_PRIMARY)
        controlsList.Push(lblTitle)

        ; Stands Today (y96)
        lblStands := g.AddText("x30 y96 w240 h22 c" O2omTheme.TEXT_MUTED, O2omLang.Get("stats_today_stands"))
        lblStands.SetFont("s10", O2omTheme.FONT_PRIMARY)
        controlsList.Push(lblStands)

        valStands := g.AddText("x280 y96 w110 h22 Right c" O2omTheme.TEXT_PRIMARY, h.todayStands " / " h.dailyStandGoal)
        valStands.SetFont("s10 Bold", O2omTheme.FONT_PRIMARY)
        appInstance.statValStands := valStands
        controlsList.Push(valStands)

        ; Focus Today (y132)
        lblFocus := g.AddText("x30 y132 w240 h22 c" O2omTheme.TEXT_MUTED, O2omLang.Get("stats_focus_today"))
        lblFocus.SetFont("s10", O2omTheme.FONT_PRIMARY)
        controlsList.Push(lblFocus)

        hours := h.todayFocusMinutes // 60
        mins := Mod(h.todayFocusMinutes, 60)
        focusStr := (hours > 0) ? Format("{1}h {2}m", hours, mins) : Format("{1}m", mins)
        valFocus := g.AddText("x280 y132 w110 h22 Right c" O2omTheme.TEXT_PRIMARY, focusStr)
        valFocus.SetFont("s10 Bold", O2omTheme.FONT_PRIMARY)
        appInstance.statValFocus := valFocus
        controlsList.Push(valFocus)

        ; Current Streak (y168)
        lblStreak := g.AddText("x30 y168 w240 h22 c" O2omTheme.TEXT_MUTED, O2omLang.Get("stats_streak"))
        lblStreak.SetFont("s10", O2omTheme.FONT_PRIMARY)
        controlsList.Push(lblStreak)

        valStreak := g.AddText("x280 y168 w110 h22 Right c" O2omTheme.ACCENT_BREAK, h.currentStreakDays)
        valStreak.SetFont("s10 Bold", O2omTheme.FONT_PRIMARY)
        appInstance.statValStreak := valStreak
        controlsList.Push(valStreak)

        ; Best Streak (y204)
        lblBest := g.AddText("x30 y204 w240 h22 c" O2omTheme.TEXT_MUTED, O2omLang.Get("stats_best_streak"))
        lblBest.SetFont("s10", O2omTheme.FONT_PRIMARY)
        controlsList.Push(lblBest)

        valBest := g.AddText("x280 y204 w110 h22 Right c" O2omTheme.TEXT_PRIMARY, h.bestStreakDays)
        valBest.SetFont("s10 Bold", O2omTheme.FONT_PRIMARY)
        appInstance.statValBest := valBest
        controlsList.Push(valBest)

        ; Lifetime Stands (y240)
        lblLife := g.AddText("x30 y240 w240 h22 c" O2omTheme.TEXT_MUTED, O2omLang.Get("stats_lifetime_stands"))
        lblLife.SetFont("s10", O2omTheme.FONT_PRIMARY)
        controlsList.Push(lblLife)

        valLife := g.AddText("x280 y240 w110 h22 Right c" O2omTheme.TEXT_PRIMARY, h.totalStandsAllTime)
        valLife.SetFont("s10 Bold", O2omTheme.FONT_PRIMARY)
        appInstance.statValLife := valLife
        controlsList.Push(valLife)

        ; Separator line (y280)
        sep := g.AddProgress("x30 y280 w360 h2 Background" O2omTheme.BORDER_SUBTLE, 0)
        controlsList.Push(sep)

        ; Reset Stats Button (y310)
        btnResetStats := g.AddButton("x30 y310 w360 h34", O2omLang.Get("btn_reset_stats"))
        btnResetStats.SetFont("s9", O2omTheme.FONT_PRIMARY)
        btnResetStats.OnEvent("Click", (*) => appInstance.ResetStats())
        controlsList.Push(btnResetStats)
    }

    static Refresh(appInstance) {
        h := appInstance.healthTracker
        if (!h)
            return

        try appInstance.statValStands.Text := h.todayStands " / " h.dailyStandGoal
        
        hours := h.todayFocusMinutes // 60
        mins := Mod(h.todayFocusMinutes, 60)
        focusStr := (hours > 0) ? Format("{1}h {2}m", hours, mins) : Format("{1}m", mins)
        try appInstance.statValFocus.Text := focusStr
        try appInstance.statValStreak.Text := h.currentStreakDays
        try appInstance.statValBest.Text := h.bestStreakDays
        try appInstance.statValLife.Text := h.totalStandsAllTime
    }
}
