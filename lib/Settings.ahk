; ---------------------------------------------------------------------------
; O2om — Configuration Settings Manager with Portable Fallback
; ---------------------------------------------------------------------------

class O2omSettings {
    static configFile := ""

    ; --- Settings State (Minutes & Preferences) ---
    language          := "ar"
    startWithWindows  := 1
    soundEnabled      := 1
    workIntervalMin   := 40
    shortBreakMin     := 5
    longBreakMin      := 15
    escalationMin     := 2
    snoozeMin         := 5
    idleThresholdMin  := 5
    cyclesBeforeLong  := 4

    static GetConfigFilePath() {
        if (O2omSettings.configFile != "")
            return O2omSettings.configFile

        localPath := A_ScriptDir "\o2om_config.ini"
        if FileExist(localPath) {
            O2omSettings.configFile := localPath
            return localPath
        }

        appDataDir  := A_AppData "\O2om"
        appDataPath := appDataDir "\o2om_config.ini"
        if FileExist(appDataPath) {
            O2omSettings.configFile := appDataPath
            return appDataPath
        }

        ; Check if local directory is writable
        try {
            testFile := A_ScriptDir "\.write_test"
            FileAppend("test", testFile)
            FileDelete(testFile)
            O2omSettings.configFile := localPath
            return localPath
        } catch {
            try DirCreate(appDataDir)
            O2omSettings.configFile := appDataPath
            return appDataPath
        }
    }

    Load() {
        cfg := O2omSettings.GetConfigFilePath()
        if !FileExist(cfg) {
            this.Save()
            return
        }

        try {
            rawLang                := IniRead(cfg, "General", "Language", "ar")
            this.language          := (rawLang == "en") ? "en" : "ar"
            this.startWithWindows  := (Integer(IniRead(cfg, "General", "StartWithWindows", 1)) == 1) ? 1 : 0
            this.soundEnabled      := (Integer(IniRead(cfg, "General", "SoundEnabled", 1)) == 1) ? 1 : 0
            this.workIntervalMin   := Max(1, Min(180, Integer(IniRead(cfg, "Timer", "WorkInterval", 40))))
            this.shortBreakMin     := Max(1, Min(60,  Integer(IniRead(cfg, "Timer", "ShortBreak", 5))))
            this.longBreakMin      := Max(1, Min(90,  Integer(IniRead(cfg, "Timer", "LongBreak", 15))))
            this.escalationMin     := Max(1, Min(30,  Integer(IniRead(cfg, "Timer", "EscalationInterval", 2))))
            this.snoozeMin         := Max(1, Min(60,  Integer(IniRead(cfg, "Timer", "SnoozeDuration", 5))))
            this.idleThresholdMin  := Max(1, Min(60,  Integer(IniRead(cfg, "Timer", "IdleThreshold", 5))))
            this.cyclesBeforeLong  := Max(1, Min(12,  Integer(IniRead(cfg, "Timer", "CyclesBeforeLong", 4))))
        } catch {
            this.ResetDefaults()
        }

        ; Sync language module state
        O2omLang.currentLang := this.language
    }

    Save() {
        cfg := O2omSettings.GetConfigFilePath()
        try {
            IniWrite(this.language,         cfg, "General", "Language")
            IniWrite(this.startWithWindows, cfg, "General", "StartWithWindows")
            IniWrite(this.soundEnabled,     cfg, "General", "SoundEnabled")
            IniWrite(this.workIntervalMin,  cfg, "Timer", "WorkInterval")
            IniWrite(this.shortBreakMin,    cfg, "Timer", "ShortBreak")
            IniWrite(this.longBreakMin,     cfg, "Timer", "LongBreak")
            IniWrite(this.escalationMin,    cfg, "Timer", "EscalationInterval")
            IniWrite(this.snoozeMin,        cfg, "Timer", "SnoozeDuration")
            IniWrite(this.idleThresholdMin, cfg, "Timer", "IdleThreshold")
            IniWrite(this.cyclesBeforeLong, cfg, "Timer", "CyclesBeforeLong")
        }
    }

    ResetDefaults() {
        this.language         := "ar"
        this.startWithWindows := 1
        this.soundEnabled     := 1
        this.workIntervalMin  := 40
        this.shortBreakMin    := 5
        this.longBreakMin     := 15
        this.escalationMin    := 2
        this.snoozeMin        := 5
        this.idleThresholdMin := 5
        this.cyclesBeforeLong := 4
        O2omLang.currentLang  := "ar"
    }
}
