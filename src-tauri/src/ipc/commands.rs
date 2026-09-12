use std::sync::Arc;
use tauri::{AppHandle, State};
use tokio::sync::Mutex;
use crate::core::engine::{EngineSettings, SessionMode, TimerEngine, TimerStateSnapshot};
use crate::core::routines::{ExerciseStep, RoutineRegistry};
use crate::db::repository::{DailyHealthRecord, DbRepository, HealthStatsSummary};
use crate::services::audio::AudioService;
use crate::ui::windows::WindowManager;

pub struct AppState {
    pub engine: TimerEngine,
    pub db: DbRepository,
}

pub type SharedState = Arc<Mutex<AppState>>;

#[tauri::command]
pub async fn get_state(state: State<'_, SharedState>) -> Result<TimerStateSnapshot, String> {
    let app_state = state.lock().await;
    Ok(app_state.engine.get_snapshot())
}

#[tauri::command]
pub async fn start_work(state: State<'_, SharedState>, app: AppHandle) -> Result<TimerStateSnapshot, String> {
    let mut app_state = state.lock().await;
    app_state.engine.start_work();
    let _ = app_state.db.save_active_session(&app_state.engine.to_persisted());
    let snapshot = app_state.engine.get_snapshot();
    WindowManager::show_main(&app);
    Ok(snapshot)
}

#[tauri::command]
pub async fn start_break(
    guided: bool,
    state: State<'_, SharedState>,
    app: AppHandle,
) -> Result<TimerStateSnapshot, String> {
    let mut app_state = state.lock().await;
    app_state.engine.start_break(guided);
    let _ = app_state.db.save_active_session(&app_state.engine.to_persisted());
    let snapshot = app_state.engine.get_snapshot();
    if guided {
        WindowManager::show_break_overlay(&app);
    } else {
        WindowManager::show_main(&app);
    }
    Ok(snapshot)
}

#[tauri::command]
pub async fn skip_break(state: State<'_, SharedState>, app: AppHandle) -> Result<TimerStateSnapshot, String> {
    let mut app_state = state.lock().await;
    app_state.engine.skip_break();
    let _ = app_state.db.save_active_session(&app_state.engine.to_persisted());
    let snapshot = app_state.engine.get_snapshot();
    WindowManager::hide_break_overlay(&app);
    WindowManager::show_main(&app);
    Ok(snapshot)
}

#[tauri::command]
pub async fn toggle_pause(state: State<'_, SharedState>) -> Result<bool, String> {
    let mut app_state = state.lock().await;
    let is_paused = app_state.engine.toggle_pause();
    let _ = app_state.db.save_active_session(&app_state.engine.to_persisted());
    Ok(is_paused)
}

#[tauri::command]
pub async fn reset_timer(state: State<'_, SharedState>) -> Result<TimerStateSnapshot, String> {
    let mut app_state = state.lock().await;
    app_state.engine.reset_to_work();
    let _ = app_state.db.save_active_session(&app_state.engine.to_persisted());
    Ok(app_state.engine.get_snapshot())
}

#[tauri::command]
pub async fn snooze_timer(state: State<'_, SharedState>) -> Result<TimerStateSnapshot, String> {
    let mut app_state = state.lock().await;
    app_state.engine.snooze();
    let _ = app_state.db.save_active_session(&app_state.engine.to_persisted());
    Ok(app_state.engine.get_snapshot())
}

#[tauri::command]
pub async fn set_mode(mode: SessionMode, state: State<'_, SharedState>) -> Result<TimerStateSnapshot, String> {
    let mut app_state = state.lock().await;
    app_state.engine.set_mode(mode);
    let _ = app_state.db.save_settings(&app_state.engine.settings);
    let _ = app_state.db.save_active_session(&app_state.engine.to_persisted());
    Ok(app_state.engine.get_snapshot())
}

#[tauri::command]
pub async fn get_settings(state: State<'_, SharedState>) -> Result<EngineSettings, String> {
    let app_state = state.lock().await;
    Ok(app_state.engine.settings.clone())
}

#[tauri::command]
pub async fn save_settings(
    settings: EngineSettings,
    state: State<'_, SharedState>,
) -> Result<TimerStateSnapshot, String> {
    let mut app_state = state.lock().await;
    let dur_changed = app_state.engine.settings.work_interval_min != settings.work_interval_min
        || app_state.engine.settings.short_break_min != settings.short_break_min
        || app_state.engine.settings.long_break_min != settings.long_break_min;

    app_state.engine.settings = settings.clone();
    let _ = app_state.db.save_settings(&settings);

    if dur_changed {
        app_state.engine.reset_to_work();
    }
    let _ = app_state.db.save_active_session(&app_state.engine.to_persisted());

    Ok(app_state.engine.get_snapshot())
}

#[tauri::command]
pub async fn get_health_stats(state: State<'_, SharedState>) -> Result<HealthStatsSummary, String> {
    let app_state = state.lock().await;
    Ok(app_state.db.get_health_stats(app_state.engine.settings.daily_stand_goal))
}

#[tauri::command]
pub async fn get_weekly_history(state: State<'_, SharedState>) -> Result<Vec<DailyHealthRecord>, String> {
    let app_state = state.lock().await;
    Ok(app_state.db.get_weekly_history())
}

#[tauri::command]
pub async fn reset_all_stats(state: State<'_, SharedState>) -> Result<(), String> {
    let app_state = state.lock().await;
    app_state.db.reset_all_stats().map_err(|e| e.to_string())
}

#[tauri::command]
pub async fn get_exercise_routine(
    total_break_ms: Option<u64>,
    state: State<'_, SharedState>,
) -> Result<Vec<ExerciseStep>, String> {
    let app_state = state.lock().await;
    let break_ms = total_break_ms.unwrap_or(app_state.engine.remaining_ms);
    Ok(RoutineRegistry::get_routine(&app_state.engine.settings.mode, break_ms))
}

#[tauri::command]
pub async fn set_pill_mode(is_pill: bool, app: AppHandle) -> Result<(), String> {
    WindowManager::set_pill_mode(&app, is_pill);
    Ok(())
}

#[tauri::command]
pub async fn snap_pill_to_edge(state: State<'_, SharedState>, app: AppHandle) -> Result<crate::ui::windows::DockInfo, String> {
    let app_state = state.lock().await;
    let allow = !app_state.engine.settings.tiling_wm_mode && app_state.engine.settings.pill_dock_snapping;
    WindowManager::snap_pill_to_edge(&app, allow)
}

#[tauri::command]
pub async fn set_pill_tucked(tucked: bool, app: AppHandle) -> Result<crate::ui::windows::DockInfo, String> {
    WindowManager::set_pill_tucked(&app, tucked)
}

#[tauri::command]
pub async fn close_break_overlay(app: AppHandle) -> Result<(), String> {
    WindowManager::hide_break_overlay(&app);
    Ok(())
}

#[tauri::command]
pub async fn play_step_transition(state: State<'_, SharedState>) -> Result<(), String> {
    let app_state = state.lock().await;
    AudioService::play_step_transition(app_state.engine.settings.sound_enabled);
    Ok(())
}
