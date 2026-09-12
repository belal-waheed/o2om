# O2om (قُوم) — Desktop Focus & Ergonomic Health Companion for Windows

**O2om** (derived from the Arabic imperative **قُوم**, meaning * Stand up!*) is a modern, high-performance desktop focus and posture companion for Windows built with **Tauri v2** (Rust backend + React 19 / Vite / Tailwind CSS v4 frontend). It helps software engineers, remote professionals, and long-session desk workers maintain deep focus, eliminate sedentary fatigue, correct posture, and build consistent daily habits through structured intervals.

---

## Workspace Structure

The repository is a pure, consolidated Tauri v2 desktop project:

`	ext
o2om/
├── o2om.exe                       # Standalone Production Executable (Double-click to run)
├── dist-setup/
│   └── o2om-setup.exe             # Official Windows NSIS Setup Installer
│
├── src/                           # React 19 + TypeScript + Tailwind CSS v4 Frontend
│   ├── components/                # Dashboard, Settings, Stats, Stretch components
│   ├── stores/                    # Zustand timer state store & IPC bridges
│   ├── windows/                   # Window views (MainWindow, Pill, BreakOverlay)
│   ├── locales/                   # Arabic (ar) & English (en) translations
│   ├── lib/                       # Theme tokens, i18n, IPC APIs
│   ├── App.tsx
│   ├── main.tsx
│   └── index.css
│
├── src-tauri/                     # Tauri v2 Rust Backend
│   ├── src/
│   │   ├── core/                  # High-precision timer engine & stretch routines
│   │   ├── db/                    # SQLite database persistence (settings & health stats)
│   │   ├── ipc/                   # Tauri IPC commands & asynchronous events
│   │   ├── services/              # Win32 hardware idle monitor, notifications, audio
│   │   ├── ui/                    # Multi-window manager & system tray icon
│   │   ├── lib.rs
│   │   └── main.rs
│   ├── Cargo.toml
│   └── tauri.conf.json
│
├── public/
│   └── assets/                    # Shared visual assets (Icons, 16:9 stretch guide)
│
├── tests/
│   └── store.test.ts              # Frontend Vitest unit test suite
│
├── package.json                   # Node dependencies & build scripts
├── vite.config.ts                 # Vite bundler configuration
└── tsconfig.json                  # TypeScript configuration
`

---

## Executable & Setup Installer

| Distribution File | Description | Path |
| :--- | :--- | :--- |
| **Standalone Executable** | Double-click portable binary | o2om.exe |
| **Windows Setup Installer** | Full NSIS Windows setup installer | dist-setup/o2om-setup.exe |

---

## How to Run & Develop

### 1. Direct Standalone Run
Double-click o2om.exe in the root directory.

### 2. Live Development Mode
`powershell
npm run tauri dev
`

### 3. Automated Tests
`powershell
# Frontend Unit Tests (Vitest)
npm test

# Rust Backend Engine Tests (Cargo)
cd src-tauri
cargo test --lib
`

### 4. Build Production Release & Bundles
`powershell
# Build standalone binary and setup installer
npm run tauri build
`

---

## Core Features

1. **Deterministic Multi-Mode Engine**: Pomodoro (25m/5m), Balanced Stand-Up (40m/5m), Eye Strain Guard (20-20-20), and Custom intervals with sub-millisecond drift compensation.
2. **Multi-Window Topology**:
   - main: Interactive dashboard, historical analytics, and settings.
   - pill: Floating transparent micro-pill with Win32 WS_EX_TOOLWINDOW taskbar isolation and auto-docking.
   - reak_overlay: Immersive 16:9 guided posture stretch routine.
3. **Tiling Window Manager (GlazeWM / Komorebi) Compatibility**: Dedicated TWM compatibility mode disables edge-dock snapping so tiling window managers do not fight window placement.
4. **Physical Inactivity Detection**: Zero-polling-lag hardware idle monitoring via Win32 GetLastInputInfo (pauses work without interrupting breaks).
5. **Obsidian Dark & Native RTL**: High-contrast theme tokens with first-class Arabic RTL (Cairo) and English LTR (Inter) typography.
6. **SQLite Relational Persistence**: Complete local tracking of daily stands, focus minutes, and streaks in %APPDATA%\com.o2om.desktop\o2om.db.

---

## License
- **Author**: Belal Waheed
- **License**: MIT Open Source License
