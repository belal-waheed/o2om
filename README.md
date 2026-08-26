# O2om (قُوم) — Stand-Up Break Timer & Ergonomic Posture Coach for Windows

**O2om** (derived from the Arabic imperative **قُوم**, meaning *"Stand up!"*) is an open-source, high-craft desktop health and posture utility for Windows built with AutoHotkey v2. It helps software engineers, remote professionals, gamers, and long-session desk workers eliminate sedentary fatigue, correct posture, reduce digital eye strain, and build consistent daily movement habits.

---

## Download O2om

[**Download Latest Standalone Executable (O2om.exe)**](https://github.com/BelalWaheed/o2om/releases/latest/download/O2om.exe)

*Zero installation required! Download `O2om.exe`, double-click to launch, and it will sit quietly in your System Tray consuming < 15MB of RAM.*

---

## Project Specifications

| Attribute | Specification |
| :--- | :--- |
| **Version** | v3.0.0 |
| **Category** | Desktop Ergonomics & Movement Coach |
| **Language & Framework** | AutoHotkey v2.0+ (Strict v2 syntax) |
| **Platform Support** | Windows 10 / Windows 11 (64-bit) |
| **Localization** | Native Arabic (`ar`, RTL mirrored) & English (`en`, LTR) |
| **Aesthetic Theme** | Modern Obsidian Dark Palette with DWM Immersive Dark Titlebar |
| **Display Support** | Responsive 16:9 stretch graphics (768p to 4K) |
| **Memory Footprint** | < 15MB RAM |
| **License** | Open Source |

---

## What's New in v3.0 (Complete Redesign)

1. **Multi-Mode Ergonomic Engine**:
   - **Stand-Up & Posture Mode (Default)**: 40m focus / 5m active stretches.
   - **20-20-20 Eye Strain Guard**: 20m focus / 20s 20-foot distance eye relaxation.
   - **Deep Work / Pomodoro Mode**: 25m focus / 5m short break / 15m long break.
   - **Custom Precision Mode**: Tailor intervals to your exact routine.
2. **Interactive Guided Break Overlay**:
   - Replaces static overlays with a step-by-step stretch coach (Chest Opener, Neck Retraction, Hip Flexor Lunge, Spine Twist, 20-20-20 Eye Rest).
   - Dedicated per-exercise countdown timers, exercise instructions in Arabic/English, and audio chimes.
3. **Daily Health Analytics & Streaks**:
   - Track completed stands against customizable daily goals (e.g. 8 stands/day).
   - Track total daily focus minutes, multi-day consecutive streaks, and lifetime metrics in `o2om_stats.ini`.
4. **Draggable Mini-Pill Floating Widget**:
   - A minimalist, always-on-top 160x46px floating pill showing status dot, countdown, and quick pause button. Double-click anywhere to restore the full Dashboard.
5. **Modern Obsidian Dark Design**:
   - Native Windows 10/11 DWM dark titlebar integration (`DWMWA_USE_IMMERSIVE_DARK_MODE`).
   - High-contrast tabular numbers that never shift or jitter horizontally.
   - Zero redraw flickering via `WS_CLIPCHILDREN` (`+0x02000000`).

---

## Quick User Guide

### 1. Launching O2om
- Double-click `O2om.exe` (or `O2om.ahk` when running from source).
- Your session countdown begins immediately in the System Tray.

### 2. Session Controls
- **Pause / Resume**: Click **Pause** or hit `Space` when the window is active to freeze the timer.
- **Switch Modes**: Click **Stand-Up**, **Eye Guard**, or **Pomodoro** pills at the top to change modes instantly.
- **Dock to Mini-Pill**: Click **Mini-Pill** to collapse the dashboard into an unobtrusive desktop floating widget. Double-click the pill to restore.

### 3. Taking a Break
- When the countdown reaches `00:00`, O2om alerts you with an Action Center notification and audio chime.
- Choose **Start Guided Stretches** for the fullscreen workout coach, **Start Break Only** for quiet background mode, or **Snooze** for a 5-minute delay.
- When the break ends, your daily stand count increments and O2om prompts you with **"Start Work"** when you're ready.

---

## Developer Guide & Repository Structure

### Prerequisites
1. Windows 10 or 11 (64-bit).
2. [AutoHotkey v2.0+](https://www.autohotkey.com/) installed.

### Directory Structure
```text
O2om/
├── O2om.ahk                       # Main Entry Point & Orchestrator (O2omApp)
├── O2om.exe                       # Standalone Compiled Executable
├── o2om_config.ini                # Persistent Configuration INI File
├── o2om_stats.ini                 # Daily Health Metrics & Streak History
├── assets/
│   ├── o2om.ico                   # Application & System Tray Icon
│   └── exercises_bg.png           # 16:9 Clean 5-Panel Posture Illustration
├── src/
│   ├── Core/
│   │   ├── TimerEngine.ahk        # State Machine & Multi-Mode Engine
│   │   ├── HealthTracker.ahk      # Daily Stands, Focus Hours, & Streak Counter
│   │   └── ExerciseRoutines.ahk   # Structured Exercise Progression & Scaling
│   ├── Services/
│   │   ├── SettingsRepo.ahk       # INI Storage & Safe Bounds Validation
│   │   ├── SoundService.ahk       # Audio Chimes & Notifications
│   │   ├── NotificationService.ahk# Action Center Toasts with AUMID
│   │   ├── IdleMonitor.ahk        # Physical Idle Absence Detection
│   │   ├── StartupService.ahk     # Windows Autostart Registry Adapter
│   │   └── Resources.ahk          # Asset Resolution & FileInstall Extraction
│   ├── Ui/
│   │   ├── Theme.ahk              # Obsidian Dark Tokens & DWM API
│   │   ├── Tray.ahk               # System Tray Menu & Dynamic Tooltip
│   │   └── Views/
│   │       ├── DashboardView.ahk  # Primary Dashboard View
│   │       ├── StatsView.ahk      # Health Metrics & Streak View
│   │       ├── SettingsView.ahk   # Configuration Panel
│   │       ├── BreakOverlayView.ahk # Guided Fullscreen Stretch Overlay
│   │       └── MiniPillView.ahk   # Floating Draggable Micro-Widget
│   └── Locale/
│       └── Language.ahk           # Bilingual Arabic & English Dictionary
├── docs/                          # Living System Documentation
└── tests/
    └── TimerEngineTest.ahk        # Comprehensive Unit Test Suite
```

### Running Tests
Execute the unit test suite with AutoHotkey v2:
```powershell
pwsh -NoProfile -Command "& 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe' tests/TimerEngineTest.ahk"
```

### Compiling Standalone Executable
Compile silently via Ahk2Exe CLI:
```powershell
pwsh -NoProfile -Command "& 'C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe' /in 'O2om.ahk' /out 'O2om.exe' /icon 'assets\o2om.ico' /base 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe' /silent"
```

---

## License & Author
- **Author**: Belal Waheed
- **License**: MIT Open Source License
