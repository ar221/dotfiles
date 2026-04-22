---
name: roster
description: |
  NOT AN INVOCABLE AGENT. This is a reference document maintained by charlotte (HR)
  that codifies the three-tier staffing model for Ayaz's agent roster. Read this
  before proposing new hires, before picking a model default for a contractor, or
  when the question "should this be permanent or one-shot" comes up.

  Consumers: charlotte (HR), the five coordinators (by launch directory), and any
  session that needs to understand how the roster is structured and why.
model: inherit
color: white
tools: []
---

# Roster — Staffing Model Reference

Ayaz runs his agent roster like a small company. Employees are hired when the work is real and recurring; contractors are brought in for one-shot jobs. Charlotte is HR — she enforces this model. This doc is her reference card and the team's shared map.

## Coordinator Architecture (Locked)

Five named identities serve as coordinators. They are **not** invocable agents — there are no `.md` files for them in `~/.claude/agents/`. They are identity overlays applied to the main Claude context based on **launch directory**. Their definitions live in `~/.claude/shared-memory/*-identity.md`.

| Identity | Launch Directory | Domain | Role |
|----------|-----------------|--------|------|
| **Oracle** | `~/Documents/Ayaz OS/` | Vault 713 (second brain) | Chief of staff. Strategy, portfolio, two-track enforcement, cross-domain dispatch. |
| **Alfred** | `~/` | Home base (system layer) | System steward. Dotfiles, theming pipeline, services, scripts, iNiR repo maintenance. |
| **Scheherazade** | `~/STWork/` | SillyTavern / creative / RP | Narrative taste-holder. Character voice, lorebooks, NSD-DarkLuxury, creative-practice accumulation. |
| **Mr. House** | `~/Modding/` | Bethesda modding | Multi-project operator. Wild Card / WC2 / MMNV / LoreRim. Plugin budget governance. |
| **Elsa** | `~/Github/inir/` + vault `03 Projects/iNiR/` | iNiR desktop shell | UX/design taste-holder. Cohesion bar, feature campaigns, on-loan for interface consults. |

**The coordinator team is locked at five.** No new coordinator identity without a Charlotte-led proposal and explicit Ayaz sign-off. The bar is high: a new coordinator means a genuinely new domain that none of the five can own, not just a busy project that needs more hands.

Any coordinator can dispatch specialists from the agent roster. Domain is the tiebreaker — if the work is primarily vault/project, Oracle dispatches; if primarily system, Alfred dispatches; domain-specific work goes to the respective domain coordinator.

## The Three Tiers

| Tier | Who | Nature | Model Default |
|------|-----|--------|---------------|
| **Coordinators** | Oracle, Alfred, Scheherazade, Mr. House, Elsa | Identity overlays on the main context. Not invocable agents. Applied by launch directory. Own strategic direction and dispatch specialists. | Inherited from the session's model selection |
| **Permanent specialists** | Charlotte (HR), Dexter (research), Akbar (sysadmin), scribe, pitstop, mordin, garrus, Artemis, Atelier, Curator, Borges, and others in `~/.claude/agents/` | Invocable agents with `.md` files. Called by coordinators when their specialty is needed. Some are session-staples (scribe, pitstop); others are domain-active only. | Sonnet or Opus per role — see individual frontmatter |
| **Contractors** | Ad-hoc personas spun up inline via `general-purpose` with persona injected as prompt prefix. No file, no registration, no persistence. | One-shot specialists for work that doesn't recur. Die when the task ends. | **Haiku by default** (policy — 2026-04-15). Escalate to Sonnet/Opus only if the task's depth demands it. |

## Staffing Heuristic

The question Charlotte asks on every hire proposal:

> **Would a Claude instance in a different domain benefit from this specialty permanently?**

- **Yes →** Permanent. Write a `.md` in `~/.claude/agents/`, go through the registry-snapshot dance.
- **No →** Contractor. Charlotte drafts the persona, the relevant coordinator spawns `general-purpose` with persona as prompt prefix.

Secondary test — **recurrence bar**: a permanent hire needs 3+ distinct tasks of evidence OR a clearly standing function. A one-time specialty, no matter how deep, is a contractor job.

## Contractor-Default-Haiku (Policy, 2026-04-15)

Previously, contractors inherited whatever model the coordinator happened to be running. Policy:

- **Default Haiku** for all contractor spawns unless the task explicitly requires depth.
- Haiku handles the vast majority of contractor jobs fine — they tend to be narrow, well-briefed, and bounded.
- **Escalate to Sonnet** when the contractor needs to reason across many sources, handle genuine ambiguity, or produce something synthesized.
- **Escalate to Opus** only for deep technical work — architectural analysis, complex code generation, multi-step reasoning with high stakes. Rare for contractors.
- Name the model in the contractor spawn prompt so it's deliberate, not default drift.

Why: contractors are bounded by design. A well-briefed one-shot doesn't need Opus. Spending Opus tokens on "parse this log and tell me the error" is waste. Reserve the heavy models for the permanent specialists who need them.

## Project-to-Team Mapping

Every `03 Projects/<name>/` folder in the vault is an employee. The domain specialist is the **project lead** — they own the work product inside the project. The coordinator for that domain dispatches specialists and holds strategic direction.

Mapping (as of 2026-04-15):

| Project | Project Lead (specialist) | Coordinator |
|---------|---------------------------------|-------------|
| Wildcard 2.0 (Pre-PM) | mordin | Mr. House |
| My Modded New Vegas | mordin | Mr. House |
| Mod Sweep | mordin + garrus (tooling build) | Mr. House |
| iNiR | atelier / artemis (paired) | Elsa |
| STWork | (TBD — creative specialist candidate) | Scheherazade |
| Steam Deck Port | akbar + garrus | Alfred |
| Job Hunt | (TBD — writing specialist candidate) | Oracle |
| Trading Archive | kasparov | Oracle |

"TBD" means no project lead has crystallized yet — work is handled by permanent specialists + contractors until a recurring pattern emerges and earns a dedicated hire.

## Charlotte's Role

Charlotte (HR) enforces all of this. Specifically:

- **Gate-keeps permanent hires.** Drafts the `.md`, flags overlap with existing agents, enforces the recurrence bar.
- **Gate-keeps coordinator proposals.** The five-coordinator team is locked. Charlotte leads the proposal process if a sixth is ever warranted — which requires a genuinely new domain, not just a busy one.
- **Designs contractors.** Composes the persona, picks the model (default Haiku, escalate deliberately), returns a ready-to-paste prompt. Doesn't spawn — the coordinator does.
- **Audits the roster.** Periodic checks for stale specialties, overlap, scope creep.
- **Holds the line on lean.** The roster stays small. Over-hiring dilutes the team and costs registry-snapshot cycles.
- **Maintains this document.** When the model changes, charlotte updates the table + change log.

Detailed protocols live in `/home/ayaz/.claude/agents/charlotte.md`.

## Registry-Snapshot Gotcha

**New permanent `.md` files in `~/.claude/agents/` are not hot-registered.** The subagent registry is session-start-snapshotted. A new agent is invisible to the `Agent` tool until Ayaz `/exit`s the current session and relaunches. Until then, if the work can't wait, the coordinator spawns a **contractor** with the same persona as a stopgap.

Flag this every time a permanent hire ships. Ayaz forgets; the workaround exists; name it explicitly.

## Task-Brief Convention (2026-04-17)

The `/task-brief` skill scaffolds a per-task 3-file triad under `~/Documents/Ayaz OS/03 Projects/<project>/™ tasks/<slug>/` (`™ plan.md`, `™ findings.md`, `™ progress.md`). When a coordinator spawns a specialist, it may include a line of the form `task-brief: <project>/<slug>` in the briefing. Agents consume this line per their tier:

| Tier | Agents | Behavior |
|------|--------|----------|
| **A — Material workers** | akbar, artemis, atelier, borges, curator, garrus, gaming, mordin, pitstop, services, sys-optimizer | Read all three files at spawn; append a **session entry** to `™ progress.md` after material work; refresh `updated:` in frontmatter. Entry format is tuned per role (design moves for atelier, xEdit decisions for mordin, measurements for sys-optimizer, etc.). |
| **A' — Research synthesizers** | dexter, insights-sweep | Read all three at spawn; append a **synthesis section** to `™ findings.md` (not progress — research output is product, not session log); refresh `updated:`. Dexter additionally checks findings.md first to avoid re-researching what's already cited. |
| **B — Read-only consumers** | charlotte | Reads the triad at spawn (mid-flight gap-fill consults) so designed contractor personas are grounded in actual task state. Does not write — HR persists nothing. Flags missing triads to Ayaz (coordinator skipped `/task-brief` at kickoff). |
| **C — Skip** | rice-scout, health, reviewer, roster (n/a), scribe (own path) | Do **not** wire in. Rationale below. |
| **Scribe** | scribe | Special case. Writes to `™ progress.md` via its existing §6 "Task-Brief Mode" — the session-log format (journal-style). If both scribe and a Tier A specialist run on the same task in the same session, both append; formats are distinct enough to not collide. |

**Why the skips:**

- **rice-scout** — web-research only, no project grounding; task state would pollute broad inspiration work.
- **health** — stateless 11-point diagnostic by charter; no project context needed.
- **reviewer** — **intentional charter preservation.** Reviewer is an adversarial cold reader — "No context from prior conversation. Do not assume the author's intent was correct." Injecting task-brief context would defeat the premise. Keep reviewer sealed.
- **roster** — not invocable (reference doc).

**Rules for future hires:**

1. Every new permanent specialist `.md` should end with a `## Task-Brief Mode` section unless the role is charter-incompatible (reviewer-shaped). Charlotte enforces this at draft time.
2. Every new contractor persona draft should include a tier assignment (A / A' / B / C) and, if A or A', the tuned append format. Borrow from the closest existing specialist's template.
3. The vault path is hardcoded: `~/Documents/Ayaz OS/03 Projects/<project>/™ tasks/<slug>/`. Don't parameterize it away without a coordinated change across all §6 blocks.
4. Agents **never scaffold the triad themselves** — that's `/task-brief`'s job. If a briefing references a triad that doesn't exist, warn and fall back to coordinator-report behavior.

**~~Open gap (T1.4 candidate)~~ Closed 2026-04-17 (T1.3b):** all five coordinator identity specs (`oracle-identity.md`, `alfred-identity.md`, `scheherazade-identity.md`, `house-identity.md`, `elsa-identity.md`) now carry a `## Task-Brief Emission` section defining when to emit `task-brief: <project>/<slug>`, when to scaffold via `/task-brief`, and when to skip. Consumers downstream still warn-and-continue if emission is forgotten (rule #4 preserved as safety net).

## Change Log

### 2026-04-18 — Hired `kasparov` (trading knowledge archivist)

- **Hired (permanent):** `kasparov` — trading knowledge archivist / wiki builder. Opus, tier A' (findings-writer), amber. Named after Garry Kasparov's "Advanced Chess" concept — machine studies, human plays.
- **Scope:** trading wiki expansion (`00 Notes/Wiki/trading/`), Trading Archive curation (`03 Projects/Trading Archive/`), factual trading-concept research (cited, neutral), and scribe mode for when Ayaz dictates his own playbooks. **Hard-bound by the Trading Boundary** (`~/.claude/shared-memory/trading-boundary.md`) — the refusal reflex is baked into the persona spine, not tacked on.
- **Does NOT:** generate strategy, setups, trade ideas, position sizing, market commentary, or evaluate trades. No broker APIs, no live accounts, no "what should I trade next" — hard refuses cleanly, no hedging.
- **Recurring-need evidence:** 4 seeded wiki articles with explicit coverage gaps, 3-tier course archive awaiting mining, standing glossary/platform reference work. 2026-04-17 archive-access lift opened the door; nobody else on the roster fits (curator is clippings-first and doesn't hold a boundary).
- **60-day check-in:** if kasparov gets invoked <1×/month by mid-June, revisit as vanity-hire candidate.
- **Registry-snapshot:** new hire, requires `/exit` + relaunch before invocable via `Agent` tool. Until then, contractor-persona fallback with `kasparov.md` content as prompt prefix.

### 2026-04-17 — T1.4: `[trap: <slug>]` tag convention for 3-strike failure detection

- **Why:** new `~/.local/bin/trap-detect` CLI scans every `™ progress.md` in the vault for `[trap: <slug>]` tags, aggregates by slug, and writes a ledger at `~/.claude/shared-memory/known-traps.md`. Slugs that hit threshold (default 3) get surfaced as "Active Traps" via the `/task-brief` skill banner on every (re-)invoke.
- **Patched §6 in 9 specialist briefs** (Tier A workers + scribe special case): akbar, atelier, artemis, borges, garrus, gaming, mordin, services, scribe. Each `**Failures (if any):**` template line now carries a `[trap: <slug>] <description>` shape, with one prose instruction line under it: *"Slug is lowercase-kebab, specific enough to recur (e.g., `systemd-user-daemon-reload`, not `systemd-error`). Skip the tag entirely if the failure is genuinely one-off."*
- **Skipped, with reason** — Tier B (charlotte: read-only, no Failures line); Tier A' (dexter, insights-sweep: append synthesis to `™ findings.md`, not session logs with failure bullets — possible future "Caveats" schema TBD); Tier C (rice-scout, health, reviewer, roster — same as T1.3 skips).
- **Anomaly flagged:** curator, sys-optimizer, pitstop are listed as Tier A above but their `## Task-Brief Mode` sections contain no `**Failures (if any):**` line. T1.3 patches were tier-tuned heavily and may have dropped the bullet (pitstop is commit-only, sys-optimizer logs measurements, curator logs synthesis-style). **Backfill candidate** — confirm whether the bullet should exist in those three specialists; if yes, patch and re-run T1.4 propagation against them.
- **Codification stays manual.** A trap surfacing in the ledger does not auto-write to CLAUDE.md or feedback memory. Ayaz says "codify `<slug>`" when ready; that's a separate human-in-the-loop step.
- **Out of scope (V1.5+):** coordinators don't yet actively read `known-traps.md` at briefing time; cross-slug dedup; fuzzy-match fallback for untagged failures.

### 2026-04-17 — T1.3b: coordinator task-brief emission wired

- Added `## Task-Brief Emission` sections to all five coordinator identity specs in `~/.claude/shared-memory/` (oracle, alfred, scheherazade, house, elsa). Inline patch, placed after each identity's `Scribe + journal` section — sibling dispatch convention.
- Common template (kickoff / emission / skip / task-switch), lightly tailored per coordinator: Oracle uses vault-project examples, Alfred uses system-project examples, Scheherazade uses STWork slugs, House flags the project-confusion failure mode explicitly (WC vs WC2 vs MMNV), Elsa hardcodes `iNiR/<slug>` since her domain is single-project.
- Closes the T1.3 open gap. Consumers keep the warn-and-continue safety net; emission is now a documented coordinator behavior, not an implicit hope.

### 2026-04-17 — Task-brief convention propagated roster-wide

- Added `## Task-Brief Mode` sections to 14 agents across three tiers: 11 material workers (akbar, artemis, atelier, borges, curator, garrus, gaming, mordin, pitstop, services, sys-optimizer), 2 research synthesizers (dexter, insights-sweep), 1 read-only consumer (charlotte).
- Intentionally skipped: rice-scout (web-only), health (stateless), reviewer (adversarial-charter preservation), roster (not invocable), scribe (already wired in its own §6).
- Tuned append formats per role — atelier logs design moves, mordin logs xEdit decisions, sys-optimizer logs measurements, dexter appends to findings not progress, etc.
- Closes the T1.1 integration gap from earlier today: the `/task-brief` skill scaffolds the triad, the verify-deliverables hook catches hallucinations, and now specialists actually consume and update the triad.
- Flagged remaining gap: coordinators don't yet emit `task-brief:` lines by default.

### 2026-04-15 — Five-coordinator architecture; retire Texas Red

- **Replaced** the generic "Texas Red" per-project coordinator framing with the five named coordinator identities: Oracle (vault), Alfred (home base), Scheherazade (STWork), Mr. House (Modding), Elsa (iNiR).
- **Added** coordinator architecture section. Coordinators are identity overlays by launch directory, not invocable agents. Definitions in `~/.claude/shared-memory/*-identity.md`.
- **Locked** coordinator team at five. New coordinators require a Charlotte-led proposal + Ayaz sign-off.
- **Updated** project-to-team mapping to reflect correct coordinator per domain.
- **Restructured** three-tier table: coordinators are now their own tier (identity layer), distinct from permanent specialists (invocable agents).

### 2026-04-15 — Initial roster meta doc + two permanent hires

- **Created:** `/home/ayaz/.claude/agents/roster.md` (this file). Codifies the three-tier staffing model, the hiring heuristic, and contractor-default-Haiku policy.
- **Hired (permanent):** `mordin` — Bethesda modding specialist. FNV primary, Skyrim SE secondary. Driven by Wildcard 2.0 (Pre-PM) kickoff but cross-covers all Bethesda modding work.
- **Hired (permanent):** `garrus` — tool smith. Builds CLI tools / Python utilities / bash scripts / pipelines. Clear differentiation from akbar (operator vs. builder).
- **New policy:** contractor-default-Haiku. Previously no default set. Now: Haiku unless task depth demands escalation.
- **Theme:** Mass Effect agent naming convention continues (mordin, garrus join the roster alongside the existing crew).
- **Registry-snapshot:** Both new hires require `/exit` + relaunch before they're callable via the `Agent` tool. Until then, contractor-persona fallback.
