/**
 * statusline — OpenCode plugin
 *
 * Writes session/message state to ~/.local/state/opencode/statusline.json
 * on every lifecycle event, so external renderers (kitty tab_bar, etc.)
 * can surface a persistent powerline-style status strip.
 *
 * OpenCode itself has no native statusline primitive (tui.json schema has
 * no statusline key; plugin hooks only expose transient toasts). The bar
 * lives one layer out: kitty reads this JSON and draws the bar in the
 * terminal's tab_bar strip, above/below the TUI viewport.
 *
 * State file is written atomically (write → rename) so readers never see
 * a partial document. Debounced at ~100ms to avoid hammering on rapid
 * message.updated churn during streaming responses.
 *
 * Schema (statusline.json):
 *   {
 *     schema: 1,
 *     updated: "ISO timestamp",
 *     pid: <opencode process id>,
 *     session: {
 *       id, title, directory, createdAt, updatedAt,
 *       status: "idle"|"busy"|"retry"|"error"|"unknown",
 *       statusDetail?: "retry message, etc"
 *     },
 *     model: {
 *       providerID, modelID,
 *       tokens: { input, output, reasoning, cacheRead, cacheWrite, total },
 *       cost
 *     } | null,
 *     todos: { pending, in_progress, completed } | null,
 *     error: string | null
 *   }
 *
 * Readers: treat any field as possibly missing. Renderer is responsible
 * for graceful fallback. If the file is older than 60s AND pid is gone,
 * assume no active session and render minimal fallback bar.
 */

import type { Plugin } from "@opencode-ai/plugin"
import { writeFile, rename, mkdir } from "node:fs/promises"
import { basename, join } from "node:path"
import { homedir } from "node:os"

const STATE_DIR = join(homedir(), ".local", "state", "opencode")
const STATE_FILE_LEGACY = join(STATE_DIR, "statusline.json")
const STATE_FILE_MAIN = join(STATE_DIR, "statusline-main.json")
const STATE_FILE_COPILOT = join(STATE_DIR, "statusline-copilot.json")
const DEBOUNCE_MS = 100

const normalizeRole = (value: unknown): "main" | "copilot" | "unknown" => {
  const role = String(value ?? "").trim().toLowerCase()
  if (role === "main") return "main"
  if (role === "copilot") return "copilot"
  return "unknown"
}

const targetFilesForRole = (role: "main" | "copilot" | "unknown") => {
  if (role === "main") return [STATE_FILE_MAIN, STATE_FILE_LEGACY]
  if (role === "copilot") return [STATE_FILE_COPILOT]
  return [STATE_FILE_LEGACY]
}

const tmpFor = (target: string) => `${target}.tmp.${process.pid}`

const summarizeLsp = (
  rows: Array<{ id: string; name: string; root: string; status: string }>,
) => {
  let connected = 0
  let error = 0
  for (const row of rows) {
    if (row.status === "connected") connected++
    else error++
  }
  return {
    total: rows.length,
    connected,
    error,
    items: rows.map((row) => ({
      id: row.id,
      name: row.name,
      status: row.status,
      root: basename(row.root || ""),
    })),
  }
}

export const Statusline: Plugin = async ({ client, directory }) => {
  await mkdir(STATE_DIR, { recursive: true })
  const role = normalizeRole(process.env.APOLLO_ROLE)
  const targetFiles = targetFilesForRole(role)

  // Latest state — mutated in place, serialized on flush.
  const state: any = {
    schema: 1,
    updated: new Date().toISOString(),
    pid: process.pid,
    session: null,
    model: null,
    todos: null,
    error: null,
    role,
    lsp: {
      total: 0,
      connected: 0,
      error: 0,
      items: [],
    },
    bootDirectory: directory,
  }

  let flushTimer: ReturnType<typeof setTimeout> | null = null
  let flushing = false
  let dirty = false

  const flush = async () => {
    if (flushing) {
      dirty = true
      return
    }
    flushing = true
    try {
      state.updated = new Date().toISOString()
      const body = JSON.stringify(state, null, 2)
      for (const target of targetFiles) {
        const tmp = tmpFor(target)
        await writeFile(tmp, body, "utf8")
        await rename(tmp, target)
      }
    } catch (err) {
      await client.app.log({
        body: {
          service: "statusline",
          level: "warn",
          message: "failed to write statusline state",
          extra: { error: String(err), stack: (err as any)?.stack },
        },
      })
    } finally {
      flushing = false
      if (dirty) {
        dirty = false
        scheduleFlush()
      }
    }
  }

  const scheduleFlush = () => {
    if (flushTimer) return
    flushTimer = setTimeout(() => {
      flushTimer = null
      flush()
    }, DEBOUNCE_MS)
  }

  const updateSession = (info: any, status?: string, statusDetail?: string) => {
    state.session = {
      id: info.id,
      title: info.title,
      directory: info.directory,
      createdAt: info.time?.created,
      updatedAt: info.time?.updated,
      status: status ?? state.session?.status ?? "unknown",
      statusDetail: statusDetail ?? state.session?.statusDetail ?? null,
    }
  }

  const refreshLsp = async () => {
    try {
      const rows = (await client.lsp.status()) as Array<{
        id: string
        name: string
        root: string
        status: string
      }>
      state.lsp = summarizeLsp(Array.isArray(rows) ? rows : [])
    } catch (err) {
      await client.app.log({
        body: {
          service: "statusline",
          level: "warn",
          message: "failed to refresh lsp status",
          extra: { error: String(err) },
        },
      })
    }
  }

  await client.app.log({
    body: {
      service: "statusline",
      level: "info",
      message: "Statusline plugin loaded",
      extra: { stateFiles: targetFiles, pid: process.pid, directory, role },
    },
  })

  // Fire-and-forget the initial LSP refresh. Blocking on client.lsp.status()
  // during plugin init deadlocks OpenCode's bootstrap — the LSP server can't
  // finish initialization until all plugins return from their init hook, and
  // our client.lsp.status() call never resolves until LSP is up. The lsp.updated
  // event handler will populate state.lsp reactively once LSP comes online.
  void refreshLsp().then(() => scheduleFlush())

  // Best-effort initial write so the renderer has something immediately,
  // even before LSP is up.
  scheduleFlush()

  return {
    event: async ({ event }) => {
      try {
        switch (event.type) {
          case "session.created":
          case "session.updated": {
            const info = (event as any).properties?.info
            if (info) updateSession(info)
            scheduleFlush()
            break
          }

          case "session.status": {
            const props = (event as any).properties
            const st = props?.status
            if (state.session && props?.sessionID === state.session.id) {
              state.session.status = st?.type ?? "unknown"
              state.session.statusDetail =
                st?.type === "retry"
                  ? `retry ${st.attempt ?? "?"}: ${st.message ?? ""}`
                  : null
            } else if (st?.type) {
              // No session object yet — stash the status so the next
              // session.updated doesn't clobber a busy→idle signal.
              state.session = state.session ?? {}
              state.session.status = st.type
              state.session.statusDetail = null
            }
            scheduleFlush()
            break
          }

          case "session.idle": {
            if (state.session) {
              state.session.status = "idle"
              state.session.statusDetail = null
            }
            scheduleFlush()
            break
          }

          case "session.error": {
            const msg = (event as any).properties?.error?.data?.message
            state.error = msg ?? "unknown error"
            if (state.session) state.session.status = "error"
            scheduleFlush()
            break
          }

          case "session.deleted": {
            const info = (event as any).properties?.info
            if (state.session && info?.id === state.session.id) {
              state.session = null
              state.model = null
              state.todos = null
            }
            scheduleFlush()
            break
          }

          case "message.updated": {
            const info = (event as any).properties?.info
            if (info?.role === "assistant") {
              const t = info.tokens ?? {}
              const cacheRead = t.cache?.read ?? 0
              const cacheWrite = t.cache?.write ?? 0
              // "total" here = input + output + reasoning + cache writes.
              // Cache reads are NOT billed as context — they're re-used context.
              const total =
                (t.input ?? 0) + (t.output ?? 0) + (t.reasoning ?? 0) + cacheWrite
              state.model = {
                providerID: info.providerID,
                modelID: info.modelID,
                tokens: {
                  input: t.input ?? 0,
                  output: t.output ?? 0,
                  reasoning: t.reasoning ?? 0,
                  cacheRead,
                  cacheWrite,
                  total,
                },
                cost: info.cost ?? 0,
              }
              // message-updated also implies session activity; if we have no
              // session status yet, mark busy so the bar reflects reality.
              if (state.session && state.session.status === "unknown") {
                state.session.status = "busy"
              }
              scheduleFlush()
            }
            break
          }

          case "todo.updated": {
            const todos = (event as any).properties?.todos ?? []
            const counts = { pending: 0, in_progress: 0, completed: 0, cancelled: 0 }
            for (const t of todos) {
              const k = t.status as keyof typeof counts
              if (k in counts) counts[k]++
            }
            state.todos = counts
            scheduleFlush()
            break
          }

          case "lsp.updated":
          case "lsp.client.diagnostics": {
            await refreshLsp()
            scheduleFlush()
            break
          }
        }
      } catch (err) {
        await client.app.log({
          body: {
            service: "statusline",
            level: "warn",
            message: "event handler threw",
            extra: { type: event.type, error: String(err) },
          },
        })
      }
    },
  }
}
