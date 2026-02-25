# ~/.config/fish/conf.d/11-git.fish
if status is-interactive
    # Better git aliases
    alias gst='git status --short --branch'
    alias gco='git checkout'
    alias gcb='git checkout -b'
    alias gpl='git pull --rebase'
    alias gps='git push'
    alias glg='git log --oneline --graph --decorate'
    alias gaa='git add --all'
    alias gcm='git commit --message'
    alias gd='git diff'
    alias gdc='git diff --cached'
    
    # Git branch switching with fzf
    function gb --description "Switch git branches with fzf"
        git branch --all | grep -v HEAD | string trim | fzf | xargs git checkout
    end
end

