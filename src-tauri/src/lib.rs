pub mod core;
pub mod db;
pub mod ipc;
pub mod services;
pub mod ui;

use std::sync::Arc;
use std::time::Duration;
use tauri::{Emitter, Listener, Manager};
use tauri_plugin_autostart::MacosLauncher;
use tokio::sync::Mutex;

use crate::core::engine::TimerEngine;
use crate::db::repository::DbRepository;
use crate::ipc::commands::*;
use crate::ipc::events::*;
use crate::services::audio::AudioService;
use crate::services::autostart::AutostartService;
use crate::services::idle::IdleMonitor;
use crate::services::notification::NotificationService;
use crate::ui::tray::TrayManager;
use crate::ui::windows::WindowManager;

static MOVE_GENERATION: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);

pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_notification::init())
        .plugin(tauri_plugin_autostart::init(
            MacosLauncher::LaunchAgent,
            Some(vec!["--minimized"]),
        ))
        .plugin(tauri_plugin_single_instance::init(|app, _args, _cwd| {
            let _ = crate::ui::windows::WindowManager::set_pill_mode(app, false);
            crate::ui::windows::WindowManager::show_main(app);
        }))
        .setup(|app| {
            // Initialize startup tick for idle monitor (prevents immediate boot freeze)
            IdleMonitor::init();

            let app_handle = app.handle().clone();
            let db = tauri::async_runtime::block_on(DbRepository::new(&app_handle));
            let settings = tauri::async_runtime::block_on(db.load_settings());
            let mut engine = TimerEngine::new(settings);

            // Hydrate active session from persistence if present
            if let Ok(Some(persisted)) = tauri::async_runtime::block_on(db.load_active_session()) {
                let hydration_event = engine.hydrate_from_persisted(persisted);
                if hydration_event == crate::core::engine::HydrationEvent::WorkCompletedOffline {
                    let work_interval = engine.settings.work_interval_min;
                    let goal = engine.settings.daily_stand_goal;
                    let _ = tauri::async_runtime::block_on(db.add_focus_minutes(work_interval, goal));
                }
            }

            let is_minimized = std::env::args().any(|arg| arg == "--minimized");
            let auto_pill = engine.settings.auto_pill_mode;

            let initial_goal = engine.settings.daily_stand_goal;
            let health_summary_cache = tauri::async_runtime::block_on(db.get_health_stats(initial_goal));
            let current_date_str = chrono::Local::now().format("%Y-%m-%d").to_string();

            if let Err(e) = AutostartService::reconcile(&app_handle, engine.settings.start_with_windows) {
                eprintln!("[O2om] Autostart reconciliation warning: {}", e);
            }

            let state: SharedState = Arc::new(AppState {
                engine: Mutex::new(engine),
                db,
                health_summary_cache: Mutex::new(health_summary_cache),
                current_date_str: Mutex::new(current_date_str),
            });
            app.manage(state.clone());

            if is_minimized {
                if let Some(main_window) = app.get_webview_window("main") {
                    let _ = main_window.hide();
                }
                if auto_pill {
                    let app_init = app_handle.clone();
                    tauri::async_runtime::spawn(async move {
                        tokio::time::sleep(Duration::from_millis(50)).await;
                        WindowManager::set_pill_mode(&app_init, true);
                        let _ = app_init.emit("pill-mode-changed", true);
                    });
                }
            } else if auto_pill {
                if let Some(main_window) = app.get_webview_window("main") {
                    let _ = main_window.hide();
                }
                let app_init = app_handle.clone();
                tauri::async_runtime::spawn(async move {
                    tokio::time::sleep(Duration::from_millis(50)).await;
                    WindowManager::set_pill_mode(&app_init, true);
                    let _ = app_init.emit("pill-mode-changed", true);
                });
            } else {
                WindowManager::show_main(&app_handle);
            }

            // Intercept window events:
            // 1. Close button on main or break -> Hide to system tray or dismiss
            // 2. Window moved in pill mode -> Auto snap to screen edge (if TWM mode disabled)
            if let Some(main_window) = app.get_webview_window("main") {
                let win_clone = main_window.clone();
                main_window.on_window_event(move |event| {
                    if let tauri::WindowEvent::CloseRequested { api, .. } = event {
                        api.prevent_close();
                        let _ = win_clone.hide();
                    }
                });
            }

            if let Some(break_window) = app.get_webview_window("break_overlay") {
                let win_clone = break_window.clone();
                let app_break_close = app_handle.clone();
                break_window.on_window_event(move |event| {
                    if let tauri::WindowEvent::CloseRequested { api, .. } = event {
                        api.prevent_close();
                        let _ = win_clone.hide();
                        WindowManager::show_main(&app_break_close);
                    }
                });
            }

            let app_move = app_handle.clone();
            let state_snap = state.clone();
            if let Some(pill_window) = app.get_webview_window("pill") {
                // Apply WS_EX_TOOLWINDOW extended style immediately on startup
                WindowManager::apply_toolwindow_style(&app_handle, "pill");

                let win_clone = pill_window.clone();
                pill_window.on_window_event(move |event| {
                    match event {
                        tauri::WindowEvent::CloseRequested { api, .. } => {
                            api.prevent_close();
                            let _ = win_clone.hide();
                        }
                        tauri::WindowEvent::Moved(_) => {
                            if WindowManager::is_programmatic_move() {
                                return;
                            }
                            WindowManager::on_user_move();
                            if WindowManager::is_pill_mode() {
                                let current_gen = MOVE_GENERATION.fetch_add(1, std::sync::atomic::Ordering::SeqCst) + 1;
                                let app_snap = app_move.clone();
                                let state_clone = state_snap.clone();
                                tauri::async_runtime::spawn(async move {
                                    tokio::time::sleep(Duration::from_millis(150)).await;
                                    if MOVE_GENERATION.load(std::sync::atomic::Ordering::SeqCst) != current_gen {
                                        return;
                                    }
                                    let allow = {
                                        let engine = state_clone.engine.lock().await;
                                        !engine.settings.tiling_wm_mode && engine.settings.pill_dock_snapping
                                    };
                                    let _ = WindowManager::snap_pill_to_edge(&app_snap, allow);
                                });
                            }
                        }
                        _ => {}
                    }
                });
            }

            // Setup System Tray
            if let Err(e) = TrayManager::setup(&app_handle) {
                eprintln!("Failed to setup system tray: {}", e);
            }

            // Listen for tray actions
            let state_tray_pause = state.clone();
            app_handle.listen("tray-toggle-pause", move |_| {
                let state_clone = state_tray_pause.clone();
                tokio::spawn(async move {
                    let persisted = {
                        let mut engine = state_clone.engine.lock().await;
                        engine.toggle_pause();
                        engine.to_persisted()
                    };
                    let _ = state_clone.db.save_active_session(&persisted).await;
                });
            });

            let state_tray_break = state.clone();
            let app_tray_break = app_handle.clone();
            app_handle.listen("tray-take-break", move |_| {
                let state_clone = state_tray_break.clone();
                let app_clone = app_tray_break.clone();
                tokio::spawn(async move {
                    let persisted = {
                        let mut engine = state_clone.engine.lock().await;
                        engine.start_break(false);
                        engine.to_persisted()
                    };
                    let _ = state_clone.db.save_active_session(&persisted).await;
                    WindowManager::restore_to_main(&app_clone);
                    let _ = app_clone.emit("pill-mode-changed", false);
                });
            });

            let app_tray_pill = app_handle.clone();
            app_handle.listen("tray-toggle-pill", move |_| {
                let _ = app_tray_pill.emit("toggle-pill-mode", ());
            });

            // Start 80ms Fast Edge-Hover & Tuck Loop for Mini-Pill (respects TWM mode)
            let app_hover = app_handle.clone();
            let state_hover = state.clone();
            tauri::async_runtime::spawn(async move {
                let mut hover_interval = tokio::time::interval(Duration::from_millis(80));
                hover_interval.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Skip);
                loop {
                    hover_interval.tick().await;
                    let allow_tuck = {
                        if let Ok(engine) = state_hover.engine.try_lock() {
                            !engine.settings.tiling_wm_mode && engine.settings.pill_dock_snapping
                        } else {
                            false
                        }
                    };
                    WindowManager::update_dock_hover(&app_hover, allow_tuck);
                }
            });

            // Start 100ms Master Background Tick Loop (High Precision)
            let state_tick = state.clone();
            let app_tick = app_handle.clone();

            tauri::async_runtime::spawn(async move {
                let mut interval = tokio::time::interval(Duration::from_millis(100));
                interval.set_missed_tick_behavior(tokio::time::MissedTickBehavior::Skip);
                let mut tick_counter: u64 = 0;
                loop {
                    interval.tick().await;
                    tick_counter = tick_counter.wrapping_add(1);

                    let idle_ms = IdleMonitor::get_idle_millis();
                    let (tick_event, work_interval, goal, sound, lang, snapshot, persisted) = {
                        let mut engine = state_tick.engine.lock().await;
                        let event = engine.tick(idle_ms);
                        let s = engine.get_snapshot();
                        let p = engine.to_persisted();
                        (
                            event,
                            engine.settings.work_interval_min,
                            engine.settings.daily_stand_goal,
                            engine.settings.sound_enabled,
                            engine.settings.language.clone(),
                            s,
                            p,
                        )
                    };

                    match tick_event {
                        crate::core::engine::TickEvent::WorkCompleted => {
                            let _ = state_tick.db.add_focus_minutes(work_interval, goal).await;
                            let new_summary = state_tick.db.get_health_stats(goal).await;
                            {
                                let mut cache = state_tick.health_summary_cache.lock().await;
                                *cache = new_summary;
                            }
                            AudioService::play_work_complete(sound);
                            let title = if lang == "ar" { "قُوم — O2om" } else { "O2om — Stand-Up Reminder" };
                            let msg = if lang == "ar" {
                                "حان وقت الاستراحة! خذ قسطاً من الراحة ومارس تمارين الاستطالة."
                            } else {
                                "Time for a break! Stand up and take a rest."
                            };
                            NotificationService::show_toast(&app_tick, title, msg);
                            
                            // Auto-restore from Mini-Pill to full main window on session finish
                            WindowManager::restore_to_main(&app_tick);
                            let _ = app_tick.emit("pill-mode-changed", false);

                            let _ = app_tick.emit("timer-work-completed", WorkCompletedPayload {
                                snapshot: snapshot.clone(),
                                title: title.to_string(),
                                message: msg.to_string(),
                            });
                        }
                        crate::core::engine::TickEvent::BreakCompleted => {
                            let break_res = state_tick.db.record_completed_break(goal).await.unwrap_or(crate::db::repository::BreakRecordResult {
                                goal_just_met: false,
                                today_stands: 0,
                                current_streak_days: 0,
                            });
                            let new_summary = state_tick.db.get_health_stats(goal).await;
                            {
                                let mut cache = state_tick.health_summary_cache.lock().await;
                                *cache = new_summary;
                            }
                            AudioService::play_break_complete(sound);

                            let title = if lang == "ar" { "قُوم — O2om" } else { "O2om — Stand-Up Reminder" };
                            let msg = if break_res.goal_just_met {
                                if lang == "ar" {
                                    format!("رائع! حققت هدفك اليومي ({} جلسات) بنجاح!", break_res.today_stands)
                                } else {
                                    format!("Awesome! You reached your daily goal ({} sessions)!", break_res.today_stands)
                                }
                            } else if lang == "ar" {
                                "انتهت الاستراحة! حان وقت العودة للتركيز.".to_string()
                            } else {
                                "Break finished! Time to return to focus.".to_string()
                            };

                            NotificationService::show_toast(&app_tick, title, &msg);
                            
                            // Auto-restore to full main window on session finish
                            WindowManager::hide_break_overlay(&app_tick);
                            WindowManager::restore_to_main(&app_tick);
                            let _ = app_tick.emit("pill-mode-changed", false);

                            let _ = app_tick.emit("timer-break-completed", BreakCompletedPayload {
                                snapshot: snapshot.clone(),
                                result: break_res,
                                title: title.to_string(),
                                message: msg,
                            });
                        }
                        crate::core::engine::TickEvent::None => {}
                    }

                    // Check for midnight rollover every 60 seconds
                    if tick_counter % 600 == 0 {
                        let now_date = chrono::Local::now().format("%Y-%m-%d").to_string();
                        let mut cur_date = state_tick.current_date_str.lock().await;
                        if now_date != *cur_date {
                            *cur_date = now_date;
                            drop(cur_date);
                            let new_summary = state_tick.db.get_health_stats(goal).await;
                            let mut cache = state_tick.health_summary_cache.lock().await;
                            *cache = new_summary;
                        }
                    }

                    // Update Tray Tooltip
                    let tooltip = format!(
                        "O2om — {} [Cycle {}/{}]",
                        snapshot.formatted_remaining, snapshot.current_cycle, snapshot.total_cycles
                    );
                    TrayManager::update_tooltip(&app_tick, &tooltip);

                    // Save active session periodically (every 5 seconds or on transition)
                    if tick_counter % 50 == 0 || tick_event != crate::core::engine::TickEvent::None {
                        let _ = state_tick.db.save_active_session(&persisted).await;
                    }

                    let health_summary = {
                        let cache = state_tick.health_summary_cache.lock().await;
                        cache.clone()
                    };

                    // Broadcast tick payload
                    let _ = app_tick.emit("timer-tick", TimerTickPayload {
                        snapshot,
                        health_summary,
                    });
                }
            });

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            get_state,
            start_work,
            start_break,
            skip_break,
            toggle_pause,
            reset_timer,
            snooze_timer,
            set_mode,
            get_settings,
            save_settings,
            get_health_stats,
            get_weekly_history,
            reset_all_stats,
            get_exercise_routine,
            set_pill_mode,
            snap_pill_to_edge,
            set_pill_tucked,
            close_break_overlay,
            play_step_transition
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
