; ---------------------------------------------------------------------------
; O2om — Windows Startup Registry Manager
; ---------------------------------------------------------------------------

class O2omStartupService {
    static REG_KEY   := "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
    static REG_VALUE := "O2om"

    static IsEnabled() {
        try return (RegRead(this.REG_KEY, this.REG_VALUE) != "")
        catch
            return false
    }

    static SetEnabled(enable) {
        if (enable) {
            exePath := A_IsCompiled ? ('"' A_ScriptFullPath '"') : ('"' A_AhkPath '" "' A_ScriptFullPath '"')
            try RegWrite(exePath, "REG_SZ", this.REG_KEY, this.REG_VALUE)
        } else {
            try RegDelete(this.REG_KEY, this.REG_VALUE)
        }
    }

    static SyncWithSettings(shouldBeEnabled) {
        current := this.IsEnabled()
        if (shouldBeEnabled && !current) {
            this.SetEnabled(true)
        } else if (!shouldBeEnabled && current) {
            this.SetEnabled(false)
        }
    }
}
