/**
 * notifier — OpenCode plugin
 *
 * Fires a Niri desktop notification on key session lifecycle events.
 * This is the hello-world plugin for the opencode-pilot task (System/opencode-pilot).
 *
 * Events handled:
 *   - session.idle   → "Session idle, ready for input"
 *   - session.error  → "Session errored: <message>"
 *
 * Deliberately silent on session.created / session.updated to avoid notification spam.
 *
 * Logs to OpenCode's structured log via client.app.log so debugging doesn't
 * require console scraping.
 */

import type { Plugin } from "@opencode-ai/plugin"

export const Notifier: Plugin = async ({ $, client }) => {
  await client.app.log({
    body: {
      service: "notifier",
      level: "info",
      message: "Notifier plugin loaded",
    },
  })

  const notify = async (title: string, body: string, urgency: "low" | "normal" | "critical" = "normal") => {
    try {
      await $`notify-send --app-name=opencode --urgency=${urgency} ${title} ${body}`.quiet()
    } catch (err) {
      await client.app.log({
        body: {
          service: "notifier",
          level: "warn",
          message: "notify-send failed",
          extra: { error: String(err) },
        },
      })
    }
  }

  return {
    event: async ({ event }) => {
      if (event.type === "session.idle") {
        await notify("OpenCode", "Session idle — ready for input", "low")
      } else if (event.type === "session.error") {
        const msg = (event as any).properties?.error?.data?.message ?? "unknown error"
        await notify("OpenCode — error", msg, "critical")
      }
    },
  }
}
