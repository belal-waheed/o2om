; ---------------------------------------------------------------------------
; O2om — Guided Desk Exercise & Ergonomic Routines
; ---------------------------------------------------------------------------

class O2omExerciseRoutines {
    static exercises := [
        {
            id: "chest_opener",
            name_ar: "فتح الصدر وعصر لوحي الكتف",
            name_en: "Chest Opener & Shoulder Squeeze",
            desc_ar: "قف مستقيماً، اشبك يديك خلف ظهرك، اسحب كتفيك للخلف والأسفل بلطف مع رفع الصدر لأعلى والتنفس بعمق.",
            desc_en: "Stand tall, interlace fingers behind your lower back, pull shoulders down and back, and lift chest upward with deep breathing.",
            durationSec: 45,
            tag: "posture"
        },
        {
            id: "neck_stretch",
            name_ar: "إرجاع الرقبة والتمدد الجانبي",
            name_en: "Neck Retraction & Lateral Stretch",
            desc_ar: "اسحب ذقنك إلى الخلف مستقيماً (Chin Tuck) لمدة 5 ثوانٍ، ثم مل برأسك ببطء نحو كل كتف لتخفيف شد الرقبة.",
            desc_en: "Pull chin straight backward (chin tuck) for 5s. Then gently tilt ear toward shoulder on each side to release tension.",
            durationSec: 45,
            tag: "neck"
        },
        {
            id: "hip_flexor",
            name_ar: "تمدد الورك والوقوف المستقيم",
            name_en: "Standing Hip Flexor & Glute Reset",
            desc_ar: "تقدم بخطوة للأمام كحركة الاندفاع الخفيف، اعصر عضلات المؤخرة واثنِ الحوض لتمديد عضلات الورك المشدودة من الجلوس.",
            desc_en: "Take a step forward into a gentle lunge. Squeeze your back glute and tuck your pelvis to stretch tight hip flexors.",
            durationSec: 60,
            tag: "lower_body"
        },
        {
            id: "torso_twist",
            name_ar: "استطالة العمود الفقري والالتفاف",
            name_en: "Spine Decompression & Torso Twist",
            desc_ar: "ارفع ذراعيك للأعلى للتمدد الكامل، ثم أنزلهما والتف بجذعك ببطء يميناً ويساراً لإعادة الليونة للفقرات القطنية.",
            desc_en: "Reach both arms overhead for a tall spinal stretch, then slowly rotate your torso left and right with relaxed shoulders.",
            durationSec: 45,
            tag: "spine"
        },
        {
            id: "eye_rest",
            name_ar: "راحة العين (قاعدة 20-20-20) والتنفس",
            name_en: "20-20-20 Eye Rest & Deep Breathing",
            desc_ar: "انظر إلى هدف يبعد 6 أمتار (20 قدماً) على الأقل. خذ شهيقاً عميقاً لـ 4 ثوانٍ وازفره لـ 6 ثوانٍ مع الرمش ببطء.",
            desc_en: "Look at an object at least 20 feet (6m) away. Inhale deeply for 4 seconds, exhale for 6 seconds, and blink gently.",
            durationSec: 45,
            tag: "eyes"
        }
    ]

    static eyeGuardExercise := {
        id: "eye_guard_20",
        name_ar: "قاعدة 20-20-20 لراحة العينين",
        name_en: "20-20-20 Eye Strain Prevention",
        desc_ar: "انظر بعيداً عن الشاشة إلى مسافة 6 أمتار لمدة 20 ثانية، وارمش بعينيك ببطء 10 مرات لإعادة ترطيبهما.",
        desc_en: "Look 20 feet (6m) away from your screen for 20 seconds and blink slowly 10 times to replenish tear film.",
        durationSec: 20,
        tag: "eyes"
    }

    static GetRoutine(mode, totalBreakMs) {
        if (mode == "eyeguard")
            return [this.eyeGuardExercise]

        totalBreakSec := Max(60, totalBreakMs // 1000)
        baseRoutine := this.exercises

        ; Scale exercise durations proportionally to fit total break duration
        baseSum := 0
        for ex in baseRoutine
            baseSum += ex.durationSec

        routine := []
        accumulated := 0
        count := baseRoutine.Length

        for i, ex in baseRoutine {
            scaledSec := (i == count) ? (totalBreakSec - accumulated) : Integer((ex.durationSec / baseSum) * totalBreakSec)
            scaledSec := Max(15, scaledSec)
            accumulated += scaledSec

            routine.Push({
                id: ex.id,
                name_ar: ex.name_ar,
                name_en: ex.name_en,
                desc_ar: ex.desc_ar,
                desc_en: ex.desc_en,
                durationSec: scaledSec,
                tag: ex.tag
            })
        }

        return routine
    }
}
