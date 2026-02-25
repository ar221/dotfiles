# ~/.config/fish/conf.d/10-ffd.fish
# Fuzzy File Finder integration

if status is-interactive
    # Basic aliases
    alias ff='fd -p'              # Fuzzy find with preview
    alias fff='fd -f -p'          # Files only with preview
    alias ffd='fd -d -p'          # Directories only with preview
    alias ffe='fd -f -e'          # Find and edit files
    
    # Advanced aliases
    alias ffa='fd -p -a'          # Show absolute paths
    alias ffh='fd -p -H'          # Include hidden files
    
    # Key bindings (Ctrl-F reserved for FZF in 06-keybindings.fish)
end

