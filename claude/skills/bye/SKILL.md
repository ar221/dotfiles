---
name: bye
description: Session wrap-up — documents the session via scribe agent, captures any new memory-worthy information, then prompts user to /exit. Use when the user wants to end a session cleanly.
disable-model-invocation: true
---

# Session Wrap-Up

You are wrapping up this session. Perform these steps in order:

## Step 1: Assess the Session

Quickly review what happened in this conversation:
- What tasks were worked on?
- What files were modified?
- What decisions were made and why?
- Did anything non-trivial happen that warrants documentation?

If this was a trivial session (quick question, single config tweak, reading-only), skip to Step 4.

## Step 2: Scribe — Document the Session

Spawn a **scribe** agent in the background with a complete briefing of the session:

```
Task: <what the user asked for / worked on>
Work performed:
- <step 1>
- <step 2>
- ...
Files changed:
- <path>: <what changed>
Decisions:
- <decision>: <why>
Status: DONE | IN PROGRESS | BLOCKED
Remaining: <anything left unfinished>
```

The scribe writes to the journal at `~/.claude/projects/<project-slug>/memory/journal/`.

## Step 3: Memory Check

Review the session for anything memory-worthy. Check against the memory types:

- **user**: Did you learn something new about the user's role, preferences, or knowledge?
- **feedback**: Did the user correct your approach or validate a non-obvious choice?
- **project**: Did you learn about ongoing work, goals, or decisions not derivable from code?
- **reference**: Did you learn about external resources or systems?

If any apply, save the memory now (write the file + update MEMORY.md index).

**Do NOT save:**
- Code patterns or architecture (derivable from reading the code)
- Debugging solutions (the fix is in the code/commit)
- Anything already in CLAUDE.md files
- Ephemeral task details only useful in this conversation

## Step 4: Report & Exit Cue

Give the user a brief wrap-up (2-4 lines max):
- What was documented (or "nothing to document" for trivial sessions)
- Any memory saved
- Any unfinished work noted for next session

Then say: **"Type `/exit` to close the session."**

## Rules

- Keep it fast. Don't re-read files you already know about.
- Don't over-document trivial sessions.
- The scribe runs in the background — don't wait for it to finish before reporting to the user.
- If the session had active tasks (TaskList), note any incomplete ones in the scribe briefing.
