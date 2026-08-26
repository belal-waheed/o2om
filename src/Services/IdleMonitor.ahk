; ---------------------------------------------------------------------------
; O2om — Physical Inactivity Monitor Adapter
; ---------------------------------------------------------------------------

class O2omIdleMonitor {
    static GetIdleMs() => A_TimeIdlePhysical

    static IsAway(thresholdMs) => (A_TimeIdlePhysical >= thresholdMs)
}
