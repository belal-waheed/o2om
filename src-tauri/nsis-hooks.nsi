!macro NSIS_HOOK_PREINSTALL
  DetailPrint "Closing running O2om instances..."
  nsis_tauri_utils::KillProcessCurrentUser "${MAINBINARYNAME}.exe"
  Sleep 500
!macroend
