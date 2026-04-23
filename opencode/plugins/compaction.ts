/**
 * compaction — OpenCode plugin
 *
 * Injects coordinator context into the compaction continuation prompt so
 * Alfred (or whichever coordinator identity is active) doesn't lose its
 * grounding after a session compacts.
 *
 * The default compaction summary naturally preserves task state (files
 * changed, what was being built) but drops the operator context: who is
 * running this session, what shared memory should be loaded, what Hermes
 * may have left in the inbox, which project this belongs to.
 *
 * This hook injects a compact briefing block covering:
 *   - Active coordinator identity and execution surface
 *   - Key shared-memory anchors (by path reference, not full content —
 *     the continuation model reads them fresh if it needs depth)
 *   - Hermes → Alfred inbox snapshot (verbatim if non-empty, skip if empty)
 *   - Working directory and MCP stack availability
 *
 * Principle: inject enough to re-orient, not so much that it crowds out
 * the actual task summary the model generates. Keep it under ~300 tokens.
 *
 * Fail-safe: every file read is wrapped in try/catch. A missing file
 * produces a one-line note rather than breaking compaction.
 */

import type { Plugin } from "@opencode-ai/plugin"
import { readFile } from "node:fs/promises"
import { homedir } from "node:os"
import { join } from "node:path"

const HOME = homedir()

const safeRead = async (path: string): Promise<string | null> => {
  try {
    return await readFile(path, "utf8")
  } catch {
    return null
  }
}

const extractHermesInboxEntries = (content: string): string => {
  const marker = "<!-- entries below this line -->"
  const idx = content.indexOf(marker)
  if (idx === -1) return ""
  const entries = content.slice(idx + marker.length).trim()
  return entries
}

export const CompactionContext: Plugin = async ({ client, directory }) => {
  await client.app.log({
    body: {
      service: "compaction",
      level: "info",
      message: "Compaction context plugin loaded",
    },
  })

  return {
    "experimental.session.compacting": async (_input, output) => {
      try {
        const lines: string[] = []

        // ── Coordinator identity ──────────────────────────────────────────
        // Detect active coordinator from working directory
        const cwd = directory ?? process.cwd()
        let coordinator = "Alfred"
        let coordinatorNote = "home base / system layer"
        if (cwd.includes("/Documents/Ayaz OS")) {
          coordinator = "Oracle"
          coordinatorNote = "vault 713 / planning layer"
        } else if (cwd.includes("/STWork")) {
          coordinator = "Scheherazade"
          coordinatorNote = "STWork / creative layer"
        } else if (cwd.includes("/Modding")) {
          coordinator = "Mr. House"
          coordinatorNote = "Modding / Wild Card domain"
        } else if (cwd.includes("/Github/inir") || cwd.includes("/.config/quickshell")) {
          coordinator = "Elsa"
          coordinatorNote = "iNiR / desktop shell"
        }

        lines.push("## Coordinator Context (injected at compaction)")
        lines.push("")
        lines.push(`**Active coordinator:** ${coordinator} — ${coordinatorNote}`)
        lines.push(`**Execution surface:** OpenCode TUI (claude-proxy/claude-sonnet-4-6)`)
        lines.push(`**Working directory:** ${cwd}`)
        lines.push("")

        // ── Shared memory anchors ─────────────────────────────────────────
        // Reference paths only — the continuation model re-reads if needed.
        // Full content injection would crowd the task summary.
        lines.push("**Shared memory anchors to reload if needed:**")
        lines.push(`- Identity: \`~/.claude/shared-memory/${coordinator.toLowerCase().replace("mr. house", "house").replace(" ", "-")}-identity.md\``)
        lines.push(`- System context: \`~/.claude/shared-memory/system-context.md\``)
        lines.push(`- Active domains: \`~/.claude/shared-memory/active-domains.md\``)
        lines.push(`- Cross-domain feedback: \`~/.claude/shared-memory/cross-domain-feedback.md\``)
        lines.push(`- Known traps: \`~/.claude/shared-memory/known-traps.md\``)
        lines.push("")

        // ── MCP stack ─────────────────────────────────────────────────────
        lines.push("**MCP servers available:** vault, projects, stwork, modding, scripts, github, browser")
        lines.push("")

        // ── Hermes → Alfred inbox ─────────────────────────────────────────
        const inboxPath = join(HOME, ".claude", "shared-memory", "hermes-inbox-alfred.md")
        const inboxContent = await safeRead(inboxPath)

        if (inboxContent !== null) {
          const entries = extractHermesInboxEntries(inboxContent)
          if (entries.length > 0) {
            lines.push("**Hermes → Alfred inbox (unprocessed entries):**")
            lines.push("```")
            // Cap at 800 chars to avoid bloating the compaction prompt
            const capped = entries.length > 800
              ? entries.slice(0, 800) + "\n… (truncated — read full inbox at compaction resume)"
              : entries
            lines.push(capped)
            lines.push("```")
            lines.push("")
          } else {
            lines.push("**Hermes inbox:** empty (no pending handoffs)")
            lines.push("")
          }
        } else {
          lines.push("**Hermes inbox:** could not read (path may be missing)")
          lines.push("")
        }

        // ── Operator model reminder ────────────────────────────────────────
        lines.push("**Operating rules:** Explore → Plan → Act → Verify. 3-3 Rule (>3 reads or >3 commands → delegate). Back up before modifying. Never kill `qs`.")
        lines.push("")
        lines.push("*This block was injected by the compaction plugin. The task summary above is the model-generated continuation.*")

        output.context.push(lines.join("\n"))

        await client.app.log({
          body: {
            service: "compaction",
            level: "info",
            message: "Coordinator context injected into compaction prompt",
            extra: { coordinator, cwd, inboxHasEntries: !!(inboxContent && extractHermesInboxEntries(inboxContent).length > 0) },
          },
        })
      } catch (err) {
        // Never break compaction — degrade gracefully
        await client.app.log({
          body: {
            service: "compaction",
            level: "warn",
            message: "Compaction context injection failed — proceeding without coordinator context",
            extra: { error: String(err) },
          },
        })
      }
    },
  }
}
