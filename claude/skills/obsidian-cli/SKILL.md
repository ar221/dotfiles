---
name: obsidian-cli
description: Headless access to Ayaz's Obsidian vault (Ayaz OS) — search, read, frontmatter ops, and safe moves that rewrite wikilinks automatically. Use whenever an agent needs to touch the vault without the GUI. Prefer this over raw mv/sed on vault files — link-aware moves and YAML-safe frontmatter edits are the killer features. Full reference is loaded below.
version: 1.0.0
user-invocable: true
---

# obsidian-cli — Headless Vault Operations

`/usr/bin/obsidian-cli` (package: `obsidian-cli-git`, internally `notesmd-cli`) — pre-registered with the `Ayaz OS` vault as default. Config at `~/.config/notesmd-cli/preferences.json`.

Full reference: **`~/.claude/shared-memory/obsidian-cli.md`** — read that file for exhaustive flag details. This skill is the quick card.

## When to Use This Tool

- Moving / renaming a vault note (wikilinks get rewritten automatically — `mv` breaks them)
- Editing a single frontmatter key (YAML-safe — won't corrupt quoting)
- Reading frontmatter without slurping the whole note
- Fuzzy content search across the vault
- Bulk frontmatter backfills (loop `fm --edit` in Bash)

## When NOT to Use

- GUI-only subcommands: `open`, `create` (interactive), `daily`, `search` (no `-content`) — useless headless
- Body-of-note edits — use `Edit` tool; obsidian-cli has no body editor
- Strict regex search — use `Grep`; obsidian-cli search is fuzzy
- Vault-wide schema migrations without sign-off — frontmatter changes ripple into Dataview / Auto Note Mover. Always propose first.

## Command Card

### Discovery & Config

```bash
obsidian-cli list-vaults                    # Registered vaults
obsidian-cli print-default                  # Default vault name + path
obsidian-cli list [path]                    # List files/folders (vault-relative)
```

### Reading & Searching

```bash
obsidian-cli print "<note>"                                    # Headless read
obsidian-cli print "<note>" -m                                 # With backlink mentions
obsidian-cli search-content "<term>" --no-interactive --format json  # KILLER FEATURE
obsidian-cli search "<term>"                                   # Fuzzy (interactive unless piped)
```

### Frontmatter Ops

```bash
obsidian-cli frontmatter "<note>" --print                       # Print YAML
obsidian-cli frontmatter "<note>" --edit --key <k> --value <v>  # Edit one key
obsidian-cli frontmatter "<note>" --delete --key <k>            # Delete one key

# Short-form alias exists:
obsidian-cli fm "<note>" -p
obsidian-cli fm "<note>" -e -k status --value compiled
obsidian-cli fm "<note>" -d -k draft
```

### Writing & Moving

```bash
obsidian-cli create "<note>" -a -c "<text>"     # Append (creates if missing)
obsidian-cli create "<note>" -c "<text>" -o     # Overwrite
obsidian-cli move "<src>" --to "<dst>"          # RENAME + auto-update backlinks
obsidian-cli delete "<note>"                    # Delete (avoid — propose archive instead)
```

## Rules

1. **`move` is the wikilink-safe relocation primitive.** Use it any time a file move could orphan a link — archive operations, topic renames, template promotions. `mv` will break backlinks across the vault; `obsidian-cli move` rewrites them.
2. **`fm --edit` is the YAML-safe frontmatter primitive.** Hand-patching YAML with `sed` corrupts quoting and nested keys. Use `fm` for every frontmatter touch.
3. **Bulk edits go in Bash loops.** Short, traceable, echo the target each iteration so failures are visible.
4. **Fallback on fuzzy-match failure.** If a fuzzy note name is ambiguous or not found, rerun with the exact vault-relative path.
5. **No writes to `00 Notes/Assets/`.** Plugin-owned (Local Images Plus). Breaks wikilinks if touched.
6. **No deletions.** Archive via `move` to `99 Archive/` instead.

## Output Format Note

`search-content --format json` returns `[{file, line, content, match_type}]`. Pipe through `jq` for filtering:

```bash
obsidian-cli search-content "<term>" --no-interactive --format json \
  | jq -r '.[] | "\(.file):\(.line): \(.content)"'
```

## Who Uses This Skill

Wired into: **curator**, **borges**, **dexter**, **insights-sweep** (read-only). If you're another agent and you find yourself reaching for vault ops, check that list first — the work may be properly delegable.
