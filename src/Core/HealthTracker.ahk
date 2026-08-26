; ---------------------------------------------------------------------------
; O2om — Health & Productivity Analytics Tracker
; ---------------------------------------------------------------------------

class O2omHealthTracker {
    todayDate               := ""
    todayStands             := 0
    dailyStandGoal          := 8
    todayFocusMinutes       := 0
    totalStandsAllTime      := 0
    totalFocusMinutesAllTime:= 0
    currentStreakDays       := 0
    bestStreakDays          := 0
    lastActiveDate          := ""
    statsFilePath           := ""

    __New(statsFile := "") {
        this.statsFilePath := (statsFile != "") ? statsFile : this.GetDefaultStatsPath()
        this.todayDate := FormatTime(, "yyyy-MM-dd")
        this.Load()
        this.CheckMidnightRollover()
    }

    GetDefaultStatsPath() {
        localPath := A_ScriptDir "\o2om_stats.ini"
        if FileExist(localPath)
            return localPath

        appDataDir := A_AppData "\O2om"
        try DirCreate(appDataDir)
        return appDataDir "\o2om_stats.ini"
    }

    CheckMidnightRollover() {
        currentDay := FormatTime(, "yyyy-MM-dd")
        if (this.todayDate == currentDay)
            return false

        ; Date changed -> check streak
        if (this.lastActiveDate != "") {
            ; Check if yesterday was active and met goal
            yesterday := FormatTime(DateAdd(A_Now, -1, "days"), "yyyy-MM-dd")
            if (this.lastActiveDate == yesterday && this.todayStands >= this.dailyStandGoal) {
                this.currentStreakDays++
                if (this.currentStreakDays > this.bestStreakDays)
                    this.bestStreakDays := this.currentStreakDays
            } else if (this.lastActiveDate != yesterday) {
                ; Missed one or more full days
                this.currentStreakDays := 0
            }
        }

        this.lastActiveDate := this.todayDate
        this.todayDate := currentDay
        this.todayStands := 0
        this.todayFocusMinutes := 0
        this.Save()
        return true
    }

    RecordCompletedBreak() {
        this.CheckMidnightRollover()
        this.todayStands++
        this.totalStandsAllTime++
        this.lastActiveDate := this.todayDate

        goalJustMet := (this.todayStands == this.dailyStandGoal)
        if (goalJustMet) {
            this.currentStreakDays++
            if (this.currentStreakDays > this.bestStreakDays)
                this.bestStreakDays := this.currentStreakDays
        }

        this.Save()
        return {
            goalJustMet: goalJustMet,
            todayStands: this.todayStands,
            goal: this.dailyStandGoal,
            streak: this.currentStreakDays
        }
    }

    AddFocusMinutes(minutes) {
        if (minutes <= 0)
            return
        this.CheckMidnightRollover()
        this.todayFocusMinutes += minutes
        this.totalFocusMinutesAllTime += minutes
        this.Save()
    }

    Load() {
        cfg := this.statsFilePath
        if !FileExist(cfg) {
            this.Save()
            return
        }

        try {
            this.todayDate               := IniRead(cfg, "Daily", "Date", FormatTime(, "yyyy-MM-dd"))
            this.todayStands             := Max(0, Integer(IniRead(cfg, "Daily", "StandsToday", 0)))
            this.dailyStandGoal          := Max(1, Integer(IniRead(cfg, "Daily", "StandGoal", 8)))
            this.todayFocusMinutes       := Max(0, Integer(IniRead(cfg, "Daily", "FocusMinutesToday", 0)))
            this.lastActiveDate          := IniRead(cfg, "Daily", "LastActiveDate", "")

            this.totalStandsAllTime      := Max(0, Integer(IniRead(cfg, "Lifetime", "TotalStands", 0)))
            this.totalFocusMinutesAllTime:= Max(0, Integer(IniRead(cfg, "Lifetime", "TotalFocusMinutes", 0)))
            this.currentStreakDays       := Max(0, Integer(IniRead(cfg, "Streaks", "CurrentStreak", 0)))
            this.bestStreakDays          := Max(0, Integer(IniRead(cfg, "Streaks", "BestStreak", 0)))
        } catch {
            this.Save()
        }
    }

    Save() {
        cfg := this.statsFilePath
        try {
            IniWrite(this.todayDate,                cfg, "Daily", "Date")
            IniWrite(this.todayStands,              cfg, "Daily", "StandsToday")
            IniWrite(this.dailyStandGoal,           cfg, "Daily", "StandGoal")
            IniWrite(this.todayFocusMinutes,        cfg, "Daily", "FocusMinutesToday")
            IniWrite(this.lastActiveDate,           cfg, "Daily", "LastActiveDate")

            IniWrite(this.totalStandsAllTime,       cfg, "Lifetime", "TotalStands")
            IniWrite(this.totalFocusMinutesAllTime, cfg, "Lifetime", "TotalFocusMinutes")
            IniWrite(this.currentStreakDays,        cfg, "Streaks", "CurrentStreak")
            IniWrite(this.bestStreakDays,           cfg, "Streaks", "BestStreak")
        }
    }

    ResetAll() {
        this.todayStands              := 0
        this.todayFocusMinutes        := 0
        this.totalStandsAllTime       := 0
        this.totalFocusMinutesAllTime := 0
        this.currentStreakDays        := 0
        this.bestStreakDays           := 0
        this.lastActiveDate           := ""
        this.Save()
    }
}
