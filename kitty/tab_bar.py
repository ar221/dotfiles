# ~/.config/kitty/tab_bar.py
#
# Mission-Clock Modern tab bar for iNiR / Apollo.
#
#   [1] ELSA · KITTY     [2] OPENCODE      ░░░      LOAD 1.42 · MEM 8.1G · GPU 52°C · 13:42:11
#
# Two cohabiting systems:
#
#   1. Custom tab rendering
#      - Format: " [N] UPPERCASE_TITLE " with a right-facing powerline solid
#        separator between tabs.
#      - Active tab:   fg = APOLLO accent (amber)    bg = APOLLO bg_element
#      - Inactive tab: fg = APOLLO dim (bronze_dim)  bg = APOLLO bg_panel
#
#   2. Right-side statusline (drawn once, after the last tab)
#      - If ~/.local/bin/opencode-statusline is installed and reports live
#        segments, those are rendered (OpenCode session data — load-bearing,
#        Ayaz uses this daily).
#      - Otherwise, Mission-Clock fallback: LOAD · MEM · GPU · time, Apollo-palette.
#
# Performance:
#   - kitty calls draw_tab many times per second. State reads (loadavg, mem,
#     GPU temp, OpenCode JSON) are cached with a 1-second TTL.
#   - All helpers silent-fallback. A broken statusline must never break the
#     tab bar itself.
#
# kitty.conf should set:
#   tab_bar_style   custom
#   tab_bar_min_tabs 1
#   tab_bar_edge    top         (or bottom)

from __future__ import annotations

import importlib.util
import os
import subprocess
import time
from pathlib import Path
from typing import Any

from kitty.boss import get_boss  # type: ignore
from kitty.fast_data_types import Screen, get_options  # type: ignore
from kitty.tab_bar import (  # type: ignore
    DrawData,
    ExtraData,
    TabBarData,
    as_rgb,
)
from kitty.utils import color_as_int  # type: ignore

# ---------------------------------------------------------------------------
# Apollo palette — Mission-Clock tokens, hardcoded per the design spec.
# ---------------------------------------------------------------------------
APOLLO = {
    "bg":         "#0E0B08",   # deepest window bg
    "bg_panel":   "#1C150C",   # tab bar / status bar background
    "bg_element": "#2B1F10",   # active tab background
    "fg":         "#F2E3C6",   # primary fg (cream)
    "accent":     "#FFB648",   # amber — active-tab fg, primary accent
    "muted":      "#C9B28B",   # bronze — inactive hover, secondary text
    "dim":        "#98876F",   # bronze_dim — inactive tab fg, status labels
    "ok":         "#A8C97B",   # sage
    "warn":       "#FF5A4E",   # ember
    "info":       "#6FC5C0",   # teal — secondary data
}

# Powerline right-solid glyph — used for tab separators AND statusline
# separators. Hardcoded here so tab rendering works even if the opencode
# module isn't installed. We still prefer the module's constant when loaded.
PL_RIGHT_SOLID_DEFAULT = ""  #

# ---------------------------------------------------------------------------
# Opencode renderer module (optional — silent fallback if missing).
# ---------------------------------------------------------------------------
_RENDERER_PATH = Path.home() / ".local/bin/opencode-statusline"
_renderer_module: Any = None
_renderer_mtime: float = 0.0


def _load_renderer() -> Any:
    """Load (and hot-reload on mtime change) the opencode-statusline module."""
    global _renderer_module, _renderer_mtime
    try:
        mtime = _RENDERER_PATH.stat().st_mtime
    except OSError:
        return None
    if _renderer_module is not None and mtime == _renderer_mtime:
        return _renderer_module
    try:
        spec = importlib.util.spec_from_file_location(
            "opencode_statusline", _RENDERER_PATH
        )
        if spec is None or spec.loader is None:
            return None
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        _renderer_module = mod
        _renderer_mtime = mtime
        return mod
    except Exception:
        return None


def _pl_right() -> str:
    """Prefer the opencode module's glyph, fall back to local constant."""
    mod = _renderer_module
    try:
        if mod is not None and isinstance(mod.PL_RIGHT_SOLID, str):
            return mod.PL_RIGHT_SOLID
    except Exception:
        pass
    return PL_RIGHT_SOLID_DEFAULT


# ---------------------------------------------------------------------------
# Segment shape for the Mission-Clock fallback. Mirrors opencode's Segment
# (text/fg/bg/bold) so _draw_statusline can treat both sources identically.
# ---------------------------------------------------------------------------
class Seg:
    __slots__ = ("text", "fg", "bg", "bold")

    def __init__(self, text: str, fg: str, bg: str, bold: bool = False) -> None:
        self.text = text
        self.fg = fg
        self.bg = bg
        self.bold = bold


# ---------------------------------------------------------------------------
# State caching. 1-second TTL covers redraws from scroll/typing without
# hammering /proc, git, or the opencode JSON state file.
# ---------------------------------------------------------------------------
_cache: dict[str, Any] = {
    "segments": None, "pal": None, "ts": 0.0,
    "load": "?", "mem": "?", "gpu": "?", "sys_ts": 0.0,
}
_CACHE_TTL = 1.0


# ---------------------------------------------------------------------------
# Opencode segment fetch
# ---------------------------------------------------------------------------
def _get_opencode_segments() -> tuple[list[Any] | None, Any]:
    """Return (segments, palette) from opencode-statusline, or (None, None).

    An empty segment list, a stale session, or a module load failure all
    collapse to (None, None) — the caller treats that as "fall back to
    Mission-Clock."
    """
    mod = _load_renderer()
    if mod is None:
        return None, None
    try:
        state = mod.load_state()
        if not getattr(state, "active", False):
            # Fallback bar is opencode's own "no session" path — not what we
            # want. Mission-Clock is nicer when there's no active session.
            return None, None
        pal = mod.load_palette()
        segments = mod.build_segments(state, pal)
        if not segments:
            return None, None
        return segments, pal
    except Exception:
        return None, None


# ---------------------------------------------------------------------------
# Mission-Clock fallback — /proc-driven system gauges.
# ---------------------------------------------------------------------------
def _read_loadavg() -> str:
    try:
        with open("/proc/loadavg") as f:
            return f.read().split()[0]
    except Exception:
        return "?"


def _read_mem() -> str:
    """Used memory in a human-readable form, via `free -h`."""
    try:
        r = subprocess.run(
            ["free", "-h"], capture_output=True, text=True, timeout=0.3, check=False
        )
        for line in r.stdout.splitlines():
            if line.startswith("Mem:"):
                parts = line.split()
                if len(parts) >= 3:
                    return parts[2]
    except Exception:
        pass
    return "?"


def _read_gpu_temp() -> str:
    """Read first GPU hwmon temp1_input, return as '52°C'."""
    try:
        for card in sorted(Path("/sys/class/drm").glob("card*")):
            hwmon_root = card / "device" / "hwmon"
            if not hwmon_root.is_dir():
                continue
            for hw in sorted(hwmon_root.iterdir()):
                temp_file = hw / "temp1_input"
                if temp_file.exists():
                    try:
                        raw = int(temp_file.read_text().strip())
                        return f"{raw // 1000}°C"
                    except Exception:
                        continue
    except Exception:
        pass
    return "?"


def _refresh_sys_cache(now: float) -> None:
    if (now - _cache["sys_ts"]) >= _CACHE_TTL:
        _cache["load"] = _read_loadavg()
        _cache["mem"] = _read_mem()
        _cache["gpu"] = _read_gpu_temp()
        _cache["sys_ts"] = now


def _get_mission_clock_segments() -> list[Seg]:
    now = time.time()
    _refresh_sys_cache(now)
    clk = time.strftime("%H:%M:%S")
    dim, bg_panel, bg_element, accent = (
        APOLLO["dim"], APOLLO["bg_panel"], APOLLO["bg_element"], APOLLO["accent"]
    )
    return [
        Seg(f" LOAD {_cache['load']} ", dim,    bg_panel),
        Seg(f" MEM {_cache['mem']} ",   dim,    bg_panel),
        Seg(f" GPU {_cache['gpu']} ",   dim,    bg_element),
        Seg(f" {clk} ",                 accent, bg_element, bold=True),
    ]


def _get_segments() -> tuple[list[Any], Any]:
    """Prefer OpenCode segments when a session is active; else Mission-Clock."""
    now = time.time()
    if _cache["segments"] is not None and (now - _cache["ts"]) < _CACHE_TTL:
        return _cache["segments"], _cache["pal"]

    opencode_segments, opencode_pal = _get_opencode_segments()
    if opencode_segments:
        _cache["segments"] = opencode_segments
        _cache["pal"] = opencode_pal
        _cache["ts"] = now
        return opencode_segments, opencode_pal

    fallback = _get_mission_clock_segments()
    _cache["segments"] = fallback
    _cache["pal"] = None
    _cache["ts"] = now
    return fallback, None


# ---------------------------------------------------------------------------
# Color helpers
# ---------------------------------------------------------------------------
def _hex_to_int(hex_color: str) -> int:
    """Convert #RRGGBB to kitty's packed 24-bit int (as used by as_rgb)."""
    h = hex_color.lstrip("#")
    if len(h) == 3:
        h = "".join(c * 2 for c in h)
    try:
        r = int(h[0:2], 16)
        g = int(h[2:4], 16)
        b = int(h[4:6], 16)
    except (ValueError, IndexError):
        return as_rgb(0xFFFFFF)
    return as_rgb((r << 16) | (g << 8) | b)


def _segments_width(segments: list[Any]) -> int:
    """Cells needed: 1 per leading separator + text len + 1 trailing separator."""
    total = 0
    for seg in segments:
        total += 1
        total += len(seg.text)
    total += 1
    return total


# ---------------------------------------------------------------------------
# Statusline drawing — works for both OpenCode and Mission-Clock segments.
# ---------------------------------------------------------------------------
def _draw_statusline(
    draw_data: DrawData,
    screen: Screen,
    segments: list[Any],
    start_x: int,
) -> None:
    """Draw segments starting at column start_x. Assumes enough room."""
    pl = _pl_right()
    default_bg = color_as_int(draw_data.default_bg)
    tabbar_bg_int = as_rgb(default_bg)

    screen.cursor.x = start_x

    prev_bg_int = tabbar_bg_int
    for seg in segments:
        seg_bg_int = _hex_to_int(seg.bg)
        seg_fg_int = _hex_to_int(seg.fg)

        # Leading separator: fg = previous bg, bg = this seg's bg
        screen.cursor.fg = prev_bg_int
        screen.cursor.bg = seg_bg_int
        screen.draw(pl)

        # Segment text
        screen.cursor.fg = seg_fg_int
        screen.cursor.bg = seg_bg_int
        screen.draw(seg.text)

        prev_bg_int = seg_bg_int

    # Trailing separator back to tabbar bg
    screen.cursor.fg = prev_bg_int
    screen.cursor.bg = tabbar_bg_int
    screen.draw(pl)

    # Reset so any remaining padding looks clean.
    screen.cursor.fg = 0
    screen.cursor.bg = tabbar_bg_int


# ---------------------------------------------------------------------------
# Mission-Clock tab renderer (replaces draw_tab_with_powerline)
# ---------------------------------------------------------------------------
def _draw_mission_clock_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_tab_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    """Render ' [N] UPPERCASE_TITLE ' with Apollo colors and right-solid separators."""
    pl = _pl_right()
    default_bg_int = as_rgb(color_as_int(draw_data.default_bg))

    is_active = bool(getattr(tab, "is_active", False))
    if is_active:
        tab_bg_hex = APOLLO["bg_element"]
        tab_fg_hex = APOLLO["accent"]
    else:
        tab_bg_hex = APOLLO["bg_panel"]
        tab_fg_hex = APOLLO["dim"]
    tab_bg_int = _hex_to_int(tab_bg_hex)
    tab_fg_int = _hex_to_int(tab_fg_hex)

    # Determine the bg of the next tab (for the trailing separator color).
    # If this is the last tab, the trailing separator flows back to the
    # tabbar's default bg.
    next_bg_int = default_bg_int
    nxt = getattr(extra_data, "next_tab", None)
    if nxt is not None:
        next_is_active = bool(getattr(nxt, "is_active", False))
        next_bg_int = _hex_to_int(
            APOLLO["bg_element"] if next_is_active else APOLLO["bg_panel"]
        )

    # --- Build the label --------------------------------------------------
    tab_num = index  # kitty passes 1-indexed `index`
    raw_title = (tab.title or "").strip()
    title = raw_title.upper() if raw_title else f"TAB {tab_num}"
    label = f" [{tab_num}] {title} "

    # --- Enforce max_tab_length ------------------------------------------
    # We have to leave 1 cell for the trailing separator. Truncate label
    # with an ellipsis if it would overshoot.
    budget = max(3, max_tab_length - 1)  # at least ' … '
    if len(label) > budget:
        if budget >= 2:
            label = label[: budget - 1] + "…"
        else:
            label = "…"

    # --- Draw label -------------------------------------------------------
    screen.cursor.fg = tab_fg_int
    screen.cursor.bg = tab_bg_int
    if getattr(tab, "is_active", False):
        # Bold pulls more weight from Krypton and reinforces the accent.
        try:
            screen.cursor.bold = True  # type: ignore[attr-defined]
        except Exception:
            pass
    screen.draw(label)

    # Reset bold before separator.
    try:
        screen.cursor.bold = False  # type: ignore[attr-defined]
    except Exception:
        pass

    # --- Trailing separator ----------------------------------------------
    # Fg = this tab's bg, Bg = next tab's bg (or tabbar bg if last).
    screen.cursor.fg = tab_bg_int
    screen.cursor.bg = next_bg_int
    screen.draw(pl)

    return screen.cursor.x


# ---------------------------------------------------------------------------
# draw_tab — kitty calls this for every tab, every redraw. Signature fixed.
# ---------------------------------------------------------------------------
def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_tab_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    end = _draw_mission_clock_tab(
        draw_data, screen, tab, before, max_tab_length, index, is_last, extra_data
    )

    if not is_last:
        return end

    # After the last tab — fill the rest of the bar with the statusline.
    try:
        segments, _pal = _get_segments()
        if not segments:
            return end

        screen_cols = screen.columns
        needed = _segments_width(segments)
        available = screen_cols - end - 1   # one cell of breathing room

        if available <= 0:
            return end

        # Truncate if needed — opencode module has a truncator we prefer.
        if needed > available:
            mod = _renderer_module
            if mod is not None and hasattr(mod, "truncate_segments"):
                try:
                    segments = mod.truncate_segments(segments, max(0, available))
                    needed = _segments_width(segments)
                except Exception:
                    pass
            # If still too wide, drop from the left (the system labels) until
            # we fit — preserves the clock.
            while needed > available and len(segments) > 1:
                segments = segments[1:]
                needed = _segments_width(segments)
            if needed > available or not segments:
                return end

        # Right-align: pad the gap with tab-bar bg, then draw.
        start_x = screen_cols - needed
        default_bg_int = as_rgb(color_as_int(draw_data.default_bg))
        screen.cursor.fg = 0
        screen.cursor.bg = default_bg_int
        pad = start_x - end
        if pad > 0:
            screen.draw(" " * pad)

        _draw_statusline(draw_data, screen, segments, screen.cursor.x)
        return screen.cursor.x
    except Exception:
        # Never break the tab bar on statusline errors.
        return end
