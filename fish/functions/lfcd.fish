# ~/.config/fish/functions/lfcd.fish
function lfcd --description "Change directory with lf"
    set tmp (mktemp)
    lf -last-dir-path="$tmp" $argv
    
    if test -f "$tmp"
        set dir (cat "$tmp")
        if test -d "$dir" -a "$dir" != (pwd)
            cd "$dir"
        end
        rm -f "$tmp"
    end
end
