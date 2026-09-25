import React from "react";
import { useTranslation } from "react-i18next";
import { useShallow } from "zustand/react/shallow";
import { useTimerStore } from "../../stores/useTimerStore";

export const StreakBadge: React.FC = () => {
  const { t, i18n } = useTranslation();
  const isAr = i18n.language === "ar";
  const { healthSummary, setActiveTab } = useTimerStore(
    useShallow((state) => ({
      healthSummary: state.healthSummary,
      setActiveTab: state.setActiveTab,
    }))
  );

  const todayStands = healthSummary?.today_stands ?? 0;
  const goal = healthSummary?.daily_stand_goal ?? 8;
  const streak = healthSummary?.current_streak_days ?? 0;
  const isGoalMet = todayStands >= goal;

  const streakUnit = isAr ? "يوم" : "days";

  return (
    <button
      onClick={() => setActiveTab("stats")}
      className="w-full flex items-center justify-between px-3.5 py-2 bg-[#161822] hover:bg-[#1F2333] border border-[#2A3048] rounded-xl transition-all duration-150 cursor-pointer group"
    >
      <div className="flex items-center gap-2">
        <span
          className={`w-2 h-2 rounded-full ${
            isGoalMet ? "bg-[#10B981]" : "bg-[#6366F1]"
          }`}
        />
        <span className="text-xs font-semibold text-[#F1F5F9]">
          {todayStands} / {goal} {t("stats_today_stands", "جلسات اليوم")}
        </span>
      </div>

      <div className="flex items-center gap-1.5 px-2.5 py-0.5 rounded-md bg-[#1F2333] border border-[#2A3048]">
        <span className="text-xs font-bold text-[#F59E0B] font-mono">{streak}</span>
        <span className="text-[11px] font-medium text-[#94A3B8]">{streakUnit}</span>
      </div>
    </button>
  );
};
