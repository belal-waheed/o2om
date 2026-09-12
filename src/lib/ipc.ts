import { invoke } from "@tauri-apps/api/core";
import { listen, type UnlistenFn } from "@tauri-apps/api/event";

export type SessionMode = "pomodoro" | "standup" | "eyeguard" | "custom";
export type TimerStatus = "work" | "waiting_break" | "on_break" | "waiting_work" | "paused" | "idle";

export interface EngineSettings {
  mode: SessionMode;
  work_interval_min: number;
  short_break_min: number;
  long_break_min: number;
  cycles_before_long: number;
  escalation_min: number;
  snooze_min: number;
  idle_threshold_min: number;
  eye_work_min: number;
  eye_break_sec: number;
  daily_stand_goal: number;
  sound_enabled: boolean;
  start_with_windows: boolean;
  language: string;
  tiling_wm_mode: boolean;
  pill_dock_snapping: boolean;
  auto_pill_mode: boolean;
}

export interface TimerStateSnapshot {
  status: TimerStatus;
  mode: SessionMode;
  remaining_ms: number;
  session_total_ms: number;
  progress_percent: number;
  formatted_remaining: string;
  current_cycle: number;
  total_cycles: number;
  is_long_break_next: boolean;
  is_guided_exercise: boolean;
  reminder_stage: number;
  is_paused: boolean;
  is_idle: boolean;
}

export interface HealthStatsSummary {
  today_stands: number;
  daily_stand_goal: number;
  today_focus_minutes: number;
  total_stands_all_time: number;
  total_focus_minutes_all_time: number;
  current_streak_days: number;
  best_streak_days: number;
}

export interface DailyHealthRecord {
  date: string;
  stands_count: number;
  stand_goal: number;
  focus_minutes: number;
  goal_met: boolean;
}

export interface ExerciseStep {
  id: string;
  name_ar: string;
  name_en: string;
  desc_ar: string;
  desc_en: string;
  duration_sec: number;
  tag: string;
}

export interface TimerTickPayload {
  snapshot: TimerStateSnapshot;
  health_summary: HealthStatsSummary;
}

export interface DockInfo {
  is_docked: boolean;
  edge: "none" | "left" | "right" | "top" | "bottom";
  is_tucked: boolean;
}

export const tauriApi = {
  getState: () => invoke<TimerStateSnapshot>("get_state"),
  startWork: () => invoke<TimerStateSnapshot>("start_work"),
  startBreak: (guided: boolean) => invoke<TimerStateSnapshot>("start_break", { guided }),
  skipBreak: () => invoke<TimerStateSnapshot>("skip_break"),
  togglePause: () => invoke<boolean>("toggle_pause"),
  resetTimer: () => invoke<TimerStateSnapshot>("reset_timer"),
  snoozeTimer: () => invoke<TimerStateSnapshot>("snooze_timer"),
  setMode: (mode: SessionMode) => invoke<TimerStateSnapshot>("set_mode", { mode }),
  getSettings: () => invoke<EngineSettings>("get_settings"),
  saveSettings: (settings: EngineSettings) => invoke<TimerStateSnapshot>("save_settings", { settings }),
  getHealthStats: () => invoke<HealthStatsSummary>("get_health_stats"),
  getWeeklyHistory: () => invoke<DailyHealthRecord[]>("get_weekly_history"),
  resetAllStats: () => invoke<void>("reset_all_stats"),
  getExerciseRoutine: (totalBreakMs?: number) => invoke<ExerciseStep[]>("get_exercise_routine", { totalBreakMs }),
  setPillMode: (isPill: boolean) => invoke<void>("set_pill_mode", { isPill }),
  snapPillToEdge: () => invoke<DockInfo>("snap_pill_to_edge"),
  setPillTucked: (tucked: boolean) => invoke<DockInfo>("set_pill_tucked", { tucked }),
  closeBreakOverlay: () => invoke<void>("close_break_overlay"),
  playStepTransition: () => invoke<void>("play_step_transition"),

  onTick: (cb: (payload: TimerTickPayload) => void): Promise<UnlistenFn> => {
    return listen<TimerTickPayload>("timer-tick", (event) => cb(event.payload));
  },
  onTogglePill: (cb: () => void): Promise<UnlistenFn> => {
    return listen<void>("toggle-pill-mode", () => cb());
  },
  onPillModeChanged: (cb: (isPill: boolean) => void): Promise<UnlistenFn> => {
    return listen<boolean>("pill-mode-changed", (event) => cb(event.payload));
  },
  onPillDockChanged: (cb: (dock: DockInfo) => void): Promise<UnlistenFn> => {
    return listen<DockInfo>("pill-dock-changed", (event) => cb(event.payload));
  },
};

