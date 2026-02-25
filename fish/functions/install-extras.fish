function install-extras -d "Install packages not covered by iNiR setup"
    set -l extras \
        ghostty alacritty zathura \
        mpd rmpc cava \
        lazygit btop htop fastfetch \
        eza broot yazi bat \
        trash-cli bc exiftool

    set -l to_install
    for pkg in $extras
        if not pacman -Qi $pkg &>/dev/null
            set -a to_install $pkg
        end
    end

    if test (count $to_install) -eq 0
        echo "All extra packages already installed."
        return 0
    end

    echo "Missing packages:"
    for pkg in $to_install
        echo "  $pkg"
    end

    read -P "Install? [Y/n] " ans
    if test -z "$ans" -o "$ans" = y -o "$ans" = Y
        paru -S --needed $to_install
    end
end
