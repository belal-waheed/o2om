import React, { useState } from "react";
import { useTranslation } from "react-i18next";
import { Play, Pause, Maximize2, GripVertical } from "lucide-react";
import { useTimerStore } from "../../stores/useTimerStore";

export const MiniPillView: React.FC = () => {
  const { t } = useTranslation();
  const { snapshot, togglePause, setPillMode, dockInfo, setPillTucked } = useTimerStore();
  const [isHovered, setIsHovered] = useState<boolean>(false);

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
    let alignmentClass = "items-center justify-center";
    let tabShape = "rounded-xl";

    if (edge === "right") {
      // Window is at right edge of monitor; visible 26px is at the FAR LEFT of window
      alignmentClass = "items-center justify-start";
      tabShape = "rounded-l-xl border-r-0";
    } else if (edge === "left") {
      // Window is at left edge of monitor; visible 26px is at the FAR RIGHT of window
      alignmentClass = "items-center justify-end";
      tabShape = "rounded-r-xl border-l-0";
    } else if (edge === "top") {
      // Window is at top edge; visible 26px is at the BOTTOM of window
      alignmentClass = "items-end justify-center";
      tabShape = "rounded-b-xl border-t-0";
    } else if (edge === "bottom") {
      // Window is at bottom edge; visible 26px is at the TOP of window
      alignmentClass = "items-start justify-center";
      tabShape = "rounded-t-xl border-b-0";
    }

    return (
      <div
        onClick={() => setPillTucked(false)}
        className={`w-full h-full flex ${alignmentClass} bg-transparent select-none cursor-pointer`}
        title={t("app_title")}
      >
        <div
          className={`w-[26px] h-[36px] bg-[#12141F]/90 backdrop-blur-md border border-[#3B4363] ${tabShape} flex items-center justify-center shadow-xl hover:bg-[#1A1E2E] transition-all duration-200 group`}
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
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      className={`flex items-center justify-between w-full h-full px-2 bg-[#0D0E15] border border-[#2A3048] rounded-xl select-none cursor-move shadow-2xl transition-colors duration-150 ${
        isHovered ? "border-[#6366F1]/60 bg-[#12141F]" : ""
      }`}
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
