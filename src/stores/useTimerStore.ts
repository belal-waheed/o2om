import { create } from "zustand";
import {
  tauriApi,
  type DockInfo,
  type EngineSettings,
  type HealthStatsSummary,
  type SessionMode,
  type TimerStateSnapshot,
} from "../lib/ipc";
import { setLanguage } from "../lib/i18n";

interface TimerStoreState {
  snapshot: TimerStateSnapshot | null;
  healthSummary: HealthStatsSummary | null;
  settings: EngineSettings | null;
  activeTab: "focus" | "stats" | "settings";
  isPillMode: boolean;
  dockInfo: DockInfo | null;
  isInitialized: boolean;

  setActiveTab: (tab: "focus" | "stats" | "settings") => void;
  setPillMode: (isPill: boolean) => Promise<void>;
  togglePillMode: () => Promise<void>;
  setPillTucked: (tucked: boolean) => Promise<void>;
  initStore: (windowLabel?: "main" | "pill" | "break_overlay") => Promise<void>;
  startWork: () => Promise<void>;
  startBreak: (guided: boolean) => Promise<void>;
  skipBreak: () => Promise<void>;
  togglePause: () => Promise<void>;
  resetTimer: () => Promise<void>;
  snoozeTimer: () => Promise<void>;
  setMode: (mode: SessionMode) => Promise<void>;
  saveSettings: (newSettings: EngineSettings) => Promise<void>;
  refreshStats: () => Promise<void>;
  resetStats: () => Promise<void>;
}

export const useTimerStore = create<TimerStoreState>((set, get) => ({
  snapshot: null,
  healthSummary: null,
  settings: null,
  activeTab: "focus",
  isPillMode: false,
  dockInfo: null,
  isInitialized: false,

  setActiveTab: (tab) => set({ activeTab: tab }),

  setPillMode: async (isPill: boolean) => {
    try {
      await tauriApi.setPillMode(isPill);
      set({ isPillMode: isPill, dockInfo: isPill ? get().dockInfo : null });
    } catch (e) {
      console.error("Failed to set pill mode:", e);
      set({ isPillMode: isPill });
    }
  },

  setPillTucked: async (tucked: boolean) => {
    try {
      const info = await tauriApi.setPillTucked(tucked);
      set({ dockInfo: info });
    } catch (e) {
      console.error("Failed to set pill tucked:", e);
    }
  },

  togglePillMode: async () => {
    const next = !get().isPillMode;
    await get().setPillMode(next);
  },

  initStore: async (windowLabel: "main" | "pill" | "break_overlay" = "main") => {
    if (get().isInitialized) return;

    try {
      if (windowLabel !== "main") {
        const initialState = await tauriApi.getState();
        set({
          snapshot: initialState,
          isInitialized: true,
        });

        await tauriApi.onTick((payload) => {
          set({
            snapshot: payload.snapshot,
            healthSummary: payload.health_summary,
          });
        });

        if (windowLabel === "pill") {
          await tauriApi.onPillDockChanged((dock) => {
            set({ dockInfo: dock });
          });
          await tauriApi.onPillModeChanged((isPill) => {
            set({ isPillMode: isPill, dockInfo: isPill ? get().dockInfo : null });
          });
        }
        return;
      }

      const [initialState, initialSettings, initialStats] = await Promise.all([
        tauriApi.getState(),
        tauriApi.getSettings(),
        tauriApi.getHealthStats(),
      ]);

      if (initialSettings?.language) {
        setLanguage(initialSettings.language);
      }

      set({
        snapshot: initialState,
        settings: initialSettings,
        healthSummary: initialStats,
        isInitialized: true,
      });

      // Subscribe to 1-second background tick event
      await tauriApi.onTick((payload) => {
        set({
          snapshot: payload.snapshot,
          healthSummary: payload.health_summary,
        });
      });

      // Listen for tray pill toggle event
      await tauriApi.onTogglePill(() => {
        get().togglePillMode();
      });

      // Listen for auto-restore pill mode events from backend
      await tauriApi.onPillModeChanged((isPill) => {
        set({ isPillMode: isPill, dockInfo: isPill ? get().dockInfo : null });
      });

      // Listen for dock and tuck state changes from backend
      await tauriApi.onPillDockChanged((dock) => {
        set({ dockInfo: dock });
      });
    } catch (err) {
      console.error("Failed to initialize timer store:", err);
    }
  },

  startWork: async () => {
    try {
      const snap = await tauriApi.startWork();
      set({ snapshot: snap });
    } catch (e) {
      console.error(e);
    }
  },

  startBreak: async (guided: boolean) => {
    try {
      const snap = await tauriApi.startBreak(guided);
      set({ snapshot: snap });
    } catch (e) {
      console.error(e);
    }
  },

  skipBreak: async () => {
    try {
      const snap = await tauriApi.skipBreak();
      set({ snapshot: snap });
    } catch (e) {
      console.error(e);
    }
  },

  togglePause: async () => {
    try {
      await tauriApi.togglePause();
      const snap = await tauriApi.getState();
      set({ snapshot: snap });
    } catch (e) {
      console.error(e);
    }
  },

  resetTimer: async () => {
    try {
      const snap = await tauriApi.resetTimer();
      set({ snapshot: snap });
    } catch (e) {
      console.error(e);
    }
  },

  snoozeTimer: async () => {
    try {
      const snap = await tauriApi.snoozeTimer();
      set({ snapshot: snap });
    } catch (e) {
      console.error(e);
    }
  },

  setMode: async (mode: SessionMode) => {
    try {
      const snap = await tauriApi.setMode(mode);
      const updatedSettings = await tauriApi.getSettings();
      set({ snapshot: snap, settings: updatedSettings });
    } catch (e) {
      console.error(e);
    }
  },

  saveSettings: async (newSettings: EngineSettings) => {
    try {
      const snap = await tauriApi.saveSettings(newSettings);
      if (newSettings.language) {
        setLanguage(newSettings.language);
      }
      set({ snapshot: snap, settings: newSettings });
    } catch (e) {
      console.error(e);
      throw e;
    }
  },

  refreshStats: async () => {
    try {
      const stats = await tauriApi.getHealthStats();
      set({ healthSummary: stats });
    } catch (e) {
      console.error(e);
    }
  },

  resetStats: async () => {
    try {
      await tauriApi.resetAllStats();
      await get().refreshStats();
    } catch (e) {
      console.error(e);
    }
  },
}));
