# Changelog

All notable changes to O2om are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [4.2.0] - 2026-09-21

### Summary
O2om v4.2.0 is a major stability, performance, and craftsmanship release. It addresses 21 architectural and UX issues identified during comprehensive auditing across backend concurrency, state persistence, hardware idle detection, audio latency, and frontend lifecycle management.

### Critical Fixes
- **Break Session Pause State Preservation (C1)**: Resolved an issue where pausing during an active break or guided exercise transitioned the engine to a generic paused work state and prematurely aborted the routine upon resume. Introduced explicit `pre_pause_status` tracking in `TimerEngine` to guarantee seamless resume into the correct break cycle.
- **Asynchronous SQLite Connection Architecture (C2)**: Migrated local storage from blocking `rusqlite::Connection` behind a standard `Mutex` to asynchronous non-blocking queries powered by `tokio-rusqlite`. Decoupled persistence operations from the high-precision 100ms timer loop and IPC commands, eliminating thread starvation and lock contention.
- **Synchronous Initialization Guard (C3)**: Added an immediate synchronous `isInitialized` flag in `useTimerStore.initStore()` preceding IPC registration. Prevents React 19 Strict Mode concurrent double-mount cycles from creating duplicate event listeners and memory leaks.
- **Frontend Performance**: Fixed Zustand store over-fetching across 11 components by implementing `useShallow`, eliminating idle CPU churn.
- **Hardware Audio Resiliency**: Fixed an audio stream panic in `rodio` caused by default audio device disconnections (e.g., unplugging headphones).
- **Streak Logic Rollover**: Fixed a logic bug in SQLite `internal_check_midnight_rollover` where missed goals were incorrectly preserving streaks upon PC reboot.
- **SQLite Data Migration**: Fixed legacy data migration to correctly copy Write-Ahead Log (`-wal`) and Shared-Memory (`-shm`) files, preventing data loss on updates.

### High-Severity Fixes
- **Midnight Date Rollover Data Loss Prevention (H1)**: Eliminated a race condition in `record_stand_if_needed` where querying the current date separately from `check_and_reset_daily_stats` could cause stands completed immediately after midnight to be lost or misattributed. The verified date string is now retrieved once and passed atomically through streak and stand calculations.
- **Frontend Event Listener Lifecycle Management (H2)**: Implemented structured unlistener tracking via an internal `unlisteners` registry in `useTimerStore` alongside an explicit `cleanup()` lifecycle hook for clean teardown during component unmounts and hot reloading.
- **Dynamic Cross-Platform AppData Resolution (H3)**: Replaced hardcoded Windows `%APPDATA%` string concatenation with Tauri's native `app.path().app_data_dir()`, ensuring robust directory initialization and cross-platform path resolution.

### Medium-Severity Enhancements
- **Extended Inactivity Auto-Reset (M1)**: Added an intelligent auto-reset mechanism during active work intervals. When physical hardware idle time reaches or exceeds double the configured idle threshold ($\ge 2\times$), the abandoned session is automatically reset back to the start of the current work interval.
- **Position-Based Dock Edge Detection (M2)**: Replaced asynchronous window move event listener tracking with direct coordinate evaluation against active monitor work areas, eliminating stale position race conditions and dock flickering for the floating mini-pill widget.
- **Non-Blocking Numeric Settings UX (M3)**: Refactored numeric inputs in `SettingsView` to support temporary empty-string states while typing, preventing premature zero-clamping and input jitter when users backspace or edit durations.
- **User-Visible IPC Error Notifications (M4)**: Integrated `react-hot-toast` notifications into `MainWindow` and `useTimerStore`, providing non-intrusive visual feedback whenever backend IPC commands encounter errors.
- **Persistent Audio Worker Thread (M5)**: Replaced on-demand audio device acquisition with a dedicated, persistent audio worker thread and bounded crossbeam/mpsc channel. Eliminates audio device re-initialization latency and allocation overhead on chime playback.

### Low-Severity Polish & Cleanups
- **Dead Code Elimination (L1-L3)**:
  - Removed legacy 2-stage reminder escalation state tracking from `TimerEngine`.
  - Removed obsolete `session_logs` table schema, indices, and dead SQL query methods from `DbRepository`.
  - Pruned unused `reminder_escalation` fields from settings structs and TypeScript IPC interfaces.
- **Tailwind CSS Mini-Pill Optimization (L5)**: Replaced JavaScript `onMouseEnter` / `onMouseLeave` state management in `MiniPillView` with pure Tailwind CSS `group-hover:` styling, avoiding unnecessary React component re-renders during mouse hover.
- **Safe Multi-Window URL Parameter Validation (L6)**: Added strict validation for `?window=` URL query parameters in `App.tsx`, safely falling back to `MainWindow` when invalid parameters are supplied.
- **Native RTL Layout Mirroring for Break Overlay (L7)**: Swapped physical `right-2` positioning with logical CSS `end-2` for close and skip controls in `GuidedBreakView`, ensuring perfect layout alignment in Arabic (RTL) mode.
- **Statistical Metric Text Selection (L8)**: Added `select-text` CSS utility classes to analytics numbers and streak displays in `StatsView`, allowing users to highlight and copy metrics while maintaining `select-none` on interactive buttons.
- **Window Startup Consolidation (L9-L10)**: Removed duplicate `show_main` invocations during application boot and unified conditional branches for mini-pill window initialization in `WindowManager`.

---

## [4.1.1] - 2026-09-21
- Encapsulated Windows autostart service behind a dedicated abstraction layer.
- Added warning observability for autostart query failures.
- Cleaned unused dependencies and optimized build flags.

## [4.1.0] - 2026-09-21
- Self-healing autostart registry engine with verification.
- Switched NSIS installer mode to `currentUser` for unprivileged installations.
- Production installer packaging and automated asset management.

## [4.0.3] - 2026-09-17
- Quiet post-session state engine avoiding unnecessary audio chimes.
- Route-aware store hydration preventing redundant IPC queries.

## [4.0.0] - 2026-09-14
- Complete desktop architecture overhaul to Tauri v2 + Rust + React 19.
- Frameless floating mini-pill widget with Win32 `WS_EX_TOOLWINDOW` integration.
- Local SQLite database persistence for focus time, daily stands, and multi-day streaks.
