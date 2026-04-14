#!/usr/bin/env bash
# PostToolUse hook: remind Claude to register new ~/.local/bin/ scripts.
# Fires after Write/Edit/MultiEdit. Emits a systemReminder only when the
# modified path is inside ~/.local/bin/ (and not a *.bak.* backup).
set -euo pipefail

input=$(cat)
file_path=$(jq -r '.tool_input.file_path // .tool_response.filePath // empty' <<<"$input")

case "$file_path" in
  "$HOME/.local/bin/"*.bak.*) exit 0 ;;
  "$HOME/.local/bin/"*)
    script_name="${file_path##*/}"
    msg="Script \`$script_name\` was just written to ~/.local/bin/. Before ending this turn, register it per the Scripts Registry protocol:

1. Add a row to ~/.claude/shared-memory/scripts-registry.md in the correct domain section (Modding / Gaming / STWork / ComfyWork / iNiR & Desktop / Video / System & General).
2. Add a row to the owning domain's CLAUDE.md Tools section if one exists — ~/STWork/CLAUDE.md, ~/Modding/CLAUDE.md, or ~/CLAUDE.md for system-general.
3. Verify the naming prefix matches domain conventions:
   - Modding: wc-*, mod*, esp-*, bsa-*, ini-*, plugin-*, launch-*, nexus*
   - Gaming: game*, proton*, gaming-*
   - STWork: st-*, dictation-*
   - System-general: no prefix
   If the prefix is wrong, rename the script (git mv or mv + update the row).

If the script is a backup, a temporary file, or a throwaway probe, ignore this reminder." ;;
  *) exit 0 ;;
esac

jq -n --arg msg "$msg" '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $msg}}'
