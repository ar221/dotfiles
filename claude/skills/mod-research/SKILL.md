---
name: mod-research
description: Research a Bethesda mod candidate against the Wild Card install, then update the mod note in place. Standard protocol (install check, deps, conflicts, anims/optics, Nexus intel, verdict). Use when the user asks to research a mod from their vault notes, or when they say "/mod-research <name>".
disable-model-invocation: true
---

# Mod Research

Standardized research protocol for mod candidates tracked in the Obsidian vault. Runs the same checklist every time, updates the source note in place, no orphan files.

## Inputs

`$ARGUMENTS` is one of:
- **A mod name or partial match** (fuzzy): `speed of light`, `bolt actions`, `desert ranger`
- **A Nexus ID**: `94734`
- **`--all-watching`**: batch-process every note with `status: watching` in frontmatter
- **Empty**: ask the user which mod

## Paths

- Vault mod notes: `/home/ayaz/Documents/Ayaz OS/03 Projects/My Modded New Vegas/00 Ideas & Research/Mods/`
- WC MO2 instance: `~/Modding/FNV Wild Card/`
- Custom profile: the profile under `FNV Wild Card/profiles/` that is NOT the Wabbajack base
- Merge ESPs of interest: `HitWeaponPack.esp`, `GunplayPack.esp`, `TacticoolMerge.esp`, `ArmorTacticalPack.esp`, `ATMOS Ambience Merge.esp`

## Step 1 — Resolve the note

1. Glob the Mods/ directory for files matching the argument. Note filenames are prefixed `™ `.
2. If the arg is a Nexus ID, grep frontmatter `nexus_id:` across notes.
3. If multiple matches, ask the user which one.
4. Read the note — extract frontmatter: `name`, `nexus_id`, `author`, `category`, `dependencies`, `esp_count`, `plugin_type`, `status`, `verdict`.

If no match found, stop and tell the user — don't research a note that doesn't exist.

## Step 2 — Delegate the research

Spawn a **general-purpose** agent. The agent should NOT update the note — its job is only to research and return structured findings. Main Claude applies edits in Step 3.

Brief the agent with:

```
Research the FNV mod "<name>" (Nexus <nexus_id>, https://www.nexusmods.com/newvegas/mods/<nexus_id>) against the user's Wild Card v6.0 install.

Note path: <full path to note>
Already-known info from the note (don't re-verify): <list: deps, coverage, ESP count, release date, etc>

Run this checklist and return a structured report:

1. INSTALL STATUS — grep custom profile modlist.txt + mods/ folder + overwrite/ for the mod. Report: installed / not installed. If installed, give the modlist.txt line number.

2. DEPENDENCIES — for each dep claimed in the note, confirm it's present in WC. Report missing deps explicitly.

3. CONFLICTS — search mods/ folder and enabled entries (+ prefix) in modlist.txt for anything covering the same territory. Name folders explicitly. If the mod touches weapons/armor/records, use `~/.local/bin/plugin-inspector` on the merge ESPs (HitWeaponPack, GunplayPack, TacticoolMerge, ArmorTacticalPack) and check for record overlap.

4. ANIMATION/OPTICS — if it's a weapon mod, check kNVSE, B42 Optics (Tactapack), ISControl, anim replacers (WAP, DRIIRE) presence and note any needed patches.

5. NEXUS INTEL — fetch the Nexus page (description, posts, bugs tabs). Use `~/.local/bin/nexus-mod` if WebFetch 403s. Report: bugs, sticky posts, author compat notes, post-release signal strength (how recent, endorsement count, community reports).

6. LOAD ORDER — any LO recommendation from the author or implied by mesh-replacer rules (loose beats BSA, later overrides earlier).

7. PLUGIN BUDGET — if the mod ships an ESP/ESM, note the impact. WC is near the 255 cap; check memory for current count.

8. VERDICT — one of: install | install-with-caveats | skip | already-installed | defer. Give a one-line reason.

Return findings as a JSON block at the end of your response, like:

```json
{
  "install_status": "not-installed" | "installed-line-NNN",
  "deps_ok": true | false,
  "deps_missing": ["..."],
  "conflicts": ["mod folder 1", "mod folder 2"],
  "anim_optics_ok": true | false | "n/a",
  "nexus_signal": "strong" | "thin" | "negative",
  "load_order_note": "...",
  "plugin_budget_impact": "none (ESPless)" | "+1 ESP (253/255 → 254/255)",
  "verdict": "install" | "install-with-caveats" | "skip" | "already-installed" | "defer",
  "verdict_reason": "one-line why",
  "open_questions_answers": {
    "<question text from note>": "<answer or null if not addressed>"
  },
  "summary_one_liner": "<one sentence for the Log entry>"
}
```

Budget ~12-15 tool calls. Do not modify any files. Return the full human-readable report AND the JSON block.
```

## Step 3 — Update the note in place

Parse the JSON block from the agent's response. Apply these edits to the note using the Edit tool:

### Frontmatter
- `status:` → map from verdict:
  - `already-installed` → `installed`
  - `install` or `install-with-caveats` → `researched`
  - `skip` → `skipped`
  - `defer` → `deferred`
- `verdict:` → set to the verdict value (kebab-case, e.g. `already-installed`, `install-with-caveats`)
- Leave other frontmatter fields alone unless research uncovered a correction (e.g., wrong `esp_count`).

### Open Questions section
For each `- [ ]` checkbox, if the agent answered it:
- Change `- [ ]` → `- [x]`
- Append the answer inline: `- [x] <original question> — **<short answer>**`

Leave unanswered questions as `- [ ]`.

### Log section
Append a new entry at the bottom:
```
- **YYYY-MM-DD** — Research complete. Verdict: <verdict>. <summary_one_liner>
```

Use today's date (absolute).

### Do NOT
- Create a separate `_research_*.md` file. The note IS the research record.
- Touch the `## What It Does` or `## Fit Assessment` sections — those are the user's authored content.

## Step 4 — Report to user

Brief wrap-up (under 100 words):
- Verdict + one-line reason
- Top 1-2 findings (conflicts, missing deps, already-installed, etc)
- "Note updated. Open questions: X answered, Y still open."

If verdict is `install-with-caveats` or `install`, list the concrete next actions (e.g., "disable [BSA] Ascended Lantern first", "download optional file X").

## Batch mode (`--all-watching`)

1. Glob `Mods/*.md`, read frontmatter of each, filter to `status: watching`.
2. Report the count to the user before starting: "Found N watching mods. Proceed?"
3. Run Step 2-3 for each, **sequentially** (each research spawns an agent with substantial context; parallel would blow the budget).
4. At the end, summarize as a table:

```
| Mod | Verdict | Headline finding |
|-----|---------|------------------|
| ... | ... | ... |
```

## Orphan cleanup

If you encounter an old `_research_<mod>.md` file sitting next to a `™ <Mod>.md` note, offer to delete the orphan after confirming the note has the research merged in. Don't delete without asking.

## Rules

- **Never modify modlist.txt, plugins.txt, or mod files.** Research only.
- **Never fabricate Nexus data.** If the Nexus page 403s and `nexus-mod` CLI has no cached info, say so explicitly in the report — don't invent.
- **Respect the note's authored sections.** Frontmatter, Open Questions, and Log are skill-managed. Everything else stays untouched.
- **Absolute dates** in the Log. Convert "today" → YYYY-MM-DD.
- If the agent's JSON is malformed, fall back to parsing the prose report and ask the user to confirm the verdict before editing.
