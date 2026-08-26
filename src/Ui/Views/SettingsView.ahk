; ---------------------------------------------------------------------------
; O2om — Radically Simplified Settings View (Smart 1-Click Presets & Toggles)
; ---------------------------------------------------------------------------

class O2omSettingsView {
    static Build(g, appInstance, controlsList) {
        s := appInstance.settings

        ; -------------------------------------------------------------------
        ; Section 1: 1-Click Smart Presets (y54 to y190)
        ; -------------------------------------------------------------------
        curMode := s.mode

        ; Preset 1: Stand-Up & Posture
        isStand := (curMode == "standup")
        card1Bg := isStand ? O2omTheme.ACCENT_FOCUS : O2omTheme.BG_CARD
        card1Txt := isStand ? "FFFFFF" : O2omTheme.TEXT_PRIMARY

        card1 := g.AddText("x30 y54 w360 h42 Center 0x200 Background" card1Bg " c" card1Txt, O2omLang.Get("preset_standup_title"))
        card1.SetFont("s10 Bold", O2omTheme.FONT_PRIMARY)
        card1.OnEvent("Click", (*) => appInstance.SelectPreset("standup"))
        appInstance.presetCardStandup := card1
        controlsList.Push(card1)

        desc1 := g.AddText("x30 y98 w360 h16 Center c" O2omTheme.TEXT_MUTED, O2omLang.Get("preset_standup_desc"))
        desc1.SetFont("s8", O2omTheme.FONT_PRIMARY)
        controlsList.Push(desc1)

        ; Preset 2: Pomodoro
        isPomo := (curMode == "pomodoro")
        card2Bg := isPomo ? O2omTheme.ACCENT_FOCUS : O2omTheme.BG_CARD
        card2Txt := isPomo ? "FFFFFF" : O2omTheme.TEXT_PRIMARY

        card2 := g.AddText("x30 y118 w360 h42 Center 0x200 Background" card2Bg " c" card2Txt, O2omLang.Get("preset_pomodoro_title"))
        card2.SetFont("s10 Bold", O2omTheme.FONT_PRIMARY)
        card2.OnEvent("Click", (*) => appInstance.SelectPreset("pomodoro"))
        appInstance.presetCardPomodoro := card2
        controlsList.Push(card2)

        desc2 := g.AddText("x30 y162 w360 h16 Center c" O2omTheme.TEXT_MUTED, O2omLang.Get("preset_pomodoro_desc"))
        desc2.SetFont("s8", O2omTheme.FONT_PRIMARY)
        controlsList.Push(desc2)

        ; Preset 3: Eye Guard
        isEye := (curMode == "eyeguard")
        card3Bg := isEye ? O2omTheme.ACCENT_FOCUS : O2omTheme.BG_CARD
        card3Txt := isEye ? "FFFFFF" : O2omTheme.TEXT_PRIMARY

        card3 := g.AddText("x30 y182 w360 h42 Center 0x200 Background" card3Bg " c" card3Txt, O2omLang.Get("preset_eyeguard_title"))
        card3.SetFont("s10 Bold", O2omTheme.FONT_PRIMARY)
        card3.OnEvent("Click", (*) => appInstance.SelectPreset("eyeguard"))
        appInstance.presetCardEye := card3
        controlsList.Push(card3)

        desc3 := g.AddText("x30 y226 w360 h16 Center c" O2omTheme.TEXT_MUTED, O2omLang.Get("preset_eyeguard_desc"))
        desc3.SetFont("s8", O2omTheme.FONT_PRIMARY)
        controlsList.Push(desc3)

        ; -------------------------------------------------------------------
        ; Section 2: Essential Toggles & Language (y250 to y350)
        ; -------------------------------------------------------------------
        sep := g.AddProgress("x30 y250 w360 h2 Background" O2omTheme.BORDER_SUBTLE, 0)
        controlsList.Push(sep)

        ; Language Dropdown
        lblLang := g.AddText("x35 y266 w180 h24 c" O2omTheme.TEXT_PRIMARY, O2omLang.Get("lbl_language"))
        lblLang.SetFont("s9 Bold", O2omTheme.FONT_PRIMARY)
        controlsList.Push(lblLang)

        langs := ["العربية", "English"]
        ddlLang := g.AddDropDownList("x230 y264 w155 r2 Choose" (s.language == "ar" ? 1 : 2), langs)
        appInstance.ddlLanguage := ddlLang
        controlsList.Push(ddlLang)

        ; Sound Checkbox
        isSound := (s.soundEnabled == 1)
        chkSound := g.AddCheckbox("x35 y300 w350 h22 c" O2omTheme.TEXT_PRIMARY " " (isSound ? "Checked" : ""), O2omLang.Get("lbl_sound_enabled"))
        chkSound.SetFont("s9", O2omTheme.FONT_PRIMARY)
        appInstance.chkSound := chkSound
        controlsList.Push(chkSound)

        ; Start With Windows Checkbox
        isStart := (s.startWithWindows == 1)
        chkStartSet := g.AddCheckbox("x35 y328 w350 h22 c" O2omTheme.TEXT_PRIMARY " " (isStart ? "Checked" : ""), O2omLang.Get("chk_startup"))
        chkStartSet.SetFont("s9", O2omTheme.FONT_PRIMARY)
        appInstance.chkStartSet := chkStartSet
        controlsList.Push(chkStartSet)

        ; -------------------------------------------------------------------
        ; Save Button (y372)
        ; -------------------------------------------------------------------
        btnSave := g.AddText("x30 y372 w360 h42 Center 0x200 Background6366F1 cFFFFFF", O2omLang.Get("btn_save"))
        btnSave.SetFont("s10 Bold", O2omTheme.FONT_PRIMARY)
        btnSave.OnEvent("Click", (*) => appInstance.ApplySettingsFromGui())
        controlsList.Push(btnSave)
    }

    static UpdatePresetHighlight(appInstance, selectedMode) {
        try {
            isStand := (selectedMode == "standup")
            appInstance.presetCardStandup.Opt("Background" (isStand ? O2omTheme.ACCENT_FOCUS : O2omTheme.BG_CARD) " c" (isStand ? "FFFFFF" : O2omTheme.TEXT_PRIMARY))

            isPomo := (selectedMode == "pomodoro")
            appInstance.presetCardPomodoro.Opt("Background" (isPomo ? O2omTheme.ACCENT_FOCUS : O2omTheme.BG_CARD) " c" (isPomo ? "FFFFFF" : O2omTheme.TEXT_PRIMARY))

            isEye := (selectedMode == "eyeguard")
            appInstance.presetCardEye.Opt("Background" (isEye ? O2omTheme.ACCENT_FOCUS : O2omTheme.BG_CARD) " c" (isEye ? "FFFFFF" : O2omTheme.TEXT_PRIMARY))
        }
    }
}
