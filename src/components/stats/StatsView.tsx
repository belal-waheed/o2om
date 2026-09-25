import React, { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import {
  CheckCircle2,
  Clock,
  Activity,
  TrendingUp,
  RotateCcw,
  BarChart3,
} from "lucide-react";
import { useShallow } from "zustand/react/shallow";
import { useTimerStore } from "../../stores/useTimerStore";
import { tauriApi, type DailyHealthRecord } from "../../lib/ipc";

export const StatsView: React.FC = () => {
  const { t, i18n } = useTranslation();
  const isAr = i18n.language === "ar";
  const { healthSummary, resetStats, refreshStats } = useTimerStore(
    useShallow((state) => ({
      healthSummary: state.healthSummary,
      resetStats: state.resetStats,
      refreshStats: state.refreshStats,
    }))
  );
  const [weeklyHistory, setWeeklyHistory] = useState<DailyHealthRecord[]>([]);

  useEffect(() => {
    refreshStats();
    tauriApi.getWeeklyHistory().then(setWeeklyHistory).catch(console.error);
  }, [refreshStats]);

  const handleResetWithConfirm = async () => {
    if (window.confirm(t("msg_reset_confirm"))) {
      await resetStats();
      const updated = await tauriApi.getWeeklyHistory();
      setWeeklyHistory(updated);
    }
  };

  const formatMins = (mins: number) => {
    const h = Math.floor(mins / 60);
    const m = mins % 60;
    if (h > 0) return `${h}h ${m}m`;
    return `${m}m`;
  };

  const todayStands = healthSummary?.today_stands ?? 0;
  const goal = healthSummary?.daily_stand_goal ?? 8;
  const todayFocus = healthSummary?.today_focus_minutes ?? 0;
  const currentStreak = healthSummary?.current_streak_days ?? 0;
  const bestStreak = healthSummary?.best_streak_days ?? 0;
  const totalStands = healthSummary?.total_stands_all_time ?? 0;
  const totalFocus = healthSummary?.total_focus_minutes_all_time ?? 0;

  const daysUnit = isAr ? "أيام" : "days";

  return (
    <div className="flex flex-col gap-3 py-1 overflow-y-auto max-h-[440px] pr-1 select-none">
      {/* 1. Metric Cards Grid */}
      <div className="grid grid-cols-2 gap-2">
        {/* Today Stands */}
        <div className="p-3 bg-[#161822] border border-[#2A3048] rounded-xl flex items-center gap-3">
          <div className="p-2 rounded-lg bg-[#6366F1]/10 text-[#6366F1]">
            <CheckCircle2 className="w-4 h-4" />
          </div>
          <div>
            <div className="text-[11px] text-[#94A3B8] font-medium">{t("stats_today_stands")}</div>
            <div className="text-base font-bold text-[#F1F5F9] font-mono select-text">
              {todayStands} <span className="text-xs text-[#64748B]">/ {goal}</span>
            </div>
          </div>
        </div>

        {/* Today Focus */}
        <div className="p-3 bg-[#161822] border border-[#2A3048] rounded-xl flex items-center gap-3">
          <div className="p-2 rounded-lg bg-[#10B981]/10 text-[#10B981]">
            <Clock className="w-4 h-4" />
          </div>
          <div>
            <div className="text-[11px] text-[#94A3B8] font-medium">{t("stats_focus_today")}</div>
            <div className="text-base font-bold text-[#F1F5F9] font-mono select-text">
              {formatMins(todayFocus)}
            </div>
          </div>
        </div>

        {/* Current Streak */}
        <div className="p-3 bg-[#161822] border border-[#2A3048] rounded-xl flex items-center gap-3">
          <div className="p-2 rounded-lg bg-[#F59E0B]/10 text-[#F59E0B]">
            <Activity className="w-4 h-4" />
          </div>
          <div>
            <div className="text-[11px] text-[#94A3B8] font-medium">{t("stats_current_streak")}</div>
            <div className="text-base font-bold text-[#F59E0B] font-mono select-text">
              {currentStreak} <span className="text-xs text-[#64748B] font-sans">{daysUnit}</span>
            </div>
          </div>
        </div>

        {/* Best Streak */}
        <div className="p-3 bg-[#161822] border border-[#2A3048] rounded-xl flex items-center gap-3">
          <div className="p-2 rounded-lg bg-[#06B6D4]/10 text-[#06B6D4]">
            <TrendingUp className="w-4 h-4" />
          </div>
          <div>
            <div className="text-[11px] text-[#94A3B8] font-medium">{t("stats_best_streak")}</div>
            <div className="text-base font-bold text-[#F1F5F9] font-mono select-text">
              {bestStreak} <span className="text-xs text-[#64748B] font-sans">{daysUnit}</span>
            </div>
          </div>
        </div>
      </div>

      {/* 2. Lifetime Totals */}
      <div className="p-3 bg-[#161822] border border-[#2A3048] rounded-xl flex justify-around">
        <div className="text-center">
          <div className="text-[11px] text-[#94A3B8]">{t("stats_total_stands")}</div>
          <div className="text-sm font-bold text-[#F1F5F9] font-mono mt-0.5 select-text">{totalStands}</div>
        </div>
        <div className="w-[1px] bg-[#2A3048]" />
        <div className="text-center">
          <div className="text-[11px] text-[#94A3B8]">{t("stats_total_focus")}</div>
          <div className="text-sm font-bold text-[#F1F5F9] font-mono mt-0.5 select-text">{formatMins(totalFocus)}</div>
        </div>
      </div>

      {/* 3. Weekly History Activity */}
      <div className="p-3.5 bg-[#161822] border border-[#2A3048] rounded-xl">
        <div className="flex items-center gap-2 mb-3 text-xs font-bold text-[#F1F5F9]">
          <BarChart3 className="w-4 h-4 text-[#6366F1]" />
          <span>{t("stats_weekly_activity")}</span>
        </div>

        {weeklyHistory.length === 0 ? (
          <div className="text-xs text-[#64748B] text-center py-4">
            {isAr ? "لا توجد سجلات أسبوعية سابقة حتى الآن." : "No previous weekly records yet."}
          </div>
        ) : (
          <div className="flex items-end justify-between gap-1.5 h-24 pt-4 px-1">
            {weeklyHistory.map((rec) => {
              const maxStands = Math.max(...weeklyHistory.map((r) => r.stands_count), goal, 1);
              const heightPct = Math.min(100, Math.round((rec.stands_count / maxStands) * 100));
              const dayLabel = rec.date.slice(5); // MM-DD

              return (
                <div key={rec.date} className="flex-1 flex flex-col items-center gap-1 group">
                  <div className="text-[10px] font-mono text-[#94A3B8] group-hover:text-white">
                    {rec.stands_count}
                  </div>
                  <div className="w-full bg-[#1F2333] rounded-t-md h-16 flex items-end overflow-hidden">
                    <div
                      className={`w-full rounded-t-md transition-all duration-300 ${
                        rec.goal_met ? "bg-[#10B981]" : "bg-[#6366F1]"
                      }`}
                      style={{ height: `${heightPct}%` }}
                    />
                  </div>
                  <div className="text-[9px] text-[#64748B] font-mono truncate">{dayLabel}</div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* 4. Reset Stats Button */}
      <button
        onClick={handleResetWithConfirm}
        className="w-full flex items-center justify-center gap-2 py-2 px-3 rounded-xl bg-[#1F2333] hover:bg-[#F43F5E]/15 hover:text-[#F43F5E] text-[#94A3B8] font-semibold text-xs border border-[#2A3048] transition-all cursor-pointer mt-1"
      >
        <RotateCcw className="w-3.5 h-3.5" />
        <span>{t("btn_reset_stats")}</span>
      </button>
    </div>
  );
};
