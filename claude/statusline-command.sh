#!/usr/bin/env bash
# Claude Code status line — styled after Starship iNiR config
# Reads JSON from stdin, outputs a single status line

input=$(cat)

# Extract fields
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
git_branch=""
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // empty')
ctx_window=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')
rate_5h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rate_7d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')

# Shorten path: replace $HOME with ~, keep last 3 components
if [[ -n "$cwd" ]]; then
    short_cwd="${cwd/#$HOME/\~}"
    # Truncate to last 3 path components
    parts=$(echo "$short_cwd" | tr '/' '\n' | tail -3 | tr '\n' '/')
    parts="${parts%/}"
    # If path was truncated, prepend ••/
    depth=$(echo "$cwd" | tr -cd '/' | wc -c)
    if [[ $depth -gt 3 ]]; then
        short_cwd=" ••/$parts"
    else
        short_cwd=" $parts"
    fi
fi

# Git branch (skip lock to avoid blocking)
if git_out=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null); then
    git_branch="$git_out"
fi

# Colors — Material You palette from iNiR (matches starship theme)
# Using ANSI 256/true-color where available, with dim fallback
C_RESET='\e[0m'
C_DIM='\e[2m'
C_BOLD='\e[1m'

# Primary: #EABAC6 → approximate 256: 217  | Tertiary: #EABCAF → 216
# onPrimary: #531E31 → dark rose bg
# We use printf for color output

# Segment: directory (primary colors)
# Segment: git branch (secondary)
# Segment: model + context (tertiary)

seg_dir=""
seg_git=""
seg_model=""
seg_ctx=""
seg_session=""
seg_warn=""
seg_rate=""
seg_vim=""

# Domain detection — colors the directory segment per-workspace so the
# "monkey brain" instantly knows which domain this session belongs to.
# Palette tuned for legibility on the existing primary background.
domain_bg=""
domain_fg=""
domain_icon="󰉋"
case "$cwd" in
    "$HOME/Github/inir"*|"$HOME/.config"*)
        # iNiR / home base — default rose (matches existing statusline theme)
        domain_bg='234;186;198'; domain_fg='83;30;49'; domain_icon='󰋜' ;;
    "$HOME/STWork"*)
        # STWork — warm peach
        domain_bg='234;188;175'; domain_fg='80;35;21'; domain_icon='󰏫' ;;
    "$HOME/ComfyWork"*|"$HOME/ComfyUI"*)
        # ComfyWork / image gen — cool lavender
        domain_bg='200;180;230'; domain_fg='50;30;80'; domain_icon='󰋩' ;;
    "$HOME/Modding"*)
        # Modding — earthy olive
        domain_bg='180;190;130'; domain_fg='40;50;20'; domain_icon='󰆦' ;;
    "$HOME/Documents/Ayaz OS"*)
        # Ayaz OS vault — cool teal (planning layer, distinct from execution)
        domain_bg='150;200;200'; domain_fg='20;50;55'; domain_icon='󰧑' ;;
    "$HOME/Github/dotfiles"*)
        # Dotfiles — neutral slate
        domain_bg='180;180;195'; domain_fg='30;30;45'; domain_icon='󰈻' ;;
    *)
        # Unknown / ad-hoc — default rose
        domain_bg='234;186;198'; domain_fg='83;30;49'; domain_icon='󰉋' ;;
esac

# Directory segment
if [[ -n "$short_cwd" ]]; then
    seg_dir=$(printf '\e[38;2;%sm\e[48;2;%sm %s %s \e[0m' "$domain_fg" "$domain_bg" "$domain_icon" "$short_cwd")
fi

# Git branch segment — shares the domain bg so the dir+git pair reads as one unit
if [[ -n "$git_branch" ]]; then
    # Truncate branch name to 16 chars
    branch_display="${git_branch:0:16}"
    seg_git=$(printf '\e[38;2;%sm\e[48;2;%sm 󰘬 %s \e[0m' "$domain_fg" "$domain_bg" "$branch_display")
fi

# Model segment
if [[ -n "$model" ]]; then
    seg_model=$(printf '\e[38;2;80;35;21m\e[48;2;234;188;175m  %s \e[0m' "$model")
fi

# Context usage segment — show remaining tokens
if [[ -n "$used_pct" ]]; then
    used_int=${used_pct%.*}
    remaining_pct=$((100 - used_int))
    # Color code by remaining: green > 50, yellow > 20, red <= 20
    if [[ $remaining_pct -le 20 ]]; then
        ctx_color=$(printf '\e[38;2;214;133;135m')  # red
    elif [[ $remaining_pct -le 50 ]]; then
        ctx_color=$(printf '\e[38;2;233;162;107m')  # yellow
    else
        ctx_color=$(printf '\e[38;2;164;190;120m')  # green
    fi
    if [[ -n "$input_tokens" && -n "$ctx_window" ]]; then
        remaining=$((ctx_window - input_tokens))
        fmt_remaining=$(awk -v r="$remaining" 'BEGIN {
            if (r >= 1000000) { printf "%.0fM", r/1000000 }
            else if (r >= 1000) { printf "%.0fk", r/1000 }
            else { printf "%d", r }
        }')
        seg_ctx=$(printf '%b 󰄰 %s left\e[0m' "$ctx_color" "$fmt_remaining")
    else
        seg_ctx=$(printf '%b 󰄰 %d%% left\e[0m' "$ctx_color" "$remaining_pct")
    fi
fi

# Session total tokens segment
if [[ -n "$total_in" && -n "$total_out" ]]; then
    session_total=$((total_in + total_out))
    fmt_session=$(awk -v t="$session_total" 'BEGIN {
        if (t >= 1000000) { printf "%.1fM", t/1000000 }
        else if (t >= 1000) { printf "%.0fk", t/1000 }
        else { printf "%d", t }
    }')
    seg_session=$(printf '\e[38;2;180;160;200m 󰆒 %s\e[0m' "$fmt_session")
fi

# 200k warning — fires when current context window input tokens exceed 200k
if [[ -n "$input_tokens" ]] && [[ "$input_tokens" -ge 200000 ]]; then
    fmt_ctx_warn=$(awk -v t="$input_tokens" 'BEGIN { printf "%.0fk", t/1000 }')
    seg_warn=$(printf '\e[1;38;2;214;133;135m 󰀦 ctx:%s\e[0m' "$fmt_ctx_warn")
fi

# Rate limit segments
rate_parts=""
for label_var in "5h:$rate_5h" "7d:$rate_7d"; do
    label="${label_var%%:*}"
    val="${label_var#*:}"
    [[ -z "$val" ]] && continue
    val_int=${val%.*}
    if [[ $val_int -ge 80 ]]; then
        rc=$(printf '\e[38;2;214;133;135m')  # red
    elif [[ $val_int -ge 50 ]]; then
        rc=$(printf '\e[38;2;233;162;107m')  # yellow
    else
        rc=$(printf '\e[2;38;2;164;190;120m')  # dim green
    fi
    rate_parts+=$(printf '%b%s:%d%%%b ' "$rc" "$label" "$val_int" '\e[0m')
done
if [[ -n "$rate_parts" ]]; then
    seg_rate=$(printf '󱐋 %b' "$rate_parts")
fi

# Vim mode segment
if [[ -n "$vim_mode" ]]; then
    if [[ "$vim_mode" == "NORMAL" ]]; then
        seg_vim=$(printf '\e[38;2;134;162;214m\e[1m [N]\e[0m')
    else
        seg_vim=$(printf '\e[38;2;164;190;120m\e[1m [I]\e[0m')
    fi
fi

# Assemble line
parts=()
[[ -n "$seg_dir" ]]     && parts+=("$seg_dir")
[[ -n "$seg_git" ]]     && parts+=("$seg_git")
[[ -n "$seg_model" ]]   && parts+=("$seg_model")
[[ -n "$seg_ctx" ]]     && parts+=("$seg_ctx")
[[ -n "$seg_session" ]] && parts+=("$seg_session")
[[ -n "$seg_warn" ]]    && parts+=("$seg_warn")
[[ -n "$seg_rate" ]]    && parts+=("$seg_rate")
[[ -n "$seg_vim" ]]     && parts+=("$seg_vim")

printf '%b' "${parts[*]}"
