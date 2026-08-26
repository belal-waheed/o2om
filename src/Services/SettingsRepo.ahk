; ---------------------------------------------------------------------------
; O2om — Configuration Repository & Settings Adapter
; ---------------------------------------------------------------------------

class O2omSettingsRepo {
    static configFile := ""

    ; General
    language          := "ar"
    mode              := "standup"  ; standup, pomodoro, eyeguard, custom
    startWithWindows  := 1
    soundEnabled      := 1
    miniPillEnabled   := 0
    miniPillX         := -1
    miniPillY         := -1

    ; Timer Intervals (Minutes)
    workIntervalMin   := 40
    shortBreakMin     := 5
    longBreakMin      := 15
    escalationMin     := 2
    snoozeMin         := 5
    idleThresholdMin  := 5
    cyclesBeforeLong  := 4

    ; Eye Guard Specifics
    eyeWorkMin        := 20
    eyeBreakSec       := 20

    ; Daily Goals
    dailyStandGoal    := 8

    static SafeInt(val, minVal, maxVal, fallback) {
        if (!IsInteger(val))
            return fallback
        i := Integer(val)
        return Max(minVal, Min(maxVal, i))
    }

    static GetConfigPath() {
        if (O2omSettingsRepo.configFile != "")
            return O2omSettingsRepo.configFile

        localPath := A_ScriptDir "\o2om_config.ini"
        if FileExist(localPath) {
            O2omSettingsRepo.configFile := localPath
            return localPath
        }

        appDataDir := A_AppData "\O2om"
        appDataPath := appDataDir "\o2om_config.ini"
        if FileExist(appDataPath) {
            O2omSettingsRepo.configFile := appDataPath
            return appDataPath
        }

        try {
            testFile := A_ScriptDir "\.write_test"
            FileAppend("test", testFile)
            FileDelete(testFile)
            O2omSettingsRepo.configFile := localPath
            return localPath
        } catch {
            try DirCreate(appDataDir)
            O2omSettingsRepo.configFile := appDataPath
            return appDataPath
        }
    }

    ApplyPreset(presetName) {
        this.mode := presetName
        if (presetName == "standup") {
            this.workIntervalMin  := 40
            this.shortBreakMin    := 5
            this.longBreakMin     := 15
            this.cyclesBeforeLong := 4
        } else if (presetName == "pomodoro") {
            this.workIntervalMin  := 25
            this.shortBreakMin    := 5
            this.longBreakMin     := 15
            this.cyclesBeforeLong := 4
        } else if (presetName == "eyeguard") {
            this.workIntervalMin  := 20
            this.shortBreakMin    := 1  ; 20 seconds representation in minutes
            this.longBreakMin     := 2
            this.cyclesBeforeLong := 4
        }
        this.Save()
    }

    Load() {
        cfg := O2omSettingsRepo.GetConfigPath()
        if !FileExist(cfg) {
            this.Save()
            return
        }

        try {
            rawLang := IniRead(cfg, "General", "Language", "ar")
            this.language := (rawLang == "en") ? "en" : "ar"

            rawMode := IniRead(cfg, "General", "Mode", "standup")
            if (rawMode == "standup" || rawMode == "eyeguard" || rawMode == "pomodoro" || rawMode == "custom")
                this.mode := rawMode
            else
                this.mode := "standup"

            this.startWithWindows := (Integer(IniRead(cfg, "General", "StartWithWindows", 1)) == 1) ? 1 : 0
            this.soundEnabled     := (Integer(IniRead(cfg, "General", "SoundEnabled", 1)) == 1) ? 1 : 0
            this.miniPillEnabled  := (Integer(IniRead(cfg, "General", "MiniPillEnabled", 0)) == 1) ? 1 : 0
            this.miniPillX        := Integer(IniRead(cfg, "General", "MiniPillX", -1))
            this.miniPillY        := Integer(IniRead(cfg, "General", "MiniPillY", -1))

            this.workIntervalMin  := O2omSettingsRepo.SafeInt(IniRead(cfg, "Timer", "WorkInterval", 40), 1, 180, 40)
            this.shortBreakMin    := O2omSettingsRepo.SafeInt(IniRead(cfg, "Timer", "ShortBreak", 5), 1, 60, 5)
            this.longBreakMin     := O2omSettingsRepo.SafeInt(IniRead(cfg, "Timer", "LongBreak", 15), 1, 90, 15)
            this.escalationMin    := O2omSettingsRepo.SafeInt(IniRead(cfg, "Timer", "EscalationInterval", 2), 1, 30, 2)
            this.snoozeMin        := O2omSettingsRepo.SafeInt(IniRead(cfg, "Timer", "SnoozeDuration", 5), 1, 60, 5)
            this.idleThresholdMin := O2omSettingsRepo.SafeInt(IniRead(cfg, "Timer", "IdleThreshold", 5), 1, 60, 5)
            this.cyclesBeforeLong := O2omSettingsRepo.SafeInt(IniRead(cfg, "Timer", "CyclesBeforeLong", 4), 1, 12, 4)

            this.eyeWorkMin       := O2omSettingsRepo.SafeInt(IniRead(cfg, "EyeGuard", "WorkMin", 20), 1, 60, 20)
            this.eyeBreakSec      := O2omSettingsRepo.SafeInt(IniRead(cfg, "EyeGuard", "BreakSec", 20), 5, 120, 20)
            this.dailyStandGoal   := O2omSettingsRepo.SafeInt(IniRead(cfg, "Goals", "DailyStandGoal", 8), 1, 24, 8)
        } catch {
            this.ResetDefaults()
        }
    }

    Save() {
        cfg := O2omSettingsRepo.GetConfigPath()
        try {
            IniWrite(this.language,         cfg, "General", "Language")
            IniWrite(this.mode,             cfg, "General", "Mode")
            IniWrite(this.startWithWindows, cfg, "General", "StartWithWindows")
            IniWrite(this.soundEnabled,     cfg, "General", "SoundEnabled")
            IniWrite(this.miniPillEnabled,  cfg, "General", "MiniPillEnabled")
            IniWrite(this.miniPillX,        cfg, "General", "MiniPillX")
            IniWrite(this.miniPillY,        cfg, "General", "MiniPillY")

            IniWrite(this.workIntervalMin,  cfg, "Timer", "WorkInterval")
            IniWrite(this.shortBreakMin,    cfg, "Timer", "ShortBreak")
            IniWrite(this.longBreakMin,     cfg, "Timer", "LongBreak")
            IniWrite(this.escalationMin,    cfg, "Timer", "EscalationInterval")
            IniWrite(this.snoozeMin,        cfg, "Timer", "SnoozeDuration")
            IniWrite(this.idleThresholdMin, cfg, "Timer", "IdleThreshold")
            IniWrite(this.cyclesBeforeLong, cfg, "Timer", "CyclesBeforeLong")

            IniWrite(this.eyeWorkMin,       cfg, "EyeGuard", "WorkMin")
            IniWrite(this.eyeBreakSec,      cfg, "EyeGuard", "BreakSec")
            IniWrite(this.dailyStandGoal,   cfg, "Goals", "DailyStandGoal")
        }
    }

    ResetDefaults() {
        this.language         := "ar"
        this.mode             := "standup"
        this.startWithWindows := 1
        this.soundEnabled     := 1
        this.miniPillEnabled  := 0
        this.miniPillX        := -1
        this.miniPillY        := -1
        this.workIntervalMin  := 40
        this.shortBreakMin    := 5
        this.longBreakMin     := 15
        this.escalationMin    := 2
        this.snoozeMin        := 5
        this.idleThresholdMin := 5
        this.cyclesBeforeLong := 4
        this.eyeWorkMin       := 20
        this.eyeBreakSec      := 20
        this.dailyStandGoal   := 8
        this.Save()
    }
}
