# O2om (قُوم) — Workflows & Runtime State Sequences

This document outlines the state machine transitions, background tick lifecycle, break decision branches, quiet waiting states, and multi-window orchestration for **O2om** (Tauri v2 + Rust Core + React 19).

---

## 1. Complete Application State Machine

```mermaid
flowchart TD
    Launch([App Initialization]) --> Work[Active Work Session]

    %% Work state actions
    Work -->|Click Pause| Paused[Paused State]
    Paused -->|Click Resume| Work
    Work -->|Physical Inactivity >= IdleThreshold| Idle[Idle State - Countdown Suspended]
    Idle -->|Physical Input Detected| Work

    %% Work session completion
    Work -->|Countdown Reaches 00:00| WaitingBreak[WaitingBreak State - Paused Silently at 00:00]
    WaitingBreak -->|Play Bell Once & Show Toast Once| WaitingBreak

    %% User decisions from WaitingBreak
    WaitingBreak -->|Click Snooze| SnoozeWork[Snooze 5m Session]
    SnoozeWork -->|Countdown Reaches 00:00| WaitingBreak

    WaitingBreak -->|Click Start Break| BreakQuiet[OnBreak - Quiet Break Session]
    WaitingBreak -->|Click Start Exercises| BreakGuided[OnBreak - Guided Exercise Overlay]

    %% Break completion
    BreakQuiet -->|Break Reaches 00:00| WaitingWork[WaitingWork State]
    BreakGuided -->|Break Reaches 00:00 or Dismissed| WaitingWork

    WaitingWork -->|Play Rising Chime Once & Show Toast Once| WaitingWork
    WaitingWork -->|Click Start Work| Work
```

---

## 2. 100ms Master Background Tick Sequence Diagram

The background engine runs a high-precision `tokio::time::interval(100ms)` loop in Rust to track physical hardware idle and delta milliseconds with zero layout jitter:

```mermaid
sequenceDiagram
    autonumber
    participant Tokio as Tokio Interval (100ms)
    participant State as SharedState Mutex (AppState)
    participant IdleMon as IdleMonitor (Win32 GetLastInputInfo)
    participant Engine as TimerEngine (State Machine)
    participant Audio as AudioService (Rodio Bell / Chime)
    participant Windows as WindowManager (Multi-Window)
    participant Webview as Webview Windows (Main / Pill / Break)

    Tokio->>State: Acquire Lock
    State->>IdleMon: Get physical idle milliseconds
    IdleMon-->>State: idle_ms
    State->>Engine: tick(idle_ms)

    alt Physical Inactivity during Work (idle_ms >= threshold)
        Engine-->>State: is_idle = true, returns TickEvent::None
    else Countdown Reaches 00:00 (Work session finished)
        Engine-->>State: status = WaitingBreak, returns TickEvent::WorkCompleted
        State->>Audio: play_work_complete (528 Hz bell, played once)
        State->>Windows: restore_to_main()
        State->>Webview: emit("timer-work-completed", payload)
    else In WaitingBreak State (post-session pause)
        Note over Engine: Silently stays at 00:00 awaiting user action.<br/>Zero escalation chimes, zero auto-resets.
        Engine-->>State: returns TickEvent::None
    else Break Reaches 00:00 (Break finished)
        Engine-->>State: status = WaitingWork, returns TickEvent::BreakCompleted
        State->>Audio: play_break_complete (660 Hz / 880 Hz rising chime)
        State->>Windows: hide_break_overlay(), restore_to_main()
        State->>Webview: emit("timer-break-completed", payload)
    else Standard Countdown
        Engine-->>State: returns TickEvent::None
    end

    State->>Webview: emit("timer-tick", TimerTickPayload)
```

---

## 3. Detailed Workflow Descriptions

### A. Active Work Session & Physical Idle Detection
1. Upon startup, `TimerEngine` initializes in `TimerStatus::Work` with `remaining_ms = work_interval_min * 60 * 1000`.
2. Every 100ms tick, elapsed time is deducted using millisecond delta calculation from monotonic `Instant`.
3. Physical hardware activity is queried directly via Win32 `GetLastInputInfo`.
4. If `idle_ms >= idle_threshold_ms`, the countdown is suspended (`is_idle = true`) without resetting elapsed time.
5. Inactivity pausing strictly applies to work sessions. Break sessions continue counting down even if the user steps away from keyboard and mouse.

### B. Quiet Post-Work Behavior (WaitingBreak State)
1. When work timer reaches `00:00`:
   - `TickEvent::WorkCompleted` is returned exactly once.
   - A single completion bell (528 Hz + 1056 Hz warm tone) plays once.
   - A single desktop toast notification is shown.
   - Mini-Pill automatically restores to the full main dashboard.
   - `TimerEngine` transitions into `TimerStatus::WaitingBreak`.
2. The timer remains paused silently at `00:00`.
3. No recurring reminder chimes, no escalation toasts, and no auto-resets occur. The application waits patiently until the user explicitly selects an action:
   - **Start Exercises**: Opens the 16:9 guided stretch overlay window.
   - **Quiet Break**: Enters quiet break countdown on the main dashboard.
   - **Snooze 5 Minutes**: Temporarily adds 5 minutes of work time.
   - **Start Work**: Resets to a fresh work countdown immediately.

### C. Guided Break & Stretch Overlay Routine
1. When the user selects **Start Exercises**:
   - `WindowManager::show_break_overlay()` presents the 720x520 always-on-top window.
   - Dynamic exercise routines are generated based on break length (neck, shoulder, wrist, spine, and stand stretches).
   - Audio step chimes (880 Hz + 1320 Hz) sound between exercise intervals.
2. If closed early via the close button or keyboard, the window gracefully hides and returns focus to the main window.

### D. Post-Break Resumption (WaitingWork State)
1. When break countdown concludes (`00:00`):
   - `TickEvent::BreakCompleted` is returned once.
   - A single rising harmonic chime (660 Hz + 880 Hz) plays once.
   - If daily stand goal is achieved, celebration feedback is recorded in SQLite.
   - The break overlay closes, and main dashboard displays the prominent **Start Work** button.
2. The countdown does not start automatically; it waits for the user to click **Start Work**.

---

## 4. Settings Update & Language Switch Workflow

```mermaid
sequenceDiagram
    autonumber
    participant User as User (React UI)
    participant Store as useTimerStore (Zustand)
    participant IPC as Tauri IPC (save_settings)
    participant DB as SQLite (DbRepository)
    participant Engine as TimerEngine

    User->>Store: Edit durations, goals, or language -> click Save
    Store->>IPC: tauriApi.saveSettings(sanitizedSettings)
    IPC->>DB: save_settings(settings)
    IPC->>Engine: update engine settings in memory
    DB-->>IPC: success
    IPC-->>Store: updated TimerStateSnapshot
    Store->>User: Update UI language and switch active tab to focus
```
