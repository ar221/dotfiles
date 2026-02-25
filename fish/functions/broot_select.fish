# ~/.config/fish/functions/broot_select.fish
function broot_select --description "Use broot to select files/directories"
    broot --cmd ":pp" $argv
end
