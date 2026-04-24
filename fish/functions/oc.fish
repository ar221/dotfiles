function oc --description 'Open Apollo/Constellation flight-deck for OpenCode'
    if test -x ~/.local/bin/apollo-banner; and isatty stdout
        ~/.local/bin/apollo-banner
    end

    set -l ephemeral 0
    set -l option_args
    set -l positional_args
    set -l seen_positional 0

    for arg in $argv
        if test "$arg" = --ephemeral
            set ephemeral 1
        else if test $seen_positional -eq 0; and string match -qr '^-' -- $arg
            set -a option_args $arg
        else
            set seen_positional 1
            set -a positional_args $arg
        end
    end

    set -l tmux_conf ~/.config/tmux/apollo.conf
    if test $ephemeral -eq 1
        set tmux_conf ~/.config/tmux/apollo-ephemeral.conf
    end

    if test (count $positional_args) -eq 0; and test (count $option_args) -eq 0
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

    set -l path
    set -l rest

    if test (count $positional_args) -eq 0
        set path $PWD
        set rest $option_args
    else
        set path $positional_args[1]
        set rest $option_args $positional_args[2..-1]
    end

    set path (realpath $path 2>/dev/null; or echo $path)

    set -l slug (string replace -ra '[^a-z0-9]+' '-' (string lower (basename $path)) | string trim -c '-')
    set -l socket apollo-$slug
    set -l i 2
    while tmux -L $socket has-session -t apollo 2>/dev/null
        set socket apollo-$slug-$i
        set i (math $i + 1)
    end

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
