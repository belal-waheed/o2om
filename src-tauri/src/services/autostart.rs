use tauri_plugin_autostart::ManagerExt;

pub struct AutostartService;

impl AutostartService {
    pub fn reconcile(app: &tauri::AppHandle, enabled: bool) -> Result<(), Box<dyn std::error::Error>> {
        let autolaunch = app.autolaunch();
        // Unconditionally reset any stale/unquoted registry entry
        let _ = autolaunch.disable();

        if enabled {
            autolaunch.enable()?;
        }
        Ok(())
    }
}
