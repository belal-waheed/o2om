use chrono::Local;
use rusqlite::{params, Connection, Result};
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;
use std::sync::{Arc, Mutex};
use crate::core::engine::{EngineSettings, SessionMode};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DailyHealthRecord {
    pub date: String,
    pub stands_count: u32,
    pub stand_goal: u32,
    pub focus_minutes: u32,
    pub goal_met: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HealthStatsSummary {
    pub today_stands: u32,
    pub daily_stand_goal: u32,
    pub today_focus_minutes: u32,
    pub total_stands_all_time: u32,
    pub total_focus_minutes_all_time: u32,
    pub current_streak_days: u32,
    pub best_streak_days: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BreakRecordResult {
    pub goal_just_met: bool,
    pub today_stands: u32,
    pub current_streak_days: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct PersistedSession {
    pub status: String,
    pub remaining_ms: u64,
    pub session_total_ms: u64,
    pub completed_cycles: u32,
    pub is_paused: bool,
    pub is_guided_exercise: bool,
    pub last_saved_epoch: i64,
}

#[derive(Clone)]
pub struct DbRepository {
    pub conn: Arc<Mutex<Connection>>,
    pub db_path: PathBuf,
}

impl DbRepository {
    pub fn new() -> Self {
        let app_data = std::env::var("APPDATA").unwrap_or_else(|_| ".".to_string());
        let new_dir = PathBuf::from(&app_data).join("com.o2om.desktop");
        let _ = fs::create_dir_all(&new_dir);
        let db_path = new_dir.join("o2om.db");

        // Automatic migration from legacy %APPDATA%\O2om\o2om.db if present
        let old_db = PathBuf::from(&app_data).join("O2om").join("o2om.db");
        if old_db.exists() && !db_path.exists() {
            let _ = fs::copy(&old_db, &db_path);
        }

        let conn = Connection::open(&db_path).unwrap_or_else(|_| {
            Connection::open_in_memory().expect("Failed to initialize SQLite fallback")
        });
        let _ = conn.busy_timeout(std::time::Duration::from_millis(5000));
        let _ = conn.pragma_update(None, "journal_mode", "WAL");
        let _ = conn.pragma_update(None, "synchronous", "NORMAL");

        let _ = Self::init_tables(&conn);

        Self {
            conn: Arc::new(Mutex::new(conn)),
            db_path,
        }
    }

    pub fn for_test(db_path: PathBuf) -> Self {
        let conn = Connection::open(&db_path).expect("Failed to open test database");
        let _ = conn.busy_timeout(std::time::Duration::from_millis(5000));
        let _ = conn.pragma_update(None, "journal_mode", "WAL");
        let _ = conn.pragma_update(None, "synchronous", "NORMAL");

        let _ = Self::init_tables(&conn);

        Self {
            conn: Arc::new(Mutex::new(conn)),
            db_path,
        }
    }

    pub fn init_tables(conn: &Connection) -> Result<()> {
        conn.execute_batch(
            "
            CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS daily_health_records (
                date TEXT PRIMARY KEY,
                stands_count INTEGER DEFAULT 0,
                stand_goal INTEGER DEFAULT 8,
                focus_minutes INTEGER DEFAULT 0,
                goal_met INTEGER DEFAULT 0,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS session_logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_type TEXT NOT NULL,
                duration_seconds INTEGER NOT NULL,
                started_at DATETIME NOT NULL,
                completed_at DATETIME NOT NULL,
                was_skipped INTEGER DEFAULT 0
            );

            CREATE TABLE IF NOT EXISTS streaks_metadata (
                id INTEGER PRIMARY KEY CHECK (id = 1),
                current_streak_days INTEGER DEFAULT 0,
                best_streak_days INTEGER DEFAULT 0,
                last_active_date TEXT DEFAULT ''
            );

            CREATE TABLE IF NOT EXISTS active_session (
                id INTEGER PRIMARY KEY CHECK (id = 1),
                status TEXT NOT NULL,
                remaining_ms INTEGER NOT NULL,
                session_total_ms INTEGER NOT NULL,
                completed_cycles INTEGER NOT NULL,
                is_paused INTEGER NOT NULL,
                is_guided_exercise INTEGER NOT NULL,
                last_saved_epoch INTEGER NOT NULL
            );

            INSERT OR IGNORE INTO streaks_metadata (id, current_streak_days, best_streak_days, last_active_date)
            VALUES (1, 0, 0, '');
            ",
        )?;

        Ok(())
    }

    pub fn init_repo_tables(&self) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        Self::init_tables(&conn)
    }

    pub fn load_settings(&self) -> EngineSettings {
        let mut settings = EngineSettings::default();
        let conn = self.conn.lock().unwrap();

        let mut stmt = match conn.prepare("SELECT key, value FROM settings") {
            Ok(s) => s,
            Err(_) => return settings,
        };

        let rows = stmt.query_map([], |row| {
            let key: String = row.get(0)?;
            let val: String = row.get(1)?;
            Ok((key, val))
        });

        if let Ok(rows) = rows {
            for row in rows.flatten() {
                let (key, val) = row;
                match key.as_str() {
                    "mode" => {
                        settings.mode = match val.as_str() {
                            "standup" => SessionMode::Standup,
                            "eyeguard" => SessionMode::Eyeguard,
                            "custom" => SessionMode::Custom,
                            _ => SessionMode::Pomodoro,
                        };
                    }
                    "work_interval_min" => {
                        if let Ok(v) = val.parse() {
                            settings.work_interval_min = v;
                        }
                    }
                    "short_break_min" => {
                        if let Ok(v) = val.parse() {
                            settings.short_break_min = v;
                        }
                    }
                    "long_break_min" => {
                        if let Ok(v) = val.parse() {
                            settings.long_break_min = v;
                        }
                    }
                    "cycles_before_long" => {
                        if let Ok(v) = val.parse() {
                            settings.cycles_before_long = v;
                        }
                    }
                    "escalation_min" => {
                        if let Ok(v) = val.parse() {
                            settings.escalation_min = v;
                        }
                    }
                    "snooze_min" => {
                        if let Ok(v) = val.parse() {
                            settings.snooze_min = v;
                        }
                    }
                    "idle_threshold_min" => {
                        if let Ok(v) = val.parse() {
                            settings.idle_threshold_min = v;
                        }
                    }
                    "eye_work_min" => {
                        if let Ok(v) = val.parse() {
                            settings.eye_work_min = v;
                        }
                    }
                    "eye_break_sec" => {
                        if let Ok(v) = val.parse() {
                            settings.eye_break_sec = v;
                        }
                    }
                    "daily_stand_goal" => {
                        if let Ok(v) = val.parse() {
                            settings.daily_stand_goal = v;
                        }
                    }
                    "sound_enabled" => settings.sound_enabled = val == "1" || val == "true",
                    "start_with_windows" => settings.start_with_windows = val == "1" || val == "true",
                    "language" => settings.language = val,
                    "tiling_wm_mode" => settings.tiling_wm_mode = val == "1" || val == "true",
                    "pill_dock_snapping" => settings.pill_dock_snapping = val == "1" || val == "true",
                    "auto_pill_mode" => settings.auto_pill_mode = val == "1" || val == "true",
                    _ => {}
                }
            }
        }

        settings
    }

    pub fn save_settings(&self, settings: &EngineSettings) -> Result<()> {
        let conn = self.conn.lock().unwrap();

        let mode_str = match settings.mode {
            SessionMode::Pomodoro => "pomodoro",
            SessionMode::Standup => "standup",
            SessionMode::Eyeguard => "eyeguard",
            SessionMode::Custom => "custom",
        };

        let pairs = vec![
            ("mode", mode_str.to_string()),
            ("work_interval_min", settings.work_interval_min.to_string()),
            ("short_break_min", settings.short_break_min.to_string()),
            ("long_break_min", settings.long_break_min.to_string()),
            ("cycles_before_long", settings.cycles_before_long.to_string()),
            ("escalation_min", settings.escalation_min.to_string()),
            ("snooze_min", settings.snooze_min.to_string()),
            ("idle_threshold_min", settings.idle_threshold_min.to_string()),
            ("eye_work_min", settings.eye_work_min.to_string()),
            ("eye_break_sec", settings.eye_break_sec.to_string()),
            ("daily_stand_goal", settings.daily_stand_goal.to_string()),
            ("sound_enabled", if settings.sound_enabled { "1" } else { "0" }.to_string()),
            ("start_with_windows", if settings.start_with_windows { "1" } else { "0" }.to_string()),
            ("language", settings.language.clone()),
            ("tiling_wm_mode", if settings.tiling_wm_mode { "1" } else { "0" }.to_string()),
            ("pill_dock_snapping", if settings.pill_dock_snapping { "1" } else { "0" }.to_string()),
            ("auto_pill_mode", if settings.auto_pill_mode { "1" } else { "0" }.to_string()),
        ];

        for (k, v) in pairs {
            conn.execute(
                "INSERT INTO settings (key, value) VALUES (?1, ?2) ON CONFLICT(key) DO UPDATE SET value = ?2",
                params![k, v],
            )?;
        }

        Ok(())
    }

    fn internal_check_midnight_rollover(conn: &Connection, goal: u32) -> Result<()> {
        let today = Local::now().format("%Y-%m-%d").to_string();

        let mut stmt = conn.prepare("SELECT current_streak_days, best_streak_days, last_active_date FROM streaks_metadata WHERE id = 1")?;
        let streak_row = stmt.query_row([], |row| {
            let cur: u32 = row.get(0)?;
            let best: u32 = row.get(1)?;
            let last: String = row.get(2)?;
            Ok((cur, best, last))
        });

        if let Ok((_cur, _best, last)) = streak_row {
            if !last.is_empty() && last != today {
                let yesterday = (Local::now() - chrono::Duration::days(1)).format("%Y-%m-%d").to_string();
                if last != yesterday {
                    // Missed days -> reset streak
                    conn.execute("UPDATE streaks_metadata SET current_streak_days = 0 WHERE id = 1", [])?;
                }
            }
        }

        conn.execute(
            "INSERT OR IGNORE INTO daily_health_records (date, stands_count, stand_goal, focus_minutes, goal_met)
             VALUES (?1, 0, ?2, 0, 0)",
            params![today, goal],
        )?;

        Ok(())
    }

    pub fn check_midnight_rollover(&self, goal: u32) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        Self::internal_check_midnight_rollover(&conn, goal)
    }

    pub fn record_completed_break(&self, goal: u32) -> Result<BreakRecordResult> {
        let conn = self.conn.lock().unwrap();
        let _ = Self::internal_check_midnight_rollover(&conn, goal);
        let today = Local::now().format("%Y-%m-%d").to_string();

        conn.execute(
            "UPDATE daily_health_records 
             SET stands_count = stands_count + 1,
                 stand_goal = ?1,
                 goal_met = CASE WHEN (stands_count + 1) >= ?1 THEN 1 ELSE goal_met END
             WHERE date = ?2",
            params![goal, today],
        )?;

        let today_stands: u32 = conn.query_row(
            "SELECT stands_count FROM daily_health_records WHERE date = ?1",
            params![today],
            |row| row.get(0),
        )?;

        let goal_just_met = today_stands == goal;

        let streak_row = conn.query_row(
            "SELECT current_streak_days, best_streak_days FROM streaks_metadata WHERE id = 1",
            [],
            |row| Ok((row.get::<_, u32>(0)?, row.get::<_, u32>(1)?)),
        );

        let (mut current_streak, mut best_streak) = if let Ok((cur, best)) = streak_row {
            (cur, best)
        } else {
            (0, 0)
        };

        if goal_just_met {
            current_streak += 1;
            if current_streak > best_streak {
                best_streak = current_streak;
            }
        }

        conn.execute(
            "UPDATE streaks_metadata 
             SET current_streak_days = ?1, best_streak_days = ?2, last_active_date = ?3 
             WHERE id = 1",
            params![current_streak, best_streak, today],
        )?;

        Ok(BreakRecordResult {
            goal_just_met,
            today_stands,
            current_streak_days: current_streak,
        })
    }

    pub fn add_focus_minutes(&self, minutes: u32, goal: u32) -> Result<()> {
        if minutes == 0 {
            return Ok(());
        }
        let conn = self.conn.lock().unwrap();
        let _ = Self::internal_check_midnight_rollover(&conn, goal);
        let today = Local::now().format("%Y-%m-%d").to_string();

        conn.execute(
            "UPDATE daily_health_records 
             SET focus_minutes = focus_minutes + ?1 
             WHERE date = ?2",
            params![minutes, today],
        )?;

        Ok(())
    }

    pub fn get_health_stats(&self, goal: u32) -> HealthStatsSummary {
        let conn = self.conn.lock().unwrap();
        let _ = Self::internal_check_midnight_rollover(&conn, goal);

        let today = Local::now().format("%Y-%m-%d").to_string();

        let today_row = conn.query_row(
            "SELECT stands_count, stand_goal, focus_minutes FROM daily_health_records WHERE date = ?1",
            params![today],
            |row| Ok((row.get::<_, u32>(0)?, row.get::<_, u32>(1)?, row.get::<_, u32>(2)?)),
        ).unwrap_or((0, goal, 0));

        let totals_row = conn.query_row(
            "SELECT COALESCE(SUM(stands_count), 0), COALESCE(SUM(focus_minutes), 0) FROM daily_health_records",
            [],
            |row| Ok((row.get::<_, u32>(0)?, row.get::<_, u32>(1)?)),
        ).unwrap_or((0, 0));

        let streak_row = conn.query_row(
            "SELECT current_streak_days, best_streak_days FROM streaks_metadata WHERE id = 1",
            [],
            |row| Ok((row.get::<_, u32>(0)?, row.get::<_, u32>(1)?)),
        ).unwrap_or((0, 0));

        HealthStatsSummary {
            today_stands: today_row.0,
            daily_stand_goal: today_row.1,
            today_focus_minutes: today_row.2,
            total_stands_all_time: totals_row.0,
            total_focus_minutes_all_time: totals_row.1,
            current_streak_days: streak_row.0,
            best_streak_days: streak_row.1,
        }
    }

    pub fn get_weekly_history(&self) -> Vec<DailyHealthRecord> {
        let mut records = Vec::new();
        let conn = self.conn.lock().unwrap();

        let mut stmt = match conn.prepare(
            "SELECT date, stands_count, stand_goal, focus_minutes, goal_met 
             FROM daily_health_records 
             ORDER BY date DESC LIMIT 7"
        ) {
            Ok(s) => s,
            Err(_) => return records,
        };

        let rows = stmt.query_map([], |row| {
            Ok(DailyHealthRecord {
                date: row.get(0)?,
                stands_count: row.get(1)?,
                stand_goal: row.get(2)?,
                focus_minutes: row.get(3)?,
                goal_met: row.get::<_, i32>(4)? != 0,
            })
        });

        if let Ok(rows) = rows {
            for row in rows.flatten() {
                records.push(row);
            }
        }
        records.reverse();
        records
    }

    pub fn save_active_session(&self, session: &PersistedSession) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        conn.execute(
            "INSERT INTO active_session (id, status, remaining_ms, session_total_ms, completed_cycles, is_paused, is_guided_exercise, last_saved_epoch)
             VALUES (1, ?1, ?2, ?3, ?4, ?5, ?6, ?7)
             ON CONFLICT(id) DO UPDATE SET
                 status = ?1,
                 remaining_ms = ?2,
                 session_total_ms = ?3,
                 completed_cycles = ?4,
                 is_paused = ?5,
                 is_guided_exercise = ?6,
                 last_saved_epoch = ?7",
            params![
                session.status,
                session.remaining_ms as i64,
                session.session_total_ms as i64,
                session.completed_cycles,
                if session.is_paused { 1 } else { 0 },
                if session.is_guided_exercise { 1 } else { 0 },
                session.last_saved_epoch,
            ],
        )?;
        Ok(())
    }

    pub fn load_active_session(&self) -> Result<Option<PersistedSession>> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = match conn.prepare(
            "SELECT status, remaining_ms, session_total_ms, completed_cycles, is_paused, is_guided_exercise, last_saved_epoch
             FROM active_session WHERE id = 1",
        ) {
            Ok(s) => s,
            Err(_) => return Ok(None),
        };

        let session = stmt.query_row([], |row| {
            Ok(PersistedSession {
                status: row.get(0)?,
                remaining_ms: row.get::<_, i64>(1)? as u64,
                session_total_ms: row.get::<_, i64>(2)? as u64,
                completed_cycles: row.get(3)?,
                is_paused: row.get::<_, i32>(4)? != 0,
                is_guided_exercise: row.get::<_, i32>(5)? != 0,
                last_saved_epoch: row.get(6)?,
            })
        });

        match session {
            Ok(s) => Ok(Some(s)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(e),
        }
    }

    pub fn clear_active_session(&self) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        conn.execute("DELETE FROM active_session WHERE id = 1", [])?;
        Ok(())
    }

    pub fn reset_all_stats(&self) -> Result<()> {
        let conn = self.conn.lock().unwrap();
        conn.execute_batch(
            "
            DELETE FROM daily_health_records;
            DELETE FROM session_logs;
            UPDATE streaks_metadata SET current_streak_days = 0, best_streak_days = 0, last_active_date = '';
            ",
        )?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_db_init_and_settings() {
        let temp_dir = std::env::temp_dir().join("o2om_test_db");
        let _ = fs::create_dir_all(&temp_dir);
        let test_db = temp_dir.join("test_settings.db");
        let _ = fs::remove_file(&test_db);

        let repo = DbRepository::for_test(test_db.clone());
        assert!(repo.init_repo_tables().is_ok());

        let mut settings = EngineSettings::default();
        settings.work_interval_min = 50;
        settings.daily_stand_goal = 12;
        settings.language = "en".to_string();

        assert!(repo.save_settings(&settings).is_ok());
        let loaded = repo.load_settings();

        assert_eq!(loaded.work_interval_min, 50);
        assert_eq!(loaded.daily_stand_goal, 12);
        assert_eq!(loaded.language, "en");

        let _ = fs::remove_file(&test_db);
    }

    #[test]
    fn test_db_breaks_and_streaks() {
        let temp_dir = std::env::temp_dir().join("o2om_test_db");
        let _ = fs::create_dir_all(&temp_dir);
        let test_db = temp_dir.join("test_streaks.db");
        let _ = fs::remove_file(&test_db);

        let repo = DbRepository::for_test(test_db.clone());
        assert!(repo.init_repo_tables().is_ok());

        // Record 1st break towards goal of 3
        let res1 = repo.record_completed_break(3).unwrap();
        assert_eq!(res1.today_stands, 1);
        assert!(!res1.goal_just_met);

        // Record 2nd and 3rd break
        let _ = repo.record_completed_break(3).unwrap();
        let res3 = repo.record_completed_break(3).unwrap();
        assert_eq!(res3.today_stands, 3);
        assert!(res3.goal_just_met);
        assert_eq!(res3.current_streak_days, 1);

        // Focus minutes tracking
        assert!(repo.add_focus_minutes(25, 3).is_ok());
        assert!(repo.add_focus_minutes(25, 3).is_ok());

        let stats = repo.get_health_stats(3);
        assert_eq!(stats.today_stands, 3);
        assert_eq!(stats.today_focus_minutes, 50);
        assert_eq!(stats.total_stands_all_time, 3);
        assert_eq!(stats.total_focus_minutes_all_time, 50);

        // Weekly history check
        let history = repo.get_weekly_history();
        assert_eq!(history.len(), 1);
        assert_eq!(history[0].stands_count, 3);
        assert!(history[0].goal_met);

        // Reset
        assert!(repo.reset_all_stats().is_ok());
        let reset_stats = repo.get_health_stats(3);
        assert_eq!(reset_stats.today_stands, 0);
        assert_eq!(reset_stats.today_focus_minutes, 0);

        let _ = fs::remove_file(&test_db);
    }

    #[test]
    fn test_active_session_persistence() {
        let temp_dir = std::env::temp_dir().join("o2om_test_db");
        let _ = fs::create_dir_all(&temp_dir);
        let test_db = temp_dir.join("test_session.db");
        let _ = fs::remove_file(&test_db);

        let repo = DbRepository::for_test(test_db.clone());
        assert!(repo.init_repo_tables().is_ok());

        // Initially no active session
        let none_session = repo.load_active_session().unwrap();
        assert!(none_session.is_none());

        let session = PersistedSession {
            status: "work".to_string(),
            remaining_ms: 1200_000,
            session_total_ms: 1500_000,
            completed_cycles: 2,
            is_paused: false,
            is_guided_exercise: false,
            last_saved_epoch: 1726123456,
        };

        assert!(repo.save_active_session(&session).is_ok());

        let loaded = repo.load_active_session().unwrap();
        assert!(loaded.is_some());
        let loaded = loaded.unwrap();
        assert_eq!(loaded, session);

        // Update session
        let mut updated = session;
        updated.remaining_ms = 800_000;
        updated.is_paused = true;
        assert!(repo.save_active_session(&updated).is_ok());

        let reloaded = repo.load_active_session().unwrap().unwrap();
        assert_eq!(reloaded.remaining_ms, 800_000);
        assert!(reloaded.is_paused);

        // Clear session
        assert!(repo.clear_active_session().is_ok());
        let cleared = repo.load_active_session().unwrap();
        assert!(cleared.is_none());

        let _ = fs::remove_file(&test_db);
    }

    #[test]
    fn test_db_migration_from_legacy_path() {
        let temp_dir = std::env::temp_dir().join("o2om_test_migration");
        let _ = fs::create_dir_all(&temp_dir);
        let legacy_dir = temp_dir.join("O2om");
        let _ = fs::create_dir_all(&legacy_dir);
        let legacy_db = legacy_dir.join("o2om.db");

        // Create a dummy legacy db with specific settings
        {
            let repo = DbRepository::for_test(legacy_db.clone());
            assert!(repo.init_repo_tables().is_ok());
            let mut s = EngineSettings::default();
            s.work_interval_min = 42;
            assert!(repo.save_settings(&s).is_ok());
        }

        let new_dir = temp_dir.join("com.o2om.desktop");
        let _ = fs::create_dir_all(&new_dir);
        let new_db = new_dir.join("o2om.db");
        let _ = fs::remove_file(&new_db);

        // Test migration copy
        if legacy_db.exists() && !new_db.exists() {
            fs::copy(&legacy_db, &new_db).unwrap();
        }

        let new_repo = DbRepository::for_test(new_db.clone());
        let loaded = new_repo.load_settings();
        assert_eq!(loaded.work_interval_min, 42);

        let _ = fs::remove_dir_all(&temp_dir);
    }
}
