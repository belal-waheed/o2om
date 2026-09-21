import { describe, it, expect } from "vitest";
import ar from "../src/locales/ar.json";
import en from "../src/locales/en.json";

describe("O2om v4.0 Frontend & Localization Tests", () => {
  it("should have matching translation keys between Arabic and English", () => {
    const arKeys = Object.keys(ar).sort();
    const enKeys = Object.keys(en).sort();

    expect(arKeys).toEqual(enKeys);
  });

  it("should have non-empty values for all translation keys", () => {
    for (const [key, val] of Object.entries(ar)) {
      expect(val.trim().length, `Arabic key ${key} should not be empty`).toBeGreaterThan(0);
    }
    for (const [key, val] of Object.entries(en)) {
      expect(val.trim().length, `English key ${key} should not be empty`).toBeGreaterThan(0);
    }
  });

  it("should validate default Pomodoro interval math correctly", () => {
    const workIntervalMin = 25;
    const shortBreakMin = 5;
    const longBreakMin = 15;
    const cyclesBeforeLong = 4;

    expect(workIntervalMin * 60 * 1000).toBe(1500000);
    expect(shortBreakMin * 60 * 1000).toBe(300000);
    expect(longBreakMin * 60 * 1000).toBe(900000);

    const getBreakDuration = (completedCycles: number) => {
      return (completedCycles % cyclesBeforeLong === 0) ? longBreakMin : shortBreakMin;
    };

    expect(getBreakDuration(1)).toBe(5);
    expect(getBreakDuration(2)).toBe(5);
    expect(getBreakDuration(3)).toBe(5);
    expect(getBreakDuration(4)).toBe(15);
  });
});

describe("useTimerStore listener registration and cleanup (C3, H2)", () => {
  it("should prevent duplicate event listener registration and allow cleanup", async () => {
    const { useTimerStore } = await import("../src/stores/useTimerStore");
    const { tauriApi } = await import("../src/lib/ipc");

    let unlistenCalls = 0;
    const fakeUnlisten = () => {
      unlistenCalls++;
    };

    let tickListenersCount = 0;
    tauriApi.getState = async () => ({
      status: "work",
      mode: "pomodoro",
      remaining_ms: 1500000,
      session_total_ms: 1500000,
      progress_percent: 0,
      formatted_remaining: "25:00",
      current_cycle: 1,
      total_cycles: 4,
      is_long_break_next: false,
      is_guided_exercise: false,
      reminder_stage: 0,
      is_paused: false,
      is_idle: false,
    });
    tauriApi.getSettings = async () => ({
      mode: "pomodoro",
      work_interval_min: 25,
      short_break_min: 5,
      long_break_min: 15,
      cycles_before_long: 4,
      snooze_min: 5,
      idle_threshold_min: 5,
      eye_work_min: 20,
      eye_break_sec: 20,
      daily_stand_goal: 8,
      sound_enabled: true,
      start_with_windows: true,
      language: "ar",
      tiling_wm_mode: false,
      pill_dock_snapping: true,
      auto_pill_mode: true,
    });
    tauriApi.getHealthStats = async () => ({
      today_stands: 0,
      daily_stand_goal: 8,
      today_focus_minutes: 0,
      total_stands_all_time: 0,
      total_focus_minutes_all_time: 0,
      current_streak_days: 0,
      best_streak_days: 0,
    });
    tauriApi.onTick = async () => {
      tickListenersCount++;
      return fakeUnlisten;
    };
    tauriApi.onHealthSummaryUpdated = async () => fakeUnlisten;
    tauriApi.onTogglePill = async () => fakeUnlisten;
    tauriApi.onPillModeChanged = async () => fakeUnlisten;
    tauriApi.onPillDockChanged = async () => fakeUnlisten;

    // Reset store state
    useTimerStore.getState().cleanup();
    expect(useTimerStore.getState().isInitialized).toBe(false);
    expect(useTimerStore.getState().unlisteners.length).toBe(0);

    // Call initStore
    const initPromise = useTimerStore.getState().initStore("main");
    // isInitialized should be true synchronously before promise finishes
    expect(useTimerStore.getState().isInitialized).toBe(true);

    // Concurrent second call should return immediately
    await useTimerStore.getState().initStore("main");

    // Await first initialization to complete
    await initPromise;
    expect(tickListenersCount).toBe(1);
    expect(useTimerStore.getState().unlisteners.length).toBe(5);

    // Third call after initialization should also return immediately and not re-register
    await useTimerStore.getState().initStore("main");
    expect(tickListenersCount).toBe(1);

    // Call cleanup()
    useTimerStore.getState().cleanup();
    expect(unlistenCalls).toBe(5);
    expect(useTimerStore.getState().isInitialized).toBe(false);
    expect(useTimerStore.getState().unlisteners.length).toBe(0);
  });
});
