;@Ahk2Exe-SetDescription O2om - Stand Up & Ergonomic Health Reminder
;@Ahk2Exe-SetVersion 3.1.0
;@Ahk2Exe-SetName O2om
;@Ahk2Exe-SetMainIcon assets\o2om.ico
;@Ahk2Exe-SetCopyright (c) 2026
;@Ahk2Exe-SetOrigFilename O2om.exe

#Requires AutoHotkey v2.0
#SingleInstance Off
Persistent
SetWorkingDir(A_ScriptDir)

; ---------------------------------------------------------------------------
; Single-Instance Handshake (Activate existing running instance if present)
; ---------------------------------------------------------------------------
DetectHiddenWindows(true)
prevHwnd := 0
try {
    prevHwnd := WinExist("قُوم — O2om ahk_class AutoHotkeyGUI")
    if (!prevHwnd)
        prevHwnd := WinExist("O2om — Stand-Up Reminder ahk_class AutoHotkeyGUI")
}

if (prevHwnd) {
    try WinShow("ahk_id " prevHwnd)
    try WinRestore("ahk_id " prevHwnd)
    try WinActivate("ahk_id " prevHwnd)
    try DllCall("SetCursor", "Ptr", DllCall("LoadCursor", "Ptr", 0, "Int", 32512, "Ptr"))
    ExitApp()
}

; ---------------------------------------------------------------------------
; Global Error Handler (Safely logs errors and prevents silent crashes)
; ---------------------------------------------------------------------------
OnError(GlobalErrorHandler)

GlobalErrorHandler(thrown, mode) {
    logPath := A_AppData "\O2om\error_log.txt"
    try DirCreate(A_AppData "\O2om")
    try FileAppend(Format("[{1}] ERROR in {2} (Line {3}): {4}`n", 
        FormatTime(, "yyyy-MM-dd HH:mm:ss"), 
        thrown.File, 
        thrown.Line, 
        thrown.Message), logPath, "UTF-8")
    
    MsgBox("An unexpected error occurred in O2om:`n`n" . thrown.Message . "`n`nLogged to: " . logPath, "O2om Application Error", "Iconx 16")
    return true
}

; ---------------------------------------------------------------------------
; Layered Subsystem Imports
; ---------------------------------------------------------------------------
#Include src/Locale/Language.ahk
#Include src/Services/Resources.ahk
#Include src/Services/SettingsRepo.ahk
#Include src/Services/SoundService.ahk
#Include src/Services/NotificationService.ahk
#Include src/Services/IdleMonitor.ahk
#Include src/Services/StartupService.ahk
#Include src/Core/HealthTracker.ahk
#Include src/Core/ExerciseRoutines.ahk
#Include src/Core/TimerEngine.ahk
#Include src/Ui/Theme.ahk
#Include src/Ui/Tray.ahk
#Include src/Ui/Controls/ModernCard.ahk
#Include src/Ui/Views/DashboardView.ahk
#Include src/Ui/Views/StatsView.ahk
#Include src/Ui/Views/SettingsView.ahk
#Include src/Ui/Views/BreakOverlayView.ahk
#Include src/Ui/Views/MiniPillView.ahk

; ---------------------------------------------------------------------------
; O2om (قُوم) — Main Application Orchestrator
; ---------------------------------------------------------------------------

class O2omApp {
    settings        := ""
    healthTracker   := ""
    engine          := ""
    miniPill        := ""
    breakOverlay    := ""

    gui             := ""
    activeView      := 1  ; 1 = Timer, 2 = Stats, 3 = Settings

    ; Navigation Cards
    btnNavDash      := ""
    btnNavStats     := ""
    btnNavSet       := ""

    ; Mode Pills
    btnModeStandup  := ""
    btnModeEye      := ""
    btnModePomodoro := ""

    ; Dashboard Action Controls
    badgeText       := ""
    statusText      := ""
    countdownText   := ""
    progressBar     := ""
    btnReset        := ""
    btnPause        := ""
    btnStartWork    := ""
    btnStartExercises := ""
    btnQuietBreak   := ""
    btnSnoozeChip   := ""
    btnDock         := ""
    startupCheck    := ""

    ; Stats Controls
    statValStands   := ""
    statValFocus    := ""
    statValStreak   := ""
    statValBest     := ""
    statValLife     := ""

    ; Settings Controls
    presetCardStandup := ""
    presetCardPomodoro:= ""
    presetCardEye   := ""
    ddlLanguage     := ""
    chkSound        := ""
    chkStartSet     := ""

    ; View Control Groups
    dashControls     := []
    statsControls    := []
    settingsControls := []

    __New() {
        O2omResources.Init()

        this.settings := O2omSettingsRepo()
        this.settings.Load()

        O2omLang.currentLang := this.settings.language
        O2omStartupService.SyncWithSettings(this.settings.startWithWindows)
        O2omNotificationService.RegisterAUMID(O2omResources.GetIcon())
        O2omSoundService.enabled := (this.settings.soundEnabled == 1)

        this.healthTracker := O2omHealthTracker()
        this.engine := O2omEngine(this.settings)
        this.miniPill := O2omMiniPillView(this)

        O2omTray.Setup(this)
        this.SetupGui()
        this.ShowGui()

        SetTimer(ObjBindMethod(this, "Tick"), 1000)
        this.UpdateDisplay()
    }

    SetupGui() {
        if (this.gui && IsObject(this.gui))
            try this.gui.Destroy()

        this.dashControls     := []
        this.statsControls    := []
        this.settingsControls := []

        isRTL := (O2omLang.currentLang == "ar")
        guiOpts := "+MinimizeBox -MaximizeBox +0x02000000"  ; 0x02000000 = WS_CLIPCHILDREN (eliminates redraw flicker)
        if (isRTL)
            guiOpts .= " +E0x400000"

        g := Gui(guiOpts, O2omLang.Get("app_title"))
        g.BackColor := O2omTheme.BG_ROOT

        ; Enable native Windows 10/11 dark title bar
        O2omTheme.EnableDarkTitleBar(g.Hwnd)

        ; Top Navigation Tabs (y12) - Styled as Dark Obsidian Cards
        this.btnNavDash := O2omCardButton.Create(g, "x30 y12 w110 h32", O2omLang.Get("tab_timer"), (this.activeView == 1), (*) => this.SwitchView(1))
        this.btnNavStats := O2omCardButton.Create(g, "x155 y12 w110 h32", O2omLang.Get("tab_stats"), (this.activeView == 2), (*) => this.SwitchView(2))
        this.btnNavSet := O2omCardButton.Create(g, "x280 y12 w110 h32", O2omLang.Get("tab_settings"), (this.activeView == 3), (*) => this.SwitchView(3))

        ; Accent Separator Line (y48)
        g.AddProgress("x15 y48 w390 h2 Background" O2omTheme.BORDER_SUBTLE, 0)

        ; Build Views
        O2omDashboardView.Build(g, this, this.dashControls)
        O2omStatsView.Build(g, this, this.statsControls)
        O2omSettingsView.Build(g, this, this.settingsControls)

        ; Close (X) minimizes to tray
        g.OnEvent("Close", (*) => g.Hide())

        this.gui := g
        this.SwitchView(this.activeView)

        mode := this.engine.isWaitingWork ? "wait_work" : (this.engine.isWaitingBreak ? "wait_break" : "normal")
        this.ToggleDashboardButtons(mode)

        g.Show("w" O2omTheme.WIN_WIDTH " h" O2omTheme.WIN_HEIGHT " Hide")
    }

    ShowGui() {
        if (!this.gui)
            this.SetupGui()

        this.gui.Show("w" O2omTheme.WIN_WIDTH " h" O2omTheme.WIN_HEIGHT)
        try WinActivate("ahk_id " this.gui.Hwnd)
        try DllCall("SetCursor", "Ptr", DllCall("LoadCursor", "Ptr", 0, "Int", 32512, "Ptr"))
    }

    SwitchView(viewNum) {
        this.activeView := viewNum

        O2omCardButton.SetState(this.btnNavDash, (viewNum == 1))
        O2omCardButton.SetState(this.btnNavStats, (viewNum == 2))
        O2omCardButton.SetState(this.btnNavSet, (viewNum == 3))

        for ctrl in this.dashControls
            try ctrl.Visible := (viewNum == 1)
        for ctrl in this.statsControls
            try ctrl.Visible := (viewNum == 2)
        for ctrl in this.settingsControls
            try ctrl.Visible := (viewNum == 3)

        if (viewNum == 1) {
            mode := this.engine.isWaitingWork ? "wait_work" : (this.engine.isWaitingBreak ? "wait_break" : "normal")
            this.ToggleDashboardButtons(mode)
        } else if (viewNum == 2) {
            O2omStatsView.Refresh(this)
        }

        if (this.gui && this.gui.Hwnd)
            try WinRedraw("ahk_id " this.gui.Hwnd)
    }

    ChangeMode(newMode) {
        this.engine.SetMode(newMode)
        this.settings.ApplyPreset(newMode)

        O2omCardButton.SetState(this.btnModeStandup, (newMode == "standup"))
        O2omCardButton.SetState(this.btnModeEye, (newMode == "eyeguard"))
        O2omCardButton.SetState(this.btnModePomodoro, (newMode == "pomodoro"))

        this.ToggleDashboardButtons("normal")
        this.UpdateDisplay()
    }

    SelectPreset(presetName) {
        this.ChangeMode(presetName)
        O2omSettingsView.UpdatePresetHighlight(this, presetName)
        O2omNotificationService.Show(O2omLang.Get("app_title"), O2omLang.Get("msg_saved"), 64, this.settings.soundEnabled)
    }

    ToggleDashboardButtons(mode) {
        if (this.activeView != 1)
            return

        try {
            isNormal := (mode == "normal")
            isBreak  := (mode == "wait_break")
            isWork   := (mode == "wait_work")

            this.btnReset.Visible          := isNormal
            this.btnPause.Visible          := isNormal

            this.btnStartWork.Visible      := isWork
            this.btnStartExercises.Visible := isBreak
            this.btnQuietBreak.Visible     := isBreak
            this.btnSnoozeChip.Visible     := isBreak

            if (this.gui && this.gui.Hwnd)
                WinRedraw("ahk_id " this.gui.Hwnd)
        }
    }

    StartBreakMode(guidedExercise := false) {
        this.engine.StartBreak(guidedExercise)

        if (guidedExercise) {
            this.gui.Hide()
            this.breakOverlay := O2omBreakOverlayView(this)
        } else {
            this.ToggleDashboardButtons("normal")
        }

        this.UpdateDisplay()
    }

    StartWorkMode() {
        if (this.breakOverlay) {
            this.breakOverlay.Destroy()
            this.breakOverlay := ""
        }

        this.engine.StartWork()
        this.ToggleDashboardButtons("normal")
        this.ShowGui()
        this.UpdateDisplay()
    }

    TogglePauseTimer() {
        this.engine.TogglePause()
        isPaused := this.engine.isPaused
        try this.btnPause.Text := O2omLang.Get(isPaused ? "btn_resume" : "btn_pause")
        O2omTray.Setup(this)
        this.UpdateDisplay()
    }

    ResetTimer() {
        this.engine.ResetToWork()
        this.ToggleDashboardButtons("normal")
        this.UpdateDisplay()
    }

    SnoozeTimer() {
        this.engine.Snooze()
        this.ToggleDashboardButtons("normal")
        this.UpdateDisplay()
    }

    ActivateMiniPill() {
        this.gui.Hide()
        this.miniPill.Show()
    }

    RestoreFromMiniPill() {
        this.miniPill.Hide()
        this.ShowGui()
    }

    ToggleMiniPill() {
        if (this.miniPill.isVisible)
            this.miniPill.Hide()
        else
            this.miniPill.Show()
    }

    ToggleSound() {
        this.settings.soundEnabled := !this.settings.soundEnabled
        this.settings.Save()
        O2omSoundService.enabled := (this.settings.soundEnabled == 1)
        if (this.chkSound)
            try this.chkSound.Value := this.settings.soundEnabled
        O2omTray.Setup(this)
    }

    OnStartupToggle(val) {
        this.settings.startWithWindows := val ? 1 : 0
        this.settings.Save()
        O2omStartupService.SyncWithSettings(val ? 1 : 0)
        if (this.startupCheck)
            try this.startupCheck.Value := this.settings.startWithWindows
    }

    ResetStats() {
        this.healthTracker.ResetAll()
        O2omStatsView.Refresh(this)
        this.UpdateDisplay()
    }

    ApplySettingsFromGui() {
        s := this.settings

        s.soundEnabled      := this.chkSound.Value ? 1 : 0
        s.startWithWindows  := this.chkStartSet.Value ? 1 : 0
        O2omSoundService.enabled := (s.soundEnabled == 1)
        O2omStartupService.SyncWithSettings(s.startWithWindows)

        oldLang := s.language
        newLang := (this.ddlLanguage.Value == 1) ? "ar" : "en"
        s.language := newLang
        O2omLang.currentLang := newLang

        s.Save()

        if (oldLang != newLang) {
            this.SetupGui()
            this.ShowGui()
        }

        this.engine.ResetToWork()
        this.ToggleDashboardButtons("normal")
        this.UpdateDisplay()
        O2omTray.Setup(this)

        O2omNotificationService.Show(O2omLang.Get("app_title"), O2omLang.Get("msg_saved"), 64, s.soundEnabled)
    }

    Tick() {
        res := this.engine.Tick()
        snd := this.settings.soundEnabled

        ; Handle Guided Break Overlay Second Tick
        if (this.breakOverlay && this.engine.isOnBreak) {
            this.breakOverlay.TickOneSecond()
        }

        if (res.type == "waiting_break") {
            this.ToggleDashboardButtons("wait_break")
            this.ShowGui()
            O2omNotificationService.Show(O2omLang.Get("toast_break_title"), O2omLang.Get("toast_break_stage1"), 64, snd)
            O2omSoundService.PlayWorkComplete()
        } else if (res.type == "escalation") {
            toastMsg := (res.stage == 1) ? O2omLang.Get("toast_break_stage2") : O2omLang.Get("toast_break_stage3")
            O2omNotificationService.Show(O2omLang.Get("toast_break_title"), toastMsg, 48, snd)
            O2omSoundService.PlayEscalation(res.stage)
        } else if (res.type == "auto_work_reset") {
            O2omNotificationService.Show(O2omLang.Get("toast_break_title"), O2omLang.Get("toast_break_stage3"), 16, snd)
            O2omSoundService.PlayEscalation(2)
            this.ToggleDashboardButtons("normal")
        } else if (res.type == "break_ended") {
            statRes := this.healthTracker.RecordCompletedBreak()
            if (statRes.goalJustMet) {
                goalMsg := Format(O2omLang.Get("toast_goal_reached"), statRes.todayStands)
                O2omNotificationService.Show(O2omLang.Get("toast_break_title"), goalMsg, 64, snd)
            } else {
                O2omNotificationService.Show(O2omLang.Get("toast_break_title"), O2omLang.Get("toast_break_ended"), 64, snd)
            }
            O2omSoundService.PlayBreakComplete()

            if (this.breakOverlay) {
                this.breakOverlay.Destroy()
                this.breakOverlay := ""
            }

            this.ToggleDashboardButtons("wait_work")
            this.ShowGui()
        }

        this.UpdateDisplay()
    }

    UpdateDisplay() {
        timeStr := this.engine.FormatRemaining()

        statusStr := ""
        statusColor := O2omTheme.ACCENT_FOCUS

        if (this.engine.isOnBreak) {
            statusStr := O2omLang.Get("status_on_break")
            statusColor := O2omTheme.ACCENT_BREAK
        } else if (this.engine.isWaitingBreak) {
            statusStr := (this.engine.reminderStage >= 1) ? O2omLang.Get("status_escalation_" this.engine.reminderStage) : O2omLang.Get("toast_break_stage1")
            statusColor := O2omTheme.ACCENT_URGENT
        } else if (this.engine.isWaitingWork) {
            statusStr := O2omLang.Get("status_waiting_work")
            statusColor := O2omTheme.ACCENT_BREAK
        } else if (this.engine.isPaused) {
            statusStr := O2omLang.Get("status_paused")
            statusColor := O2omTheme.ACCENT_WARN
        } else if (this.engine.isIdle) {
            statusStr := O2omLang.Get("status_idle")
            statusColor := O2omTheme.ACCENT_WARN
        } else {
            cycleStr := Format(O2omLang.Get("status_cycle_badge"), this.engine.currentCycle, this.engine.totalCycles)
            statusStr := cycleStr " — " O2omLang.Get("status_focus_active")
            statusColor := O2omTheme.TEXT_MUTED
        }

        try this.countdownText.Value := timeStr
        try this.statusText.Value := statusStr
        try this.statusText.Opt("c" statusColor)
        try this.progressBar.Value := this.engine.progressPercent

        try {
            badgeStr := Format(O2omLang.Get("stats_badge_summary"), this.healthTracker.todayStands, this.healthTracker.dailyStandGoal, this.healthTracker.currentStreakDays)
            this.badgeText.Value := badgeStr
        }

        if (this.miniPill)
            this.miniPill.Update(timeStr, this.engine)

        modeName := O2omLang.Get("mode_" this.engine.mode)
        cycleNum := Format("{1}/{2}", this.engine.currentCycle, this.engine.totalCycles)
        O2omTray.UpdateTooltip(timeStr, modeName, cycleNum)
    }

    OnSpacePressed() {
        if (this.activeView == 1) {
            if (this.engine.isWaitingBreak) {
                this.StartBreakMode(true)
            } else if (this.engine.isWaitingWork) {
                this.StartWorkMode()
            } else {
                this.TogglePauseTimer()
            }
        }
    }

    OnEnterPressed() {
        if (this.activeView == 3) {
            this.ApplySettingsFromGui()
        } else if (this.engine.isWaitingBreak) {
            this.StartBreakMode(true)
        } else if (this.engine.isWaitingWork) {
            this.StartWorkMode()
        }
    }

    OnAppExit() {
        try {
            if (this.settings)
                this.settings.Save()
            if (this.healthTracker)
                this.healthTracker.Save()
        }
    }
}

; ---------------------------------------------------------------------------
; Application Entry Point & Singleton Registration
; ---------------------------------------------------------------------------
global globalApp := O2omApp()
OnExit((*) => globalApp.OnAppExit())

; ---------------------------------------------------------------------------
; Context-Sensitive Keyboard Shortcuts (#HotIf WinActive)
; ---------------------------------------------------------------------------
#HotIf WinActive("ahk_id " (globalApp && globalApp.gui ? globalApp.gui.Hwnd : 0))
Space::globalApp.OnSpacePressed()
Enter::globalApp.OnEnterPressed()
Esc::globalApp.gui.Hide()
#HotIf