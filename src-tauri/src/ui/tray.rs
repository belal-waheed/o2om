use tauri::{
    menu::{Menu, MenuItem},
    tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent},
    AppHandle, Emitter,
};
use super::windows::WindowManager;

pub struct TrayManager;

impl TrayManager {
    pub fn setup(app: &AppHandle) -> Result<(), Box<dyn std::error::Error>> {
        let show_i = MenuItem::with_id(app, "show", "Show O2om Focus", true, None::<&str>)?;
        let toggle_pause_i = MenuItem::with_id(app, "toggle_pause", "Pause / Resume", true, None::<&str>)?;
        let take_break_i = MenuItem::with_id(app, "take_break", "Take Break Now", true, None::<&str>)?;
        let toggle_pill_i = MenuItem::with_id(app, "toggle_pill", "Toggle Mini-Pill", true, None::<&str>)?;
        let quit_i = MenuItem::with_id(app, "quit", "Quit O2om", true, None::<&str>)?;

        let menu = Menu::with_items(
            app,
            &[
                &show_i,
                &toggle_pause_i,
                &take_break_i,
                &toggle_pill_i,
                &quit_i,
            ],
        )?;

        let mut builder = TrayIconBuilder::with_id("main-tray")
            .menu(&menu)
            .tooltip("O2om — Stand-Up & Focus Reminder")
            .show_menu_on_left_click(false)
            .on_menu_event(|app, event| {
                match event.id.as_ref() {
                    "show" => {
                        WindowManager::show_main(app);
                    }
                    "toggle_pause" => {
                        let _ = app.emit("tray-toggle-pause", ());
                    }
                    "take_break" => {
                        let _ = app.emit("tray-take-break", ());
                    }
                    "toggle_pill" => {
                        let _ = app.emit("tray-toggle-pill", ());
                    }
                    "quit" => {
                        app.exit(0);
                    }
                    _ => {}
                }
            })
            .on_tray_icon_event(|tray, event| {
                if let TrayIconEvent::Click {
                    button: MouseButton::Left,
                    button_state: MouseButtonState::Up,
                    ..
                } = event
                {
                    let app = tray.app_handle();
                    WindowManager::show_main(app);
                }
            });

        if let Some(icon) = app.default_window_icon().cloned() {
            builder = builder.icon(icon);
        } else if let Ok(icon) = tauri::image::Image::from_bytes(include_bytes!("../../icons/icon.ico")) {
            builder = builder.icon(icon);
        }

        let _tray = builder.build(app)?;

        Ok(())
    }

    pub fn update_tooltip(app: &AppHandle, tooltip: &str) {
        if let Some(tray) = app.tray_by_id("main-tray") {
            let _ = tray.set_tooltip(Some(tooltip));
        }
    }
}
