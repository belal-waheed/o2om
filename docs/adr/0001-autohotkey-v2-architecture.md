# ADR 0001: AutoHotkey v2 Native Architecture & Non-Blocking State Engine

- **Status**: Superseded by ADR 0002
- **Date**: 2026-08-15
- **Author**: O2om Core Architecture Team

---

## 1. Context & Problem Statement

Modern desktop wellness and break reminder utilities often require high memory footprints (150MB–400MB RAM when packaged with Electron, Chromium, or Webview wrappers) and present heavy background CPU usage. Furthermore, standard desktop toolkits struggle with low-level Windows physical hardware idle detection, native Windows Right-To-Left (RTL) mirroring for Arabic, and zero-flicker native control repainting.

The goal was to create an ultra-lightweight, native, single-binary desktop health reminder for Windows with zero external runtime dependencies.

---

## 2. Considered Options

1. **Option 1: AutoHotkey v2 (Strict v2.0+ Runtime)**
   - Native C++ engine underneath, direct Win32 API access, compiled standalone `.exe` under 1.5MB, memory usage < 15MB.
2. **Option 2: Web Framework (Electron / Tauri / Node.js)**
   - High development speed and modern CSS flexbox layouts, but extreme memory overhead (Electron ~250MB, Tauri ~60MB) and clumsy physical idle hardware hooks on Windows.
3. **Option 3: C# / .NET / WPF**
   - Solid Windows integration and UI capabilities, but requires .NET Desktop Runtime and heavier binary distributions.

---

## 3. Decision & Rationale

We chose **Option 1 (AutoHotkey v2)** for the following architectural reasons:

1. **Ultra-Low Resource Footprint**: AutoHotkey v2 compiled binaries consume < 15MB RAM and near-zero idle CPU cycles.
2. **Direct Windows API & System Integration**: Native access to `A_TimeIdlePhysical` (hardware keyboard/mouse state), `A_TickCount`, Windows Action Center AppUserModelID, registry autorun keys, and tray icons without foreign function interface (FFI) overhead.
3. **Native Arabic Right-to-Left (RTL) Support**: Windows GDI natively mirrors title bars, control placements, and text layout via the `+E0x400000` (`WS_EX_LAYOUTRTL`) extended style window flag.
4. **Flicker-Free Rendering**: Native support for `+0x02000000` (`WS_CLIPCHILDREN`) prevents GDI text redraw flickering during 1-second timer cycles.

---

## 4. Consequences & Trade-offs

### Positive
- Standalone portable executable (`O2om.exe`) with no installer or runtime dependencies required.
- Instantaneous startup and negligible background battery/memory footprint.
- Robust state recovery across system sleep/wake cycles.

### Negative / Trade-offs
- UI layout relies on absolute coordinate positioning rather than automated CSS flexbox/grid containers.
- Windows-exclusive (not cross-platform to macOS or Linux).
