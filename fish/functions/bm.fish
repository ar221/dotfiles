# ~/.config/fish/functions/bm.fish
function bm --description "Bookmark management system"
    if test (count $argv) -eq 0
        echo "Bookmark Management System"
        echo ""
        echo "Usage:"
        echo "  bm list              - List all bookmarks"
        echo "  bm add <name> <path> - Add a directory bookmark"
        echo "  bm file <name> <path> - Add a file bookmark"
        echo "  bm rm <name>         - Remove a bookmark"
        echo "  bm reload            - Reload bookmarks"
        echo ""
        echo "Current directory bookmarks:"
        _bm_list_dirs
        echo ""
        echo "Current file bookmarks:"
        _bm_list_files
        return
    end
    
    switch $argv[1]
        case "list"
            echo "Directory bookmarks:"
            _bm_list_dirs
            echo ""
            echo "File bookmarks:"
            _bm_list_files
            
        case "add"
            if test (count $argv) -lt 3
                echo "Usage: bm add <name> <path>"
                return 1
            end
            _bm_add_dir $argv[2] $argv[3]
            
        case "file"
            if test (count $argv) -lt 3
                echo "Usage: bm file <name> <path>"
                return 1
            end
            _bm_add_file $argv[2] $argv[3]
            
        case "rm" "remove"
            if test (count $argv) -lt 2
                echo "Usage: bm rm <name>"
                return 1
            end
            _bm_remove $argv[2]
            
        case "reload"
            _bm_reload
            
        case '*'
            echo "Unknown command: $argv[1]"
            echo "Run 'bm' for usage information"
            return 1
    end
end

# ~/.config/fish/functions/_bm_list_dirs.fish
function _bm_list_dirs --description "List directory bookmarks"
    echo "  cac  -> $XDG_CACHE_HOME"
    echo "  cf   -> $XDG_CONFIG_HOME"
    echo "  D    -> $XDG_DOWNLOAD_DIR"
    echo "  d    -> $XDG_DOCUMENTS_DIR"
    echo "  dt   -> $XDG_DATA_HOME"
    echo "  h    -> $HOME"
    echo "  m    -> $XDG_MUSIC_DIR"
    echo "  mn   -> /mnt"
    echo "  pp   -> $XDG_PICTURES_DIR"
    echo "  sc   -> $HOME/.local/bin"
    echo "  src  -> $HOME/.local/src"
    echo "  vv   -> $XDG_VIDEOS_DIR"
    echo "  cui  -> /mnt/hdd/AI/ComfyUI"
end

# ~/.config/fish/functions/_bm_list_files.fish
function _bm_list_files --description "List file bookmarks"
    echo "  cfv    -> $XDG_CONFIG_HOME/nvim/init.lua"
    echo "  cffish -> $XDG_CONFIG_HOME/fish/config.fish"
    echo "  cffb   -> $XDG_CONFIG_HOME/fish/conf.d/07-bookmarks.fish"
    echo "  cfl    -> $XDG_CONFIG_HOME/lf/lfrc"
end

# ~/.config/fish/functions/_bm_add_dir.fish
function _bm_add_dir --description "Add directory bookmark"
    set name $argv[1]
    set path $argv[2]
    
    if not test -d "$path"
        echo "Error: Directory '$path' does not exist"
        return 1
    end
    
    echo "Adding directory bookmark: $name -> $path"
    # This would add to your bookmarks file
    # For now, just show what would be added
    echo "Add this to your bookmarks config:"
    echo "alias $name=\"cd $path; and ls -A\""
end

# ~/.config/fish/functions/_bm_add_file.fish
function _bm_add_file --description "Add file bookmark"
    set name $argv[1]
    set path $argv[2]
    
    if not test -f "$path"
        echo "Error: File '$path' does not exist"
        return 1
    end
    
    echo "Adding file bookmark: $name -> $path"
    echo "Add this to your bookmarks config:"
    echo "alias $name='\$EDITOR $path'"
end

# ~/.config/fish/functions/_bm_reload.fish
function _bm_reload --description "Reload bookmark configuration"
    echo "Reloading bookmarks..."
    source $XDG_CONFIG_HOME/fish/conf.d/07-bookmarks.fish
    echo "Bookmarks reloaded!"
end

# ~/.config/fish/functions/goto.fish
function goto --description "Fuzzy find and go to bookmarked directories"
    set dirs \
        "$XDG_CACHE_HOME" \
        "$XDG_CONFIG_HOME" \
        "$XDG_DOWNLOAD_DIR" \
        "$XDG_DOCUMENTS_DIR" \
        "$XDG_DATA_HOME" \
        "$HOME/.local/src" \
        "$HOME" \
        "$XDG_MUSIC_DIR" \
        "/mnt" \
        "$XDG_PICTURES_DIR" \
        "$HOME/.local/bin" \
        "$XDG_VIDEOS_DIR" \
        "/mnt/hdd/AI/ComfyUI"
    
    if command -q fzf
        set selected (printf '%s\n' $dirs | fzf --height 40% --prompt="Go to: ")
        if test -n "$selected"
            cd "$selected"
            ls -A
        end
    else
        echo "Available directories:"
        for i in (seq (count $dirs))
            echo "$i) $dirs[$i]"
        end
        echo -n "Select number: "
        read -l choice
        if test -n "$choice" -a "$choice" -ge 1 -a "$choice" -le (count $dirs)
            cd $dirs[$choice]
            ls -A
        end
    end
end
