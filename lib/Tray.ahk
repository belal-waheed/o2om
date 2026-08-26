; ---------------------------------------------------------------------------
; O2om — System Tray Menu & Icon Management
; ---------------------------------------------------------------------------

class O2omTray {
    static Setup(appInstance) {
        iconPath := O2omResources.GetIcon()
        if (iconPath != "") {
            try TraySetIcon(iconPath)
        }

        tray := A_TrayMenu
        tray.Delete()

        tray.Add(O2omLang.Get("tray_show"), (*) => appInstance.ShowGui())
        tray.Add()
        
        pauseLabel := (appInstance.engine && appInstance.engine.isPaused) ? O2omLang.Get("tray_resume") : O2omLang.Get("tray_pause")
        tray.Add(pauseLabel, (*) => appInstance.TogglePauseTimer())
        tray.Add(O2omLang.Get("tray_take_break"), (*) => appInstance.StartBreakMode(false))
        tray.Add(O2omLang.Get("tray_reset"), (*) => appInstance.ResetTimer())
        tray.Add()
        
        soundLabel := (appInstance.settings && appInstance.settings.soundEnabled) ? O2omLang.Get("tray_sound_mute") : O2omLang.Get("tray_sound_unmute")
        tray.Add(soundLabel, (*) => appInstance.ToggleSound())
        tray.Add()
        
        tray.Add(O2omLang.Get("tray_quit"), (*) => ExitApp())

        ; "1&" explicitly binds double-click to item 1 (Show Dashboard)
        tray.Default := "1&"
    }

    static UpdateTooltip(timeStr) {
        try {
            A_IconTip := O2omLang.Get("app_title") " — " timeStr
        }
    }
}
