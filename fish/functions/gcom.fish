# ~/.config/fish/functions/gcom.fish
function gcom --description "Git add all and commit with message"
    git add . && git commit -m "$argv"
end
