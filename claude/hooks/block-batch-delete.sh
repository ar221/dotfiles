#!/usr/bin/env bash
# PreToolUse hook for Bash: blocks batch-destructive commands unless the
# command contains a '# approved: <reason>' marker. Enforces ~/CLAUDE.md §2.5
# (Safety / Destructive Operations) — no batch delete without a reviewed plan.
set -euo pipefail

input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command // ""')

# Escape hatch: explicit in-command approval marker.
if echo "$cmd" | grep -qE '#[[:space:]]*approved\b'; then
  exit 0
fi

reason=""
if echo "$cmd" | grep -qE '(^|[[:space:]&|;])rm[[:space:]]+(-[a-zA-Z]*[rRf]|--recursive|--force)'; then
  reason="rm -r/-rf/--recursive/--force"
elif echo "$cmd" | grep -qE '\bfind\b[^|;&]*-delete\b'; then
  reason="find -delete"
elif echo "$cmd" | grep -qE '\bfind\b[^|;&]*-exec[[:space:]]+rm\b'; then
  reason="find -exec rm"
elif echo "$cmd" | grep -qE '\bxargs\b[^|;&]*[[:space:]]rm\b'; then
  reason="xargs rm"
fi

if [[ -n "$reason" ]]; then
  cat >&2 <<EOF
BLOCKED: destructive batch operation detected ($reason).

Per ~/CLAUDE.md §2.5, never batch-delete without showing the user the full
list first and getting explicit approval.

To proceed:
  1. Write a plan (full file list + sizes + keep/delete categorization)
  2. Get the user's explicit approval
  3. Append '# approved: <brief reason>' to the command to bypass this gate

Single-file deletion without -r/-f is not blocked.

Command was:
  $cmd
EOF
  exit 2
fi

exit 0
