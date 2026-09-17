# ADR 0002: Transition to Tauri v2 Multi-Window Architecture

- **Status**: Accepted (Supersedes ADR 0001)
- **Date**: 2026-09-01
- **Author**: O2om Core Architecture Team

---

## 1. Context & Problem Statement

While the original AutoHotkey v2 prototype achieved an ultra-low memory footprint, modern ergonomics and wellness applications require:
1. High-fidelity UI animations, fluid progress indicators, and accessible dark mode tokens that are constrained by Win32/GDI.
2. Cross-thread relational persistence (SQLite) for comprehensive historical analytics and multi-day habit tracking.
3. Multi-window desktop topologies (central dashboard, floating micro-pill widget, and guided stretch routines) with proper tiling window manager (GlazeWM/Komorebi) integration.

---

## 2. Decision

We chose **Tauri v2** with a **Rust backend** and **React 19 + Tailwind CSS v4** frontend:
- **Rust Core**: Drives high-precision interval timers (100ms drift compensation), direct Win32 hardware idle monitoring (GetLastInputInfo), native audio synthesis (rodio), and SQLite persistence (rusqlite).
- **Multi-Window Topology**: Central WindowManager controlling main, pill (with WS_EX_TOOLWINDOW taskbar isolation), and break_overlay.
- **Lightweight Footprint**: Compiled standalone binary (~15MB), ~30MB runtime memory, and 0% idle CPU.