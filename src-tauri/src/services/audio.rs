use rodio::{buffer::SamplesBuffer, OutputStream, Sink};

pub struct AudioService;

impl AudioService {
    fn play_chime(freq1: f32, freq2: f32, duration_sec: f32) {
        std::thread::spawn(move || {
            let Ok((_stream, stream_handle)) = OutputStream::try_default() else {
                return;
            };
            let Ok(sink) = Sink::try_new(&stream_handle) else {
                return;
            };

            let sample_rate = 44100;
            let total_samples = (sample_rate as f32 * duration_sec) as usize;
            let mut samples = Vec::with_capacity(total_samples);

            for i in 0..total_samples {
                let t = i as f32 / sample_rate as f32;
                // Soft exponential decay envelope for a calm bell resonance
                let envelope = (-3.0 * t / duration_sec).exp();
                let wave1 = (2.0 * std::f32::consts::PI * freq1 * t).sin();
                let wave2 = (2.0 * std::f32::consts::PI * freq2 * t).sin();
                let sample = (wave1 * 0.65 + wave2 * 0.35) * envelope * 0.3;
                samples.push(sample);
            }

            let buffer = SamplesBuffer::new(1, sample_rate, samples);
            sink.append(buffer);
            sink.sleep_until_end();
        });
    }

    pub fn play_work_complete(enabled: bool) {
        if !enabled {
            return;
        }
        // Calming warm bell (528 Hz + 1056 Hz, 1.8s)
        Self::play_chime(528.0, 1056.0, 1.8);
    }

    pub fn play_break_complete(enabled: bool) {
        if !enabled {
            return;
        }
        // Pleasant rising harmonic chime (660 Hz + 880 Hz, 1.4s)
        Self::play_chime(660.0, 880.0, 1.4);
    }

    pub fn play_step_transition(enabled: bool) {
        if !enabled {
            return;
        }
        // Gentle step chime (880 Hz + 1320 Hz, 0.4s)
        Self::play_chime(880.0, 1320.0, 0.4);
    }

    pub fn play_escalation(stage: u32, enabled: bool) {
        if !enabled {
            return;
        }
        if stage == 1 {
            Self::play_chime(440.0, 660.0, 1.2);
        } else {
            Self::play_chime(392.0, 587.33, 1.5);
        }
    }
}
