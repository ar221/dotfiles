#!/usr/bin/env python3
"""
SessionStart hook — auto-loads Claude Code project memory into context.

Replaces the manual "read MEMORY.md first" instruction (CLAUDE.md §0) with
automatic injection. Fires on every session start and post-compaction resume.

Determines the active project from hook input (cwd/project_path), finds the
matching memory directory, reads MEMORY.md index, and injects it as context.
Also loads shared memory index for cross-cutting user context.

Coexists with the llm-personal-kb SessionStart hook (both fire sequentially).
"""

import json
import sys
from pathlib import Path

# Memory roots
PROJECTS_MEMORY = Path.home() / ".claude" / "projects"
SHARED_MEMORY = Path.home() / ".claude" / "shared-memory"

# Max chars to inject (keep it reasonable — this hits every session)
MAX_CONTEXT_CHARS = 30_000


def project_key_from_path(cwd: str) -> str:
    """Convert a working directory to Claude Code's project key format.

    Claude Code stores project memory at:
      ~/.claude/projects/<sanitized-path>/memory/
    where the path has slashes replaced with dashes and leading dash.
    e.g., /home/ayaz -> -home-ayaz
          /home/ayaz/Github/inir -> -home-ayaz-Github-inir
    """
    return cwd.replace("/", "-")


def find_memory_dir(cwd: str) -> Path | None:
    """Find the memory directory for the given working directory.

    Tries exact match first, then walks up parent directories.
    """
    # Try exact match
    key = project_key_from_path(cwd)
    candidate = PROJECTS_MEMORY / key / "memory"
    if candidate.exists():
        return candidate

    # Walk up parent directories
    path = Path(cwd)
    for parent in path.parents:
        key = project_key_from_path(str(parent))
        candidate = PROJECTS_MEMORY / key / "memory"
        if candidate.exists():
            return candidate

    return None


def read_file_safe(path: Path, max_chars: int = 0) -> str:
    """Read a file, returning empty string on any error."""
    try:
        content = path.read_text(encoding="utf-8")
        if max_chars and len(content) > max_chars:
            content = content[:max_chars] + "\n...(truncated)"
        return content
    except (OSError, UnicodeDecodeError):
        return ""


def build_context(cwd: str) -> str:
    """Assemble memory context for injection."""
    parts = []

    # 1. Shared memory index (cross-cutting: user profile, preferences, system)
    shared_index = SHARED_MEMORY / "MEMORY.md"
    if shared_index.exists():
        content = read_file_safe(shared_index, max_chars=3000)
        if content:
            parts.append(f"## Shared Memory (cross-domain)\n\n{content}")

    # 2. Project-specific memory index
    memory_dir = find_memory_dir(cwd)
    if memory_dir:
        project_index = memory_dir / "MEMORY.md"
        if project_index.exists():
            content = read_file_safe(project_index, max_chars=15000)
            if content:
                parts.append(f"## Project Memory\n\n{content}")

        # 3. Recent journal entries (last 2 days)
        journal_dir = memory_dir / "journal"
        if journal_dir.exists():
            journal_files = sorted(journal_dir.glob("*.md"), reverse=True)[:2]
            for jf in journal_files:
                jcontent = read_file_safe(jf, max_chars=3000)
                if jcontent:
                    parts.append(f"## Recent Journal: {jf.stem}\n\n{jcontent}")

    if not parts:
        return ""

    context = "\n\n---\n\n".join(parts)

    # Final truncation guard
    if len(context) > MAX_CONTEXT_CHARS:
        context = context[:MAX_CONTEXT_CHARS] + "\n\n...(truncated)"

    return context


def main():
    # Read hook input
    try:
        hook_input = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, EOFError):
        hook_input = {}

    cwd = hook_input.get("cwd", str(Path.home()))

    context = build_context(cwd)

    if not context:
        sys.exit(0)

    output = {
        "hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": context,
        }
    }

    print(json.dumps(output))


if __name__ == "__main__":
    main()
