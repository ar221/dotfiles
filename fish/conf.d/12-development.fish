# ~/.config/fish/conf.d/12-development.fish
if status is-interactive
    # Quick server starter
    alias serve='python -m http.server 8000'

    # Quick directory creation and navigation
    function mcd --description "Create directory and cd into it"
        mkdir -p $argv[1] && cd $argv[1]
    end

    # Find and kill process by name
    function kp --description "Kill process by name (interactive)"
        set -l processes (ps aux | grep -v grep | grep $argv[1])

        if test -z "$processes"
            echo "No processes found matching: $argv[1]"
            return 1
        end

        echo "$processes"
        echo ""
        read -P "Kill these processes? [y/N]: " -n 1 confirm

        if test "$confirm" = "y" -o "$confirm" = "Y"
            ps aux | grep -v grep | grep $argv[1] | awk '{print $2}' | xargs kill
            echo "Processes terminated (SIGTERM)"
        else
            echo "Cancelled"
        end
    end
end
