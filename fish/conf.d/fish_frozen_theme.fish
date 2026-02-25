# Fish theme — managed by Matugen pipeline
# To regenerate: change wallpaper via Quickshell (Ctrl+Alt+T)
# Source: ~/.config/fish/themes/Matugen.theme

# Load the active theme file so matugen-generated colors take effect
if test -f ~/.config/fish/themes/Matugen.theme
    while read -l line
        test -z "$line"; and continue
        string match -q '#*' -- $line; and continue
        set -l parts (string split ' ' -- $line)
        set -l varname $parts[1]
        set -l values $parts[2..]
        set --global $varname $values
    end < ~/.config/fish/themes/Matugen.theme
end
