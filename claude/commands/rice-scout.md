---
description: Launch a ricing research and inspiration session
argument-hint: "[trend|deep|tools|wallpaper|fonts] [topic]"
allowed-tools: [WebSearch, WebFetch, Read, Write, Bash, Glob, Grep]
model: sonnet
---

Research Linux ricing trends and design inspiration using the rice-scout agent persona.

## Usage

- `/rice-scout` — Default trend report (what's hot on r/unixporn)
- `/rice-scout trend` — Broad survey of current ricing trends (3-5 briefs)
- `/rice-scout deep "topic"` — Deep dive into a specific element
- `/rice-scout tools` — Scout new Wayland/tiling WM tools and widgets
- `/rice-scout wallpaper` — Find wallpapers that generate great Material You palettes
- `/rice-scout fonts` — Research font pairings for terminal + UI

## Instructions

1. Parse `$ARGUMENTS` for session type and optional topic. Default: trend report.
2. Read `~/.claude/projects/-home-ayaz/memory/topics/theming.md` for current pipeline state.
3. Read `~/.claude/projects/-home-ayaz/memory/topics/rice-research.md` if it exists — avoid repeating findings.
4. Use **WebSearch** to research current trends based on session type.
5. Use **WebFetch** to pull details from promising links.
6. Compile findings into structured Inspiration Briefs (trend name, visual description, links, adaptation steps, difficulty, vibe match).
7. Append findings to `~/.claude/projects/-home-ayaz/memory/topics/rice-research.md`.
8. End with 2-3 concrete "quick wins" the user could implement now.

## Stack Context

Niri + Quickshell (iNiR) + matugen Material You pipeline + kitty + fish + starship + yazi + Firefox ShyMaterial. Dark theme preference, modern/clean/functional aesthetic. NOT a frontend dev — needs actionable steps.
