# ~/.config/fish/conf.d/04-tools.fish
# Tool configuration (FZF, Less, Ripgrep, etc.)

# ============================================================================
# Tool Configuration
# ============================================================================
# FZF
set -gx FZF_DEFAULT_OPTS "--layout=reverse --height 40% --border --preview 'bat --color=always --style=numbers --line-range=:500 {}' --preview-window=right:50%"
set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND

# Less
set -gx LESS R
if command -q highlight
    set -gx LESSOPEN "| /usr/bin/highlight -O ansi %s 2>/dev/null"
else if command -q bat
    set -gx LESSOPEN "| bat --color=always --style=plain %s 2>/dev/null"
end

# Ripgrep
set -gx RIPGREP_CONFIG_PATH $XDG_CONFIG_HOME/ripgrep/config
