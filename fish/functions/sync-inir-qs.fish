function sync-inir-qs -d "Sync iNiR repo to ~/.config/quickshell/ii/"
    set -l src ~/Github/inir
    set -l dst ~/.config/quickshell/ii

    if not test -d $src/.git
        echo "iNiR repo not found at $src"
        return 1
    end

    if not test -d $dst
        echo "Quickshell ii dir not found at $dst"
        return 1
    end

    rsync -a --delete \
        --exclude='.git/' \
        --exclude='__pycache__/' \
        --exclude='.venv/' \
        --exclude='node_modules/' \
        --exclude='*.pyc' \
        --exclude='.claude/' \
        --exclude='.vscode/' \
        $src/ $dst/

    echo "Synced inir → quickshell/ii"
end
