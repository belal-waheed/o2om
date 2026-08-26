; ---------------------------------------------------------------------------
; O2om — Unified 5-in-1 Desk Exercise & Ergonomics Break Overlay
; ---------------------------------------------------------------------------

class O2omBreakOverlayView {
    appInstance    := ""
    overlayGui     := ""
    routine        := []
    currentStep    := 1
    stepRemaining  := 0
    isStepPaused   := false

    ; Controls
    txtTitle       := ""
    txtStepBadge   := ""
    txtExDesc      := ""
    txtStepTimer   := ""
    stepCards      := []
    picExercise    := ""

    __New(appInstance) {
        this.appInstance := appInstance
        this.routine := O2omExerciseRoutines.GetRoutine(appInstance.engine.mode, appInstance.engine.remaining)
        this.currentStep := 1
        this.stepRemaining := (this.routine.Length > 0) ? this.routine[1].durationSec : 30
        this.Build()
    }

    Build() {
        if (this.overlayGui && IsObject(this.overlayGui))
            try this.overlayGui.Destroy()

        isRTL := (O2omLang.currentLang == "ar")
        guiOpts := "-Caption +0x02000000"
        if (isRTL)
            guiOpts .= " +E0x400000"

        bg := Gui(guiOpts, O2omLang.Get("app_title"))
        bg.BackColor := O2omTheme.BG_ROOT

        bg.OnEvent("Escape", (*) => this.appInstance.StartWorkMode())

        sw := A_ScreenWidth
        sh := A_ScreenHeight

        ; 1. Top Header
        titleStr := O2omLang.Get("exercise_overview_title")
        txtTitle := bg.AddText("x40 y20 w" (sw - 80) " h24 Center c" O2omTheme.ACCENT_BREAK, titleStr)
        txtTitle.SetFont("s11 Bold", O2omTheme.FONT_PRIMARY)
        this.txtTitle := txtTitle

        curEx := (this.routine.Length >= this.currentStep) ? this.routine[this.currentStep] : ""
        stepName := curEx ? ((O2omLang.currentLang == "ar") ? curEx.name_ar : curEx.name_en) : ""
        badgeStr := Format("{1}: {2}", Format(O2omLang.Get("exercise_step_badge"), this.currentStep, this.routine.Length), stepName)

        txtBadge := bg.AddText("x40 y46 w" (sw - 80) " h34 Center c" O2omTheme.TEXT_PRIMARY, badgeStr)
        txtBadge.SetFont("s16 Bold", O2omTheme.FONT_DISPLAY)
        this.txtStepBadge := txtBadge

        descStr := curEx ? ((O2omLang.currentLang == "ar") ? curEx.desc_ar : curEx.desc_en) : ""
        txtDesc := bg.AddText("x60 y82 w" (sw - 120) " h40 Center c" O2omTheme.TEXT_MUTED, descStr)
        txtDesc.SetFont("s10", O2omTheme.FONT_PRIMARY)
        this.txtExDesc := txtDesc

        ; 2. Centered Panoramic 16:9 Graphic (contains all 5 exercises)
        imgPath := O2omResources.GetExerciseImage()
        imgW := 0
        imgH := 0
        ix := 0
        iy := 126

        if (imgPath != "") {
            maxH := sh - 240
            maxW := sw - 80
            imgW := Min(maxH * 16 // 9, maxW)
            imgH := imgW * 9 // 16
            ix := (sw - imgW) // 2

            this.picExercise := bg.AddPicture("x" ix " y" iy " w" imgW " h" imgH, imgPath)
        }

        ; 3. 5-Segment Synchronized Indicator Cards (directly under the 5 panels)
        segY := iy + imgH + 10
        segW := (imgW > 0) ? (imgW // 5) : (sw // 5)
        this.stepCards := []

        stepLabelsAr := ["1. إرجاع الرقبة", "2. عصر الكتفين", "3. التفاف الجذع", "4. تمدد الورك", "5. راحة العينين"]
        stepLabelsEn := ["1. Neck Tuck", "2. Chest Opener", "3. Torso Twist", "4. Hip Lunge", "5. Eye Rest"]
        labels := (O2omLang.currentLang == "ar") ? stepLabelsAr : stepLabelsEn

        loop 5 {
            idx := A_Index
            cx := ix + (idx - 1) * segW + 4
            cw := segW - 8
            isCur := (idx == this.currentStep)

            cardBg := isCur ? O2omTheme.ACCENT_BREAK : O2omTheme.BG_CARD
            cardTxt := isCur ? "FFFFFF" : O2omTheme.TEXT_MUTED

            sc := bg.AddText("x" cx " y" segY " w" cw " h28 Center 0x200 Background" cardBg " c" cardTxt, labels[idx])
            sc.SetFont("s9 Bold", O2omTheme.FONT_PRIMARY)
            this.stepCards.Push(sc)
        }

        ; 4. Bottom Timer & Navigation Controls
        botY := sh - 68

        timerStr := Format("00:{:02}", this.stepRemaining)
        txtTimer := bg.AddText("x" ix " y" botY " w140 h44 c" O2omTheme.TEXT_PRIMARY, timerStr)
        txtTimer.SetFont("s26 Bold", O2omTheme.FONT_DISPLAY)
        this.txtStepTimer := txtTimer

        btnPrev := bg.AddText("x" (ix + 160) " y" (botY + 4) " w110 h36 Center 0x200 Background1F2333 c" O2omTheme.TEXT_PRIMARY, O2omLang.Get("btn_prev_exercise"))
        btnPrev.SetFont("s9 Bold", O2omTheme.FONT_PRIMARY)
        btnPrev.OnEvent("Click", (*) => this.PrevStep())

        btnNext := bg.AddText("x" (ix + 280) " y" (botY + 4) " w110 h36 Center 0x200 Background1F2333 c" O2omTheme.TEXT_PRIMARY, O2omLang.Get("btn_next_exercise"))
        btnNext.SetFont("s9 Bold", O2omTheme.FONT_PRIMARY)
        btnNext.OnEvent("Click", (*) => this.NextStep())

        btnEnd := bg.AddText("x" (ix + imgW - 200) " y" (botY + 4) " w200 h36 Center 0x200 Background6366F1 cFFFFFF", O2omLang.Get("btn_finish_break"))
        btnEnd.SetFont("s9 Bold", O2omTheme.FONT_PRIMARY)
        btnEnd.OnEvent("Click", (*) => this.appInstance.StartWorkMode())

        this.overlayGui := bg
        bg.Show("x0 y0 w" sw " h" sh)
        try DllCall("SetCursor", "Ptr", DllCall("LoadCursor", "Ptr", 0, "Int", 32512, "Ptr"))
    }

    TickOneSecond() {
        if (!this.overlayGui || this.isStepPaused)
            return

        if (this.stepRemaining > 1) {
            this.stepRemaining--
            try this.txtStepTimer.Text := Format("00:{:02}", this.stepRemaining)
        } else {
            this.NextStep()
        }
    }

    NextStep() {
        if (this.currentStep < this.routine.Length) {
            this.currentStep++
            this.stepRemaining := this.routine[this.currentStep].durationSec
            O2omSoundService.PlayStepTransition()
            this.UpdateStepDisplay()
        } else {
            this.appInstance.StartWorkMode()
        }
    }

    PrevStep() {
        if (this.currentStep > 1) {
            this.currentStep--
            this.stepRemaining := this.routine[this.currentStep].durationSec
            this.UpdateStepDisplay()
        }
    }

    UpdateStepDisplay() {
        if (!this.overlayGui)
            return

        curEx := this.routine[this.currentStep]
        stepName := (O2omLang.currentLang == "ar") ? curEx.name_ar : curEx.name_en
        badgeStr := Format("{1}: {2}", Format(O2omLang.Get("exercise_step_badge"), this.currentStep, this.routine.Length), stepName)
        descStr := (O2omLang.currentLang == "ar") ? curEx.desc_ar : curEx.desc_en

        try this.txtStepBadge.Text := badgeStr
        try this.txtExDesc.Text := descStr
        try this.txtStepTimer.Text := Format("00:{:02}", this.stepRemaining)

        ; Update 5-panel indicator cards highlight
        loop this.stepCards.Length {
            isCur := (A_Index == this.currentStep)
            cardBg := isCur ? O2omTheme.ACCENT_BREAK : O2omTheme.BG_CARD
            cardTxt := isCur ? "FFFFFF" : O2omTheme.TEXT_MUTED
            try this.stepCards[A_Index].Opt("Background" cardBg " c" cardTxt)
        }
    }

    Destroy() {
        if (this.overlayGui && IsObject(this.overlayGui)) {
            try this.overlayGui.Destroy()
            this.overlayGui := ""
        }
    }
}
