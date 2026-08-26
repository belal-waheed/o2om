; ---------------------------------------------------------------------------
; O2om — Modern Edge-Docking & Auto-Hiding Mini-Pill Widget View
; ---------------------------------------------------------------------------

class O2omMiniPillView {
    appInstance     := ""
    pillGui         := ""
    txtDot          := ""
    txtTimer        := ""
    btnAction       := ""
    isVisible       := false

    ; Edge-Docking & Auto-Hide State
    dockState       := "none"  ; "none", "right", "left"
    isCollapsed     := false
    lastHoverTick   := 0
    pillWidth       := 150
    pillHeight      := 38
    collapsedWidth  := 8

    __New(appInstance) {
        this.appInstance := appInstance
        this.Build()
        OnMessage(0x0201, ObjBindMethod(this, "OnMouseDown"))
        SetTimer(ObjBindMethod(this, "CheckHoverState"), 150)
    }

    Build() {
        if (this.pillGui && IsObject(this.pillGui))
            try this.pillGui.Destroy()

        isRTL := (O2omLang.currentLang == "ar")
        guiOpts := "-Caption +AlwaysOnTop +ToolWindow +0x02000000"
        if (isRTL)
            guiOpts .= " +E0x400000"

        pg := Gui(guiOpts, "O2om Mini Pill")
        pg.BackColor := "11131F"  ; Deep obsidian glass

        ; Glowing Status Dot (x10 y8 w14 h22)
        dot := pg.AddText("x10 y8 w14 h22 Center c" O2omTheme.ACCENT_FOCUS, "●")
        dot.SetFont("s11 Bold", O2omTheme.FONT_PRIMARY)
        dot.OnEvent("Click", (*) => this.appInstance.RestoreFromMiniPill())
        this.txtDot := dot

        ; Digital Tabular Countdown (x26 y6 w74 h26)
        tm := pg.AddText("x26 y6 w74 h26 Center c" O2omTheme.TEXT_PRIMARY, "00:00")
        tm.SetFont("s13 Bold", O2omTheme.FONT_DISPLAY)
        tm.OnEvent("DoubleClick", (*) => this.appInstance.RestoreFromMiniPill())
        this.txtTimer := tm

        ; Minimal Dark Action Card (x106 y6 w34 h26)
        act := pg.AddText("x106 y6 w34 h26 Center 0x200 Background1F2333 c" O2omTheme.TEXT_PRIMARY, "||")
        act.SetFont("s8 Bold", O2omTheme.FONT_PRIMARY)
        act.OnEvent("Click", (*) => this.appInstance.TogglePauseTimer())
        this.btnAction := act

        this.pillGui := pg
    }

    ApplyRoundedRegion(w, h) {
        if (!this.pillGui || !this.pillGui.Hwnd)
            return
        try {
            rgn := DllCall("gdi32\CreateRoundRectRgn", "Int", 0, "Int", 0, "Int", w, "Int", h, "Int", 20, "Int", 20, "Ptr")
            DllCall("user32\SetWindowRgn", "Ptr", this.pillGui.Hwnd, "Ptr", rgn, "Int", 1)
        }
    }

    Show() {
        if (!this.pillGui)
            this.Build()

        s := this.appInstance.settings
        xPos := (s.miniPillX > 0) ? s.miniPillX : (A_ScreenWidth - this.pillWidth - 10)
        yPos := (s.miniPillY > 0) ? s.miniPillY : 60

        ; Detect initial edge proximity
        this.UpdateDockState(xPos)

        this.pillGui.Show(Format("x{1} y{2} w{3} h{4} NoActivate", xPos, yPos, this.pillWidth, this.pillHeight))
        this.ApplyRoundedRegion(this.pillWidth, this.pillHeight)
        this.isVisible := true
        this.isCollapsed := false
    }

    Hide() {
        if (this.pillGui && this.isVisible) {
            this.SavePosition()
            this.pillGui.Hide()
            this.isVisible := false
        }
    }

    SavePosition() {
        if (!this.pillGui || !this.isVisible)
            return
        try {
            this.pillGui.GetPos(&x, &y, &w, &h)
            if (!this.isCollapsed) {
                this.appInstance.settings.miniPillX := x
                this.appInstance.settings.miniPillY := y
                this.appInstance.settings.Save()
            }
        }
    }

    UpdateDockState(xPos) {
        sw := A_ScreenWidth
        if (xPos >= sw - this.pillWidth - 35) {
            this.dockState := "right"
        } else if (xPos <= 35) {
            this.dockState := "left"
        } else {
            this.dockState := "none"
        }
    }

    OnMouseDown(wParam, lParam, msg, hwnd) {
        if (this.pillGui && hwnd == this.pillGui.Hwnd) {
            ; Allow smooth dragging of the frameless pill
            PostMessage(0xA1, 2,,, "ahk_id " this.pillGui.Hwnd) ; WM_NCLBUTTONDOWN with HTCAPTION
            
            ; Re-evaluate dock state after drag completes
            SetTimer(() => this.OnDragFinished(), -250)
        }
    }

    OnDragFinished() {
        if (!this.pillGui || !this.isVisible)
            return

        try {
            this.pillGui.GetPos(&x, &y, &w, &h)
            this.UpdateDockState(x)
            this.SavePosition()

            ; If docked near edge, snap to boundary
            sw := A_ScreenWidth
            if (this.dockState == "right") {
                this.pillGui.Move(sw - this.pillWidth, y, this.pillWidth, this.pillHeight)
                this.ApplyRoundedRegion(this.pillWidth, this.pillHeight)
            } else if (this.dockState == "left") {
                this.pillGui.Move(0, y, this.pillWidth, this.pillHeight)
                this.ApplyRoundedRegion(this.pillWidth, this.pillHeight)
            }
        }
    }

    CheckHoverState() {
        if (!this.pillGui || !this.isVisible || this.dockState == "none")
            return

        CoordMode("Mouse", "Screen")
        MouseGetPos(&mx, &my)

        try this.pillGui.GetPos(&px, &py, &pw, &ph)
        catch
            return

        sw := A_ScreenWidth

        if (this.dockState == "right") {
            ; Check if cursor is over right edge handle or over expanded pill
            isOverHandle := (mx >= sw - 15 && my >= py - 10 && my <= py + ph + 10)
            isOverPill   := (mx >= px - 15 && mx <= sw && my >= py - 10 && my <= py + ph + 10)

            if (isOverHandle || isOverPill) {
                this.lastHoverTick := A_TickCount
                if (this.isCollapsed) {
                    ; Expand to full pill
                    this.pillGui.Move(sw - this.pillWidth, py, this.pillWidth, this.pillHeight)
                    this.ApplyRoundedRegion(this.pillWidth, this.pillHeight)
                    this.isCollapsed := false
                }
            } else if (!this.isCollapsed && (A_TickCount - this.lastHoverTick > 1000)) {
                ; Retract to 8px handle
                this.pillGui.Move(sw - this.collapsedWidth, py, this.collapsedWidth, this.pillHeight)
                this.isCollapsed := true
            }
        } else if (this.dockState == "left") {
            isOverHandle := (mx <= 15 && my >= py - 10 && my <= py + ph + 10)
            isOverPill   := (mx >= 0 && mx <= px + pw + 15 && my >= py - 10 && my <= py + ph + 10)

            if (isOverHandle || isOverPill) {
                this.lastHoverTick := A_TickCount
                if (this.isCollapsed) {
                    this.pillGui.Move(0, py, this.pillWidth, this.pillHeight)
                    this.ApplyRoundedRegion(this.pillWidth, this.pillHeight)
                    this.isCollapsed := false
                }
            } else if (!this.isCollapsed && (A_TickCount - this.lastHoverTick > 1000)) {
                this.pillGui.Move(0, py, this.collapsedWidth, this.pillHeight)
                this.isCollapsed := true
            }
        }
    }

    Update(timeStr, engine) {
        if (!this.pillGui || !this.isVisible)
            return

        try this.txtTimer.Text := timeStr

        dotColor := O2omTheme.ACCENT_FOCUS
        if (engine.isOnBreak)
            dotColor := O2omTheme.ACCENT_BREAK
        else if (engine.isPaused || engine.isIdle)
            dotColor := O2omTheme.ACCENT_WARN
        else if (engine.isWaitingBreak)
            dotColor := O2omTheme.ACCENT_URGENT

        try this.txtDot.Opt("c" dotColor)
        try this.btnAction.Text := engine.isPaused ? ">" : "||"
    }

    Destroy() {
        if (this.pillGui && IsObject(this.pillGui)) {
            try this.pillGui.Destroy()
            this.pillGui := ""
            this.isVisible := false
        }
    }
}
