import React, { useState, useEffect } from "react";
import { useTranslation } from "react-i18next";
import {
  Globe,
  Clock,
  Settings as SettingsIcon,
  Volume2,
  Power,
  Target,
  Check,
  Layout,
  Magnet,
  Minimize2,
  AlertCircle,
} from "lucide-react";
import { useTimerStore } from "../../stores/useTimerStore";
import { enable, disable, isEnabled } from "@tauri-apps/plugin-autostart";
import type { EngineSettings } from "../../lib/ipc";

export const SettingsView: React.FC = () => {
  const { t } = useTranslation();
  const { settings, saveSettings, setActiveTab } = useTimerStore();

  const [formData, setFormData] = useState<EngineSettings>({
    mode: "pomodoro",
    work_interval_min: 25,
    short_break_min: 5,
    long_break_min: 15,
    cycles_before_long: 4,
    escalation_min: 2,
    snooze_min: 5,
    idle_threshold_min: 5,
    eye_work_min: 20,
    eye_break_sec: 20,
    daily_stand_goal: 8,
    sound_enabled: true,
    start_with_windows: true,
    language: "ar",
    tiling_wm_mode: false,
    pill_dock_snapping: true,
    auto_pill_mode: true,
  });

  const [savedFeedback, setSavedFeedback] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    if (settings) {
      setFormData(settings);
    }
  }, [settings]);

  const updateField = <K extends keyof EngineSettings>(key: K, value: EngineSettings[K]) => {
    setErrorMessage(null);
    setFormData((prev) => ({ ...prev, [key]: value }));
  };

  const handleSave = async () => {
    setErrorMessage(null);

    // Clamping & Bounds Validation
    const sanitized: EngineSettings = {
      ...formData,
      work_interval_min: Math.max(1, Math.min(180, Number(formData.work_interval_min) || 25)),
      short_break_min: Math.max(1, Math.min(60, Number(formData.short_break_min) || 5)),
      long_break_min: Math.max(1, Math.min(90, Number(formData.long_break_min) || 15)),
      cycles_before_long: Math.max(1, Math.min(12, Number(formData.cycles_before_long) || 4)),
      daily_stand_goal: Math.max(1, Math.min(24, Number(formData.daily_stand_goal) || 8)),
    };

    // Autostart Plugin Sync
    try {
      if (sanitized.start_with_windows) {
        if (!(await isEnabled())) await enable();
      } else {
        if (await isEnabled()) await disable();
      }
    } catch (e) {
      console.warn("Autostart sync warning:", e);
    }

    try {
      await saveSettings(sanitized);
      setErrorMessage(null);
      setSavedFeedback(true);
      setTimeout(() => {
        setSavedFeedback(false);
        setActiveTab("focus");
      }, 600);
    } catch (e) {
      console.error(e);
      setErrorMessage(String(e));
    }
  };

  return (
    <div className="flex flex-col gap-3 py-1 overflow-y-auto max-h-[440px] pr-1">
      {/* 1. Language Dropdown */}
      <div className="p-3 bg-[#161822] border border-[#2A3048] rounded-xl flex items-center justify-between">
        <div className="flex items-center gap-2 text-xs font-semibold text-[#F1F5F9]">
          <Globe className="w-4 h-4 text-[#6366F1]" />
          <span>{t("lbl_language")}</span>
        </div>
        <select
          value={formData.language}
          onChange={(e) => updateField("language", e.target.value)}
          className="bg-[#1F2333] text-xs text-[#F1F5F9] font-medium py-1.5 px-3 rounded-lg border border-[#2A3048] focus:border-[#6366F1] outline-none cursor-pointer"
        >
          <option value="ar">العربية</option>
          <option value="en">English</option>
        </select>
      </div>

      {/* 2. Timer Durations Section */}
      <div className="p-3.5 bg-[#161822] border border-[#2A3048] rounded-xl flex flex-col gap-2.5">
        <div className="flex items-center gap-2 text-xs font-bold text-[#6366F1] mb-1">
          <Clock className="w-4 h-4" />
          <span>{t("sec_durations")}</span>
        </div>

        <div className="grid grid-cols-2 gap-2">
          <div>
            <label className="text-[11px] text-[#94A3B8] font-medium block mb-1">
              {t("lbl_work_min")}
            </label>
            <input
              type="number"
              min={1}
              max={180}
              value={formData.work_interval_min}
              onChange={(e) => updateField("work_interval_min", parseInt(e.target.value) || 1)}
              className="w-full bg-[#1F2333] border border-[#2A3048] rounded-lg py-1.5 px-3 text-xs text-center font-mono font-bold text-[#F1F5F9] focus:border-[#6366F1] outline-none"
            />
          </div>

          <div>
            <label className="text-[11px] text-[#94A3B8] font-medium block mb-1">
              {t("lbl_short_break_min")}
            </label>
            <input
              type="number"
              min={1}
              max={60}
              value={formData.short_break_min}
              onChange={(e) => updateField("short_break_min", parseInt(e.target.value) || 1)}
              className="w-full bg-[#1F2333] border border-[#2A3048] rounded-lg py-1.5 px-3 text-xs text-center font-mono font-bold text-[#F1F5F9] focus:border-[#6366F1] outline-none"
            />
          </div>

          <div>
            <label className="text-[11px] text-[#94A3B8] font-medium block mb-1">
              {t("lbl_long_break_min")}
            </label>
            <input
              type="number"
              min={1}
              max={90}
              value={formData.long_break_min}
              onChange={(e) => updateField("long_break_min", parseInt(e.target.value) || 1)}
              className="w-full bg-[#1F2333] border border-[#2A3048] rounded-lg py-1.5 px-3 text-xs text-center font-mono font-bold text-[#F1F5F9] focus:border-[#6366F1] outline-none"
            />
          </div>

          <div>
            <label className="text-[11px] text-[#94A3B8] font-medium block mb-1">
              {t("lbl_cycles")}
            </label>
            <input
              type="number"
              min={1}
              max={12}
              value={formData.cycles_before_long}
              onChange={(e) => updateField("cycles_before_long", parseInt(e.target.value) || 1)}
              className="w-full bg-[#1F2333] border border-[#2A3048] rounded-lg py-1.5 px-3 text-xs text-center font-mono font-bold text-[#F1F5F9] focus:border-[#6366F1] outline-none"
            />
          </div>
        </div>
      </div>

      {/* 3. Daily Goals Section */}
      <div className="p-3.5 bg-[#161822] border border-[#2A3048] rounded-xl flex items-center justify-between">
        <div className="flex items-center gap-2 text-xs font-semibold text-[#F1F5F9]">
          <Target className="w-4 h-4 text-[#10B981]" />
          <span>{t("lbl_daily_goal")}</span>
        </div>
        <input
          type="number"
          min={1}
          max={24}
          value={formData.daily_stand_goal}
          onChange={(e) => updateField("daily_stand_goal", parseInt(e.target.value) || 8)}
          className="w-16 bg-[#1F2333] border border-[#2A3048] rounded-lg py-1 px-2 text-xs text-center font-mono font-bold text-[#F1F5F9] focus:border-[#6366F1] outline-none"
        />
      </div>

      {/* 4. System Options Section */}
      <div className="p-3.5 bg-[#161822] border border-[#2A3048] rounded-xl flex flex-col gap-2.5">
        <div className="flex items-center gap-2 text-xs font-bold text-[#6366F1] mb-1">
          <SettingsIcon className="w-4 h-4" />
          <span>{t("sec_system")}</span>
        </div>

        <label className="flex items-center justify-between text-xs text-[#F1F5F9] font-medium cursor-pointer">
          <div className="flex items-center gap-2">
            <Volume2 className="w-4 h-4 text-[#94A3B8]" />
            <span>{t("lbl_sound")}</span>
          </div>
          <input
            type="checkbox"
            checked={formData.sound_enabled}
            onChange={(e) => updateField("sound_enabled", e.target.checked)}
            className="w-4 h-4 accent-[#6366F1] rounded cursor-pointer"
          />
        </label>

        <label className="flex items-center justify-between text-xs text-[#F1F5F9] font-medium cursor-pointer">
          <div className="flex items-center gap-2">
            <Power className="w-4 h-4 text-[#94A3B8]" />
            <span>{t("lbl_startup")}</span>
          </div>
          <input
            type="checkbox"
            checked={formData.start_with_windows}
            onChange={(e) => updateField("start_with_windows", e.target.checked)}
            className="w-4 h-4 accent-[#6366F1] rounded cursor-pointer"
          />
        </label>

        <label className="flex items-center justify-between text-xs text-[#F1F5F9] font-medium cursor-pointer">
          <div className="flex items-center gap-2">
            <Minimize2 className="w-4 h-4 text-[#6366F1]" />
            <div>
              <span className="block">{t("lbl_auto_pill", "البدء بالشريط العائم تلقائياً")}</span>
              <span className="text-[10px] text-[#94A3B8] font-normal block">
                {t("desc_auto_pill", "تشغيل التطبيق في الشريط العائم الملتصق بالطرف")}
              </span>
            </div>
          </div>
          <input
            type="checkbox"
            checked={formData.auto_pill_mode}
            onChange={(e) => updateField("auto_pill_mode", e.target.checked)}
            className="w-4 h-4 accent-[#6366F1] rounded cursor-pointer"
          />
        </label>

        <div className="pt-1 border-t border-[#2A3048]/50 flex flex-col gap-2">
          <label className="flex items-start justify-between text-xs text-[#F1F5F9] font-medium cursor-pointer gap-2">
            <div className="flex items-start gap-2">
              <Layout className="w-4 h-4 text-[#6366F1] mt-0.5 flex-shrink-0" />
              <div>
                <span className="block font-semibold">{t("lbl_tiling_wm")}</span>
                <span className="text-[10px] text-[#94A3B8] font-normal leading-relaxed block mt-0.5">
                  {t("desc_tiling_wm")}
                </span>
              </div>
            </div>
            <input
              type="checkbox"
              checked={formData.tiling_wm_mode}
              onChange={(e) => updateField("tiling_wm_mode", e.target.checked)}
              className="w-4 h-4 accent-[#6366F1] rounded cursor-pointer mt-0.5 flex-shrink-0"
            />
          </label>

          <label className="flex items-start justify-between text-xs text-[#F1F5F9] font-medium cursor-pointer gap-2">
            <div className="flex items-start gap-2">
              <Magnet className="w-4 h-4 text-[#10B981] mt-0.5 flex-shrink-0" />
              <div>
                <span className="block font-semibold">{t("lbl_pill_snapping")}</span>
                <span className="text-[10px] text-[#94A3B8] font-normal leading-relaxed block mt-0.5">
                  {t("desc_pill_snapping")}
                </span>
              </div>
            </div>
            <input
              type="checkbox"
              disabled={formData.tiling_wm_mode}
              checked={!formData.tiling_wm_mode && formData.pill_dock_snapping}
              onChange={(e) => updateField("pill_dock_snapping", e.target.checked)}
              className="w-4 h-4 accent-[#6366F1] rounded cursor-pointer mt-0.5 flex-shrink-0 disabled:opacity-40"
            />
          </label>
        </div>
      </div>

      {/* Error Message */}
      {errorMessage && (
        <div className="p-3 bg-red-950/40 border border-red-800/60 rounded-xl flex items-center gap-2.5 text-xs text-red-200">
          <AlertCircle className="w-4 h-4 text-red-400 flex-shrink-0" />
          <span className="leading-snug">{errorMessage}</span>
        </div>
      )}

      {/* 5. Save Button */}
      <button
        onClick={handleSave}
        className="w-full flex items-center justify-center gap-2 py-3 px-4 rounded-xl bg-[#6366F1] hover:bg-[#4F46E5] text-white font-bold text-sm shadow-lg shadow-[#6366F1]/20 transition-all active:scale-[0.98] cursor-pointer mt-1"
      >
        {savedFeedback ? <Check className="w-4 h-4 text-[#10B981]" /> : null}
        <span>{savedFeedback ? t("msg_saved") : t("btn_save")}</span>
      </button>
    </div>
  );
};
