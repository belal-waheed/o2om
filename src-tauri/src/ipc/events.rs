use serde::{Deserialize, Serialize};
use crate::core::engine::TimerStateSnapshot;
use crate::db::repository::{BreakRecordResult, HealthStatsSummary};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TimerTickPayload {
    pub snapshot: TimerStateSnapshot,
    pub health_summary: HealthStatsSummary,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkCompletedPayload {
    pub snapshot: TimerStateSnapshot,
    pub title: String,
    pub message: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BreakCompletedPayload {
    pub snapshot: TimerStateSnapshot,
    pub result: BreakRecordResult,
    pub title: String,
    pub message: String,
}

pub fn emit_health_summary(app: &tauri::AppHandle, summary: &HealthStatsSummary) -> Result<(), tauri::Error> {
    use tauri::Emitter;
    app.emit("health-summary-updated", summary)
}
