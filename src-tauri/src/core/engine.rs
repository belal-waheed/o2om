use serde::{Deserialize, Serialize};
use std::time::Instant;
use crate::db::repository::PersistedSession;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum SessionMode {
    Pomodoro,
    Standup,
    Eyeguard,
    Custom,
}

impl Default for SessionMode {
    fn default() -> Self {
        SessionMode::Pomodoro
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum TimerStatus {
    Work,
    WaitingBreak,
    OnBreak,
    WaitingWork,
    Paused,
    Idle,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EngineSettings {
    pub mode: SessionMode,
    pub work_interval_min: u32,
    pub short_break_min: u32,
    pub long_break_min: u32,
    pub cycles_before_long: u32,
    pub escalation_min: u32,
    pub snooze_min: u32,
    pub idle_threshold_min: u32,
    pub eye_work_min: u32,
    pub eye_break_sec: u32,
    pub daily_stand_goal: u32,
    pub sound_enabled: bool,
    pub start_with_windows: bool,
    pub language: String,
    pub tiling_wm_mode: bool,
    pub pill_dock_snapping: bool,
    pub auto_pill_mode: bool,
}

impl Default for EngineSettings {
    fn default() -> Self {
        Self {
            mode: SessionMode::Pomodoro,
            work_interval_min: 25,
            short_break_min: 5,
            long_break_min: 15,
            cycles_before_long: 4,
            escalation_min: 2,
            snooze_min: 5,
            idle_threshold_min: 5,
            eye_work_min: 20,
            eye_break_sec: 20,
            daily_stand_goal: 8,
            sound_enabled: true,
            start_with_windows: true,
            language: "ar".to_string(),
            tiling_wm_mode: false,
            pill_dock_snapping: true,
            auto_pill_mode: true,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TimerStateSnapshot {
    pub status: TimerStatus,
    pub mode: SessionMode,
    pub remaining_ms: u64,
    pub session_total_ms: u64,
    pub progress_percent: u32,
    pub formatted_remaining: String,
    pub current_cycle: u32,
    pub total_cycles: u32,
    pub is_long_break_next: bool,
    pub is_guided_exercise: bool,
    pub reminder_stage: u32,
    pub is_paused: bool,
    pub is_idle: bool,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum TickEvent {
    None,
    WorkCompleted,
    BreakCompleted,
    EscalationWarning { stage: u32 },
    AutoWorkReset,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum HydrationEvent {
    None,
    WorkCompletedOffline,
}

pub struct TimerEngine {
    pub settings: EngineSettings,
    pub status: TimerStatus,
    pub remaining_ms: u64,
    pub session_total_ms: u64,
    pub last_tick: Instant,
    pub completed_cycles: u32,
    pub is_guided_exercise: bool,
    pub break_wait_start: Option<Instant>,
    pub reminder_stage: u32,
    pub is_paused: bool,
    pub is_idle: bool,
}

impl TimerEngine {
    pub fn new(settings: EngineSettings) -> Self {
        let mut engine = Self {
            settings,
            status: TimerStatus::Work,
            remaining_ms: 0,
            session_total_ms: 0,
            last_tick: Instant::now(),
            completed_cycles: 0,
            is_guided_exercise: false,
            break_wait_start: None,
            reminder_stage: 0,
            is_paused: false,
            is_idle: false,
        };
        engine.reset_to_work();
        engine
    }

    pub fn work_ms(&self) -> u64 {
        match self.settings.mode {
            SessionMode::Eyeguard => (self.settings.eye_work_min.max(1) as u64) * 60 * 1000,
            _ => (self.settings.work_interval_min.max(1) as u64) * 60 * 1000,
        }
    }

    pub fn short_break_ms(&self) -> u64 {
        match self.settings.mode {
            SessionMode::Eyeguard => (self.settings.eye_break_sec.max(5) as u64) * 1000,
            _ => (self.settings.short_break_min.max(1) as u64) * 60 * 1000,
        }
    }

    pub fn long_break_ms(&self) -> u64 {
        match self.settings.mode {
            SessionMode::Eyeguard => 60 * 1000,
            _ => (self.settings.long_break_min.max(1) as u64) * 60 * 1000,
        }
    }

    pub fn snooze_ms(&self) -> u64 {
        (self.settings.snooze_min.max(1) as u64) * 60 * 1000
    }

    pub fn escalation_ms(&self) -> u64 {
        (self.settings.escalation_min.max(1) as u64) * 60 * 1000
    }

    pub fn idle_threshold_ms(&self) -> u64 {
        (self.settings.idle_threshold_min.max(1) as u64) * 60 * 1000
    }

    pub fn total_cycles(&self) -> u32 {
        self.settings.cycles_before_long.max(1)
    }

    pub fn current_cycle(&self) -> u32 {
        (self.completed_cycles % self.total_cycles()) + 1
    }

    pub fn is_long_break_next(&self) -> bool {
        ((self.completed_cycles + 1) % self.total_cycles()) == 0
    }

    pub fn progress_percent(&self) -> u32 {
        if self.session_total_ms == 0 {
            0
        } else {
            let elapsed = self.session_total_ms.saturating_sub(self.remaining_ms);
            let pct = ((elapsed as f64 / self.session_total_ms as f64) * 100.0).round() as u32;
            pct.min(100)
        }
    }

    pub fn format_remaining(&self) -> String {
        let total_sec = (self.remaining_ms + 999) / 1000;
        let mins = total_sec / 60;
        let secs = total_sec % 60;
        format!("{:02}:{:02}", mins, secs)
    }

    pub fn get_snapshot(&self) -> TimerStateSnapshot {
        TimerStateSnapshot {
            status: self.status.clone(),
            mode: self.settings.mode.clone(),
            remaining_ms: self.remaining_ms,
            session_total_ms: self.session_total_ms,
            progress_percent: self.progress_percent(),
            formatted_remaining: self.format_remaining(),
            current_cycle: self.current_cycle(),
            total_cycles: self.total_cycles(),
            is_long_break_next: self.is_long_break_next(),
            is_guided_exercise: self.is_guided_exercise,
            reminder_stage: self.reminder_stage,
            is_paused: self.is_paused,
            is_idle: self.is_idle,
        }
    }

    pub fn to_persisted(&self) -> PersistedSession {
        let status_str = match self.status {
            TimerStatus::Work => "work",
            TimerStatus::WaitingBreak => "waiting_break",
            TimerStatus::OnBreak => "on_break",
            TimerStatus::WaitingWork => "waiting_work",
            TimerStatus::Paused => "paused",
            TimerStatus::Idle => "idle",
        };
        let now_epoch = chrono::Utc::now().timestamp();
        PersistedSession {
            status: status_str.to_string(),
            remaining_ms: self.remaining_ms,
            session_total_ms: self.session_total_ms,
            completed_cycles: self.completed_cycles,
            is_paused: self.is_paused,
            is_guided_exercise: self.is_guided_exercise,
            last_saved_epoch: now_epoch,
        }
    }

    pub fn hydrate_from_persisted(&mut self, session: PersistedSession) -> HydrationEvent {
        let now_epoch = chrono::Utc::now().timestamp();
        let elapsed_sec = (now_epoch - session.last_saved_epoch).max(0);
        let elapsed_ms = (elapsed_sec as u64) * 1000;

        self.completed_cycles = session.completed_cycles;
        self.is_guided_exercise = session.is_guided_exercise;
        self.session_total_ms = if session.session_total_ms > 0 {
            session.session_total_ms
        } else {
            self.work_ms()
        };
        self.last_tick = Instant::now();

        // 1. If stale (>= 30 minutes away / overnight shutdown):
        // cleanly reset to fresh Work session without playing sounds!
        if elapsed_sec >= 30 * 60 {
            self.reset_to_work();
            return HydrationEvent::None;
        }

        // 2. If paused:
        if session.is_paused || session.status == "paused" {
            self.is_paused = true;
            self.status = TimerStatus::Paused;
            self.remaining_ms = session.remaining_ms;
            return HydrationEvent::None;
        }

        match session.status.as_str() {
            "work" => {
                if elapsed_ms < session.remaining_ms {
                    self.status = TimerStatus::Work;
                    self.remaining_ms = session.remaining_ms - elapsed_ms;
                    HydrationEvent::None
                } else {
                    self.status = TimerStatus::WaitingBreak;
                    self.remaining_ms = 0;
                    self.break_wait_start = Some(Instant::now());
                    self.reminder_stage = 0;
                    HydrationEvent::WorkCompletedOffline
                }
            }
            "on_break" => {
                if elapsed_ms < session.remaining_ms {
                    self.status = TimerStatus::OnBreak;
                    self.remaining_ms = session.remaining_ms - elapsed_ms;
                } else {
                    self.status = TimerStatus::WaitingWork;
                    self.remaining_ms = self.work_ms();
                    self.session_total_ms = self.remaining_ms;
                }
                HydrationEvent::None
            }
            "waiting_break" => {
                self.status = TimerStatus::WaitingBreak;
                self.remaining_ms = 0;
                self.break_wait_start = Some(Instant::now());
                self.reminder_stage = 0;
                HydrationEvent::None
            }
            "waiting_work" => {
                self.status = TimerStatus::WaitingWork;
                self.remaining_ms = self.work_ms();
                self.session_total_ms = self.remaining_ms;
                HydrationEvent::None
            }
            _ => {
                self.reset_to_work();
                HydrationEvent::None
            }
        }
    }

    pub fn set_mode(&mut self, new_mode: SessionMode) {
        self.settings.mode = new_mode.clone();
        match new_mode {
            SessionMode::Pomodoro => {
                self.settings.work_interval_min = 25;
                self.settings.short_break_min = 5;
                self.settings.long_break_min = 15;
                self.settings.cycles_before_long = 4;
            }
            SessionMode::Standup => {
                self.settings.work_interval_min = 40;
                self.settings.short_break_min = 5;
                self.settings.long_break_min = 15;
                self.settings.cycles_before_long = 4;
            }
            SessionMode::Eyeguard => {
                self.settings.eye_work_min = 20;
                self.settings.eye_break_sec = 20;
                self.settings.cycles_before_long = 999;
            }
            SessionMode::Custom => {}
        }
        self.completed_cycles = 0;
        self.reset_to_work();
    }

    pub fn reset_to_work(&mut self) {
        let work = self.work_ms();
        self.remaining_ms = work;
        self.session_total_ms = work;
        self.status = TimerStatus::Work;
        self.is_paused = false;
        self.is_idle = false;
        self.is_guided_exercise = false;
        self.break_wait_start = None;
        self.reminder_stage = 0;
        self.last_tick = Instant::now();
    }

    pub fn start_work(&mut self) {
        self.reset_to_work();
    }

    pub fn start_break(&mut self, guided_exercise: bool) {
        self.is_guided_exercise = guided_exercise;
        self.completed_cycles += 1;

        let break_dur = if self.completed_cycles % self.total_cycles() == 0 {
            self.long_break_ms()
        } else {
            self.short_break_ms()
        };

        self.remaining_ms = break_dur;
        self.session_total_ms = break_dur;
        self.status = TimerStatus::OnBreak;
        self.is_paused = false;
        self.is_idle = false;
        self.break_wait_start = None;
        self.reminder_stage = 0;
        self.last_tick = Instant::now();
    }

    pub fn snooze(&mut self) {
        let snooze = self.snooze_ms();
        self.remaining_ms = snooze;
        self.session_total_ms = snooze;
        self.status = TimerStatus::Work;
        self.is_paused = false;
        self.is_idle = false;
        self.is_guided_exercise = false;
        self.break_wait_start = None;
        self.reminder_stage = 0;
        self.last_tick = Instant::now();
    }

    pub fn skip_break(&mut self) {
        self.reset_to_work();
    }

    pub fn toggle_pause(&mut self) -> bool {
        self.is_paused = !self.is_paused;
        if self.is_paused {
            self.status = TimerStatus::Paused;
        } else {
            self.status = TimerStatus::Work;
        }
        self.last_tick = Instant::now();
        self.is_paused
    }

    pub fn tick(&mut self, physical_idle_ms: u64) -> TickEvent {
        let now = Instant::now();
        let delta_ms = now.duration_since(self.last_tick).as_millis() as u64;
        self.last_tick = now;

        // 1. Sleep/wake gap detection (> 5000ms delta)
        if delta_ms > 5000 {
            if self.status == TimerStatus::Work && delta_ms >= self.idle_threshold_ms() {
                self.reset_to_work();
                return TickEvent::None;
            } else if self.status == TimerStatus::WaitingBreak && delta_ms >= self.idle_threshold_ms() {
                self.reset_to_work();
                return TickEvent::None;
            } else if self.status == TimerStatus::OnBreak {
                if delta_ms >= self.remaining_ms {
                    self.status = TimerStatus::WaitingWork;
                    self.remaining_ms = self.work_ms();
                    self.session_total_ms = self.remaining_ms;
                    return TickEvent::None;
                } else {
                    self.remaining_ms = self.remaining_ms.saturating_sub(delta_ms);
                    return TickEvent::None;
                }
            }
        }

        // 2. Manual Pause
        if self.is_paused {
            return TickEvent::None;
        }

        // 3. Physical Inactivity Detection during active work countdown
        if self.status == TimerStatus::Work {
            if physical_idle_ms >= self.idle_threshold_ms() {
                self.is_idle = true;
                return TickEvent::None;
            } else {
                self.is_idle = false;
            }
        }

        // 4. Waiting Break Escalation
        if self.status == TimerStatus::WaitingBreak {
            if physical_idle_ms >= self.idle_threshold_ms() {
                self.is_idle = true;
                return TickEvent::None;
            } else {
                self.is_idle = false;
            }

            if let Some(start) = self.break_wait_start {
                let wait_duration = now.duration_since(start).as_millis() as u64;
                if wait_duration >= self.escalation_ms() {
                    if self.reminder_stage == 0 {
                        self.reminder_stage = 1;
                        self.break_wait_start = Some(now);
                        return TickEvent::EscalationWarning { stage: 1 };
                    } else if self.reminder_stage == 1 {
                        self.reminder_stage = 2;
                        self.break_wait_start = Some(now);
                        self.reset_to_work();
                        return TickEvent::AutoWorkReset;
                    }
                }
            }
            return TickEvent::None;
        }

        // 5. Waiting Work State (awaiting user click to start work)
        if self.status == TimerStatus::WaitingWork {
            return TickEvent::None;
        }

        // 6. Countdown subtraction
        self.remaining_ms = self.remaining_ms.saturating_sub(delta_ms);

        if self.remaining_ms == 0 {
            if self.status == TimerStatus::OnBreak {
                self.status = TimerStatus::WaitingWork;
                self.remaining_ms = self.work_ms();
                self.session_total_ms = self.remaining_ms;
                return TickEvent::BreakCompleted;
            } else {
                self.status = TimerStatus::WaitingBreak;
                self.break_wait_start = Some(now);
                self.reminder_stage = 0;
                return TickEvent::WorkCompleted;
            }
        }

        TickEvent::None
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_engine_initial_state() {
        let settings = EngineSettings::default();
        let engine = TimerEngine::new(settings);

        assert_eq!(engine.status, TimerStatus::Work);
        assert_eq!(engine.remaining_ms, 25 * 60 * 1000);
        assert_eq!(engine.current_cycle(), 1);
        assert_eq!(engine.total_cycles(), 4);
        assert!(!engine.is_paused);
        assert!(!engine.is_idle);
    }

    #[test]
    fn test_toggle_pause() {
        let settings = EngineSettings::default();
        let mut engine = TimerEngine::new(settings);

        let paused = engine.toggle_pause();
        assert!(paused);
        assert_eq!(engine.status, TimerStatus::Paused);

        let resumed = engine.toggle_pause();
        assert!(!resumed);
        assert_eq!(engine.status, TimerStatus::Work);
    }

    #[test]
    fn test_break_cycles() {
        let settings = EngineSettings::default();
        let mut engine = TimerEngine::new(settings);

        // Cycle 1 -> Short break (5 min)
        engine.start_break(false);
        assert_eq!(engine.status, TimerStatus::OnBreak);
        assert_eq!(engine.remaining_ms, 5 * 60 * 1000);
        assert_eq!(engine.completed_cycles, 1);

        // Cycles 2, 3, 4
        engine.start_break(false); // 2
        engine.start_break(false); // 3
        engine.start_break(false); // 4 -> Long break (15 min)
        assert_eq!(engine.remaining_ms, 15 * 60 * 1000);
    }

    #[test]
    fn test_snooze_and_skip() {
        let settings = EngineSettings::default();
        let mut engine = TimerEngine::new(settings);

        engine.snooze();
        assert_eq!(engine.remaining_ms, 5 * 60 * 1000);
        assert_eq!(engine.status, TimerStatus::Work);

        engine.start_break(true);
        assert_eq!(engine.status, TimerStatus::OnBreak);
        assert!(engine.is_guided_exercise);

        engine.skip_break();
        assert_eq!(engine.status, TimerStatus::Work);
        assert_eq!(engine.remaining_ms, 25 * 60 * 1000);
    }

    #[test]
    fn test_mode_switching() {
        let settings = EngineSettings::default();
        let mut engine = TimerEngine::new(settings);

        engine.set_mode(SessionMode::Eyeguard);
        assert_eq!(engine.remaining_ms, 20 * 60 * 1000);
        engine.start_break(false);
        assert_eq!(engine.remaining_ms, 20 * 1000);

        engine.set_mode(SessionMode::Standup);
        assert_eq!(engine.remaining_ms, 40 * 60 * 1000);
    }

    #[test]
    fn test_persisted_roundtrip() {
        let settings = EngineSettings::default();
        let mut engine = TimerEngine::new(settings);
        engine.remaining_ms = 18 * 60 * 1000;
        engine.completed_cycles = 2;

        let persisted = engine.to_persisted();
        assert_eq!(persisted.status, "work");
        assert_eq!(persisted.remaining_ms, 18 * 60 * 1000);
        assert_eq!(persisted.completed_cycles, 2);

        // Hydrate back
        let mut engine2 = TimerEngine::new(EngineSettings::default());
        engine2.hydrate_from_persisted(persisted);
        assert_eq!(engine2.status, TimerStatus::Work);
        assert_eq!(engine2.completed_cycles, 2);
        // Elapsed time is minimal since last_saved_epoch was right now
        assert!(engine2.remaining_ms <= 18 * 60 * 1000 && engine2.remaining_ms >= 17 * 60 * 1000);
    }

    #[test]
    fn test_hydrate_stale_session() {
        let settings = EngineSettings::default();
        let mut engine = TimerEngine::new(settings);

        // Stale session (saved 40 minutes ago)
        let stale_session = PersistedSession {
            status: "work".to_string(),
            remaining_ms: 10 * 60 * 1000,
            session_total_ms: 25 * 60 * 1000,
            completed_cycles: 1,
            is_paused: false,
            is_guided_exercise: false,
            last_saved_epoch: chrono::Utc::now().timestamp() - 40 * 60,
        };

        engine.hydrate_from_persisted(stale_session);
        // Stale session must reset cleanly to fresh work session without alarm
        assert_eq!(engine.status, TimerStatus::Work);
        assert_eq!(engine.remaining_ms, 25 * 60 * 1000);
    }

    #[test]
    fn test_hydrate_work_completed_offline() {
        let settings = EngineSettings::default();
        let mut engine = TimerEngine::new(settings);

        // Session was in work mode with 5 minutes left, saved 10 minutes ago (< 30 minutes)
        let session = PersistedSession {
            status: "work".to_string(),
            remaining_ms: 5 * 60 * 1000,
            session_total_ms: 25 * 60 * 1000,
            completed_cycles: 0,
            is_paused: false,
            is_guided_exercise: false,
            last_saved_epoch: chrono::Utc::now().timestamp() - 10 * 60,
        };

        let event = engine.hydrate_from_persisted(session);
        assert_eq!(event, HydrationEvent::WorkCompletedOffline);
        assert_eq!(engine.status, TimerStatus::WaitingBreak);
        assert_eq!(engine.remaining_ms, 0);
    }
}
