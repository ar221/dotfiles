# Simple bookmark system

if status is-interactive
    # Pick the listing command
    if command -q eza
        set -g _bm_ls 'eza -A --icons'
    else
        set -g _bm_ls 'ls -A'
    end

    # Directory bookmarks
    alias cac="cd \$XDG_CACHE_HOME; and $_bm_ls"
    alias cf="cd \$XDG_CONFIG_HOME; and $_bm_ls"
    alias D="cd \$HOME/Downloads; and $_bm_ls"
    alias d="cd \$HOME/Documents; and $_bm_ls"
    alias dt="cd \$XDG_DATA_HOME; and $_bm_ls"
    alias h="cd \$HOME; and $_bm_ls"
    alias m="cd \$HOME/Music; and $_bm_ls"
    alias mn="cd /mnt; and $_bm_ls"
    alias pp="cd \$HOME/Pictures; and $_bm_ls"
    alias sc="cd \$HOME/.local/bin; and $_bm_ls"
    alias vv="cd \$HOME/Videos; and $_bm_ls"

    # File bookmarks - open in editor
    alias cfv='\$EDITOR \$XDG_CONFIG_HOME/nvim/init.lua'
    alias cffish='\$EDITOR \$XDG_CONFIG_HOME/fish/config.fish'
    alias cffb='\$EDITOR \$XDG_CONFIG_HOME/fish/conf.d/07-bookmarks.fish'
end
