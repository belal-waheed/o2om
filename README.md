# O2om (قُوم) — Ergonomic Desktop Focus & Stand-Up Companion

[![Release](https://img.shields.io/github/v/release/belal-waheed/o2om?style=flat-square&color=blue)](https://github.com/belal-waheed/o2om/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-gray.svg?style=flat-square)](LICENSE)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D6?style=flat-square)](https://github.com/belal-waheed/o2om)
[![Rust 2021](https://img.shields.io/badge/Backend-Rust%202021-DEA584?style=flat-square)](https://www.rust-lang.org/)
[![Tauri v2](https://img.shields.io/badge/Framework-Tauri%20v2-24C8DB?style=flat-square)](https://v2.tauri.app/)
[![React 19](https://img.shields.io/badge/Frontend-React%2019-61DAFB?style=flat-square)](https://react.dev/)
[![Tailwind CSS v4](https://img.shields.io/badge/Styling-Tailwind%20CSS%20v4-38B2AC?style=flat-square)](https://tailwindcss.com/)
[![Memory Footprint](https://img.shields.io/badge/Memory-~30MB%20RAM-success?style=flat-square)](https://github.com/belal-waheed/o2om)

**O2om** (derived from the Arabic imperative **قُوم**, meaning *"Stand up!"*) is an open-source desktop focus and ergonomic stand-up timer built with **Tauri v2**, **Rust**, and **React 19** for software engineers and desk professionals to eliminate sedentary fatigue, maintain posture, and sustain deep work. Unlike resource-heavy Electron timers or disruptive screen-lockers, O2om delivers sub-millisecond countdown precision, zero-polling physical inactivity detection via Win32 hardware hooks, and an edge-dockable floating micro-pill widget in an ultra-lightweight ~30MB memory footprint.

---

## Downloads & Installation

| Package | Format | Direct Download / Path | Compatibility |
| :--- | :--- | :--- | :--- |
| **Recommended Setup** | NSIS (`.exe`) | [`dist-setup/o2om-setup.exe`](file:///d:/dev/projects/o2om/dist-setup/o2om-setup.exe) | Windows 10 & 11 (Per-User, No UAC prompt) |
| **Versioned NSIS** | NSIS (`.exe`) | [`dist-setup/O2om_4.0.3_x64-setup.exe`](file:///d:/dev/projects/o2om/dist-setup/O2om_4.0.3_x64-setup.exe) | Release v4.0.3 standalone setup package |
| **Windows Installer** | MSI (`.msi`) | [`dist-setup/O2om_4.0.3_x64_en-US.msi`](file:///d:/dev/projects/o2om/dist-setup/O2om_4.0.3_x64_en-US.msi) | Active Directory GPO & Microsoft Intune |

---

## Technical Specifications

| Specification | Implementation Detail |
| :--- | :--- |
| **Core Architecture** | Tauri v2 multi-window desktop topology with asynchronous Rust engine |
| **Backend Runtime** | Rust 2021 with Tokio 100ms interval loop, rodio audio, and windows-rs |
| **Frontend Framework** | React 19, TypeScript 5.7, Vite 6, Tailwind CSS v4, Zustand 5 |
| **Process Model** | Single-instance enforcement (`tauri-plugin-single-instance` via named pipes) |
| **Window Topologies** | `main` (420x490), `pill` (176x42 WS_EX_TOOLWINDOW), `break_overlay` (720x520) |
| **Idle Detection** | Physical hardware idle query via Win32 `GetLastInputInfo` (zero event polling) |
| **Audio Pipeline** | Synthesized dynamic frequencies via rodio without external runtime DLLs |
| **Persistence Layer** | Local SQLite (`rusqlite` bundled) with WAL journal mode and in-memory mutex |
| **Data Location** | `%APPDATA%\com.o2om.desktop\o2om.db` (isolated from binaries for safe updates) |
| **Memory & CPU** | ~30MB RAM footprint, 0% CPU consumption during idle periods |
| **Tiling WM Support** | Dedicated compatibility mode for GlazeWM and Komorebi |
| **Localization** | Native Arabic RTL (Cairo font) and English LTR (Inter font) via i18next |
| **License** | MIT Open Source License |

---

## System Architecture

```mermaid
flowchart TD
    subgraph Rust_Backend["Rust Core Engine (Tauri v2)"]
        tokio["Tokio 100ms Engine Loop"]
        engine["TimerEngine State Machine"]
        idle["Win32 GetLastInputInfo Monitor"]
        db[("SQLite DbRepository (WAL Mode)")]
        audio["Rodio Synthesized Audio"]
        winmgr["WindowManager (Win32 ToolWindow)"]
    end

    subgraph Windows_Shell["Windows Subsystems"]
        tray["Windows System Tray"]
        registry["HKCU Run Autostart"]
        nsis["NSIS Pre-Install Hook"]
    end

    subgraph React_Frontend["React 19 Multi-Window Frontend"]
        store["Zustand useTimerStore"]
        main_win["MainWindow (Dashboard & Settings)"]
        pill_win["MiniPillView (Edge Docked 176x42)"]
        overlay_win["BreakOverlay (Guided 5-Step Stretch)"]
    end

    tokio --> engine
    idle --> engine
    engine --> db
    engine --> audio
    engine -- "timer-tick / health-summary-updated" --> store
    store --> main_win
    store --> pill_win
    store --> overlay_win
    winmgr --> tray
    nsis -- "Auto-Kill on Update" --> engine
```

---

## Core Capabilities

### 1. High-Precision Interval Engine
- **Pomodoro Mode**: 25m focus, 5m short break, 15m long break after 4 completed cycles.
- **Balanced Stand-Up Mode**: 40m ergonomic work interval followed by a 5m stand-up prompt.
- **20-20-20 Eye Guard Mode**: 20m screen time followed by a 20-second distant focal break.
- **Quiet WaitingBreak State**: Completed focus sessions pause silently at `00:00` without recurring escalation dings or forced resets.

### 2. Multi-Window Desktop Topology
- **Dashboard (`main`)**: Comprehensive daily stand tracker, historical 7-day bar analytics, and full configuration.
- **Floating Mini-Pill (`pill`)**: Frameless 176x42px widget injected with Win32 `WS_EX_TOOLWINDOW` to eliminate taskbar clutter. Features automated screen edge docking and auto-tuck.
- **Guided Stretch Overlay (`break_overlay`)**: 720x520px centered, always-on-top window providing a guided 5-step desktop mobility and posture correction routine.

### 3. Tiling Window Manager (TWM) Compatibility
Designed for users of **GlazeWM**, **Komorebi**, and custom tiling managers:
- Activating `tiling_wm_mode` bypasses all automated edge-snapping and cursor-tucking calculations.
- Window management delegates cleanly to manual placement or tiling workspace rules.

### 4. Hardware Idle Monitoring
- Monitors physical keyboard and mouse activity using Win32 `GetLastInputInfo`.
- Inactivity pausing strictly applies to **work sessions only**. Break sessions continue running when users step away from the keyboard to exercise.

### 5. Local SQLite Persistence
- Tracks daily completed stands, daily goals, total focus time, and multi-day habit streaks.
- Encapsulated in `DbRepository` using Write-Ahead Logging (WAL) and memory-serialized transactions to guarantee zero database locking collisions.

---

## Repository Structure

```text
o2om/
├── dist-setup/                     # Production installer distributables
│   ├── o2om-setup.exe              # Recommended NSIS setup installer (v4.0.3)
│   ├── O2om_4.0.3_x64-setup.exe    # Versioned NSIS installer
│   └── O2om_4.0.3_x64_en-US.msi    # Enterprise Windows Installer (MSI)
│
├── src/                            # React 19 Frontend (Vite + Tailwind CSS v4)
│   ├── components/                 # UI components
│   │   ├── dashboard/              # ModeSelector, ActionCenter, MiniPillView
│   │   ├── settings/               # SettingsView & Danger Zone reset
│   │   ├── stats/                  # WeeklyChart, HealthSummaryCard
│   │   └── stretch/                # Guided stretch routine steps
│   ├── stores/                     # useTimerStore (Zustand state management)
│   ├── windows/                    # Window routes (MainWindow, PillWindow, BreakOverlay)
│   ├── locales/                    # Arabic (ar.json) & English (en.json)
│   ├── lib/                        # cn helper (utils.ts), IPC bindings (ipc.ts)
│   ├── App.tsx                     # Route-aware window dispatcher
│   ├── main.tsx                    # Application entry point
│   └── index.css                   # Tailwind CSS v4 design tokens
│
├── src-tauri/                      # Rust Desktop Core (Tauri v2)
│   ├── src/
│   │   ├── core/                   # TimerEngine & exercise routines
│   │   ├── db/                     # DbRepository (SQLite persistence & migrations)
│   │   ├── ipc/                    # Tauri IPC commands & asynchronous events
│   │   ├── services/               # Win32 idle monitor, audio synthesis, notifications
│   │   ├── ui/                     # WindowManager (Win32 ToolWindow styles) & tray
│   │   ├── lib.rs                  # Application bootstrap & single-instance hook
│   │   └── main.rs                 # Win32 entry point & AppUserModelID
│   ├── nsis-hooks.nsi              # Pre-install process auto-kill hook
│   ├── Cargo.toml                  # Rust dependencies
│   └── tauri.conf.json             # Tauri multi-window & bundle configuration
│
├── public/assets/                  # Exercise routine visual illustrations
├── tests/                          # Vitest store unit test suite
├── llms.txt                        # Architectural reference for AI agents
├── package.json                    # Node dependencies & build scripts
└── vite.config.ts                  # Vite bundler configuration
```

---

## Development & Build Guide

### Prerequisites
- **Node.js**: v18+ with `npm`
- **Rust Toolchain**: Stable channel (`rustc` and `cargo` 1.77+)
- **Windows Build Tools**: Visual Studio C++ Build Tools or Windows 10/11 SDK

### Setup & Local Development
```powershell
# Clone the repository
git clone https://github.com/belal-waheed/o2om.git
cd o2om

# Install frontend dependencies
npm install

# Run application in live development mode (Hot Module Reloading)
npm run tauri dev
```

### Running Automated Tests
```powershell
# Run frontend unit tests (Vitest)
npm test

# Run Rust backend engine & persistence tests (Cargo)
cd src-tauri
cargo test
```

### Building Release Installers
```powershell
# Compiles optimized release binary and generates NSIS + MSI bundles
npm run tauri build
```
Compiled installers are output to `dist-setup/` and `src-tauri/target/release/bundle/`.

---

## Frequently Asked Questions (FAQ)

#### Q: How does O2om detect physical user inactivity?
**A:** O2om queries the Win32 `GetLastInputInfo` system API from the background Rust engine every 100ms. By computing the difference between `GetTickCount()` and the last hardware event timestamp, it identifies user idle states without CPU overhead, event-hook interception, or keyboard surveillance.

#### Q: How does single-instance enforcement work?
**A:** Using `tauri-plugin-single-instance`, secondary attempts to launch O2om forward their command-line arguments to the active primary instance via local named pipes and terminate immediately. The primary instance intercepts the event, unminimizes the window, and brings the main dashboard to the foreground.

#### Q: Where are user settings, streaks, and focus statistics saved?
**A:** All data is persisted locally in an SQLite database located at `%APPDATA%\com.o2om.desktop\o2om.db`. Installing updates replaces only the application binaries; your local database, settings, and streak history remain untouched.

#### Q: How does O2om prevent conflicts with tiling window managers like GlazeWM or Komorebi?
**A:** O2om includes a dedicated `tiling_wm_mode` setting. When enabled, automatic border-snapping and cursor auto-tuck logic are bypassed, allowing the tiling window manager to manage workspace layout without interference.

---

## License

This project is licensed under the **MIT Open Source License**. See [LICENSE](LICENSE) for details.

- **Author**: Belal Waheed ([@belal-waheed](https://github.com/belal-waheed))
- **Repository**: [https://github.com/belal-waheed/o2om](https://github.com/belal-waheed/o2om)
