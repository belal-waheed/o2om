use serde::{Deserialize, Serialize};
use super::engine::SessionMode;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExerciseStep {
    pub id: String,
    pub name_ar: String,
    pub name_en: String,
    pub desc_ar: String,
    pub desc_en: String,
    pub duration_sec: u32,
    pub tag: String,
}

pub struct RoutineRegistry;

impl RoutineRegistry {
    pub fn get_exercises() -> Vec<ExerciseStep> {
        vec![
            ExerciseStep {
                id: "chest_opener".to_string(),
                name_ar: "فتح الصدر وعصر لوحي الكتف".to_string(),
                name_en: "Chest Opener & Shoulder Squeeze".to_string(),
                desc_ar: "قف مستقيماً، اشبك يديك خلف ظهرك، اسحب كتفيك للخلف والأسفل بلطف مع رفع الصدر لأعلى والتنفس بعمق.".to_string(),
                desc_en: "Stand tall, interlace fingers behind your lower back, pull shoulders down and back, and lift chest upward with deep breathing.".to_string(),
                duration_sec: 45,
                tag: "posture".to_string(),
            },
            ExerciseStep {
                id: "neck_stretch".to_string(),
                name_ar: "إرجاع الرقبة والتمدد الجانبي".to_string(),
                name_en: "Neck Retraction & Lateral Stretch".to_string(),
                desc_ar: "اسحب ذقنك إلى الخلف مستقيماً (Chin Tuck) لمدة 5 ثوانٍ، ثم مل برأسك ببطء نحو كل كتف لتخفيف شد الرقبة.".to_string(),
                desc_en: "Pull chin straight backward (chin tuck) for 5s. Then gently tilt ear toward shoulder on each side to release tension.".to_string(),
                duration_sec: 45,
                tag: "neck".to_string(),
            },
            ExerciseStep {
                id: "hip_flexor".to_string(),
                name_ar: "تمدد الورك والوقوف المستقيم".to_string(),
                name_en: "Standing Hip Flexor & Glute Reset".to_string(),
                desc_ar: "تقدم بخطوة للأمام كحركة الاندفاع الخفيف، اعصر عضلات المؤخرة واثنِ الحوض لتمديد عضلات الورك المشدودة من الجلوس.".to_string(),
                desc_en: "Take a step forward into a gentle lunge. Squeeze your back glute and tuck your pelvis to stretch tight hip flexors.".to_string(),
                duration_sec: 60,
                tag: "lower_body".to_string(),
            },
            ExerciseStep {
                id: "torso_twist".to_string(),
                name_ar: "استطالة العمود الفقري والالتفاف".to_string(),
                name_en: "Spine Decompression & Torso Twist".to_string(),
                desc_ar: "ارفع ذراعيك للأعلى للتمدد الكامل، ثم أنزلهما والتف بجذعك ببطء يميناً ويساراً لإعادة الليونة للفقرات القطنية.".to_string(),
                desc_en: "Reach both arms overhead for a tall spinal stretch, then slowly rotate your torso left and right with relaxed shoulders.".to_string(),
                duration_sec: 45,
                tag: "spine".to_string(),
            },
            ExerciseStep {
                id: "eye_rest".to_string(),
                name_ar: "راحة العين (قاعدة 20-20-20) والتنفس".to_string(),
                name_en: "20-20-20 Eye Rest & Deep Breathing".to_string(),
                desc_ar: "انظر إلى هدف يبعد 6 أمتار (20 قدماً) على الأقل. خذ شهيقاً عميقاً لـ 4 ثوانٍ وازفره لـ 6 ثوانٍ مع الرمش ببطء.".to_string(),
                desc_en: "Look at an object at least 20 feet (6m) away. Inhale deeply for 4 seconds, exhale for 6 seconds, and blink gently.".to_string(),
                duration_sec: 45,
                tag: "eyes".to_string(),
            },
        ]
    }

    pub fn get_eye_guard_exercise() -> ExerciseStep {
        ExerciseStep {
            id: "eye_guard_20".to_string(),
            name_ar: "قاعدة 20-20-20 لراحة العينين".to_string(),
            name_en: "20-20-20 Eye Strain Prevention".to_string(),
            desc_ar: "انظر بعيداً عن الشاشة إلى مسافة 6 أمتار لمدة 20 ثانية، وارمش بعينيك ببطء 10 مرات لإعادة ترطيبهما.".to_string(),
            desc_en: "Look 20 feet (6m) away from your screen for 20 seconds and blink slowly 10 times to replenish tear film.".to_string(),
            duration_sec: 20,
            tag: "eyes".to_string(),
        }
    }

    pub fn get_routine(mode: &SessionMode, total_break_ms: u64) -> Vec<ExerciseStep> {
        if *mode == SessionMode::Eyeguard {
            return vec![Self::get_eye_guard_exercise()];
        }

        let base_exercises = Self::get_exercises();
        let total_break_sec = (total_break_ms / 1000).max(60) as u32;

        let base_sum: u32 = base_exercises.iter().map(|e| e.duration_sec).sum();
        let count = base_exercises.len();
        let mut routine = Vec::new();
        let mut accumulated = 0;

        for (i, ex) in base_exercises.iter().enumerate() {
            let scaled_sec = if i + 1 == count {
                total_break_sec.saturating_sub(accumulated)
            } else {
                ((ex.duration_sec as f64 / base_sum as f64) * total_break_sec as f64).round() as u32
            };
            let clamped_sec = scaled_sec.max(15);
            accumulated += clamped_sec;

            routine.push(ExerciseStep {
                id: ex.id.clone(),
                name_ar: ex.name_ar.clone(),
                name_en: ex.name_en.clone(),
                desc_ar: ex.desc_ar.clone(),
                desc_en: ex.desc_en.clone(),
                duration_sec: clamped_sec,
                tag: ex.tag.clone(),
            });
        }

        routine
    }
}
