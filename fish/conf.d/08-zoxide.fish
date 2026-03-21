# ~/.config/fish/conf.d/08-zoxide.fish
# zoxide integration for Fish (replaced z.lua)

if status is-interactive
    if command -q zoxide
        zoxide init fish | source
    end
end
