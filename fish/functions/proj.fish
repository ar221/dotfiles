function proj --description "Jump to a project directory via zoxide + fzf"
    set -l dir (zoxide query --list | fzf --height 40% --reverse --prompt "project> ")
    if test -n "$dir"
        cd "$dir"
        commandline -f repaint
    end
end
