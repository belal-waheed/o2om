; ---------------------------------------------------------------------------
; O2om — Desktop Audio & Chime Service
; ---------------------------------------------------------------------------

class O2omSoundService {
    static enabled := true

    static PlayWorkComplete() {
        if (!this.enabled)
            return
        ; Harmonious ascending chime
        try SoundPlay("*64")
    }

    static PlayBreakComplete() {
        if (!this.enabled)
            return
        ; Energetic focus prompt chime
        try SoundPlay("*64")
    }

    static PlayStepTransition() {
        if (!this.enabled)
            return
        ; Soft, subtle transition click/ping
        try SoundBeep(880, 80)
    }

    static PlayEscalation(stage := 1) {
        if (!this.enabled)
            return
        if (stage == 1) {
            try SoundPlay("*48")
        } else {
            try SoundPlay("*16")
        }
    }
}
