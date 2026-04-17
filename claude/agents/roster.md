---
name: roster
description: |
  NOT AN INVOCABLE AGENT. This is a reference document maintained by charlotte (HR)
  that codifies the three-tier staffing model for Ayaz's agent roster. Read this
  before proposing new hires, before picking a model default for a contractor, or
  when the question "should this be permanent or one-shot" comes up.

  Consumers: charlotte (HR), the five coordinators (by launch directory), and any
  session that needs to understand how the roster is structured and why.
model: sonnet
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

## Change Log

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
