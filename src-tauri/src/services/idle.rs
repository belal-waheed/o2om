use std::sync::atomic::{AtomicU32, Ordering};

#[cfg(windows)]
use windows::Win32::UI::Input::KeyboardAndMouse::{GetLastInputInfo, LASTINPUTINFO};
#[cfg(windows)]
use windows::Win32::System::SystemInformation::GetTickCount;

static APP_START_TICK: AtomicU32 = AtomicU32::new(0);

pub struct IdleMonitor;

impl IdleMonitor {
    pub fn init() {
        #[cfg(windows)]
        {
            let ticks = unsafe { GetTickCount() };
            APP_START_TICK.store(ticks, Ordering::SeqCst);
        }
    }

    #[cfg(windows)]
    pub fn get_idle_millis() -> u64 {
        unsafe {
            let current_ticks = GetTickCount();
            let start_tick = APP_START_TICK.load(Ordering::SeqCst);

            // 30-second post-startup grace period where get_idle_millis() returns 0
            if start_tick > 0 && current_ticks.wrapping_sub(start_tick) < 30_000 {
                return 0;
            }

            let mut lii = LASTINPUTINFO {
                cbSize: std::mem::size_of::<LASTINPUTINFO>() as u32,
                dwTime: 0,
            };

            if GetLastInputInfo(&mut lii).as_bool() {
                let elapsed_since_start = if start_tick > 0 {
                    current_ticks.wrapping_sub(start_tick)
                } else {
                    u32::MAX
                };
                let raw_idle = current_ticks.wrapping_sub(lii.dwTime);
                let idle = if start_tick > 0 && raw_idle > elapsed_since_start {
                    elapsed_since_start
                } else {
                    raw_idle
                };
                idle as u64
            } else {
                0
            }
        }
    }

    #[cfg(not(windows))]
    pub fn init() {}

    #[cfg(not(windows))]
    pub fn get_idle_millis() -> u64 {
        0
    }
}

