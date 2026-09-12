use serde::{Deserialize, Serialize};
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::RwLock;
use std::time::Instant;
use tauri::{AppHandle, Emitter, Manager, PhysicalPosition, Position};

#[cfg(windows)]
use windows::Win32::Foundation::{HWND, POINT};
#[cfg(windows)]
use windows::Win32::UI::WindowsAndMessaging::{
    GetCursorPos, GetWindowLongPtrW, SetWindowLongPtrW, SetWindowPos, GWL_EXSTYLE,
    SWP_FRAMECHANGED, SWP_NOACTIVATE, SWP_NOMOVE, SWP_NOSIZE, SWP_NOZORDER, WS_EX_APPWINDOW,
    WS_EX_TOOLWINDOW,
};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DockInfo {
    pub is_docked: bool,
    pub edge: String,
    pub is_tucked: bool,
}

#[derive(Debug, Clone)]
struct StoredDockState {
    edge: String,
    normal_pos: PhysicalPosition<i32>,
    tucked_pos: PhysicalPosition<i32>,
    is_tucked: bool,
    last_hovered: Instant,
}

static CURRENT_DOCK: RwLock<Option<StoredDockState>> = RwLock::new(None);
static IS_PILL: AtomicBool = AtomicBool::new(false);
static IS_PROGRAMMATIC_MOVE: AtomicBool = AtomicBool::new(false);

pub struct WindowManager;

impl WindowManager {
    pub const MAIN_LABEL: &'static str = "main";
    pub const PILL_LABEL: &'static str = "pill";
    pub const BREAK_LABEL: &'static str = "break_overlay";

    pub fn is_pill_mode() -> bool {
        IS_PILL.load(Ordering::SeqCst)
    }

    pub fn is_programmatic_move() -> bool {
        IS_PROGRAMMATIC_MOVE.swap(false, Ordering::SeqCst)
    }

    pub fn on_user_move() {
        let mut lock = CURRENT_DOCK.write().unwrap_or_else(|e| e.into_inner());
        if let Some(ref mut state) = *lock {
            state.is_tucked = false;
            state.last_hovered = Instant::now();
        }
    }

    /// Configures native Windows extended styles (WS_EX_TOOLWINDOW) for the pill window
    /// Configures native Windows extended styles (WS_EX_TOOLWINDOW) for the pill window
    /// while clearing WS_EX_APPWINDOW and parenting to main window so Windows taskbar never shows it.
    pub fn apply_toolwindow_style(app: &AppHandle, label: &str) {
        #[cfg(windows)]
        {
            if let Some(win) = app.get_webview_window(label) {
                let _ = win.set_skip_taskbar(true);
                if let Ok(hwnd_ptr) = win.hwnd() {
                    let hwnd = HWND(hwnd_ptr.0 as _);
                    unsafe {
                        use windows::Win32::UI::WindowsAndMessaging::GWLP_HWNDPARENT;
                        if let Some(main_win) = app.get_webview_window(Self::MAIN_LABEL) {
                            if let Ok(main_hwnd) = main_win.hwnd() {
                                let _ = SetWindowLongPtrW(hwnd, GWLP_HWNDPARENT, main_hwnd.0 as _);
                            }
                        }
                        let cur_ex_style = GetWindowLongPtrW(hwnd, GWL_EXSTYLE);
                        let new_ex_style = (cur_ex_style & !(WS_EX_APPWINDOW.0 as isize))
                            | (WS_EX_TOOLWINDOW.0 as isize);
                        let _ = SetWindowLongPtrW(hwnd, GWL_EXSTYLE, new_ex_style);
                        let _ = SetWindowPos(
                            hwnd,
                            None,
                            0,
                            0,
                            0,
                            0,
                            SWP_NOMOVE
                                | SWP_NOSIZE
                                | SWP_NOZORDER
                                | SWP_FRAMECHANGED
                                | SWP_NOACTIVATE,
                        );
                    }
                }
            }
        }
    }

    /// Shows the main dashboard window and hides auxiliary windows
    pub fn show_main(app: &AppHandle) {
        IS_PILL.store(false, Ordering::SeqCst);

        // Hide pill if visible
        if let Some(pill_win) = app.get_webview_window(Self::PILL_LABEL) {
            let _ = pill_win.set_skip_taskbar(true);
            let _ = pill_win.hide();
        }

        // Show main window
        if let Some(main_win) = app.get_webview_window(Self::MAIN_LABEL) {
            let _ = main_win.set_skip_taskbar(false);
            let _ = main_win.unminimize();
            let _ = main_win.show();
            let _ = main_win.set_focus();
        }
    }

    /// Switches between Main window and dedicated Mini-Pill window
    pub fn set_pill_mode(app: &AppHandle, is_pill: bool) {
        IS_PILL.store(is_pill, Ordering::SeqCst);

        if is_pill {
            // Hide main window and remove from taskbar
            if let Some(main_win) = app.get_webview_window(Self::MAIN_LABEL) {
                let _ = main_win.set_skip_taskbar(true);
                let _ = main_win.hide();
            }

            // Show, style, and auto-dock pill window to left side of screen
            if let Some(pill_win) = app.get_webview_window(Self::PILL_LABEL) {
                let _ = pill_win.set_skip_taskbar(true);
                Self::apply_toolwindow_style(app, Self::PILL_LABEL);

                if let Ok(Some(monitor)) = pill_win.current_monitor().or_else(|_| app.primary_monitor()) {
                    let mon_pos = monitor.position();
                    let mon_size = monitor.size();
                    let scale = monitor.scale_factor();
                    let margin = (4.0 * scale) as i32;
                    let win_size = pill_win.outer_size().unwrap_or(tauri::PhysicalSize {
                        width: (176.0 * scale) as u32,
                        height: (42.0 * scale) as u32,
                    });
                    let visible_handle = (26.0 * scale) as i32;

                    let normal_x = mon_pos.x + margin;
                    let normal_y = mon_pos.y + (mon_size.height as i32 / 3);
                    let tucked_x = mon_pos.x - win_size.width as i32 + visible_handle;
                    let tucked_y = normal_y;

                    let normal_pos = PhysicalPosition { x: normal_x, y: normal_y };
                    let tucked_pos = PhysicalPosition { x: tucked_x, y: tucked_y };

                    IS_PROGRAMMATIC_MOVE.store(true, Ordering::SeqCst);
                    let _ = pill_win.set_position(Position::Physical(normal_pos));

                    *CURRENT_DOCK.write().unwrap_or_else(|e| e.into_inner()) = Some(StoredDockState {
                        edge: "left".to_string(),
                        normal_pos,
                        tucked_pos,
                        is_tucked: false,
                        last_hovered: Instant::now(),
                    });

                    let _ = app.emit(
                        "pill-dock-changed",
                        DockInfo {
                            is_docked: true,
                            edge: "left".to_string(),
                            is_tucked: false,
                        },
                    );
                }

                let _ = pill_win.set_always_on_top(true);
                let _ = pill_win.show();
                Self::apply_toolwindow_style(app, Self::PILL_LABEL);
                let _ = pill_win.set_skip_taskbar(true);
            }
        } else {
            *CURRENT_DOCK.write().unwrap_or_else(|e| e.into_inner()) = None;
            let _ = app.emit(
                "pill-dock-changed",
                DockInfo {
                    is_docked: false,
                    edge: "none".to_string(),
                    is_tucked: false,
                },
            );

            // Hide pill window
            if let Some(pill_win) = app.get_webview_window(Self::PILL_LABEL) {
                let _ = pill_win.set_skip_taskbar(true);
                let _ = pill_win.hide();
            }

            // Show main window
            if let Some(main_win) = app.get_webview_window(Self::MAIN_LABEL) {
                let _ = main_win.set_skip_taskbar(false);
                let _ = main_win.unminimize();
                let _ = main_win.show();
                let _ = main_win.set_focus();
            }
        }
    }

    pub fn restore_to_main(app: &AppHandle) {
        Self::set_pill_mode(app, false);
    }

    /// Controls the dedicated Break Overlay window
    pub fn show_break_overlay(app: &AppHandle) {
        // Hide pill during active break
        if let Some(pill_win) = app.get_webview_window(Self::PILL_LABEL) {
            let _ = pill_win.hide();
        }

        // Hide main window
        if let Some(main_win) = app.get_webview_window(Self::MAIN_LABEL) {
            let _ = main_win.hide();
        }

        // Show dedicated Break Overlay
        if let Some(break_win) = app.get_webview_window(Self::BREAK_LABEL) {
            let _ = break_win.unminimize();
            let _ = break_win.show();
            let _ = break_win.set_focus();
        }
    }

    pub fn hide_break_overlay(app: &AppHandle) {
        if let Some(break_win) = app.get_webview_window(Self::BREAK_LABEL) {
            let _ = break_win.hide();
        }
        // Restore main view
        Self::show_main(app);
    }

    /// Snaps the pill to the closest monitor edge if within snap threshold (55px).
    /// Respects tiling WM compatibility: skips snapping if disabled by settings.
    pub fn snap_pill_to_edge(app: &AppHandle, allow_snapping: bool) -> Result<DockInfo, String> {
        if !Self::is_pill_mode() || !allow_snapping {
            *CURRENT_DOCK.write().unwrap_or_else(|e| e.into_inner()) = None;
            let dock_info = DockInfo {
                is_docked: false,
                edge: "none".to_string(),
                is_tucked: false,
            };
            let _ = app.emit("pill-dock-changed", &dock_info);
            return Ok(dock_info);
        }

        let win = app.get_webview_window(Self::PILL_LABEL).ok_or("No pill window")?;
        let monitor = win
            .current_monitor()
            .map_err(|e| e.to_string())?
            .ok_or("No monitor detected")?;

        let mon_pos = monitor.position();
        let mon_size = monitor.size();
        let scale = monitor.scale_factor();

        let win_pos = win.outer_position().map_err(|e| e.to_string())?;
        let win_size = win.outer_size().map_err(|e| e.to_string())?;

        // 55px snap threshold in physical pixels
        let snap_threshold = (55.0 * scale) as i32;
        let margin = (4.0 * scale) as i32;
        // Visible handle with comfortable 26px grab space
        let visible_handle = (26.0 * scale) as i32;

        let dist_left = (win_pos.x - mon_pos.x).abs();
        let dist_right =
            ((mon_pos.x + mon_size.width as i32) - (win_pos.x + win_size.width as i32)).abs();
        let dist_top = (win_pos.y - mon_pos.y).abs();
        let dist_bottom =
            ((mon_pos.y + mon_size.height as i32) - (win_pos.y + win_size.height as i32)).abs();

        let mut normal_x = win_pos.x;
        let mut normal_y = win_pos.y;
        let mut tucked_x = win_pos.x;
        let mut tucked_y = win_pos.y;
        let mut edge = "none";

        if dist_right < snap_threshold && dist_right <= dist_left {
            normal_x = mon_pos.x + mon_size.width as i32 - win_size.width as i32 - margin;
            tucked_x = mon_pos.x + mon_size.width as i32 - visible_handle;
            edge = "right";
        } else if dist_left < snap_threshold {
            normal_x = mon_pos.x + margin;
            tucked_x = mon_pos.x - win_size.width as i32 + visible_handle;
            edge = "left";
        }

        if dist_top < snap_threshold && dist_top <= dist_bottom {
            normal_y = mon_pos.y + margin;
            if edge == "none" {
                tucked_y = mon_pos.y - win_size.height as i32 + visible_handle;
                edge = "top";
            }
        } else if dist_bottom < snap_threshold {
            normal_y = mon_pos.y + mon_size.height as i32 - win_size.height as i32 - margin;
            if edge == "none" {
                tucked_y = mon_pos.y + mon_size.height as i32 - visible_handle;
                edge = "bottom";
            }
        }

        if edge != "none" {
            let normal_pos = PhysicalPosition {
                x: normal_x,
                y: normal_y,
            };
            let tucked_pos = PhysicalPosition {
                x: tucked_x,
                y: tucked_y,
            };

            // Only move if actually shifted
            if (win_pos.x - normal_x).abs() > 1 || (win_pos.y - normal_y).abs() > 1 {
                IS_PROGRAMMATIC_MOVE.store(true, Ordering::SeqCst);
                let _ = win.set_position(Position::Physical(normal_pos));
            }

            *CURRENT_DOCK.write().unwrap_or_else(|e| e.into_inner()) = Some(StoredDockState {
                edge: edge.to_string(),
                normal_pos,
                tucked_pos,
                is_tucked: false,
                last_hovered: Instant::now(),
            });

            let dock_info = DockInfo {
                is_docked: true,
                edge: edge.to_string(),
                is_tucked: false,
            };
            let _ = app.emit("pill-dock-changed", &dock_info);
            Ok(dock_info)
        } else {
            *CURRENT_DOCK.write().unwrap_or_else(|e| e.into_inner()) = None;
            let dock_info = DockInfo {
                is_docked: false,
                edge: "none".to_string(),
                is_tucked: false,
            };
            let _ = app.emit("pill-dock-changed", &dock_info);
            Ok(dock_info)
        }
    }

    pub fn set_pill_tucked(app: &AppHandle, tucked: bool) -> Result<DockInfo, String> {
        let win = app.get_webview_window(Self::PILL_LABEL).ok_or("No pill window")?;

        let mut lock = CURRENT_DOCK.write().unwrap_or_else(|e| e.into_inner());
        if let Some(ref mut state) = *lock {
            if state.is_tucked != tucked {
                state.is_tucked = tucked;
                let target_pos = if tucked {
                    state.tucked_pos
                } else {
                    state.normal_pos
                };
                IS_PROGRAMMATIC_MOVE.store(true, Ordering::SeqCst);
                let _ = win.set_position(Position::Physical(target_pos));
            }
            if !tucked {
                state.last_hovered = Instant::now();
            }
            let dock_info = DockInfo {
                is_docked: true,
                edge: state.edge.clone(),
                is_tucked: state.is_tucked,
            };
            let _ = app.emit("pill-dock-changed", &dock_info);
            Ok(dock_info)
        } else {
            let dock_info = DockInfo {
                is_docked: false,
                edge: "none".to_string(),
                is_tucked: false,
            };
            let _ = app.emit("pill-dock-changed", &dock_info);
            Ok(dock_info)
        }
    }

    /// Background hover monitor: checks if mouse is near docked edge.
    /// Skips tucking/hover loops when tiling WM mode is active or snapping is disabled.
    pub fn update_dock_hover(app: &AppHandle, allow_tuck: bool) {
        if !Self::is_pill_mode() || !allow_tuck {
            return;
        }

        #[cfg(windows)]
        {
            // If left mouse button is pressed, user is actively dragging - do not auto-tuck!
            let is_lbutton_down = unsafe {
                (windows::Win32::UI::Input::KeyboardAndMouse::GetAsyncKeyState(0x01) as u16 & 0x8000) != 0
            };
            if is_lbutton_down {
                let mut lock = CURRENT_DOCK.write().unwrap_or_else(|e| e.into_inner());
                if let Some(ref mut state) = *lock {
                    state.last_hovered = Instant::now();
                }
                return;
            }

            let mut pt = POINT { x: 0, y: 0 };
            unsafe {
                if GetCursorPos(&mut pt).is_err() {
                    return;
                }
            }

            let Some(win) = app.get_webview_window(Self::PILL_LABEL) else {
                return;
            };
            let Ok(win_pos) = win.outer_position() else {
                return;
            };
            let Ok(win_size) = win.outer_size() else {
                return;
            };

            let mut lock = CURRENT_DOCK.write().unwrap_or_else(|e| e.into_inner());
            if let Some(ref mut state) = *lock {
                let pad = 25;
                let is_hovering = pt.x >= win_pos.x - pad
                    && pt.x <= win_pos.x + win_size.width as i32 + pad
                    && pt.y >= win_pos.y - pad
                    && pt.y <= win_pos.y + win_size.height as i32 + pad;

                if is_hovering {
                    state.last_hovered = Instant::now();
                    if state.is_tucked {
                        state.is_tucked = false;
                        IS_PROGRAMMATIC_MOVE.store(true, Ordering::SeqCst);
                        let _ = win.set_position(Position::Physical(state.normal_pos));
                        let dock_info = DockInfo {
                            is_docked: true,
                            edge: state.edge.clone(),
                            is_tucked: false,
                        };
                        let _ = app.emit("pill-dock-changed", &dock_info);
                    }
                } else if !state.is_tucked {
                    // Hide / tuck after 650ms of mouse leaving the area
                    if state.last_hovered.elapsed().as_millis() > 650 {
                        state.is_tucked = true;
                        IS_PROGRAMMATIC_MOVE.store(true, Ordering::SeqCst);
                        let _ = win.set_position(Position::Physical(state.tucked_pos));
                        let dock_info = DockInfo {
                            is_docked: true,
                            edge: state.edge.clone(),
                            is_tucked: true,
                        };
                        let _ = app.emit("pill-dock-changed", &dock_info);
                    }
                }
            }
        }
    }
}
