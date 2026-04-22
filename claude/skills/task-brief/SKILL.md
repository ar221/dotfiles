---
name: task-brief
description: Scaffold a per-task 3-file persistence triad (plan / findings / progress) under `03 Projects/<project>/™ tasks/<slug>/` in the vault. Use when starting a non-trivial multi-step task that you want to survive compaction, /clear, or a Niri crash. Re-invocation is idempotent — never overwrites, always refreshes `updated:`.
version: 1.0.0
user-invocable: true
---

# task-brief — Per-Task Persistence Triad

Scaffolds (or opens) three linked markdown files for a task. The triad lives in the vault so it is grep-able, Dataview-queryable, and survives context loss.

## When to Use

- Starting any task that will span multiple Claude turns, phases, or specialists
- Before kicking off a campaign, sprint, or investigation
- When you want scribe to append per-task progress entries (not just the day-level journal)

## When NOT to Use

- One-shot commands, typos, single-file edits — overkill
- Tasks that are already captured in an active journal entry and don't need finer granularity
- Research that belongs in `00 Notes/Raw/` (vault wiki captures, not task state)

## Invocation

```
/task-brief <project>/<slug>
```

- `<project>` — must match a directory under `~/Documents/Ayaz OS/03 Projects/`
- `<slug>` — kebab-case (`^[a-z0-9][a-z0-9-]*$`)

Examples:
- `/task-brief iNiR/campaign-k`
- `/task-brief System/verify-deliverables-hook`

## Behavior

1. Validate arg shape. If missing `/` or slug is malformed, print usage and exit.
2. Validate `<project>` exists under `03 Projects/`. If not, list actual projects and exit.
3. If `™ tasks/<slug>/` already exists: refresh `updated:` timestamps, re-print `™ plan.md`, exit.
4. Otherwise: create the directory and scaffold all three files with starter content.
5. Print the paths and a one-line next-step hint.

## Implementation

When the user invokes `/task-brief <arg>`, run the bash block below via the `Bash` tool, passing the user's argument as the first positional. The block is self-contained — no pre-validation in Claude's head; let the bash do the work and surface errors.

```bash
set -euo pipefail

ARG="${1:-}"
VAULT="$HOME/Documents/Ayaz OS"
PROJECTS_ROOT="$VAULT/03 Projects"

if [[ -z "$ARG" || "$ARG" != */* ]]; then
  echo "Usage: /task-brief <project>/<slug>"
  echo "Example: /task-brief iNiR/campaign-k"
  echo ""
  echo "Active projects:"
  find "$PROJECTS_ROOT" -maxdepth 1 -mindepth 1 -type d -printf "  %f\n" | sort
  exit 1
fi

PROJECT="${ARG%%/*}"
SLUG="${ARG#*/}"

if [[ ! "$SLUG" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "Error: slug must be kebab-case (lowercase alphanumerics + hyphens, starting with a letter or digit)."
  echo "Got: '$SLUG'"
  exit 1
fi

PROJECT_DIR="$PROJECTS_ROOT/$PROJECT"
if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "Error: project '$PROJECT' not found under 03 Projects/."
  echo "Actual projects:"
  find "$PROJECTS_ROOT" -maxdepth 1 -mindepth 1 -type d -printf "  %f\n" | sort
  exit 1
fi

TASK_DIR="$PROJECT_DIR/™ tasks/$SLUG"
PLAN="$TASK_DIR/™ plan.md"
FINDINGS="$TASK_DIR/™ findings.md"
PROGRESS="$TASK_DIR/™ progress.md"
NOW="$(date -Iseconds)"

# Print active-trap banner if trap-detect is available and there are any active traps.
# Suppressed when the ledger has none — no noise on the happy path.
trap_banner() {
  command -v trap-detect >/dev/null 2>&1 || {
    echo "warn: trap-detect not found; skipping trap banner" >&2
    return 0
  }
  trap-detect scan --quiet 2>/dev/null || return 0
  local active
  active="$(trap-detect list --active-only 2>/dev/null | sed -n '/^### /,$p')"
  if [[ -n "$active" ]]; then
    echo ""
    echo "⚠ Known traps (vault-wide):"
    echo "$active" | sed -n 's/^### \(.*\) — \([0-9]*\) hits/  - \1 (\2 hits)/p'
    echo ""
    echo "Full ledger: ~/.claude/shared-memory/known-traps.md"
    echo ""
  fi
}

if [[ -d "$TASK_DIR" ]]; then
  echo "Task brief already exists at: $TASK_DIR"
  echo ""
  echo "Refreshing 'updated:' timestamps…"
  for f in "$PLAN" "$FINDINGS" "$PROGRESS"; do
    if [[ -f "$f" ]]; then
      sed -i "0,/^updated:.*/s|^updated:.*|updated: $NOW|" "$f"
    fi
  done
  echo ""
  echo "--- ™ plan.md ---"
  cat "$PLAN" 2>/dev/null || echo "(missing)"
  echo ""
  echo "Paths:"
  echo "  plan:     $PLAN"
  echo "  findings: $FINDINGS"
  echo "  progress: $PROGRESS"
  trap_banner
  exit 0
fi

mkdir -p "$TASK_DIR"

cat > "$PLAN" <<EOF
---
type: task-plan
task: $SLUG
project: $PROJECT
created: $NOW
updated: $NOW
status: in-progress
---

# $SLUG — Plan

**Goal:** _One sentence. What does "done" look like?_

## Context

_What's the backdrop? Why now? Link to any parent plan, journal entry, or vault note._

## Phases

- [ ] Phase 1: _short label_
- [ ] Phase 2:
- [ ] Phase 3:

## Open Questions

- _Question 1_

## Done Criteria

- _Criterion 1_

## Related

- Findings: [[™ findings]]
- Progress: [[™ progress]]
EOF

cat > "$FINDINGS" <<EOF
---
type: task-findings
task: $SLUG
project: $PROJECT
created: $NOW
updated: $NOW
---

# $SLUG — Findings

_Research, discovered constraints, reference links, discarded approaches. Paged out of conversation context so findings don't stuff the window._

## Log

### $NOW

- _First finding_

## Discarded Approaches

_Things considered and rejected, with the reason. Prevents rediscovery._

## Related

- Plan: [[™ plan]]
- Progress: [[™ progress]]
EOF

cat > "$PROGRESS" <<EOF
---
type: task-progress
task: $SLUG
project: $PROJECT
created: $NOW
updated: $NOW
---

# $SLUG — Progress

_Session log. One entry per working session. Failures tracked for 3-strike detection (T1.4)._

## Sessions

### $NOW — Task brief scaffolded

- Scaffolded via \`/task-brief\`.

## Failure Log

_Track recurring errors here. If the same class of failure hits 3×, log as a known trap._

## Related

- Plan: [[™ plan]]
- Findings: [[™ findings]]
EOF

echo "Scaffolded task brief: $PROJECT / $SLUG"
echo ""
echo "Paths:"
echo "  plan:     $PLAN"
echo "  findings: $FINDINGS"
echo "  progress: $PROGRESS"
echo ""
echo "Next: open ™ plan.md and fill in Goal + Phases."

trap_banner
```

## Integration with Scribe

When spawning scribe on a task that has a brief, include this line in the briefing:

```
task-brief: <project>/<slug>
```

Scribe will append a session entry to `™ progress.md` in addition to its usual journal write.

## Discovery

Dataview query (run in Obsidian) to list all active task briefs:

```dataview
TABLE status, updated FROM "03 Projects"
WHERE type = "task-plan" AND status != "done" AND status != "parked"
SORT updated DESC
```
