# O2om (قُوم) — Overview & Product Vision

**O2om** (derived from the Arabic imperative **قُوم**, meaning *"Stand up!"*) is an open-source, high-craft desktop health, posture, and ergonomics utility for Windows built in **AutoHotkey v2.0+**. It mitigates sedentary fatigue, musculoskeletal strain, and digital eye strain for software engineers, remote professionals, gamers, and desk workers.

---

## 1. Core Problem & Product Value

Prolonged seated desk work degrades circulation, weakens posterior posture muscles (forward head tilt, rounded shoulders), and causes computer vision syndrome. Existing solutions suffer from three fundamental flaws:
1. **Aggressive Disruption**: Locking user screens abruptly in the middle of active workflows.
2. **Heavy Resource Bloat**: Consuming 200MB–400MB RAM through bloated Electron/Chromium runtimes.
3. **Passive Reminders Without Actionable Guidance**: Informing users to "take a break" without structured physical routines or interactive progression.

**O2om (v3.0)** resolves these problems with:
- **Ultra-Lightweight Footprint**: Native Windows execution consuming < 15MB RAM and near-zero idle CPU.
- **Modern Obsidian Dark Craftsmanship**: DWM immersive dark titlebar integration, high-contrast tabular typography, and zero generic AI clichés or emojis.
- **Multi-Mode Ergonomics**: Ergonomic Stand-Up & Posture mode (40m/5m), 20-20-20 Eye Strain Guard (20m/20s), Deep Work Pomodoro (25m/5m/15m), and Custom Intervals.
- **Interactive Guided Stretch Routines**: Step-by-step stretch coach with per-exercise countdown timers, audio transitions, and clean 16:9 posture illustrations.
- **Daily Health Analytics & Streaks**: Tracks completed stands against daily goals, total focus time, and continuous multi-day streaks.
- **Compact Floating Mini-Pill**: Draggable micro-timer widget that docks to any screen edge with double-click dashboard restoration.
- **Physical Inactivity Intelligence**: `A_TimeIdlePhysical` hardware polling suspends work countdowns when users step away, but never interrupts active stretching breaks.
- **Native Dual Localization**: Arabic (`ar`) default with `+E0x400000` (`WS_EX_LAYOUTRTL`) mirroring, alongside English (`en`).

---

## 2. Key Capabilities & Subsystems

| Subsystem | Description |
| :--- | :--- |
| **Multi-Mode Timer Engine** | Non-blocking state machine supporting Stand-Up, Eye Guard, Pomodoro, and Custom modes with sleep/wake gap recovery and 32-bit tick wrap safety. |
| **Guided Break Overlay** | Fullscreen immersive stretch overlay guiding users through 5 targeted mobility exercises with individual timers, instructions, and chimes. |
| **Health Analytics Tracker** | Records daily stands, compares against customizable daily goals, logs focus hours, and manages multi-day streaks across midnight rollovers. |
| **Floating Mini-Pill Widget** | Always-on-top, draggable 160x46px micro widget displaying mode indicator, countdown, and pause toggle. |
| **Escalation Notification Engine** | Escalates unacknowledged break reminders across two warning stages before cleanly resetting work sessions for active users. |
| **Desktop Audio Chimes** | Subtle, pleasant native audio feedback for session completions, exercise transitions, and escalation warnings. |
| **Action Center Toasts** | Persistent Windows Action Center toasts linked via AppUserModelId (`O2om.StandUpReminder`) without blue informational icons. |

---

## 3. Technology Stack & Runtime Specifications

| Attribute | Specification |
| :--- | :--- |
| **Version** | v3.0.0 |
| **Language / Framework** | AutoHotkey v2.0+ (Strict v2 syntax) |
| **Target OS** | Windows 10 / Windows 11 (64-bit) |
| **Architecture Pattern** | Layered Clean Architecture (`Core` / `Services` / `Ui` / `Locale`) |
| **Styling Archetype** | Modern Obsidian Dark Palette (`#0D0E15`, `#161822`, `#1F2333`) |
| **Configuration Storage** | INI Storage (`o2om_config.ini` & `o2om_stats.ini`) |
| **Binary Distribution** | Standalone Compiled Executable (`O2om.exe` via Ahk2Exe CLI) |
| **Default Language** | Arabic (`ar`) with native `+E0x400000` RTL layout mirroring |

---

## 4. Repository & File Structure

```text
O2om/
├── O2om.ahk                  # Application Entry Point & Singleton Orchestrator (O2omApp)
├── O2om.exe                  # Standalone Compiled Portable Executable
├── o2om_config.ini           # User Preferences & Interval Configurations
├── o2om_stats.ini            # Daily Health Metrics & Streak History
├── assets/
│   ├── o2om.ico              # High-Resolution Application & System Tray Icon
│   └── exercises_bg.png      # 16:9 Clean 5-Panel Posture & Stretch Illustration
├── src/
│   ├── Core/
│   │   ├── TimerEngine.ahk   # Pure Domain State Machine & Mode Engine
│   │   ├── HealthTracker.ahk # Daily Stands, Focus Hours, & Streak Counter
│   │   └── ExerciseRoutines.ahk # Structured Exercise Progression & Scaling
│   ├── Services/
│   │   ├── SettingsRepo.ahk  # INI Repository with Safe Bounds Validation
│   │   ├── SoundService.ahk  # Audio Chimes & Audio Notifications
│   │   ├── NotificationService.ahk # Action Center Toasts with AUMID
│   │   ├── IdleMonitor.ahk   # Hardware Keyboard/Mouse Idle State Adapter
│   │   ├── StartupService.ahk# Windows Autostart Registry Adapter
│   │   └── Resources.ahk     # Asset Extraction & Resolution
│   ├── Ui/
│   │   ├── Theme.ahk         # Obsidian Palette Tokens & DWM Dark Titlebar
│   │   ├── Tray.ahk          # System Tray Menu & Dynamic Tooltip
│   │   └── Views/
│   │       ├── DashboardView.ahk    # Primary Dashboard View
│   │       ├── StatsView.ahk        # Health Metrics & Streak View
│   │       ├── SettingsView.ahk     # Configuration Panel
│   │       ├── BreakOverlayView.ahk # Guided Fullscreen Stretch Overlay
│   │       └── MiniPillView.ahk     # Floating Draggable Micro-Widget
│   └── Locale/
│       └── Language.ahk      # Comprehensive Arabic & English Dictionary
├── docs/                     # Living System Documentation
└── tests/
    └── TimerEngineTest.ahk   # Automated Comprehensive Unit Test Suite
```
