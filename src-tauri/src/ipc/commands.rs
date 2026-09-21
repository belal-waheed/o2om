use std::sync::Arc;
use tauri::{AppHandle, State};
use tokio::sync::Mutex;
use crate::core::engine::{EngineSettings, SessionMode, TimerEngine, TimerStateSnapshot};
use crate::core::routines::{ExerciseStep, RoutineRegistry};
use crate::db::repository::{DailyHealthRecord, DbRepository, HealthStatsSummary};
use crate::services::audio::AudioService;
use crate::services::autostart::AutostartService;
use crate::ui::windows::WindowManager;

pub struct AppState {
    pub engine: Mutex<TimerEngine>,
    pub db: DbRepository,
    pub health_summary_cache: Mutex<HealthStatsSummary>,
    pub current_date_str: Mutex<String>,
}

pub type SharedState = Arc<AppState>;

#[tauri::command]
pub async fn get_state(state: State<'_, SharedState>) -> Result<TimerStateSnapshot, String> {
    let engine = state.engine.lock().await;
    Ok(engine.get_snapshot())
}

#[tauri::command]
pub async fn start_work(state: State<'_, SharedState>, app: AppHandle) -> Result<TimerStateSnapshot, String> {
    let (snapshot, persisted) = {
        let mut engine = state.engine.lock().await;
        engine.start_work();
        (engine.get_snapshot(), engine.to_persisted())
    };
    let _ = state.db.save_active_session(&persisted).await;
    WindowManager::show_main(&app);
    Ok(snapshot)
}

#[tauri::command]
pub async fn start_break(
    guided: bool,
    state: State<'_, SharedState>,
    app: AppHandle,
) -> Result<TimerStateSnapshot, String> {
    let (snapshot, persisted) = {
        let mut engine = state.engine.lock().await;
        engine.start_break(guided);
        (engine.get_snapshot(), engine.to_persisted())
    };
    let _ = state.db.save_active_session(&persisted).await;
    if guided {
        WindowManager::show_break_overlay(&app);
    } else {
        WindowManager::show_main(&app);
    }
    Ok(snapshot)
}

#[tauri::command]
pub async fn skip_break(state: State<'_, SharedState>, app: AppHandle) -> Result<TimerStateSnapshot, String> {
    let (snapshot, persisted) = {
        let mut engine = state.engine.lock().await;
        engine.skip_break();
        (engine.get_snapshot(), engine.to_persisted())
    };
    let _ = state.db.save_active_session(&persisted).await;
    WindowManager::hide_break_overlay(&app);
    WindowManager::show_main(&app);
    Ok(snapshot)
}

#[tauri::command]
pub async fn toggle_pause(state: State<'_, SharedState>) -> Result<bool, String> {
    let (is_paused, persisted) = {
        let mut engine = state.engine.lock().await;
        let paused = engine.toggle_pause();
        (paused, engine.to_persisted())
    };
    let _ = state.db.save_active_session(&persisted).await;
    Ok(is_paused)
}

#[tauri::command]
pub async fn reset_timer(state: State<'_, SharedState>) -> Result<TimerStateSnapshot, String> {
    let (snapshot, persisted) = {
        let mut engine = state.engine.lock().await;
        engine.reset_to_work();
        (engine.get_snapshot(), engine.to_persisted())
    };
    let _ = state.db.save_active_session(&persisted).await;
    Ok(snapshot)
}

#[tauri::command]
pub async fn snooze_timer(state: State<'_, SharedState>) -> Result<TimerStateSnapshot, String> {
    let (snapshot, persisted) = {
        let mut engine = state.engine.lock().await;
        engine.snooze();
        (engine.get_snapshot(), engine.to_persisted())
    };
    let _ = state.db.save_active_session(&persisted).await;
    Ok(snapshot)
}

#[tauri::command]
pub async fn set_mode(mode: SessionMode, state: State<'_, SharedState>) -> Result<TimerStateSnapshot, String> {
    let (snapshot, persisted, settings) = {
        let mut engine = state.engine.lock().await;
        engine.set_mode(mode);
        (engine.get_snapshot(), engine.to_persisted(), engine.settings.clone())
    };
    if let Err(e) = state.db.save_settings(&settings).await {
        eprintln!("Failed to save settings: {}", e);
    }
    let _ = state.db.save_active_session(&persisted).await;
    Ok(snapshot)
}

#[tauri::command]
pub async fn get_settings(state: State<'_, SharedState>) -> Result<EngineSettings, String> {
    let engine = state.engine.lock().await;
    Ok(engine.settings.clone())
}

#[tauri::command]
pub async fn save_settings(
    app: AppHandle,
    settings: EngineSettings,
    state: State<'_, SharedState>,
) -> Result<TimerStateSnapshot, String> {
    let (_dur_changed, goal_changed) = {
        let mut engine = state.engine.lock().await;
        let dur = engine.settings.work_interval_min != settings.work_interval_min
            || engine.settings.short_break_min != settings.short_break_min
            || engine.settings.long_break_min != settings.long_break_min;
        let goal = engine.settings.daily_stand_goal != settings.daily_stand_goal;
        engine.settings = settings.clone();
        if dur {
            engine.reset_to_work();
        }
        (dur, goal)
    };

    if let Err(e) = state.db.save_settings(&settings).await {
        eprintln!("Failed to save settings: {}", e);
        return Err(format!("Failed to save settings to database: {}", e));
    }

    if let Err(e) = AutostartService::reconcile(&app, settings.start_with_windows) {
        eprintln!("[O2om] Autostart reconciliation warning: {}", e);
    }

    if goal_changed {
        let stats = state.db.get_health_stats(settings.daily_stand_goal).await;
        let mut cache = state.health_summary_cache.lock().await;
        *cache = stats;
    }

    let (snapshot, persisted) = {
        let engine = state.engine.lock().await;
        (engine.get_snapshot(), engine.to_persisted())
    };
    let _ = state.db.save_active_session(&persisted).await;

    Ok(snapshot)
}

#[tauri::command]
pub async fn get_health_stats(state: State<'_, SharedState>) -> Result<HealthStatsSummary, String> {
    let cache = state.health_summary_cache.lock().await;
    Ok(cache.clone())
}

#[tauri::command]
pub async fn get_weekly_history(state: State<'_, SharedState>) -> Result<Vec<DailyHealthRecord>, String> {
    Ok(state.db.get_weekly_history().await)
}

#[tauri::command]
pub async fn reset_all_stats(state: State<'_, SharedState>, app: tauri::AppHandle) -> Result<(), String> {
    state.db.reset_all_stats().await.map_err(|e| e.to_string())?;
    let goal = {
        let engine = state.engine.lock().await;
        engine.settings.daily_stand_goal
    };
    let new_stats = state.db.get_health_stats(goal).await;
    {
        let mut cache = state.health_summary_cache.lock().await;
        *cache = new_stats.clone();
    }
    let _ = crate::ipc::events::emit_health_summary(&app, &new_stats);
    Ok(())
}

#[tauri::command]
pub async fn get_exercise_routine(
    total_break_ms: Option<u64>,
    state: State<'_, SharedState>,
) -> Result<Vec<ExerciseStep>, String> {
    let (mode, rem) = {
        let engine = state.engine.lock().await;
        (engine.settings.mode.clone(), engine.remaining_ms)
    };
    let break_ms = total_break_ms.unwrap_or(rem);
    Ok(RoutineRegistry::get_routine(&mode, break_ms))
}

#[tauri::command]
pub async fn set_pill_mode(is_pill: bool, app: AppHandle) -> Result<(), String> {
    WindowManager::set_pill_mode(&app, is_pill);
    Ok(())
}

#[tauri::command]
pub async fn snap_pill_to_edge(state: State<'_, SharedState>, app: AppHandle) -> Result<crate::ui::windows::DockInfo, String> {
    let allow = {
        let engine = state.engine.lock().await;
        !engine.settings.tiling_wm_mode && engine.settings.pill_dock_snapping
    };
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
    let sound_enabled = {
        let engine = state.engine.lock().await;
        engine.settings.sound_enabled
    };
    AudioService::play_step_transition(sound_enabled);
    Ok(())
}
