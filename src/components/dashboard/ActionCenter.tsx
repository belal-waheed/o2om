import React from "react";
import { useTranslation } from "react-i18next";
import {
  Play,
  Pause,
  RotateCcw,
  Activity,
  Coffee,
  Clock,
  Minimize2,
  CheckCircle2,
} from "lucide-react";
import { useShallow } from "zustand/react/shallow";
import { useTimerStore } from "../../stores/useTimerStore";
import { cn } from "../../lib/utils";

export const ActionCenter: React.FC = () => {
  const { t } = useTranslation();
  const {
    snapshot,
    startWork,
    startBreak,
    skipBreak,
    togglePause,
    resetTimer,
    snoozeTimer,
    setPillMode,
  } = useTimerStore(
    useShallow((state) => ({
      snapshot: state.snapshot,
      startWork: state.startWork,
      startBreak: state.startBreak,
      skipBreak: state.skipBreak,
      togglePause: state.togglePause,
      resetTimer: state.resetTimer,
      snoozeTimer: state.snoozeTimer,
      setPillMode: state.setPillMode,
    }))
  );

  const status = snapshot?.status || "work";
  const isPaused = snapshot?.is_paused || false;

  return (
    <div className="flex flex-col gap-2 mt-auto pt-2">
      {/* 1. Normal Work State */}
      {(status === "work" || status === "paused" || status === "idle") && (
        <div className="grid grid-cols-2 gap-2">
          <button
            onClick={togglePause}
            className={cn(
              "flex items-center justify-center gap-2 py-3 px-4 rounded-xl font-bold text-sm shadow-lg transition-all active:scale-[0.98] cursor-pointer",
              "bg-[#6366F1] hover:bg-[#4F46E5] text-white shadow-[#6366F1]/20"
            )}
          >
            {isPaused ? <Play className="w-4 h-4" /> : <Pause className="w-4 h-4" />}
            <span>{t(isPaused ? "btn_resume" : "btn_pause")}</span>
          </button>

          <button
            onClick={resetTimer}
            className={cn(
              "flex items-center justify-center gap-2 py-3 px-4 rounded-xl font-bold text-sm border border-[#2A3048] transition-all active:scale-[0.98] cursor-pointer",
              "bg-[#1F2333] hover:bg-[#2A3048] text-[#F1F5F9]"
            )}
          >
            <RotateCcw className="w-4 h-4 text-[#94A3B8]" />
            <span>{t("btn_reset")}</span>
          </button>
        </div>
      )}

      {/* 2. Break Prompt State (Waiting Break) */}
      {status === "waiting_break" && (
        <div className="flex flex-col gap-2">
          <button
            onClick={() => startBreak(true)}
            className={cn(
              "flex items-center justify-center gap-2 py-3.5 px-4 rounded-xl font-bold text-sm shadow-lg transition-all active:scale-[0.98] cursor-pointer animate-pulse",
              "bg-[#10B981] hover:bg-[#059669] text-white shadow-[#10B981]/25"
            )}
          >
            <Activity className="w-4 h-4" />
            <span>{t("btn_start_exercises", "بدء الاستراحة والتمارين")}</span>
          </button>

          <div className="grid grid-cols-2 gap-2">
            <button
              onClick={() => startBreak(false)}
              className={cn(
                "flex items-center justify-center gap-1.5 py-2.5 px-3 rounded-xl font-semibold text-xs border border-[#2A3048] transition-all cursor-pointer",
                "bg-[#1F2333] hover:bg-[#2A3048] text-[#F1F5F9]"
              )}
            >
              <Coffee className="w-3.5 h-3.5 text-[#10B981]" />
              <span>{t("btn_quiet_break", "استراحة هادئة")}</span>
            </button>

            <button
              onClick={snoozeTimer}
              className={cn(
                "flex items-center justify-center gap-1.5 py-2.5 px-3 rounded-xl font-semibold text-xs border border-[#2A3048] transition-all cursor-pointer",
                "bg-[#1F2333] hover:bg-[#2A3048] text-[#F1F5F9]"
              )}
            >
              <Clock className="w-3.5 h-3.5 text-[#F59E0B]" />
              <span>{t("btn_snooze", "تأجيل 5 دقائق")}</span>
            </button>
          </div>
        </div>
      )}

      {/* 3. Waiting Work State (Post-Break) */}
      {status === "waiting_work" && (
        <button
          onClick={startWork}
          className={cn(
            "flex items-center justify-center gap-2 py-3.5 px-4 rounded-xl font-bold text-sm shadow-xl transition-all active:scale-[0.98] cursor-pointer animate-pulse",
            "bg-[#6366F1] hover:bg-[#4F46E5] text-white shadow-[#6366F1]/30"
          )}
        >
          <Play className="w-4 h-4" />
          <span>{t("btn_start_work", "بدء جلسة التركيز")}</span>
        </button>
      )}

      {/* 4. On Break State */}
      {status === "on_break" && (
        <div className="grid grid-cols-2 gap-2">
          <button
            onClick={skipBreak}
            className={cn(
              "flex items-center justify-center gap-2 py-3 px-4 rounded-xl font-bold text-sm shadow-md cursor-pointer",
              "bg-[#10B981] hover:bg-[#059669] text-white shadow-[#10B981]/20"
            )}
          >
            <CheckCircle2 className="w-4 h-4" />
            <span>{t("btn_finish_break", "إنهاء الاستراحة")}</span>
          </button>

          <button
            onClick={resetTimer}
            className={cn(
              "flex items-center justify-center gap-2 py-3 px-4 rounded-xl font-bold text-sm border border-[#2A3048] cursor-pointer",
              "bg-[#1F2333] hover:bg-[#2A3048] text-[#F1F5F9]"
            )}
          >
            <RotateCcw className="w-4 h-4 text-[#94A3B8]" />
            <span>{t("btn_reset")}</span>
          </button>
        </div>
      )}

      {/* 5. Bottom Floating Mini-Pill Dock Button */}
      <button
        onClick={() => setPillMode(true)}
        className={cn(
          "w-full flex items-center justify-center gap-1.5 py-2 px-3 rounded-xl font-medium text-xs border border-[#2A3048] transition-all cursor-pointer",
          "bg-[#161822] hover:bg-[#1F2333] text-[#94A3B8] hover:text-[#F1F5F9]"
        )}
      >
        <Minimize2 className="w-3.5 h-3.5" />
        <span>{t("btn_dock_pill", "تصغير إلى شريط عائم")}</span>
      </button>
    </div>
  );
};
