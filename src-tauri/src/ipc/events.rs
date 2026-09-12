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

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EscalationPayload {
    pub stage: u32,
    pub title: String,
    pub message: String,
}
