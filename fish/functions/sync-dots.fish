function sync-dots -d "Sync local dotfiles to ar221/dotfiles repo"
    set -l repo ~/Github/dotfiles
    set -l configs kitty fish niri starship yazi yazi-apollo lazygit btop foot ghostty matugen nvim fastfetch mpv zathura fuzzel git alacritty bat cava fontconfig gtk-3.0 gtk-4.0 qt5ct qt6ct paru mpd rmpc tmux opencode

    if not test -d $repo/.git
        echo "Dotfiles repo not found at $repo — clone it first:"
        echo "  git clone https://github.com/ar221/dotfiles.git $repo"
        return 1
    end

    echo "Syncing configs..."
    for d in $configs
        if test -d ~/.config/$d
            rsync -a --delete --exclude='fish_history' --exclude='fish_variables' --exclude='completions/' --exclude='cache/' --exclude='credentials' --exclude='*.log' --exclude='pid' --exclude='state' --exclude='sticker.sql' --exclude='database' --exclude='db' ~/.config/$d/ $repo/$d/
        end
    end

    if test -d ~/.local/bin
        set -l managed_scripts \
            apollo-banner apollo-jump apollo-launchpad apollo-projects \
            apollo-rail apollo-sync-projects apollo-toggle-copilot apollo-toggle-rail \
            oc-capture oc-cockpit oc-cockpit-reset-layout oc-context-push \
            oc-daily oc-link-here oc-note-open oc-note-resolve \
            oc-project-note oc-vault

        for script_name in $managed_scripts
            if test -f ~/.local/bin/$script_name
                cp ~/.local/bin/$script_name $repo/scripts/$script_name
            end
        end
    end

    pushd $repo

    set -l changes (git status --porcelain)
    if test -z "$changes"
        echo "No changes to sync."
        popd
        return 0
    end

    git add -A
    set -l stat (git diff --cached --shortstat)
    echo $stat

    git commit -m "sync: update dotfiles ($(date +%Y-%m-%d))"
    and git push
    and echo "Dotfiles synced and pushed."
    or echo "Push failed."

    popd
end
