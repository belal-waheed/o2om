; ---------------------------------------------------------------------------
; O2om — Settings Shim (Forwarding to src/Services/SettingsRepo.ahk)
; ---------------------------------------------------------------------------

#Include ../src/Services/SettingsRepo.ahk

class O2omSettings extends O2omSettingsRepo {
    static GetConfigFilePath() => O2omSettingsRepo.GetConfigPath()
}
