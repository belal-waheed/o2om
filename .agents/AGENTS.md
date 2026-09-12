# O2om Project Rules & Invariants

These rules apply to all development within the O2om repository (Tauri v2 + Rust + React 19):

## 1. Localization & RTL Architecture
- Arabic (r) is the default language.
- The React application root dynamically sets document.documentElement.dir = (lang === 'ar') ? 'rtl' : 'ltr' and lang = lang to guarantee native right-to-left layout and mirrored spacing.
- Tabular numeric displays (TabularTimer, countdown digits) MUST maintain ontVariantNumeric: 'tabular-nums' and ontFeatureSettings: '\ tnum\' to eliminate layout jitter during countdown ticks.

## 2. Multi-Window Topology & Win32 ToolWindow Invariants
- The application employs three distinct window instances defined in src-tauri/tauri.conf.json:
  1. main: The primary interactive dashboard, settings, and health analytics window. Hides to system tray on close.
  2. pill: A floating micro-pill widget (176x42 px, frameless, transparent). It MUST be styled via Win32 WS_EX_TOOLWINDOW to prevent appearing as an active task in Alt+Tab and taskbar switchers.
  3. reak_overlay: The guided stretch routine window (720x520 px, centered, always-on-top).
- Never spawn ad-hoc webview windows from the frontend; use explicit IPC commands (set_pill_mode, start_break, skip_break, inish_break) handled by WindowManager.

## 3. Tiling Window Manager (TWM) Compatibility (GlazeWM / Komorebi)
- Users running tiling window managers must not experience window snapping conflicts or resize fighting.
- When 	iling_wm_mode is enabled in settings:
  - All automatic edge-snapping and tucking logic for the floating mini-pill is bypassed.
  - Window positioning delegates cleanly to the user's manual dragging or the WM workspace rules.

## 4. State Engine & Hardware Idle Invariants
- The high-precision countdown state machine is managed in Rust (TimerEngine / 	okio::time::interval(100ms)) to guarantee millisecond drift compensation and zero CPU churn.
- Hardware physical idle monitoring is queried via Win32 GetLastInputInfo.
- Inactivity pausing strictly applies to **work sessions only**. Break sessions must countdown without pausing when the user steps away from the keyboard to perform exercises.

## 5. Persistence & SQLite Boundaries
- All user preferences, daily stands, focus time, and multi-day streaks are persisted locally via SQLite (usqlite) in %APPDATA%\com.o2om.desktop\o2om.db.
- Database operations must be encapsulated in DbRepository with transactional safety.

## 6. Audio & Media Asset Resolution
- Exercise routines reference visual assets located in public/assets/exercises_bg.png and public/assets/o2om.ico.
- Desktop audio chimes are synthesized dynamically via odio and standard system frequencies, eliminating external runtime DLL dependencies.
