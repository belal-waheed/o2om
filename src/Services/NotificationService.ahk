; ---------------------------------------------------------------------------
; O2om — Action Center Notifications Service (AUMID & Clean Toasts)
; ---------------------------------------------------------------------------

class O2omNotificationService {
    static AUMID := "O2om.StandUpReminder"
    static APP_NAME := "O2om"

    static RegisterAUMID(iconPath := "") {
        regPath := "HKCU\Software\Classes\AppUserModelId\" this.AUMID
        try {
            currName := RegRead(regPath, "DisplayName", "")
            if (currName != this.APP_NAME)
                RegWrite(this.APP_NAME, "REG_SZ", regPath, "DisplayName")

            if (iconPath != "") {
                currIcon := RegRead(regPath, "IconUri", "")
                if (currIcon != iconPath)
                    RegWrite(iconPath, "REG_SZ", regPath, "IconUri")
            }
        }
    }

    static Show(title, message, soundType := 64, playSound := true) {
        if (playSound)
            try SoundPlay("*" soundType)

        try TrayTip() ; Dismiss prior active toast immediately
        try TrayTip(message, title, "Mute") ; "Mute" prevents blue (i) icon circle and duplicate beep
    }
}
