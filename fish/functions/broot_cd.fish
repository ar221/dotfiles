# ~/.config/fish/functions/broot_cd.fish
function broot_cd --description "Use broot to change directory"
    set tmp (mktemp)
    broot --outcmd "$tmp" $argv
    
    if test -f "$tmp"
        set cmd (cat "$tmp")
        rm -f "$tmp"
        
        # Execute the command from broot
        switch "$cmd"
            case 'cd *'
                set dir (string replace 'cd ' '' "$cmd")
                if test -d "$dir"
                    cd "$dir"
                    echo "Changed to: $dir"
                end
            case '*'
                # Execute other commands
                eval "$cmd"
        end
    end
end
