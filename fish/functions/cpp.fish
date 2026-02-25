# ~/.config/fish/functions/cpp.fish
function cpp --description "Copy files/directories with progress bar"
    if test (count $argv) -lt 2
        echo "Usage: cpp source destination"
        return 1
    end
    
    set source $argv[1]
    set dest $argv[2]
    
    if not test -e "$source"
        echo "Source does not exist: $source"
        return 1
    end
    
    # Handle directories with rsync for better progress
    if test -d "$source"
        echo "Copying directory: $source -> $dest"
        if command -q rsync
            rsync -av --progress "$source" "$dest"
        else
            echo "Using cp for directory (install rsync for better progress)"
            cp -r "$source" "$dest"
        end
        return $status
    end
    
    # Handle single files with progress bar
    if not test -f "$source"
        echo "Source is not a regular file: $source"
        return 1
    end
    
    # Use rsync for files too if available (better progress)
    if command -q rsync
        rsync -av --progress "$source" "$dest"
        return $status
    end
    
    # Fallback to original method for files
    strace -q -ewrite cp -- "$source" "$dest" 2>&1 | awk -v total_size=(stat -c '%s' "$source") '
    {
        count += $NF
        if (count % 10 == 0) {
            percent = count / total_size * 100
            printf "%3d%% [", percent
            for (i=0;i<=percent;i++)
                printf "="
            printf ">"
            for (i=percent;i<100;i++)
                printf " "
            printf "]\r"
        }
    }
    END { print "" }'
end
