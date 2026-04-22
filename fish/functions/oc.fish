function oc --description 'Open Apollo/Constellation flight-deck for OpenCode'
    # optional ignition banner — fires only if binary exists and stdout is a tty
    if test -x ~/.local/bin/apollo-banner; and isatty stdout
        ~/.local/bin/apollo-banner
    end

    set -l ephemeral 0
    set -l args
    for arg in $argv
        if test "$arg" = --ephemeral
            set ephemeral 1
        else
            set -a args $arg
        end
    end

    set -l tmux_conf ~/.config/tmux/apollo.conf
    if test $ephemeral -eq 1
        set tmux_conf ~/.config/tmux/apollo-ephemeral.conf
    end

    # --- No args → Launchpad ---------------------------------
    if test (count $args) -eq 0
        # Spawn a kitty window running the launchpad. On selection, the
        # launchpad script writes the path to a temp file, then the inner
        # shell exec's tmux pointed at that path.
        set -l selection_file (mktemp /tmp/apollo-selection.XXXXXX)

        kitty --detach \
            --config ~/.config/kitty/apollo.conf \
            --title LAUNCHPAD \
            fish -c "apollo-launchpad > $selection_file; \
                     set -l picked (cat $selection_file); \
                     command rm -f $selection_file; \
                     if test -z \"\$picked\"; exit 0; end; \
                     set -l slug (string replace -ra '[^a-z0-9]+' '-' (string lower (basename \$picked)) | string trim -c '-'); \
                     set -l socket apollo-\$slug; \
                     set -l i 2; \
                     while tmux -L \$socket has-session -t apollo 2>/dev/null; \
                         set socket apollo-\$slug-\$i; \
                         set i (math \$i + 1); \
                     end; \
                     mkdir -p ~/.cache/apollo; \
                     set -l recents_tmp (mktemp); \
                     echo \$picked > \$recents_tmp; \
                     if test -f ~/.cache/apollo/recents; \
                         grep -vxF \$picked ~/.cache/apollo/recents | head -4 >> \$recents_tmp; end; \
                      command mv -f \$recents_tmp ~/.cache/apollo/recents; \
                      kitty @ set-window-title \"APOLLO·\$slug\" 2>/dev/null; \
                       exec tmux -L \$socket -f $tmux_conf \
                                new-session -A -s apollo -c \$picked env APOLLO_ROLE=main opencode"
        return 0
    end

    # --- Path arg → direct cockpit ---------------------------
    set -l path $args[1]
    set -l rest $args[2..-1]

    # resolve ~ and relative
    set path (realpath $path 2>/dev/null; or echo $path)

    set -l slug (string replace -ra '[^a-z0-9]+' '-' (string lower (basename $path)) | string trim -c '-')
    set -l socket apollo-$slug
    set -l i 2
    while tmux -L $socket has-session -t apollo 2>/dev/null
        set socket apollo-$slug-$i
        set i (math $i + 1)
    end

    # update recents
    mkdir -p ~/.cache/apollo
    set -l recents_tmp (mktemp)
    echo $path >$recents_tmp
    if test -f ~/.cache/apollo/recents
        grep -vxF $path ~/.cache/apollo/recents | head -4 >>$recents_tmp
    end
    command mv -f $recents_tmp ~/.cache/apollo/recents

    kitty --detach \
        --config ~/.config/kitty/apollo.conf \
        --title "APOLLO·$slug" \
        tmux -L $socket -f $tmux_conf \
        new-session -A -s apollo -c $path env APOLLO_ROLE=main opencode $rest
end
