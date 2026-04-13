# ~/.config/fish/conf.d/06-keybindings.fish
# Key bindings
if status is-interactive
    # ============================================================================
    # Key Bindings
    # ============================================================================
    
    # Ctrl-O for yazi (file manager with cd on exit)
    bind \co 'y; commandline -f repaint'
    
    # Ctrl-A for calculator
    bind \ca 'bc -lq; commandline -f repaint'
    
    # REMOVED: Ctrl-F (conflicts with FZF - use FZF's default Ctrl-T instead)
    # bind \cf 'cd (dirname (fzf)); commandline -f repaint'
    
    # Ctrl-E for edit command line
    bind \ce edit_command_buffer
    
    # FZF key bindings (load last to override conflicts)
    if command -q fzf
        fzf --fish | source
    end
end

