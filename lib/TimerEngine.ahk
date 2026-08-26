; ---------------------------------------------------------------------------
; O2om — Timer & Pomodoro Cycle Engine
; ---------------------------------------------------------------------------

class O2omEngine {
    static SLEEP_GAP := 5000 ; 5 seconds gap indicates system sleep/hibernate

    settings := ""

    ; State
    remaining       := 0
    sessionTotalMs  := 0
    lastTick        := 0
    reminderStage   := 0    ; 0 = Countdown, 1 = First Warning, 2 = Final Warning / Auto-Reset
    isIdle          := false
    isOnBreak       := false
    isWaitingBreak  := false
    isWaitingWork   := false
    isPaused        := false
    breakWaitStart  := 0
    completedCycles := 0

    __New(settingsObj) {
        this.settings := settingsObj
        this.ResetToWork()
    }

    ; Millisecond Calculations
    workMs          => this.settings.workIntervalMin * 60 * 1000
    shortBreakMs    => this.settings.shortBreakMin * 60 * 1000
    longBreakMs     => this.settings.longBreakMin * 60 * 1000
    snoozeMs        => this.settings.snoozeMin * 60 * 1000
    idleThresholdMs => this.settings.idleThresholdMin * 60 * 1000
    escalationMs    => this.settings.escalationMin * 60 * 1000

    ; Progress & Cycle Properties
    currentCycle    => Mod(this.completedCycles, Max(1, this.settings.cyclesBeforeLong)) + 1
    totalCycles     => Max(1, this.settings.cyclesBeforeLong)
    progressPercent => (this.sessionTotalMs > 0) ? Max(0, Min(100, Integer(((this.sessionTotalMs - this.remaining) / this.sessionTotalMs) * 100))) : 0

    ResetToWork() {
        this.remaining       := this.workMs
        this.sessionTotalMs  := this.workMs
        this.reminderStage   := 0
        this.isIdle          := false
        this.isOnBreak       := false
        this.isWaitingBreak  := false
        this.isWaitingWork   := false
        this.isPaused        := false
        this.breakWaitStart  := 0
        this.lastTick        := A_TickCount
    }

    TogglePause() {
        this.isPaused := !this.isPaused
        if (!this.isPaused)
            this.lastTick := A_TickCount
        return this.isPaused
    }

    StartWork() {
        this.isWaitingWork  := false
        this.isOnBreak      := false
        this.isWaitingBreak := false
        this.isPaused       := false
        this.isIdle         := false
        this.reminderStage  := 0
        this.breakWaitStart := 0
        this.remaining      := this.workMs
        this.sessionTotalMs := this.workMs
        this.lastTick       := A_TickCount
    }

    StartBreak() {
        this.isOnBreak      := true
        this.isWaitingBreak := false
        this.isWaitingWork  := false
        this.isPaused       := false
        this.isIdle         := false
        this.reminderStage  := 0
        this.breakWaitStart := 0
        this.completedCycles += 1

        ; Determine if long break or short break
        if (Mod(this.completedCycles, Max(1, this.settings.cyclesBeforeLong)) == 0) {
            this.remaining := this.longBreakMs
        } else {
            this.remaining := this.shortBreakMs
        }
        this.sessionTotalMs := this.remaining
        this.lastTick := A_TickCount
    }

    Snooze() {
        this.remaining      := this.snoozeMs
        this.sessionTotalMs := this.snoozeMs
        this.reminderStage  := 0
        this.isIdle         := false
        this.isOnBreak      := false
        this.isWaitingBreak := false
        this.isWaitingWork  := false
        this.isPaused       := false
        this.breakWaitStart := 0
        this.lastTick       := A_TickCount
    }

    Tick() {
        now   := A_TickCount
        delta := now - this.lastTick
        this.lastTick := now

        ; Handle 32-bit tick wraparound
        if (delta < 0)
            delta += 0x100000000

        idle := A_TimeIdlePhysical

        ; 1. Sleep/Wake gap check (e.g. laptop closed or system suspended)
        if (delta > O2omEngine.SLEEP_GAP) {
            if (!this.isOnBreak) {
                ; If suspended for >= idle threshold or user was away, reset to fresh work session
                if (delta >= this.idleThresholdMs || idle >= this.idleThresholdMs) {
                    this.ResetToWork()
                    return { type: "normal" }
                }
            } else {
                ; If break elapsed while sleeping, transition to waiting work
                if (delta >= this.remaining) {
                    this.isOnBreak     := false
                    this.isWaitingWork := true
                    this.remaining     := this.workMs
                    this.sessionTotalMs:= this.workMs
                    return { type: "break_ended" }
                } else {
                    this.remaining -= delta
                    return { type: "normal" }
                }
            }
        }

        ; 2. Idle State Handling (Enforced strictly during active work sessions)
        isActiveWorkSession := (!this.isOnBreak && !this.isWaitingBreak && !this.isWaitingWork && !this.isPaused)

        if (isActiveWorkSession) {
            if (this.isIdle) {
                if (idle < this.idleThresholdMs) {
                    this.ResetToWork()
                }
                return { type: "idle" }
            }

            if (idle >= this.idleThresholdMs) {
                this.isIdle := true
                return { type: "idle" }
            }
        } else {
            this.isIdle := false
        }

        ; 3. Normal Countdown
        if (!this.isPaused && !this.isWaitingWork && !this.isWaitingBreak && this.remaining > 0)
            this.remaining -= delta

        ; 4. Escalation Warning & Auto-Reset Check
        if (this.isWaitingBreak) {
            ; Check if user returned during unacknowledged break
            if (this.isIdle && idle < this.idleThresholdMs) {
                if (this.reminderStage >= 2) {
                    this.ResetToWork()
                    return { type: "auto_work_reset", stage: 2 }
                }
                this.isIdle := false
            }

            if (this.breakWaitStart > 0 && (now - this.breakWaitStart) >= this.escalationMs) {
                this.reminderStage++
                this.breakWaitStart := now

                ; If both warnings (stage 1 and stage 2) are ignored:
                if (this.reminderStage >= 2) {
                    if (idle < this.idleThresholdMs) {
                        ; User is actively using device -> auto-start new work session
                        this.ResetToWork()
                        return { type: "auto_work_reset", stage: 2 }
                    } else {
                        ; User walked away from desk -> transition to idle
                        this.isIdle := true
                        return { type: "idle" }
                    }
                }

                return { type: "escalation", stage: this.reminderStage }
            }
        }

        ; 5. Expiry Transitions
        if (this.remaining <= 0 && !this.isWaitingWork) {
            if (this.isOnBreak) {
                ; Break finished, transition to waiting work state
                this.isOnBreak     := false
                this.isWaitingWork := true
                this.remaining     := this.workMs
                this.sessionTotalMs:= this.workMs
                return { type: "break_ended" }
            } else if (!this.isWaitingBreak) {
                this.isWaitingBreak := true
                this.reminderStage  := 0
                this.breakWaitStart := now
                return { type: "waiting_break" }
            }
        }

        return { type: "normal" }
    }
}
