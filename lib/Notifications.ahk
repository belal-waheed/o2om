; ---------------------------------------------------------------------------
; O2om — Windows Toast Notifications with Action Center Persistence & AUMID
; ---------------------------------------------------------------------------

class O2omNotify {
    static AUMID := "O2om.StandUpReminder"
    static APP_NAME := "O2om"

    static RegisterAUMID() {
        ; Register AppUserModelID in registry once so Windows Action Center attributes toasts
        ; to "O2om" and retains them in the Notification Center panel.
        regPath := "HKCU\Software\Classes\AppUserModelId\" this.AUMID
        try {
            currName := RegRead(regPath, "DisplayName", "")
            if (currName != this.APP_NAME)
                RegWrite(this.APP_NAME, "REG_SZ", regPath, "DisplayName")
            
            iconPath := O2omResources.GetIcon()
            if (iconPath != "") {
                currIcon := RegRead(regPath, "IconUri", "")
                if (currIcon != iconPath)
                    RegWrite(iconPath, "REG_SZ", regPath, "IconUri")
            }
        }
    }

    static Show(title, message, soundType := 64, playSound := true) {
        ; Sound feedback
        if (playSound)
            try SoundPlay("*" soundType)

        ; Clear any active tray tip before displaying new one to ensure clean pop-up
        try TrayTip()

        ; Native TrayTip / Toast dispatch without the big blue (i) icon circle
        try {
            TrayTip(message, title, "Mute")
        } catch {
            ; Fallback
        }
    }
}
