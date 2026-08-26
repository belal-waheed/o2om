;@Ahk2Exe-SetDescription O2om - Stand Up & Physical Health Reminder
;@Ahk2Exe-SetVersion 2.5.3
;@Ahk2Exe-SetName O2om
;@Ahk2Exe-SetMainIcon assets\o2om.ico
;@Ahk2Exe-SetCopyright (c) 2026
;@Ahk2Exe-SetOrigFilename O2om.exe

#Requires AutoHotkey v2.0
#SingleInstance Off
Persistent
SetWorkingDir(A_ScriptDir)

; ---------------------------------------------------------------------------
; Single-Instance Handshake (Activate existing running window if present)
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
; Global Error Handler (Prevents crashes and logs errors safely)
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
; O2om (قُوم) — Stand-Up & Physical Health Reminder
; ---------------------------------------------------------------------------

#Include lib/Resources.ahk
#Include lib/Styles.ahk
#Include lib/Language.ahk
#Include lib/Startup.ahk
#Include lib/Notifications.ahk
#Include lib/Settings.ahk
#Include lib/TimerEngine.ahk
#Include lib/Tray.ahk
#Include lib/Gui/Dashboard.ahk
#Include lib/Gui/SettingsView.ahk

class O2omApp {
    settings   := ""
    engine     := ""

    gui        := ""
    activeView := 1  ; 1 = Timer, 4 = Settings

    ; GUI Navigation Buttons
    btnNavDash       := ""
    btnNavSet        := ""
    btnStartWork     := ""
    btnStartExercises:= ""
    btnStartBreak    := ""
    btnSnooze        := ""
    btnReset         := ""
    btnPause         := ""

    ; Break Overlay GUI
    breakGui         := ""
    breakCt          := ""

    ; Control Handles
    cycleText        := ""
    countdownText    := ""
    statusText       := ""
    progressBar      := ""
    startupCheck     := ""
    ddlLanguage      := ""

    ; Settings Inputs
    editWork         := ""
    editShortBreak   := ""
    editLongBreak    := ""
    editCycles       := ""
    editEscalation   := ""
    editSnooze       := ""
    editIdle         := ""
    chkSound         := ""

    ; Control Collections
    dashControls     := []
    settingsControls := []

    __New() {
        O2omResources.Init()

        this.settings := O2omSettings()
        this.settings.Load()

        O2omStartup.SyncWithSettings(this.settings.startWithWindows)
        O2omNotify.RegisterAUMID()

        this.engine := O2omEngine(this.settings)

        O2omTray.Setup(this)
        this.SetupGui()
        this.ShowGui()

        SetTimer(ObjBindMethod(this, "Tick"), 1000)
        this.UpdateDisplay()
    }

    SetupGui() {
        if (this.gui && IsObject(this.gui))
            try this.gui.Destroy()

        this.dashControls      := []
        this.settingsControls  := []

        isRTL := (O2omLang.currentLang == "ar")
        guiOpts := "+MinimizeBox -MaximizeBox +0x02000000"  ; 0x02000000 = WS_CLIPCHILDREN (eliminates redraw flicker)
        if (isRTL)
            guiOpts .= " +E0x400000"

        g := Gui(guiOpts, O2omLang.Get("app_title"))
        g.BackColor := O2omStyles.COLOR_BG

        ; 2 Top Navigation Tabs (Centered: x82 and x197)
        this.btnNavDash := g.AddButton("x82 y14 w105 h32", O2omLang.Get("tab_timer"))
        this.btnNavDash.SetFont("s9 Bold", O2omStyles.FONT_PRIMARY)
        this.btnNavDash.OnEvent("Click", (*) => this.SwitchView(1))

        this.btnNavSet := g.AddButton("x197 y14 w105 h32", O2omLang.Get("tab_settings"))
        this.btnNavSet.SetFont("s9 norm", O2omStyles.FONT_PRIMARY)
        this.btnNavSet.OnEvent("Click", (*) => this.SwitchView(4))

        ; Accent Separator Line
        g.AddProgress("x15 y52 w355 h2 Background" O2omStyles.COLOR_CARD, 0)

        ; Build Views
        O2omDashboardView.Build(g, this, this.dashControls)
        O2omSettingsView.Build(g, this, this.settingsControls)

        ; Window Close (X) minimizes to tray
        g.OnEvent("Close", (*) => g.Hide())

        this.gui := g

        this.SwitchView(this.activeView)
        mode := this.engine.isWaitingWork ? "wait_work" : (this.engine.isWaitingBreak ? "wait_break" : "normal")
        this.ToggleDashboardButtons(mode)
        
        g.Show("w" O2omStyles.WIN_WIDTH " h" O2omStyles.WIN_HEIGHT " Hide")
    }

    SetupBreakGui() {
        if (this.breakGui && IsObject(this.breakGui)) {
            try this.breakGui.Destroy()
            this.breakGui := ""
        }

        bg := Gui("-Caption +0x02000000", O2omLang.Get("app_title"))
        bg.BackColor := O2omStyles.COLOR_BG
        
        ; Pressing ESC key closes break mode and returns to work
        bg.OnEvent("Escape", (*) => this.StartWorkMode())

        ; Timer Text at bottom left
        this.breakCt := bg.AddText("x40 y" (A_ScreenHeight - 70) " w300 h60 c" O2omStyles.COLOR_TEXT, "00:00")
        this.breakCt.SetFont("s42 Bold", O2omStyles.FONT_TITLE)

        ; High-visibility Start Work / Close Button at bottom right
        btnEnd := bg.AddButton("x" (A_ScreenWidth - 240) " y" (A_ScreenHeight - 65) " w200 h45", O2omLang.Get("btn_start_work"))
        btnEnd.SetFont("s12 Bold", O2omStyles.FONT_PRIMARY)
        btnEnd.OnEvent("Click", (*) => this.StartWorkMode())

        ; Responsive Screen Scaling for 16:9 illustration (Clean, text-free)
        imgPath := O2omResources.GetExerciseImage()
        if (imgPath != "") {
            maxImgH := A_ScreenHeight - 140
            maxImgW := A_ScreenWidth - 40
            imgW := Min(maxImgH * 16 // 9, maxImgW)
            imgH := imgW * 9 // 16

            ix := (A_ScreenWidth - imgW) // 2
            iy := (A_ScreenHeight - 80 - imgH) // 2
            try bg.AddPicture("x" ix " y" iy " w" imgW " h" imgH, imgPath)
        }

        this.breakGui := bg
    }

    SwitchView(viewNum) {
        if (viewNum == 2 || viewNum == 3)
            viewNum := 1

        this.activeView := viewNum

        if IsObject(this.btnNavDash)
            this.btnNavDash.SetFont(viewNum == 1 ? "s9 Bold" : "s9 norm")
        if IsObject(this.btnNavSet)
            this.btnNavSet.SetFont(viewNum == 4 ? "s9 Bold" : "s9 norm")

        for ctrl in this.dashControls {
            ; Don't blindly make Action buttons visible, preserve their specific state
            if (ctrl == this.btnReset || ctrl == this.btnPause || ctrl == this.btnStartWork || ctrl == this.btnStartBreak || ctrl == this.btnStartExercises || ctrl == this.btnSnooze) {
                if (viewNum != 1)
                    ctrl.Visible := false
                continue
            }
            ctrl.Visible := (viewNum == 1)
        }

        if (viewNum == 1) {
            mode := this.engine.isWaitingWork ? "wait_work" : (this.engine.isWaitingBreak ? "wait_break" : "normal")
            this.ToggleDashboardButtons(mode)
        }

        for ctrl in this.settingsControls
            ctrl.Visible := (viewNum == 4)

        if (this.gui && this.gui.Hwnd)
            try WinRedraw("ahk_id " this.gui.Hwnd)
    }

    ShowGui() {
        if (this.gui && IsObject(this.gui)) {
            mode := this.engine.isWaitingWork ? "wait_work" : (this.engine.isWaitingBreak ? "wait_break" : "normal")
            this.ToggleDashboardButtons(mode)
            try this.gui.Show()
            try WinActivate("ahk_id " this.gui.Hwnd)
            ; Ensure Windows resets mouse cursor from loading spinner to standard arrow
            try DllCall("SetCursor", "Ptr", DllCall("LoadCursor", "Ptr", 0, "Int", 32512, "Ptr"))
        }
    }

    OnStartupToggle(val) {
        this.settings.startWithWindows := val
        this.settings.Save()
        O2omStartup.SetEnabled(val)
    }

    ToggleSound() {
        this.settings.soundEnabled := this.settings.soundEnabled ? 0 : 1
        this.settings.Save()
        if IsObject(this.chkSound)
            try this.chkSound.Value := this.settings.soundEnabled
        O2omTray.Setup(this)
    }

    SafeInt(val, minVal := 1, maxVal := 180) {
        valStr := Trim(String(val))
        if (!IsInteger(valStr))
            return 0
        intVal := Integer(valStr)
        if (intVal < minVal || intVal > maxVal)
            return 0
        return intVal
    }

    ApplySettingsFromGui() {
        workVal       := this.SafeInt(this.editWork.Value, 1, 180)
        shortVal      := this.SafeInt(this.editShortBreak.Value, 1, 60)
        longVal       := this.SafeInt(this.editLongBreak.Value, 1, 90)
        cyclesVal     := this.SafeInt(this.editCycles.Value, 1, 12)
        escalationVal := this.SafeInt(this.editEscalation.Value, 1, 30)
        snoozeVal     := this.SafeInt(this.editSnooze.Value, 1, 60)
        idleVal       := this.SafeInt(this.editIdle.Value, 1, 60)

        if (workVal <= 0 || shortVal <= 0 || longVal <= 0 || cyclesVal <= 0 || escalationVal <= 0 || snoozeVal <= 0 || idleVal <= 0) {
            MsgBox(O2omLang.Get("msg_invalid_input"), O2omLang.Get("app_title"), "Icon!")
            return
        }

        selectedLang := (this.ddlLanguage.Value == 2) ? "en" : "ar"
        
        this.settings.language         := selectedLang
        O2omLang.currentLang           := selectedLang

        this.settings.workIntervalMin  := workVal
        this.settings.shortBreakMin    := shortVal
        this.settings.longBreakMin     := longVal
        this.settings.cyclesBeforeLong := cyclesVal
        this.settings.escalationMin     := escalationVal
        this.settings.snoozeMin         := snoozeVal
        this.settings.idleThresholdMin  := idleVal
        this.settings.soundEnabled     := (this.chkSound.Value == 1) ? 1 : 0

        this.settings.Save()

        ; Apply new timer duration and refresh UI
        this.engine.ResetToWork()
        O2omTray.Setup(this)
        this.SetupGui()
        this.ShowGui()

        O2omNotify.Show(O2omLang.Get("app_title"), O2omLang.Get("msg_saved"), 64, this.settings.soundEnabled)
    }

    Tick() {
        res := this.engine.Tick()
        snd := this.settings.soundEnabled

        if (res.type == "waiting_break") {
            this.SwitchView(1)
            this.ToggleDashboardButtons("wait_break")
            this.ShowGui()
            O2omNotify.Show(O2omLang.Get("toast_break_title"), O2omLang.Get("toast_break_stage1"), 64, snd)
        } else if (res.type == "escalation") {
            toastMsg := (res.stage == 1) ? O2omLang.Get("toast_break_stage2") : O2omLang.Get("toast_break_stage3")
            O2omNotify.Show(O2omLang.Get("toast_break_title"), toastMsg, 48, snd)
        } else if (res.type == "auto_work_reset") {
            ; Ignored both warnings and still in use -> dispatch final notification and resume work countdown
            O2omNotify.Show(O2omLang.Get("toast_break_title"), O2omLang.Get("toast_break_stage3"), 16, snd)
            this.ToggleDashboardButtons("normal")
            this.SwitchView(1)
        } else if (res.type == "break_ended") {
            O2omNotify.Show(O2omLang.Get("toast_break_title"), O2omLang.Get("toast_break_ended"), 64, snd)
            if (this.breakGui && IsObject(this.breakGui)) {
                try this.breakGui.Destroy()
                this.breakGui := ""
            }
            this.SwitchView(1)
            this.ToggleDashboardButtons("wait_work")
            this.ShowGui()
        }

        this.UpdateDisplay()
    }

    ToggleDashboardButtons(mode) {
        if !IsObject(this.btnReset)
            return

        if (this.activeView != 1) {
            this.btnReset.Visible          := false
            this.btnPause.Visible          := false
            this.btnStartWork.Visible      := false
            this.btnStartBreak.Visible     := false
            this.btnStartExercises.Visible := false
            this.btnSnooze.Visible         := false
            return
        }

        this.btnReset.Visible          := (mode == "normal")
        this.btnPause.Visible          := (mode == "normal")
        this.btnStartWork.Visible      := (mode == "wait_work")
        this.btnStartExercises.Visible := (mode == "wait_break")
        this.btnStartBreak.Visible     := (mode == "wait_break")
        this.btnSnooze.Visible         := (mode == "wait_break")

        if (this.gui && this.gui.Hwnd)
            try WinRedraw("ahk_id " this.gui.Hwnd)
    }

    TogglePauseTimer() {
        isPaused := this.engine.TogglePause()
        if IsObject(this.btnPause)
            this.btnPause.Text := O2omLang.Get(isPaused ? "btn_resume" : "btn_pause")
        O2omTray.Setup(this)
        this.UpdateDisplay()
    }

    StartWorkMode() {
        this.engine.StartWork()
        if (this.breakGui && IsObject(this.breakGui)) {
            try this.breakGui.Destroy()
            this.breakGui := ""
        }
        this.ToggleDashboardButtons("normal")
        this.SwitchView(1)
        this.UpdateDisplay()
        this.ShowGui()
    }

    StartBreakMode(showExercises) {
        this.engine.StartBreak()
        if (this.gui && IsObject(this.gui))
            this.gui.Hide()
        this.ToggleDashboardButtons("normal")
        if (showExercises) {
            this.SetupBreakGui()
            if (this.breakGui && IsObject(this.breakGui))
                this.breakGui.Show("x0 y0 w" A_ScreenWidth " h" A_ScreenHeight)
        }
    }

    ResetTimer() {
        if (this.breakGui && IsObject(this.breakGui)) {
            try this.breakGui.Destroy()
            this.breakGui := ""
        }
        this.ToggleDashboardButtons("normal")
        this.engine.ResetToWork()
        this.SwitchView(1)
        this.UpdateDisplay()
    }

    SnoozeTimer() {
        if (this.breakGui && IsObject(this.breakGui)) {
            try this.breakGui.Destroy()
            this.breakGui := ""
        }
        this.ToggleDashboardButtons("normal")
        this.engine.Snooze()
        this.SwitchView(1)
        this.UpdateDisplay()
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
        if (this.activeView == 4) {
            this.ApplySettingsFromGui()
        } else if (this.engine.isWaitingBreak) {
            this.StartBreakMode(true)
        } else if (this.engine.isWaitingWork) {
            this.StartWorkMode()
        }
    }

    UpdateDisplay() {
        totalSec := Max(0, this.engine.remaining) // 1000
        mins := Format("{:02}", totalSec // 60)
        secs := Format("{:02}", Mod(totalSec, 60))
        timeStr := mins ":" secs

        try this.countdownText.Value := timeStr
        try this.breakCt.Value := timeStr
        try this.progressBar.Value := this.engine.progressPercent

        try {
            cycleBadge := Format(O2omLang.Get("status_cycle_badge"), this.engine.currentCycle, this.engine.totalCycles)
            this.cycleText.Value := cycleBadge
        }

        try {
            if (this.engine.isIdle)
                statusVal := O2omLang.Get("status_idle")
            else if (this.engine.isPaused)
                statusVal := O2omLang.Get("status_paused")
            else if (this.engine.isOnBreak)
                statusVal := O2omLang.Get("status_on_break")
            else if (this.engine.isWaitingBreak)
                statusVal := O2omLang.Get("toast_break_stage1")
            else if (this.engine.isWaitingWork)
                statusVal := O2omLang.Get("btn_start_work")
            else
                statusVal := O2omLang.Get("status_next_break")
            this.statusText.Value := statusVal
        }

        try this.gui.Title := O2omLang.Get("app_title")
        O2omTray.UpdateTooltip(timeStr)
    }

    OnAppExit() {
        try {
            if (this.settings)
                this.settings.Save()
        }
    }
}

; App Entry Point & Singleton Registration
global globalApp := O2omApp()
OnExit((*) => globalApp.OnAppExit())

; ---------------------------------------------------------------------------
; Context-Sensitive Keyboard Navigation & Shortcuts
; ---------------------------------------------------------------------------
#HotIf WinActive("ahk_id " (globalApp && globalApp.gui ? globalApp.gui.Hwnd : 0))
Space::globalApp.OnSpacePressed()
Enter::globalApp.OnEnterPressed()
Esc::globalApp.gui.Hide()
#HotIf