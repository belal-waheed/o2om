# O2om (قُوم) — Overview & Product Vision (v4.0)

**O2om** (derived from the Arabic imperative **قُوم**, meaning * Stand up!*) is an open-source, high-craft desktop health, posture, and ergonomics companion for Windows built with **Tauri v2** (Rust + React 19). It mitigates sedentary fatigue, musculoskeletal strain, and digital eye strain for software engineers, remote professionals, gamers, and desk workers.

---

## 1. Core Problem & Product Value

Prolonged seated desk work degrades circulation, weakens posterior posture muscles, and causes computer vision syndrome. Existing solutions suffer from three fundamental flaws:
1. **Aggressive Disruption**: Locking user screens abruptly in the middle of active workflows.
2. **Heavy Resource Bloat**: Consuming 200MB–400MB RAM through bloated Electron runtimes.
3. **Passive Reminders Without Guidance**: Telling users to take a break without structured physical routines.

**O2om (v4.0)** resolves these problems with:
- **Ultra-Lightweight Footprint**: Native Rust engine consuming ~30MB RAM and 0% idle CPU.
- **Modern Obsidian Dark Craftsmanship**: High-contrast tabular typography, clean SVG vector icons, zero AI clichés.
- **Multi-Mode Ergonomics**: Pomodoro (25m/5m/15m), Balanced Stand-Up (40m/5m), Eye Strain Guard (20-20-20), and Custom.
- **Interactive Guided Stretch Routines**: 5-step mobility routines with individual countdowns, audio chimes, and illustrations.
- **Floating Mini-Pill Widget**: Always-on-top, draggable micro-timer widget with double-click dashboard restoration.
- **Hardware Idle Detection**: Win32 GetLastInputInfo hardware polling suspends work countdowns when users step away, without pausing active stretch breaks.
- **Native Dual Localization**: Arabic (r) default with full RTL mirroring, alongside English (n).

---

## 2. Technology Stack & Runtime Specifications

| Layer | Technology |
| :--- | :--- |
| **Desktop Framework** | Tauri v2.x |
| **Backend Core** | Rust 2021 (tokio, rodio, windows-rs, rusqlite) |
| **Frontend Framework** | React 19 + TypeScript + Vite |
| **Styling & Icons** | Tailwind CSS v4 + Lucide React |
| **State Management** | Zustand v5 + Tauri Event Bridge |
| **Local Persistence** | SQLite (stored in local %APPDATA%) |
| **Target Platforms** | Windows 10 & 11 (64-bit) |