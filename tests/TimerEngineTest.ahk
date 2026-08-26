#Requires AutoHotkey v2.0
#SingleInstance Force

OnError(TestErrorHandler)

TestErrorHandler(thrown, mode) {
    FileAppend(Format("FATAL TEST ERROR in {1} (Line {2}): {3}`n", thrown.File, thrown.Line, thrown.Message), A_ScriptDir "\test_results.txt", "UTF-8")
    ExitApp(1)
}

#Include ../src/Locale/Language.ahk
#Include ../src/Services/Resources.ahk
#Include ../src/Services/SettingsRepo.ahk
#Include ../src/Services/SoundService.ahk
#Include ../src/Services/NotificationService.ahk
#Include ../src/Services/IdleMonitor.ahk
#Include ../src/Services/StartupService.ahk
#Include ../src/Core/HealthTracker.ahk
#Include ../src/Core/ExerciseRoutines.ahk
#Include ../src/Core/TimerEngine.ahk
#Include ../src/Ui/Theme.ahk

class Assert {
    static passCount := 0
    static failCount := 0
    static logFile   := A_ScriptDir "\test_results.txt"

    static Init() {
        try FileDelete(this.logFile)
    }

    static Equal(expected, actual, testName := "Test") {
        if (expected == actual) {
            this.passCount++
            FileAppend(Format("[PASS] {1}`n", testName), this.logFile, "UTF-8")
        } else {
            this.failCount++
            FileAppend(Format("[FAIL] {1}: Expected '{2}', got '{3}'`n", testName, expected, actual), this.logFile, "UTF-8")
        }
    }

    static True(condition, testName := "Test") {
        this.Equal(true, !!condition, testName)
    }

    static Summary() {
        resText := Format("`n====================================`nTest Results: {1} Passed, {2} Failed`n====================================`n", this.passCount, this.failCount)
        FileAppend(resText, this.logFile, "UTF-8")
        ExitApp(this.failCount > 0 ? 1 : 0)
    }
}

RunTests() {
    Assert.Init()
    FileAppend("Running O2om v3.0 Comprehensive Unit Tests...`n`n", Assert.logFile, "UTF-8")

    ; -----------------------------------------------------------------------
    ; 1. Settings & Safe Parsing
    ; -----------------------------------------------------------------------
    s := O2omSettingsRepo()
    s.workIntervalMin   := 40
    s.shortBreakMin     := 5
    s.longBreakMin      := 15
    s.snoozeMin         := 5
    s.idleThresholdMin  := 5
    s.cyclesBeforeLong  := 4
    s.startWithWindows  := 1
    s.soundEnabled      := 1

    Assert.Equal(40, O2omSettingsRepo.SafeInt("40", 1, 180, 40), "SafeInt parses valid string")
    Assert.Equal(40, O2omSettingsRepo.SafeInt("not_a_num", 1, 180, 40), "SafeInt returns fallback on invalid string")
    Assert.Equal(180, O2omSettingsRepo.SafeInt(999, 1, 180, 40), "SafeInt clamps values above max")
    Assert.Equal(1, O2omSettingsRepo.SafeInt(-10, 1, 180, 40), "SafeInt clamps values below min")

    ; -----------------------------------------------------------------------
    ; 2. Stand-Up Mode (Default)
    ; -----------------------------------------------------------------------
    engine := O2omEngine(s)
    Assert.Equal(40 * 60 * 1000, engine.remaining, "Initial remaining matches work interval (40 min)")
    Assert.True(!engine.isPaused, "Engine is not paused by default")
    Assert.True(!engine.isOnBreak, "Engine is not on break by default")
    Assert.True(!engine.isWaitingBreak, "Engine is not waiting for break by default")
    Assert.True(!engine.isWaitingWork, "Engine is not waiting for work by default")

    ; Pause / Resume
    engine.TogglePause()
    Assert.True(engine.isPaused, "TogglePause pauses engine")
    engine.TogglePause()
    Assert.True(!engine.isPaused, "TogglePause resumes engine")

    ; Short Break & Cycles
    engine.StartBreak()
    Assert.True(engine.isOnBreak, "StartBreak activates isOnBreak")
    Assert.Equal(5 * 60 * 1000, engine.remaining, "1st break is a short break (5 min)")
    Assert.Equal(1, engine.completedCycles, "Completed cycles count incremented to 1")

    ; 4th break is long break
    engine.StartBreak() ; cycle 2
    engine.StartBreak() ; cycle 3
    engine.StartBreak() ; cycle 4
    Assert.Equal(15 * 60 * 1000, engine.remaining, "4th break is a long break (15 min)")

    ; Snooze
    engine.Snooze()
    Assert.True(!engine.isOnBreak, "Snooze deactivates break mode")
    Assert.Equal(5 * 60 * 1000, engine.remaining, "Snooze sets remaining to snooze duration (5 min)")

    ; Reset to work
    engine.ResetToWork()
    Assert.Equal(40 * 60 * 1000, engine.remaining, "ResetToWork resets remaining to work duration")

    ; -----------------------------------------------------------------------
    ; 3. Multi-Mode Switching (Pomodoro & Eye Guard)
    ; -----------------------------------------------------------------------
    engine.SetMode("pomodoro")
    Assert.Equal("pomodoro", engine.mode, "Mode switched to pomodoro")
    Assert.Equal(25 * 60 * 1000, engine.remaining, "Pomodoro work session is 25 minutes")
    engine.StartBreak()
    Assert.Equal(5 * 60 * 1000, engine.remaining, "Pomodoro short break is 5 minutes")
    engine.StartBreak() ; 2
    engine.StartBreak() ; 3
    engine.StartBreak() ; 4
    Assert.Equal(15 * 60 * 1000, engine.remaining, "Pomodoro 4th break is 15 minutes")

    engine.SetMode("eyeguard")
    Assert.Equal("eyeguard", engine.mode, "Mode switched to eyeguard")
    Assert.Equal(20 * 60 * 1000, engine.remaining, "Eye guard work session is 20 minutes")
    engine.StartBreak()
    Assert.Equal(20 * 1000, engine.remaining, "Eye guard break is 20 seconds")

    engine.SetMode("standup")
    Assert.Equal("standup", engine.mode, "Mode switched back to standup")

    ; -----------------------------------------------------------------------
    ; 4. Escalation Cycle & Device Activity
    ; -----------------------------------------------------------------------
    engine.ResetToWork()
    engine.isWaitingBreak := true
    engine.reminderStage  := 0
    engine.breakWaitStart := A_TickCount - (s.escalationMin * 60 * 1000 + 100)

    res1 := engine.Tick()
    Assert.Equal("escalation", res1.type, "First warning escalation triggers")
    Assert.Equal(1, res1.stage, "Stage 1 escalation verified")

    engine.breakWaitStart := A_TickCount - (s.escalationMin * 60 * 1000 + 100)
    res2 := engine.Tick()
    Assert.Equal("auto_work_reset", res2.type, "Second warning triggers auto work reset when user active")
    Assert.Equal(40 * 60 * 1000, engine.remaining, "Session auto-resets to full work duration")

    ; -----------------------------------------------------------------------
    ; 5. Sleep/Wake Gap Recovery
    ; -----------------------------------------------------------------------
    engine.ResetToWork()
    engine.remaining := 20 * 60 * 1000
    engine.lastTick  := A_TickCount - (6 * 60 * 1000) ; simulated 6m sleep gap
    resSleep := engine.Tick()
    Assert.Equal(40 * 60 * 1000, engine.remaining, "System sleep gap resets to fresh session")

    ; -----------------------------------------------------------------------
    ; 6. Exercise Routines Provider
    ; -----------------------------------------------------------------------
    standupRoutine := O2omExerciseRoutines.GetRoutine("standup", 5 * 60 * 1000)
    Assert.Equal(5, standupRoutine.Length, "Standup routine contains 5 structured exercises")
    Assert.Equal("chest_opener", standupRoutine[1].id, "First exercise is chest opener")

    eyeRoutine := O2omExerciseRoutines.GetRoutine("eyeguard", 20 * 1000)
    Assert.Equal(1, eyeRoutine.Length, "Eye guard routine contains 1 targeted exercise")
    Assert.Equal("eye_guard_20", eyeRoutine[1].id, "Eye guard exercise id matches")

    ; -----------------------------------------------------------------------
    ; 7. Health & Analytics Tracker
    ; -----------------------------------------------------------------------
    testStatsFile := A_ScriptDir "\temp_test_stats.ini"
    try FileDelete(testStatsFile)

    ht := O2omHealthTracker(testStatsFile)
    Assert.Equal(0, ht.todayStands, "Initial today stands count is 0")
    Assert.Equal(8, ht.dailyStandGoal, "Daily stand goal is 8")

    recRes := ht.RecordCompletedBreak()
    Assert.Equal(1, ht.todayStands, "RecordCompletedBreak increments todayStands to 1")
    Assert.Equal(1, ht.totalStandsAllTime, "Lifetime stands incremented to 1")
    Assert.True(!recRes.goalJustMet, "Goal not met at 1 stand")

    ; Simulate reaching daily goal
    loop 7
        ht.RecordCompletedBreak()
    Assert.Equal(8, ht.todayStands, "Reached 8 stands today")
    Assert.Equal(1, ht.currentStreakDays, "Streak incremented to 1 day on reaching daily goal")

    ; Clean up temp test stats
    try FileDelete(testStatsFile)

    ; -----------------------------------------------------------------------
    ; 8. Localization & Theme Tokens
    ; -----------------------------------------------------------------------
    O2omLang.currentLang := "ar"
    Assert.Equal("قُوم — O2om", O2omLang.Get("app_title"), "Arabic app_title translation loaded")
    Assert.Equal("الوقوف والتمدد", O2omLang.Get("mode_standup"), "Arabic mode_standup loaded")
    O2omLang.currentLang := "en"
    Assert.Equal("O2om — Stand-Up Reminder", O2omLang.Get("app_title"), "English app_title translation loaded")
    Assert.Equal("Stand-Up & Posture", O2omLang.Get("mode_standup"), "English mode_standup loaded")
    O2omLang.currentLang := "ar"

    Assert.Equal("0D0E15", O2omTheme.BG_ROOT, "Theme BG_ROOT token verified")
    Assert.Equal("6366F1", O2omTheme.ACCENT_FOCUS, "Theme ACCENT_FOCUS token verified")

    Assert.Summary()
}

RunTests()
