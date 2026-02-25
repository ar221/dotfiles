# ~/.config/fish/functions/ftext.fish
function ftext --description "Find text in files"
    if test (count $argv) -eq 0
        echo "Usage: ftext search_term"
        return 1
    end
    
    # Use ripgrep if available, otherwise fall back to grep
    if command -q rg
        rg --color=always --line-number --ignore-case --follow --hidden --glob='!.git/' $argv[1] . | less -r
    else
        grep -iIHrn --color=always $argv[1] . | less -r
    end
end
