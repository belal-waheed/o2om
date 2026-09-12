import React from "react";
import { useTimerStore } from "../../stores/useTimerStore";

export const ProgressBar: React.FC = () => {
  const { snapshot } = useTimerStore();
  const progress = snapshot?.progress_percent ?? 0;
  const status = snapshot?.status || "work";

  const barColor =
    status === "on_break"
      ? "bg-gradient-to-r from-[#10B981] to-[#059669]"
      : status === "waiting_break"
      ? "bg-[#F43F5E]"
      : status === "paused" || status === "idle"
      ? "bg-[#F59E0B]"
      : "bg-gradient-to-r from-[#6366F1] to-[#4F46E5]";

  return (
    <div className="w-full px-6 mb-3">
      <div className="w-full h-1.5 bg-[#1F2333] rounded-full overflow-hidden border border-[#2A3048]/50">
        <div
          className={`h-full ${barColor} transition-all duration-300 ease-out rounded-full`}
          style={{ width: `${progress}%` }}
        />
      </div>
    </div>
  );
};
