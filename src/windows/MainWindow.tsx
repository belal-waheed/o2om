import React, { useEffect } from "react";
import { useTranslation } from "react-i18next";
import { Timer, BarChart3, Settings } from "lucide-react";
import { useTimerStore } from "../stores/useTimerStore";
import { ModeSelector } from "../components/dashboard/ModeSelector";
import { TabularTimer } from "../components/dashboard/TabularTimer";
import { ProgressBar } from "../components/dashboard/ProgressBar";
import { StreakBadge } from "../components/dashboard/StreakBadge";
import { ActionCenter } from "../components/dashboard/ActionCenter";
import { StatsView } from "../components/stats/StatsView";
import { SettingsView } from "../components/settings/SettingsView";

export const MainWindow: React.FC = () => {
  const { t } = useTranslation();
  const { activeTab, setActiveTab, initStore } = useTimerStore();

  useEffect(() => {
    initStore();
  }, [initStore]);

  // Main Dashboard View
  return (
    <div className="w-full h-screen bg-[#0D0E15] flex flex-col p-3.5 select-none overflow-hidden justify-between">
      {/* Header Navigation Bar */}
      <div className="flex items-center justify-between pb-2.5 border-b border-[#2A3048]/60">
        <div className="flex items-center gap-2">
          <span className="w-2 h-2 rounded-full bg-[#6366F1]" />
          <h1 className="text-xs font-bold text-[#F1F5F9] tracking-tight">{t("app_title")}</h1>
        </div>

        {/* Tab Buttons */}
        <div className="flex items-center gap-1 bg-[#161822] p-0.5 rounded-xl border border-[#2A3048]">
          <button
            onClick={() => setActiveTab("focus")}
            className={`flex items-center gap-1 py-1 px-2.5 rounded-lg text-xs font-semibold transition-all cursor-pointer ${
              activeTab === "focus"
                ? "bg-[#6366F1] text-white shadow-sm"
                : "text-[#94A3B8] hover:text-[#F1F5F9]"
            }`}
          >
            <Timer className="w-3.5 h-3.5" />
            <span>{t("nav_focus")}</span>
          </button>

          <button
            onClick={() => setActiveTab("stats")}
            className={`flex items-center gap-1 py-1 px-2.5 rounded-lg text-xs font-semibold transition-all cursor-pointer ${
              activeTab === "stats"
                ? "bg-[#6366F1] text-white shadow-sm"
                : "text-[#94A3B8] hover:text-[#F1F5F9]"
            }`}
          >
            <BarChart3 className="w-3.5 h-3.5" />
            <span>{t("nav_stats")}</span>
          </button>

          <button
            onClick={() => setActiveTab("settings")}
            className={`flex items-center gap-1 py-1 px-2.5 rounded-lg text-xs font-semibold transition-all cursor-pointer ${
              activeTab === "settings"
                ? "bg-[#6366F1] text-white shadow-sm"
                : "text-[#94A3B8] hover:text-[#F1F5F9]"
            }`}
          >
            <Settings className="w-3.5 h-3.5" />
            <span>{t("nav_settings")}</span>
          </button>
        </div>
      </div>

      {/* Main Content Body */}
      <div className="flex-1 flex flex-col justify-between pt-2">
        {activeTab === "focus" && (
          <div className="flex flex-col justify-between h-full gap-2">
            <ModeSelector />
            <TabularTimer />
            <ProgressBar />
            <StreakBadge />
            <ActionCenter />
          </div>
        )}

        {activeTab === "stats" && <StatsView />}

        {activeTab === "settings" && <SettingsView />}
      </div>
    </div>
  );
};
