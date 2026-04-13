# ~/.config/fish/conf.d/07-atuin.fish
# Atuin shell history (local-only, no cloud sync)
if status is-interactive; and command -q atuin
    atuin init fish --disable-up-arrow | source
end
