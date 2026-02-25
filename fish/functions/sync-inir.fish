function sync-inir -d "Sync iNiR fork with upstream snowarch/inir"
    set -l repo ~/Github/inir

    if not test -d $repo/.git
        echo "iNiR repo not found at $repo"
        return 1
    end

    pushd $repo

    echo "Fetching upstream..."
    git fetch upstream
    or begin; popd; return 1; end

    set -l local (git rev-parse HEAD)
    set -l remote (git rev-parse upstream/main)

    if test "$local" = "$remote"
        echo "Already up to date."
        popd
        return 0
    end

    set -l behind (git rev-list --count HEAD..upstream/main)
    echo "$behind new commit(s) from upstream"

    git rebase upstream/main
    or begin
        echo "Conflict detected — resolve it, then run: git rebase --continue"
        popd
        return 1
    end

    git push
    echo "Synced and pushed."
    popd

    sync-inir-qs
end
