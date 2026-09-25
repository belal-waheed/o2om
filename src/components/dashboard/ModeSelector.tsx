import React from "react";
import { useTranslation } from "react-i18next";
import { useShallow } from "zustand/react/shallow";
import { useTimerStore } from "../../stores/useTimerStore";
import { cn } from "../../lib/utils";

export const ModeSelector: React.FC = () => {
  const { t } = useTranslation();
  const { snapshot, settings } = useTimerStore(
    useShallow((state) => ({
      snapshot: state.snapshot,
      settings: state.settings,
    }))
  );

  const currentCycle = snapshot?.current_cycle || 1;
  const totalCycles = snapshot?.total_cycles || 4;
  const workMin = settings?.work_interval_min || 25;
  const breakMin = snapshot?.is_long_break_next
    ? (settings?.long_break_min || 15)
    : (settings?.short_break_min || 5);

  return (
    <div className="flex items-center justify-between px-3 py-2 bg-[#161822] rounded-xl border border-[#2A3048]">
      <span className="text-xs font-semibold text-[#F1F5F9] tracking-wide">
        {t("focus_session_title", "جلسة التركيز والوقوف")}
      </span>

      <div className="flex items-center gap-2.5">
        <span className="text-[11px] font-medium text-[#94A3B8] bg-[#1F2333] px-2 py-0.5 rounded-md border border-[#2A3048]/60 font-mono">
          {workMin}m / {breakMin}m
        </span>
        <div className="flex items-center gap-1.5" title={`${currentCycle} / ${totalCycles}`}>
          {Array.from({ length: totalCycles }).map((_, i) => (
            <div
              key={i}
              className={cn(
                "w-1.5 h-1.5 rounded-full transition-all duration-200",
                i + 1 === currentCycle && "bg-[#6366F1] scale-125 ring-2 ring-[#6366F1]/30",
                i + 1 < currentCycle && "bg-[#10B981]",
                i + 1 > currentCycle && "bg-[#2A3048]"
              )}
            />
          ))}
        </div>
      </div>
    </div>
  );
};
