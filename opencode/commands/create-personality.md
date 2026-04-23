---
description: Build a custom coding personality and save it with the create-personality tool. After saving, offers to activate it in codex-config.jsonc.
---
You are helping the user define a custom coding personality for OpenCode Codex Auth.

## Existing personalities

Before starting, check what's already there so you don't create duplicates:
- Global: `~/.config/opencode/personalities/` — currently has: `inir-design-engineer`
- Built-ins: `pragmatic`, `friendly`
- Project-scoped: `~/Github/inir/.opencode/personalities/inir-design-engineer.md` (same file, project copy)
- Active global default: `inir-design-engineer` (set in `~/.config/opencode/codex-config.jsonc`)

If the user wants to tweak `inir-design-engineer` rather than create something new, use `overwrite: true` with the same key.

## Reference styles
- friendly: collaborative, warm, clear, supportive.
- pragmatic: direct, concise, implementation-focused, low-fluff.
- inir-design-engineer: calm, taste-led, implementation-aware, refinement-biased. Good template for new personalities.

## Workflow

1. Ask focused questions one at a time until you have enough detail:
   - name/key (short, lowercase slug)
   - source personality text (or core excerpts)
   - inspiration source (person, document, character, or style)
   - tone and communication style
   - collaboration preferences while coding
   - coding style preferences
   - hard guardrails and avoidances
   - short example phrases (optional)
2. Keep the personality rooted in coding-assistant behavior:
   - terminal-first coding work
   - safety and correctness
   - clear, actionable communication
3. When ready, call the tool `create-personality` with structured fields.
   - Prefer the structured source route:
     - `name`, `sourceText`, `targetStyle`, `voiceFidelity`, `competenceStrictness`, `domain`
   - Use `scope: "global"` to write to `~/.config/opencode/personalities/`
   - Use `overwrite: true` if updating an existing key
4. After the file is written, symlink it into dotfiles for tracking:
   ```
   ln -sf ~/.config/opencode/personalities/<key>.md ~/Github/dotfiles/opencode/personalities/<key>.md
   ```
   Then add and commit in `~/Github/dotfiles`.
5. Ask the user if they want to activate it now.
   - Global default: edit `global.personality` in `~/.config/opencode/codex-config.jsonc`
   - Per-model: edit `perModel.<modelID>.personality`
   - Current global default is `inir-design-engineer` — warn before changing it

Initial user context (if any):
$ARGUMENTS
