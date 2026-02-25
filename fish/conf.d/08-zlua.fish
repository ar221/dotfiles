# ~/.config/fish/conf.d/08-zlua.fish
# z.lua integration for Fish

if status is-interactive
    # Set z.lua data file location
    set -gx _ZL_DATA "$XDG_DATA_HOME/zlua/zlua.txt"
    mkdir -p (dirname $_ZL_DATA)
    
    # Initialize z.lua with Fish support
    if test -f ~/.local/bin/z.lua
        source (lua ~/.local/bin/z.lua --init fish | psub)
        
        # Create convenient aliases
        alias zi='z -i'      # Interactive selection with fzf
        alias zf='z -I'      # Use fzf to select from recent directories
        alias zb='z -b'      # Jump backwards in directory history
        alias zh='z -h'      # Show help
        alias zl='z -l'      # List matched directories
        alias zc='z -c'      # Clean up database
        alias zr='z -r'      # Jump to highest ranked directory
    else
        echo "z.lua not found. Install with:"
        echo "curl -fsSL https://raw.githubusercontent.com/skywind3000/z.lua/master/z.lua -o ~/.local/bin/z.lua"
    end
end

