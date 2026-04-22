#!/usr/bin/env python3
"""SubagentStop hook — verify claimed file deliverables exist on disk.

Scans the subagent's final message (`last_assistant_message`) for claims like
"Created /path/to/file" or "Wrote `~/foo.md`" and verifies those paths exist.

- HARD FAIL (blocks, surfaces to parent context): `created|wrote` a path that
  does not exist.
- SOFT WARN (stderr only): `modified|updated|deleted|removed` mismatches.
- PASS (silent): no claims detected OR all claims verify.

Bypass: export CLAUDE_SKIP_VERIFY_DELIVERABLES=1

V1 limitations (documented, acceptable):
- Only verifies absolute (/foo) and home-anchored (~/foo) paths. Relative paths
  ignored to keep noise down.
- Existence check only — does not verify mtime fell within subagent's run.
- Regex extraction only; no <deliverables> opt-in contract yet.
"""
import json
import os
import re
import sys


PATH_CHARS = r"[^\s`\"'<>)]+"
PATH_RE = rf"(~?/{PATH_CHARS})"

HARD_RE = re.compile(
    rf"\b(creat(?:ed|ing)|wrote|writing|wrote\s+to)\b[^\n]{{0,60}}?[`\"']?{PATH_RE}",
    re.IGNORECASE,
)
SOFT_RE = re.compile(
    rf"\b(modif(?:ied|ying)|updat(?:ed|ing)|delet(?:ed|ing)|remov(?:ed|ing))\b"
    rf"[^\n]{{0,60}}?[`\"']?{PATH_RE}",
    re.IGNORECASE,
)

PLACEHOLDER_RE = re.compile(r"<[A-Z_/<>]+>|PATH/TO|/path/to\b", re.IGNORECASE)

# Paths under these prefixes are ephemeral — exempt from verification.
# Agents frequently describe past test artifacts, sentinel files, and temp
# pipelines that have been legitimately cleaned up. Verifying these produces
# noisy false positives with low hallucination-catching value.
EPHEMERAL_PREFIXES = ("/tmp/", "/var/tmp/", "/dev/shm/", "/run/user/")


def strip_code_fences(msg: str) -> str:
    """Remove lines inside ``` fenced blocks to reduce false positives."""
    out = []
    in_fence = False
    for line in msg.split("\n"):
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
            continue
        if not in_fence:
            out.append(line)
    return "\n".join(out)


def looks_real(path: str) -> bool:
    if PLACEHOLDER_RE.search(path):
        return False
    # Skip ephemeral locations — not reliable hallucination signal.
    expanded = os.path.expanduser(path)
    if expanded.startswith(EPHEMERAL_PREFIXES):
        return False
    return True


def normalize(path: str, cwd: str) -> str:
    path = os.path.expanduser(path)
    if not os.path.isabs(path):
        path = os.path.join(cwd, path)
    return path


def extract_paths(regex: re.Pattern, body: str) -> list[str]:
    paths = [m.group(2) for m in regex.finditer(body) if looks_real(m.group(2))]
    # De-dup while preserving order
    return list(dict.fromkeys(paths))


def run() -> int:
    if os.environ.get("CLAUDE_SKIP_VERIFY_DELIVERABLES") == "1":
        return 0

    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0

    msg = data.get("last_assistant_message") or ""
    if not msg.strip():
        return 0

    agent_type = data.get("agent_type", "unknown")
    cwd = data.get("cwd") or os.getcwd()

    body = strip_code_fences(msg)
    hard_paths = extract_paths(HARD_RE, body)
    soft_paths = extract_paths(SOFT_RE, body)

    missing_hard = [p for p in hard_paths if not os.path.exists(normalize(p, cwd))]
    missing_soft = [p for p in soft_paths if not os.path.exists(normalize(p, cwd))]

    for p in missing_soft:
        print(
            f"verify-deliverables [{agent_type}]: SOFT WARN — claimed "
            f"modify/update/delete of '{p}' but not on disk",
            file=sys.stderr,
        )

    if missing_hard:
        reason_lines = [
            f"Subagent '{agent_type}' claimed to create or write the following "
            f"paths, but they do not exist on disk:"
        ]
        for p in missing_hard:
            reason_lines.append(f"  - {p}")
        reason_lines.append("")
        reason_lines.append(
            "This may indicate a hallucinated deliverable. Verify with the "
            "subagent or re-dispatch. Bypass: CLAUDE_SKIP_VERIFY_DELIVERABLES=1"
        )
        print(json.dumps({"decision": "block", "reason": "\n".join(reason_lines)}))
        return 0

    return 0


if __name__ == "__main__":
    try:
        sys.exit(run())
    except Exception as e:
        # Fail-safe: never block on script errors.
        print(f"verify-deliverables: internal error: {e}", file=sys.stderr)
        sys.exit(0)
