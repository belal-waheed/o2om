; ---------------------------------------------------------------------------
; O2om — Localization & Multi-language Support (Arabic Default / English)
; ---------------------------------------------------------------------------

class O2omLang {
    static currentLang := "ar"

    static dict := Map(
        "ar", Map(
            "app_title",              "قُوم — O2om",
            "mode_standup",            "الوقوف والتمدد",
            "mode_eyeguard",           "حماية العين 20-20-20",
            "mode_pomodoro",           "التركيز (بومودورو)",
            "mode_custom",             "مخصص",

            "tab_timer",               "المؤقت",
            "tab_stats",               "الإحصائيات",
            "tab_settings",            "الإعدادات",

            "status_focus_active",     "جلسة تركيز ونشاط",
            "status_next_break",       "الاستراحة القادمة خلال...",
            "status_on_break",         "وقت الاستراحة! متبقي:",
            "status_idle",             "المستخدم غير نشط — توقف مؤقت",
            "status_paused",           "المؤقت متوقف مؤقتاً",
            "status_escalation_1",     "تنبيه أول: حان وقت الوقوف!",
            "status_escalation_2",     "تنبيه أخير: يرجى التحرك الآن!",
            "status_waiting_work",     "انتهت الاستراحة، مستعد لجلسة العمل القادمة؟",
            "status_cycle_badge",      "الجولة {1} من {2}",

            "btn_reset",               "إعادة ضبط",
            "btn_pause",               "إيقاف مؤقت",
            "btn_resume",              "استئناف",
            "btn_start_break",         "بدء الاستراحة فقط",
            "btn_start_exercises",     "ابدأ التمارين والوقوف",
            "btn_quiet_break",         "استراحة هادئة",
            "btn_snooze_chip",         "تأجيل 5د",
            "btn_start_work",          "بدء جلسة العمل",
            "btn_snooze",              "تأجيل (غفوة)",
            "btn_save",                "حفظ الإعدادات",
            "btn_reset_stats",         "تصفير الإحصائيات",
            "btn_dock_pill",           "شريط مصغر عائم",
            "btn_next_exercise",       "التالي",
            "btn_prev_exercise",       "السابق",
            "btn_finish_break",        "إنهاء والعودة للعمل",

            "preset_standup_title",    "الوقوف وتصحيح القامة (موصى به)",
            "preset_standup_desc",     "40 دقيقة عمل  •  5 دقائق تمارين استطالة",
            "preset_pomodoro_title",   "التركيز العميق (بومودورو)",
            "preset_pomodoro_desc",    "25 دقيقة تركيز  •  5 دقائق استراحة",
            "preset_eyeguard_title",   "حماية العينين (قاعدة 20-20-20)",
            "preset_eyeguard_desc",    "20 دقيقة شاشة  •  20 ثانية راحة نظر",
            "lbl_advanced_toggle",     "خيارات الفترات المخصصة المتقدمة",

            "stats_title",             "إحصائيات الصحة والإنتاجية",
            "stats_today_stands",      "مرات الوقوف اليوم:",
            "stats_daily_goal",        "الهدف اليومي:",
            "stats_streak",            "سلسلة الأيام المتتالية:",
            "stats_best_streak",       "أفضل سلسلة أيام:",
            "stats_focus_today",       "وقت التركيز اليوم:",
            "stats_lifetime_stands",   "إجمالي مرات الوقوف:",
            "stats_badge_summary",     "{1} من {2} وقفات اليوم  |  سلسلة {3} أيام",

            "exercise_overview_title", "دليل التمارين والاستطالة المكتبية المتكامل",
            "exercise_step_badge",     "التمرين {1} من {2}",
            "exercise_tag_posture",    "استقامة القامة",
            "exercise_tag_neck",       "تخفيف إجهاد الرقبة",
            "exercise_tag_spine",      "مرونة العمود الفقري",
            "exercise_tag_lower",      "تنشيط عضلات الورك",
            "exercise_tag_eyes",       "راحة وترطيب العينين",

            "chk_startup",             "البدء تلقائياً مع تشغيل Windows",
            "lbl_mode",                "نمط الجلسات:",
            "lbl_language",            "اللغة:",
            "lbl_work_min",            "فترة العمل (دقائق):",
            "lbl_short_break_min",     "الاستراحة القصيرة (دقائق):",
            "lbl_long_break_min",      "الاستراحة الطويلة (دقائق):",
            "lbl_cycles_before_long",  "الجولات قبل الاستراحة الطويلة:",
            "lbl_escalation_min",      "فترة التنبيه (دقائق):",
            "lbl_snooze_min",          "مدة التأجيل (دقائق):",
            "lbl_idle_min",            "حد الخمول (دقائق):",
            "lbl_sound_enabled",       "تفعيل التنبيهات والأصوات",
            "lbl_mini_pill",           "تفعيل الشريط المصغر العائم",
            "lbl_daily_goal",          "هدف الوقوف اليومي:",

            "msg_saved",               "تم حفظ الإعدادات بنجاح.",
            "msg_invalid_input",       "جميع الفترات يجب أن تكون بين 1 و 180 دقيقة.",

            "toast_break_title",       "O2om (قُوم)",
            "toast_break_stage1",      "حان وقت الاستراحة! قم للوقوف والتمدد.",
            "toast_break_stage2",      "تنبيه إضافي: مرت فترة الاستراحة، يرجى القيام والتحرك!",
            "toast_break_stage3",      "التنبيه الأخير: تم إعادة تشغيل المؤقت تلقائياً.",
            "toast_break_ended",       "انتهت الاستراحة! حان وقت العودة للعمل.",
            "toast_goal_reached",      "رائع! حققت هدفك اليومي ({1} مرات وقوف) بنجاح!",

            "tray_show",               "إظهار لوحة التحكم",
            "tray_pause",              "إيقاف مؤقت",
            "tray_resume",             "استئناف",
            "tray_take_break",         "بدء استراحة الآن",
            "tray_reset",              "إعادة ضبط المؤقت",
            "tray_toggle_pill",        "تبديل الشريط المصغر",
            "tray_sound_mute",         "كتم الصوت",
            "tray_sound_unmute",       "تفعيل الصوت",
            "tray_quit",               "إغلاق التطبيق"
        ),
        "en", Map(
            "app_title",              "O2om — Stand-Up Reminder",
            "mode_standup",            "Stand-Up & Posture",
            "mode_eyeguard",           "Eye Guard 20-20-20",
            "mode_pomodoro",           "Deep Work (Pomodoro)",
            "mode_custom",             "Custom Intervals",

            "tab_timer",               "Timer",
            "tab_stats",               "Stats",
            "tab_settings",            "Settings",

            "status_focus_active",     "Focus Session Active",
            "status_next_break",       "Next break in...",
            "status_on_break",         "Break time! Remaining:",
            "status_idle",             "User inactive — Paused",
            "status_paused",           "Timer Paused",
            "status_escalation_1",     "First Warning: Time to stand up!",
            "status_escalation_2",     "Final Warning: Please move now!",
            "status_waiting_work",     "Break finished! Ready to begin next session?",
            "status_cycle_badge",      "Cycle {1} of {2}",

            "btn_reset",               "Reset",
            "btn_pause",               "Pause",
            "btn_resume",              "Resume",
            "btn_start_break",         "Start Break (Tray Only)",
            "btn_start_exercises",     "Start Guided Stretches",
            "btn_quiet_break",         "Quiet Break",
            "btn_snooze_chip",         "Snooze 5m",
            "btn_start_work",          "Start Work Session",
            "btn_snooze",              "Snooze (5 min)",
            "btn_save",                "Save Settings",
            "btn_reset_stats",         "Reset Stats",
            "btn_dock_pill",           "Floating Mini-Pill",
            "btn_next_exercise",       "Next",
            "btn_prev_exercise",       "Previous",
            "btn_finish_break",        "Finish & Return to Work",

            "preset_standup_title",    "Ergonomic Posture (Recommended)",
            "preset_standup_desc",     "40 min focus  •  5 min posture stretches",
            "preset_pomodoro_title",   "Deep Work (Pomodoro)",
            "preset_pomodoro_desc",    "25 min focus  •  5 min short break",
            "preset_eyeguard_title",   "Eye Strain Guard (20-20-20)",
            "preset_eyeguard_desc",    "20 min screen  •  20 sec distant rest",
            "lbl_advanced_toggle",     "Advanced Custom Durations",

            "stats_title",             "Health & Productivity Analytics",
            "stats_today_stands",      "Stands Completed Today:",
            "stats_daily_goal",        "Daily Goal:",
            "stats_streak",            "Current Streak:",
            "stats_best_streak",       "Best Streak:",
            "stats_focus_today",       "Focus Time Today:",
            "stats_lifetime_stands",   "Lifetime Stands:",
            "stats_badge_summary",     "{1} of {2} Stands Today  |  {3}-Day Streak",

            "exercise_overview_title", "Complete 5-Step Desk Ergonomics Guide",
            "exercise_step_badge",     "Exercise {1} of {2}",
            "exercise_tag_posture",    "Posture Reset",
            "exercise_tag_neck",       "Neck Tension",
            "exercise_tag_spine",      "Spine Mobility",
            "exercise_tag_lower",      "Hip Flexors",
            "exercise_tag_eyes",       "Eye Rest",

            "chk_startup",             "Start automatically with Windows",
            "lbl_mode",                "Session Mode:",
            "lbl_language",            "Language:",
            "lbl_work_min",            "Work Interval (min):",
            "lbl_short_break_min",     "Short Break (min):",
            "lbl_long_break_min",      "Long Break (min):",
            "lbl_cycles_before_long",  "Cycles Before Long Break:",
            "lbl_escalation_min",      "Warning Interval (min):",
            "lbl_snooze_min",          "Snooze Duration (min):",
            "lbl_idle_min",            "Idle Threshold (min):",
            "lbl_sound_enabled",       "Enable Audio Chimes & Toasts",
            "lbl_mini_pill",           "Show Floating Mini-Pill Widget",
            "lbl_daily_goal",          "Daily Stand Goal:",

            "msg_saved",               "Settings updated successfully.",
            "msg_invalid_input",       "All interval values must be between 1 and 180 minutes.",

            "toast_break_title",       "O2om — Stand-Up Reminder",
            "toast_break_stage1",      "Time for a break! Stand up and stretch.",
            "toast_break_stage2",      "Warning: break time has passed, please get up!",
            "toast_break_stage3",      "Final warning: timer has been auto-reset.",
            "toast_break_ended",       "Break finished! Back to work.",
            "toast_goal_reached",      "Awesome! You completed your daily goal ({1} stands)!",

            "tray_show",               "Show Dashboard",
            "tray_pause",              "Pause Timer",
            "tray_resume",             "Resume Timer",
            "tray_take_break",         "Take Break Now",
            "tray_reset",              "Reset Timer",
            "tray_toggle_pill",        "Toggle Mini-Pill",
            "tray_sound_mute",         "Mute Sound",
            "tray_sound_unmute",       "Unmute Sound",
            "tray_quit",               "Quit O2om"
        )
    )

    static Get(key, fallback := "") {
        langMap := this.dict.Has(this.currentLang) ? this.dict[this.currentLang] : this.dict["en"]
        if langMap.Has(key)
            return langMap[key]
        enMap := this.dict["en"]
        if enMap.Has(key)
            return enMap[key]
        return (fallback != "") ? fallback : key
    }
}
