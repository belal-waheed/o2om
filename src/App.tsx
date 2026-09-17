import React, { useEffect } from "react";
import { MainWindow } from "./windows/MainWindow";
import { MiniPillView } from "./components/dashboard/MiniPillView";
import { GuidedBreakView } from "./components/dashboard/GuidedBreakView";
import { useTimerStore } from "./stores/useTimerStore";

export const App: React.FC = () => {
  const { initStore } = useTimerStore();

  const params = new URLSearchParams(window.location.search);
  const win = params.get("win");
  const targetWin = (win as "pill" | "break_overlay") || "main";

  useEffect(() => {
    initStore(targetWin);
  }, [initStore, targetWin]);

  if (win === "pill") {
    return (
      <div className="w-screen h-screen overflow-hidden bg-transparent select-none">
        <MiniPillView />
      </div>
    );
  }

  if (win === "break_overlay") {
    return (
      <div className="w-screen h-screen overflow-hidden bg-[#0D0E15] select-none p-2">
        <GuidedBreakView />
      </div>
    );
  }

  return <MainWindow />;
};

export default App;
