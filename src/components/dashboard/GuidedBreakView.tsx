import React, { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import {
  ChevronLeft,
  ChevronRight,
  Pause,
  Play,
  CheckCircle2,
  X,
} from "lucide-react";
import { useTimerStore } from "../../stores/useTimerStore";
import { tauriApi, type ExerciseStep } from "../../lib/ipc";

export const GuidedBreakView: React.FC = () => {
  const { i18n, t } = useTranslation();
  const isAr = i18n.language === "ar";
  const { snapshot, skipBreak, togglePause } = useTimerStore();

  const [routine, setRoutine] = useState<ExerciseStep[]>([]);
  const [currentStepIdx, setCurrentStepIdx] = useState<number>(0);
  const [stepSecondsLeft, setStepSecondsLeft] = useState<number>(30);
  const isPaused = snapshot?.is_paused || false;

  useEffect(() => {
    tauriApi.getExerciseRoutine().then((steps) => {
      if (steps && steps.length > 0) {
        setRoutine(steps);
        setCurrentStepIdx(0);
        setStepSecondsLeft(steps[0].duration_sec);
      }
    });
  }, []);

  // Step countdown tick
  useEffect(() => {
    if (isPaused || routine.length === 0) return;

    const timer = setInterval(() => {
      setStepSecondsLeft((prev) => {
        if (prev <= 1) {
          if (currentStepIdx < routine.length - 1) {
            const nextIdx = currentStepIdx + 1;
            setCurrentStepIdx(nextIdx);
            tauriApi.playStepTransition();
            return routine[nextIdx].duration_sec;
          }
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(timer);
  }, [currentStepIdx, routine, isPaused]);

  const handleNextStep = () => {
    if (currentStepIdx < routine.length - 1) {
      const nextIdx = currentStepIdx + 1;
      setCurrentStepIdx(nextIdx);
      setStepSecondsLeft(routine[nextIdx].duration_sec);
      tauriApi.playStepTransition();
    } else {
      skipBreak();
      tauriApi.closeBreakOverlay();
    }
  };

  const handlePrevStep = () => {
    if (currentStepIdx > 0) {
      const prevIdx = currentStepIdx - 1;
      setCurrentStepIdx(prevIdx);
      setStepSecondsLeft(routine[prevIdx].duration_sec);
    }
  };

  const currentStep = routine[currentStepIdx];
  const stepProgress = currentStep
    ? Math.round(((currentStep.duration_sec - stepSecondsLeft) / currentStep.duration_sec) * 100)
    : 0;

  return (
    <div className="flex flex-col h-full bg-[#0D0E15] text-[#F1F5F9] p-3.5 gap-2.5 select-none">
      {/* Header Bar */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <span className="w-2.5 h-2.5 rounded-full bg-[#10B981] animate-pulse" />
          <div>
            <h2 className="text-xs font-bold text-[#F1F5F9] leading-tight">
              {t("break_guide_title", "دليل الاستطالة والراحة")}
            </h2>
            <p className="text-[10px] text-[#94A3B8]">
              {t("step_counter", {
                current: currentStepIdx + 1,
                total: routine.length || 5,
                defaultValue: `الخطوة ${currentStepIdx + 1} من ${routine.length || 5}`,
              })}
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <div className="tabular-timer px-2 py-0.5 rounded-md bg-[#161822] border border-[#2A3048] text-xs font-bold text-[#10B981] font-mono">
            {snapshot?.formatted_remaining || "05:00"}
          </div>
          <button
            onClick={() => {
              skipBreak();
              tauriApi.closeBreakOverlay();
            }}
            className="p-1 rounded-lg text-[#94A3B8] hover:text-[#F1F5F9] hover:bg-[#1F2333] transition-colors cursor-pointer"
            title={t("end_break", "إنهاء الاستراحة")}
          >
            <X className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>

      {/* 16:9 Clean Exercise Illustration Card */}
      <div className="relative w-full aspect-16/9 bg-[#161822] rounded-xl overflow-hidden border border-[#2A3048] flex items-center justify-center shadow-md">
        <img
          src="/assets/exercises_bg.png"
          alt="Desk Ergonomics Exercises"
          className="w-full h-full object-cover object-center"
          onError={(e) => {
            (e.target as HTMLElement).style.display = "none";
          }}
        />
        <div className="absolute top-2 end-2 bg-[#0D0E15]/90 backdrop-blur-sm px-2 py-0.5 rounded-md border border-[#2A3048] flex items-center gap-1.5">
          <span className="w-1.5 h-1.5 rounded-full bg-[#10B981]" />
          <span className="text-[11px] font-bold text-[#F1F5F9]">
            {currentStep ? (isAr ? currentStep.name_ar : currentStep.name_en) : ""}
          </span>
        </div>
      </div>

      {/* Step Description & Countdown */}
      {currentStep && (
        <div className="bg-[#161822] rounded-xl p-2.5 border border-[#2A3048] flex flex-col gap-1.5">
          <div className="flex items-center justify-between">
            <h3 className="text-xs font-bold text-[#F1F5F9]">
              {isAr ? currentStep.name_ar : currentStep.name_en}
            </h3>
            <span className="tabular-timer text-xs font-black text-[#10B981] font-mono">
              {String(Math.floor(stepSecondsLeft / 60)).padStart(2, "0")}:
              {String(stepSecondsLeft % 60).padStart(2, "0")}
            </span>
          </div>

          <p className="text-[11px] text-[#94A3B8] leading-relaxed">
            {isAr ? currentStep.desc_ar : currentStep.desc_en}
          </p>

          <div className="w-full h-1 bg-[#1F2333] rounded-full overflow-hidden mt-0.5">
            <div
              className="h-full bg-[#10B981] transition-all duration-300 rounded-full"
              style={{ width: `${stepProgress}%` }}
            />
          </div>
        </div>
      )}

      {/* Step Navigation Controls */}
      <div className="grid grid-cols-3 gap-2 mt-auto">
        <button
          onClick={handlePrevStep}
          disabled={currentStepIdx === 0}
          className="flex items-center justify-center gap-1 py-2 px-2.5 rounded-xl text-xs font-semibold bg-[#161822] border border-[#2A3048] text-[#94A3B8] hover:text-[#F1F5F9] hover:bg-[#1F2333] disabled:opacity-30 disabled:pointer-events-none transition-all cursor-pointer"
        >
          {isAr ? <ChevronRight className="w-3.5 h-3.5" /> : <ChevronLeft className="w-3.5 h-3.5" />}
          <span>{t("prev_step", "السابق")}</span>
        </button>

        <button
          onClick={() => togglePause()}
          className="flex items-center justify-center gap-1 py-2 px-2.5 rounded-xl text-xs font-bold bg-[#1F2333] border border-[#2A3048] text-[#F1F5F9] hover:bg-[#262B3F] transition-all cursor-pointer"
        >
          {isPaused ? <Play className="w-3.5 h-3.5 text-[#10B981]" /> : <Pause className="w-3.5 h-3.5 text-[#F59E0B]" />}
          <span>{isPaused ? t("resume", "استئناف") : t("pause", "إيقاف")}</span>
        </button>

        <button
          onClick={handleNextStep}
          className="flex items-center justify-center gap-1 py-2 px-2.5 rounded-xl text-xs font-bold bg-[#10B981] text-white hover:bg-[#059669] shadow-sm shadow-[#10B981]/20 transition-all cursor-pointer"
        >
          <span>
            {currentStepIdx === routine.length - 1 ? t("finish", "إنهاء") : t("next_step", "التالي")}
          </span>
          {currentStepIdx === routine.length - 1 ? (
            <CheckCircle2 className="w-3.5 h-3.5" />
          ) : isAr ? (
            <ChevronLeft className="w-3.5 h-3.5" />
          ) : (
            <ChevronRight className="w-3.5 h-3.5" />
          )}
        </button>
      </div>
    </div>
  );
};
