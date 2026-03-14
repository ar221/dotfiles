if status is-interactive

    # Pokemon + fastfetch greeting
    function fish_greeting
        if command -q pokemon-colorscripts; and command -q fastfetch
            fastfetch --data-raw (pokemon-colorscripts -r --no-title | string collect)
        end
    end

    # Use starship
    starship init fish | source

    # Apply terminal color sequences (Material You)
    if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    end

    # Typo fixes
    alias pamcan pacman
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias q 'qs -c ii'

    # ============================================================================
    # File listing (eza)
    # ============================================================================
    if command -q eza
        alias ls 'eza --icons'
        alias ll 'eza -la --icons'
        alias la 'eza -a --icons'
        alias lt 'eza -la --icons --sort=modified'
        alias tree 'eza --tree --icons'
    end

    # ============================================================================
    # Navigation
    # ============================================================================
    alias cd..='cd ..'
    alias ..='cd ..'
    alias ...='cd ../..'
    alias ....='cd ../../..'
    alias .....='cd ../../../..'
    alias bd='cd -'

    # ============================================================================
    # Vim
    # ============================================================================
    if command -q nvim
        alias vim nvim
        alias vi nvim
        alias svi 'sudo nvim'
    end

    # ============================================================================
    # Safe operations
    # ============================================================================
    alias cp='cp -i'
    alias mv='mv -i'
    if command -q trash
        alias rm='trash -v'
    else
        alias rm='rm -i'
    end
    alias mkdir='mkdir -p'

    # ============================================================================
    # System
    # ============================================================================
    alias psa='ps auxf'
    alias less='less -R'
    alias cls='clear'
    alias da='date "+%Y-%m-%d %A %T %Z"'
    alias topcpu='/bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10'

    # ============================================================================
    # chmod
    # ============================================================================
    alias mx='chmod a+x'
    alias 000='chmod -R 000'
    alias 644='chmod -R 644'
    alias 755='chmod -R 755'
    alias 777='chmod -R 777'

    # ============================================================================
    # Disk usage
    # ============================================================================
    alias diskspace='du -S | sort -n -r | more'
    alias folders='du -h --max-depth=1'
    alias mountedinfo='df -hT'

    # ============================================================================
    # Archives
    # ============================================================================
    alias mktar='tar -cvf'
    alias mkbz2='tar -cvjf'
    alias mkgz='tar -cvzf'
    alias untar='tar -xvf'
    alias unbz2='tar -xvjf'
    alias ungz='tar -xvzf'

    # ============================================================================
    # Better tools
    # ============================================================================
    if command -q bat
        alias cat='bat'
    end
    if command -q rg
        alias grep='rg'
    else
        alias grep='grep --color=auto'
    end

    # ============================================================================
    # Development
    # ============================================================================
    alias py='python3'
    alias pip='pip3'
    alias snano='sudo nano'

    # ============================================================================
    # Git (extras — main aliases in 11-git.fish)
    # ============================================================================
    alias gs='git status'
    alias gl='git log --oneline'
    alias g='git'

    # ============================================================================
    # Network
    # ============================================================================
    alias kssh='kitty +kitten ssh'
    alias ip='ip -color=auto'

    # ============================================================================
    # Misc
    # ============================================================================
    alias ka='killall'
    alias sdn='shutdown -h now'
    alias e='$EDITOR'
    alias v='$EDITOR'
    alias p='pacman'
    alias bc='bc -ql'
    alias rsync='rsync -vrPlu'
    alias mkd='mkdir -pv'
    alias ffmpeg='ffmpeg -hide_banner'
    alias diff='diff --color=auto'

    # yt-dlp
    if command -q yt-dlp
        alias yt='yt-dlp --embed-metadata -i'
        alias yta='yt -x -f bestaudio/best'
        alias ytt='yt --skip-download --write-thumbnail'
    end

end
