import React from "react";
import { useTranslation } from "react-i18next";
import { useTimerStore } from "../../stores/useTimerStore";

export const TabularTimer: React.FC = () => {
  const { t } = useTranslation();
  const { snapshot } = useTimerStore();

  const formattedTime = snapshot?.formatted_remaining || "25:00";
  const status = snapshot?.status || "work";
  const currentCycle = snapshot?.current_cycle || 1;
  const totalCycles = snapshot?.total_cycles || 4;

  let statusText = t("status_focus_active");
  let statusColor = "text-[#6366F1]";
  let dotBg = "bg-[#6366F1]";

  if (status === "on_break") {
    statusText = t("status_on_break");
    statusColor = "text-[#10B981]";
    dotBg = "bg-[#10B981]";
  } else if (status === "waiting_break") {
    statusText = t("status_waiting_break");
    statusColor = "text-[#F43F5E]";
    dotBg = "bg-[#F43F5E]";
  } else if (status === "waiting_work") {
    statusText = t("status_waiting_work");
    statusColor = "text-[#10B981]";
    dotBg = "bg-[#10B981]";
  } else if (status === "paused") {
    statusText = t("status_paused");
    statusColor = "text-[#F59E0B]";
    dotBg = "bg-[#F59E0B]";
  } else if (status === "idle") {
    statusText = t("status_idle");
    statusColor = "text-[#F59E0B]";
    dotBg = "bg-[#F59E0B]";
  }

  return (
    <div className="flex flex-col items-center justify-center my-3">
      {/* Cycle Badge & Status */}
      <div className="flex items-center gap-2 mb-1 px-3 py-0.5 rounded-full bg-[#161822] border border-[#2A3048]">
        <span className={`w-2 h-2 rounded-full ${dotBg} animate-pulse`} />
        <span className={`text-xs font-bold ${statusColor}`}>{statusText}</span>
        <span className="text-[10px] text-[#64748B] font-mono">
          {t("status_cycle", { current: currentCycle, total: totalCycles })}
        </span>
      </div>

      {/* Large Tabular Digital Countdown */}
      <div
        className="text-6xl font-extrabold tracking-tight text-[#F1F5F9] my-1 select-none font-mono"
        style={{
          fontVariantNumeric: "tabular-nums",
          fontFeatureSettings: '"tnum"',
        }}
      >
        {formattedTime}
      </div>
    </div>
  );
};
