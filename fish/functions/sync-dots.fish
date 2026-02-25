function sync-dots -d "Sync local dotfiles to ar221/dotfiles repo"
    set -l repo /tmp/dotfiles-setup
    set -l configs kitty fish niri starship yazi lazygit btop foot ghostty matugen nvim fastfetch mpv zathura fuzzel git alacritty bat cava fontconfig gtk-3.0 gtk-4.0 qt5ct qt6ct paru mpd rmpc

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
