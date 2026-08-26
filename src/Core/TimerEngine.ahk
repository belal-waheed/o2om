; ---------------------------------------------------------------------------
; O2om — Core Timer Engine (Multi-Mode State Machine)
; ---------------------------------------------------------------------------

class O2omEngine {
    ; Operational Modes
    static MODE_STANDUP   := "standup"    ; Ergonomic stand-up & posture reminder
    static MODE_EYEGUARD  := "eyeguard"   ; 20-20-20 Eye strain guard (20m / 20s)
    static MODE_POMODORO  := "pomodoro"   ; Classic Pomodoro (25m / 5m / 15m)
    static MODE_CUSTOM    := "custom"     ; User custom intervals

    static SLEEP_GAP      := 5000         ; 5 seconds gap indicates system sleep/suspend

    settings        := ""
    mode            := "standup"

    remaining       := 0
    sessionTotalMs  := 0
    lastTick        := 0

    isOnBreak       := false
    isWaitingBreak  := false
    isWaitingWork   := false
    isPaused        := false
    isIdle          := false

    isExerciseBreak := false
    breakWaitStart  := 0
    reminderStage   := 0
    completedCycles := 0

    __New(settings) {
        this.settings := settings
        this.mode := (settings.mode != "") ? settings.mode : O2omEngine.MODE_STANDUP
        this.ResetToWork()
    }

    ; --- Duration Computations (Milliseconds) ---
    workMs {
        get {
            if (this.mode == O2omEngine.MODE_POMODORO)
                return 25 * 60 * 1000
            if (this.mode == O2omEngine.MODE_EYEGUARD)
                return 20 * 60 * 1000
            return Max(1, this.settings.workIntervalMin) * 60 * 1000
        }
    }

    shortBreakMs {
        get {
            if (this.mode == O2omEngine.MODE_POMODORO)
                return 5 * 60 * 1000
            if (this.mode == O2omEngine.MODE_EYEGUARD)
                return 20 * 1000  ; 20 seconds for 20-20-20
            return Max(1, this.settings.shortBreakMin) * 60 * 1000
        }
    }

    longBreakMs {
        get {
            if (this.mode == O2omEngine.MODE_POMODORO)
                return 15 * 60 * 1000
            if (this.mode == O2omEngine.MODE_EYEGUARD)
                return 60 * 1000  ; 1 minute long break for eye guard
            return Max(1, this.settings.longBreakMin) * 60 * 1000
        }
    }

    snoozeMs        => Max(1, this.settings.snoozeMin) * 60 * 1000
    escalationMs    => Max(1, this.settings.escalationMin) * 60 * 1000
    idleThresholdMs => Max(1, this.settings.idleThresholdMin) * 60 * 1000

    ; --- Progress & Cycle Properties ---
    totalCycles     => (this.mode == O2omEngine.MODE_POMODORO) ? 4 : Max(1, this.settings.cyclesBeforeLong)
    currentCycle    => Mod(this.completedCycles, this.totalCycles) + 1
    isLongBreakNext => (Mod(this.completedCycles + 1, this.totalCycles) == 0)
    progressPercent => (this.sessionTotalMs > 0) ? Max(0, Min(100, Integer(((this.sessionTotalMs - this.remaining) / this.sessionTotalMs) * 100))) : 0

    SetMode(newMode) {
        if (newMode != O2omEngine.MODE_STANDUP && newMode != O2omEngine.MODE_EYEGUARD 
            && newMode != O2omEngine.MODE_POMODORO && newMode != O2omEngine.MODE_CUSTOM)
            return

        this.mode := newMode
        this.settings.mode := newMode
        this.completedCycles := 0
        this.ResetToWork()
    }

    ResetToWork() {
        this.remaining       := this.workMs
        this.sessionTotalMs  := this.workMs
        this.reminderStage   := 0
        this.breakWaitStart  := 0
        this.isOnBreak       := false
        this.isWaitingBreak  := false
        this.isWaitingWork   := false
        this.isPaused        := false
        this.isIdle          := false
        this.isExerciseBreak := false
        this.lastTick        := A_TickCount
    }

    TogglePause() {
        this.isPaused := !this.isPaused
        this.lastTick := A_TickCount
    }

    StartWork() {
        this.isWaitingWork   := false
        this.isOnBreak       := false
        this.isWaitingBreak  := false
        this.isPaused        := false
        this.isIdle          := false
        this.isExerciseBreak := false
        this.reminderStage   := 0
        this.breakWaitStart  := 0
        this.remaining       := this.workMs
        this.sessionTotalMs  := this.workMs
        this.lastTick        := A_TickCount
    }

    StartBreak(exerciseMode := false) {
        this.isOnBreak       := true
        this.isWaitingBreak  := false
        this.isWaitingWork   := false
        this.isPaused        := false
        this.isIdle          := false
        this.isExerciseBreak := exerciseMode
        this.reminderStage   := 0
        this.breakWaitStart  := 0

        this.completedCycles++

        ; Determine whether short break or long break applies
        if (Mod(this.completedCycles, this.totalCycles) == 0) {
            this.remaining := this.longBreakMs
        } else {
            this.remaining := this.shortBreakMs
        }
        this.sessionTotalMs := this.remaining
        this.lastTick := A_TickCount
    }

    Snooze() {
        this.isOnBreak       := false
        this.isWaitingBreak  := false
        this.isWaitingWork   := false
        this.isPaused        := false
        this.isIdle          := false
        this.isExerciseBreak := false
        this.remaining       := this.snoozeMs
        this.sessionTotalMs  := this.snoozeMs
        this.reminderStage   := 0
        this.breakWaitStart  := 0
        this.lastTick        := A_TickCount
    }

    FormatRemaining() {
        totalSec := Max(0, Ceil(this.remaining / 1000))
        m := totalSec // 60
        s := Mod(totalSec, 60)
        return Format("{:02}:{:02}", m, s)
    }

    Tick() {
        now := A_TickCount
        delta := now - this.lastTick
        this.lastTick := now

        ; Guard 32-bit tick wraparound (occurs after ~49.7 days of system uptime)
        if (delta < 0)
            delta += 0x100000000

        ; 1. Sleep/Wake gap check (e.g. laptop closed or system suspended)
        if (delta > O2omEngine.SLEEP_GAP) {
            if (!this.isOnBreak) {
                idle := A_TimeIdlePhysical
                if (delta >= this.idleThresholdMs || idle >= this.idleThresholdMs) {
                    this.ResetToWork()
                    return { type: "normal" }
                }
            } else {
                if (delta >= this.remaining) {
                    this.isOnBreak      := false
                    this.isWaitingWork  := true
                    this.remaining      := this.workMs
                    this.sessionTotalMs := this.workMs
                    return { type: "break_ended" }
                } else {
                    this.remaining -= delta
                    return { type: "normal" }
                }
            }
        }

        ; 2. Manual Pause
        if (this.isPaused)
            return { type: "normal" }

        ; 3. Physical Idle Detection (Applies strictly to active work countdowns)
        idle := A_TimeIdlePhysical
        if (!this.isOnBreak && !this.isWaitingBreak && !this.isWaitingWork) {
            if (idle >= this.idleThresholdMs) {
                this.isIdle := true
                return { type: "normal" }
            } else {
                this.isIdle := false
            }
        }

        ; 4. Break Prompts & Escalation Handling
        if (this.isWaitingBreak) {
            ; Check if user returned after stepping away
            if (this.isIdle && idle < this.idleThresholdMs) {
                if (this.reminderStage >= 2) {
                    this.ResetToWork()
                    return { type: "auto_work_reset", stage: 2 }
                }
                this.isIdle := false
            }

            if (this.breakWaitStart > 0 && (now - this.breakWaitStart) >= this.escalationMs) {
                if (this.reminderStage == 0) {
                    this.reminderStage := 1
                    this.breakWaitStart := now
                    return { type: "escalation", stage: 1 }
                } else if (this.reminderStage == 1) {
                    this.reminderStage := 2
                    this.breakWaitStart := now
                    if (idle < this.idleThresholdMs) {
                        this.ResetToWork()
                        return { type: "auto_work_reset", stage: 2 }
                    } else {
                        this.isIdle := true
                    }
                    return { type: "escalation", stage: 2 }
                }
            }
            return { type: "normal" }
        }

        ; 5. Waiting for User to Start Work Session
        if (this.isWaitingWork)
            return { type: "normal" }

        ; 6. Active Session Countdown
        this.remaining -= delta
        if (this.remaining <= 0) {
            this.remaining := 0
            if (this.isOnBreak) {
                ; Break finished -> transition to waiting work
                this.isOnBreak      := false
                this.isWaitingWork  := true
                this.remaining      := this.workMs
                this.sessionTotalMs := this.workMs
                return { type: "break_ended" }
            } else {
                ; Work session finished -> transition to waiting break
                this.isWaitingBreak := true
                this.breakWaitStart := now
                this.reminderStage  := 0
                return { type: "waiting_break" }
            }
        }

        return { type: "normal" }
    }
}
