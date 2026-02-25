# ~/.config/fish/conf.d/09-broot.fish
# Broot integration for Fish

if status is-interactive
    # Initialize broot if available
    if command -q broot
        # Set up broot launcher integration
        if test -f ~/.config/broot/launcher/fish/br
            source ~/.config/broot/launcher/fish/br
        else
            # Generate the launcher on first run
            echo "Setting up broot launcher..."
            broot --print-shell-function fish > ~/.config/fish/functions/br.fish
            
            # Alternative: create the integration manually
            mkdir -p ~/.config/broot/launcher/fish
            broot --print-shell-function fish > ~/.config/broot/launcher/fish/br
        end
        
        # Create convenient aliases (tree alias lives in config.fish → eza)
        alias btree='broot --tree'          # Broot tree view
        alias sizes='broot --sizes'         # Show sizes
        alias dates='broot --dates'         # Show dates
        alias perms='broot --permissions'   # Show permissions
        alias hidden='broot --hidden'       # Show hidden files
        
        # Key bindings for broot integration
        # Bind Alt+B to open broot in current directory
        bind \eb 'broot_cd; commandline -f repaint'
        
        # Bind Ctrl+B to open broot with file selection
        bind \cb 'broot_select; commandline -f repaint'
    end
end
