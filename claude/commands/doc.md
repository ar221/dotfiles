Document recent changes to project memory files.

## Instructions

You are documenting changes made during this session (or recent sessions) to the auto-memory files so that future Claude Code sessions have full context.

### Step 1: Gather what changed

- Check `git log --oneline -10` and `git diff --stat` in any repos that were modified (look at the working directory and any project dirs referenced in conversation)
- Review the conversation history for what was done — configs changed, bugs fixed, features added, scripts written, packages installed, decisions made
- Check if any files were created, deleted, or significantly modified outside of git

### Step 2: Determine which memory files to update

Memory lives at: `~/.claude/projects/-home-ayaz/memory/`

- **MEMORY.md** — Concise index/summary. Keep under 200 lines. Contains: role, system info, resolved items (brief), known issues, key paths. Link to topic files for details.
- **Topic files** (e.g., `theming.md`, `system-cleanup-feb2026.md`) — Detailed notes on specific domains. Create new topic files when a subject has enough detail to warrant its own file.

### Step 3: Write the documentation

For each change or resolved issue, document:
- **What** was done (1-2 sentences)
- **Why** it was needed (root cause if it was a fix)
- **Key details** that a future session needs (file paths, config values, gotchas, commands)
- **Status** — resolved, in-progress, or known issue

### Rules

- **Don't duplicate** — check existing entries before adding new ones. Update existing entries if the information has changed.
- **Be concise** — MEMORY.md entries should be 1-3 lines each. Details go in topic files.
- **Use "Resolved:" prefix** for completed work items in MEMORY.md
- **Keep MEMORY.md under 200 lines** — if it's over, move detailed sections into topic files and replace with a link
- **Don't document trivial changes** — a typo fix or single config tweak doesn't need memory unless it reveals a pattern
- **Do document**: architectural decisions, bug root causes, workflow patterns, file path discoveries, tool configurations, gotchas that would waste time if rediscovered
- **Date your entries** when they represent point-in-time work (e.g., "Feb 2026")
- **Remove outdated entries** — if something was a known issue and is now fixed, move it to resolved or remove it entirely

### Step 4: Verify

- Confirm MEMORY.md is under 200 lines
- Confirm no secrets or API keys are in any memory file
- Confirm topic files are linked from MEMORY.md where relevant
