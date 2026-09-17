# O2om (قُوم) — System Architecture (v4.0)

This document describes the architectural layout, core subsystems, multi-window topology, state engine contracts, design tokens, and engineering invariants of **O2om v4.0** built with **Tauri v2**.

---

## 1. System Component Diagram

`mermaid
graph TD
    subgraph Presentation_Layer [Presentation Layer React 19]
        MainWindow[MainWindow]
        MiniPill[MiniPillView]
        BreakOverlay[GuidedBreakView]
        StatsView[StatsView]
        SettingsView[SettingsView]
        ZustandStore[useTimerStore]
    end

    subgraph IPC_Bridge [Tauri v2 IPC Bridge]
        Commands[Tauri Commands]
        Events[Tauri Events]
    end

    subgraph Rust_Core [Domain Core and Services]
        Engine[TimerEngine]
        Routines[ExerciseRoutines]
        DbRepo[DbRepository SQLite]
        WinMgr[WindowManager]
        TrayMgr[TrayManager]
        IdleMonitor[IdleMonitor Win32]
        Audio[AudioService Rodio]
        Notifications[NotificationService]
    end

    subgraph OS_Layer [Windows OS Subsystems]
        Win32_API[Win32 User32 API]
        SQLite[SQLite Local AppData]
        Audio_Out[Windows Audio Endpoint]
    end

    Presentation_Layer --> IPC_Bridge
    IPC_Bridge --> Rust_Core
    Rust_Core --> OS_Layer
`

---

## 2. Multi-Window Topology & Window Management

The application orchestrates three independent windows managed centrally by WindowManager:

1. **main**:
   - Primary interactive window (420x490px, centered).
   - Hosts navigation tabs: Focus Dashboard, Historical Statistics, and Settings.
   - Close interception: Hides window to Windows System Tray rather than quitting the process.
2. **pill**:
   - Draggable, always-on-top micro-pill (176x42px, frameless, transparent).
   - Injected with Win32 WS_EX_TOOLWINDOW to isolate it from Windows Alt+Tab and taskbar.
   - Supports screen edge docking and auto-tuck unless `tiling_wm_mode` is enabled.
3. **`break_overlay`**:
   - Guided stretch and posture routine window (720x520px, centered, always-on-top).
   - Step-by-step stretch coach with individual exercise countdowns and sound chimes.

---

## 3. GlazeWM & Komorebi Compatibility

For users running tiling window managers (TWM):
- TWM Mode flag (`tiling_wm_mode`) disables edge snapping and tucking.
- Windows are given appropriate fixed dimensions and window attributes to prevent tiling layout conflicts.

---

## 4. SQLite Persistence & Health Analytics

- Database stored at %APPDATA%\com.o2om.desktop\o2om.db.
- Daily tracking records:
  - stands_count: Total work/break intervals completed.
  - ocus_minutes: Accumulated deep work time.
  - current_streak_days: Consecutive days meeting the daily goal.