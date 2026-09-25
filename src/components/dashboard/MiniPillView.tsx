import React from "react";
import { useTranslation } from "react-i18next";
import { Play, Pause, Maximize2, GripVertical } from "lucide-react";
import { useShallow } from "zustand/react/shallow";
import { useTimerStore } from "../../stores/useTimerStore";
import { cn } from "../../lib/utils";

export const MiniPillView: React.FC = () => {
  const { t } = useTranslation();
  const { snapshot, togglePause, setPillMode, dockInfo, setPillTucked } = useTimerStore(
    useShallow((state) => ({
      snapshot: state.snapshot,
      togglePause: state.togglePause,
      setPillMode: state.setPillMode,
      dockInfo: state.dockInfo,
      setPillTucked: state.setPillTucked,
    }))
  );

  const isPaused = snapshot?.is_paused || false;
  const isBreak = snapshot?.status === "on_break";
  const timerText = snapshot?.formatted_remaining || "25:00";

  const getStatusDotColor = () => {
    if (isPaused) return "#F59E0B";
    if (isBreak) return "#10B981";
    return "#6366F1";
  };

  // If tucked to screen edge, render sleek translucent indicator aligned to the visible edge
  if (dockInfo?.is_tucked) {
    const edge = dockInfo.edge;
    const alignmentClass = cn(
      "items-center justify-center",
      edge === "right" && "items-center justify-start",
      edge === "left" && "items-center justify-end",
      edge === "top" && "items-end justify-center",
      edge === "bottom" && "items-start justify-center"
    );

    const tabShape = cn(
      "rounded-xl",
      edge === "right" && "rounded-l-xl border-r-0",
      edge === "left" && "rounded-r-xl border-l-0",
      edge === "top" && "rounded-b-xl border-t-0",
      edge === "bottom" && "rounded-t-xl border-b-0"
    );

    return (
      <div
        onClick={() => setPillTucked(false)}
        className={cn("w-full h-full flex bg-transparent select-none cursor-pointer", alignmentClass)}
        title={t("app_title")}
      >
        <div
          className={cn(
            "w-[26px] h-[36px] bg-[#12141F]/90 backdrop-blur-md border border-[#3B4363] flex items-center justify-center shadow-xl hover:bg-[#1A1E2E] transition-all duration-200 group",
            tabShape
          )}
        >
          <span
            className="w-2.5 h-2.5 rounded-full transition-transform duration-200 group-hover:scale-125 shadow-sm"
            style={{ backgroundColor: getStatusDotColor() }}
          />
        </div>
      </div>
    );
  }

  return (
    <div
      data-tauri-drag-region
      className="flex items-center justify-between w-full h-full px-2 bg-[#0D0E15] hover:bg-[#12141F] border border-[#2A3048] hover:border-[#6366F1]/60 rounded-xl select-none cursor-move shadow-2xl transition-colors duration-150"
    >
      {/* Drag Grip & Status Dot */}
      <div className="flex items-center gap-1.5" data-tauri-drag-region>
        <GripVertical
          className="w-3 h-3 text-[#64748B] flex-shrink-0"
          data-tauri-drag-region
        />
        <span
          className="w-2 h-2 rounded-full flex-shrink-0"
          style={{ backgroundColor: getStatusDotColor() }}
          data-tauri-drag-region
        />
        <span
          className="tabular-timer text-xs font-black text-[#F1F5F9] font-mono leading-none tracking-tight w-[38px] inline-block text-center flex-shrink-0"
          style={{
            fontVariantNumeric: "tabular-nums",
            fontFeatureSettings: '"tnum"',
          }}
          data-tauri-drag-region
        >
          {timerText}
        </span>
      </div>

      {/* Action Controls */}
      <div className="flex items-center gap-1">
        <button
          onClick={(e) => {
            e.stopPropagation();
            togglePause();
          }}
          className="flex items-center justify-center w-6 h-6 rounded-lg bg-[#161822] hover:bg-[#1F2333] text-[#94A3B8] hover:text-[#F1F5F9] border border-[#2A3048]/60 transition-colors duration-150 cursor-pointer"
          title={isPaused ? t("btn_resume") : t("btn_pause")}
        >
          {isPaused ? (
            <Play className="w-3 h-3 text-[#10B981]" />
          ) : (
            <Pause className="w-3 h-3 text-[#F59E0B]" />
          )}
        </button>

        <button
          onClick={(e) => {
            e.stopPropagation();
            setPillMode(false);
          }}
          className="flex items-center justify-center w-6 h-6 rounded-lg bg-[#6366F1] hover:bg-[#4F46E5] text-white transition-colors duration-150 cursor-pointer shadow-sm shadow-[#6366F1]/20"
          title={t("btn_expand_main", "توسيع النافذة")}
        >
          <Maximize2 className="w-3 h-3" />
        </button>
      </div>
    </div>
  );
};
