use rodio::{buffer::SamplesBuffer, OutputStream, Sink};
use std::sync::mpsc::{sync_channel, SyncSender};
use std::sync::OnceLock;

struct ChimeRequest {
    freq1: f32,
    freq2: f32,
    duration_sec: f32,
}

static AUDIO_TX: OnceLock<SyncSender<ChimeRequest>> = OnceLock::new();

fn get_audio_sender() -> Option<&'static SyncSender<ChimeRequest>> {
    AUDIO_TX.get_or_init(|| {
        let (tx, rx) = sync_channel::<ChimeRequest>(16);
        let _ = std::thread::Builder::new()
            .name("o2om-audio-worker".to_string())
            .spawn(move || {
                let mut stream_info = OutputStream::try_default().ok();

                while let Ok(req) = rx.recv() {
                    if stream_info.is_none() {
                        stream_info = OutputStream::try_default().ok();
                    }
                    
                    let Some((ref _stream, ref stream_handle)) = stream_info else {
                        eprintln!("[O2om Audio] Could not get audio device for chime");
                        continue;
                    };

                    let Ok(sink) = Sink::try_new(stream_handle) else {
                        // If the stream became invalid, clear it so we try again next chime
                        stream_info = None;
                        continue;
                    };

                    let sample_rate = 44100;
                    let total_samples = (sample_rate as f32 * req.duration_sec) as usize;
                    let mut samples = Vec::with_capacity(total_samples);

                    for i in 0..total_samples {
                        let t = i as f32 / sample_rate as f32;
                        // Soft exponential decay envelope for a calm bell resonance
                        let envelope = (-3.0 * t / req.duration_sec).exp();
                        let wave1 = (2.0 * std::f32::consts::PI * req.freq1 * t).sin();
                        let wave2 = (2.0 * std::f32::consts::PI * req.freq2 * t).sin();
                        let sample = (wave1 * 0.65 + wave2 * 0.35) * envelope * 0.3;
                        samples.push(sample);
                    }

                    let buffer = SamplesBuffer::new(1, sample_rate, samples);
                    sink.append(buffer);
                    sink.sleep_until_end();
                }
            });
        tx
    });
    AUDIO_TX.get()
}

pub struct AudioService;

impl AudioService {
    fn play_chime(freq1: f32, freq2: f32, duration_sec: f32) {
        if let Some(sender) = get_audio_sender() {
            let _ = sender.try_send(ChimeRequest {
                freq1,
                freq2,
                duration_sec,
            });
        }
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
}
