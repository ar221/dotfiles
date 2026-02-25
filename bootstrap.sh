#!/usr/bin/env bash
# Bootstrap script for fresh CachyOS/Arch install
# Clones repos, installs packages, deploys configs
set -euo pipefail

DOTFILES_REPO="https://github.com/ar221/dotfiles.git"
INIR_REPO="https://github.com/ar221/iNiR.git"
INIR_UPSTREAM="https://github.com/snowarch/iNiR.git"
GITHUB_DIR="$HOME/Github"
DOTFILES_DIR="$GITHUB_DIR/dotfiles"
INIR_DIR="$GITHUB_DIR/inir"

# ── Colors ──────────────────────────────────────────────────────────
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
cyan='\033[0;36m'
reset='\033[0m'

info()  { echo -e "${cyan}::${reset} $*"; }
ok()    { echo -e "${green}✓${reset} $*"; }
warn()  { echo -e "${yellow}!${reset} $*"; }
err()   { echo -e "${red}✗${reset} $*"; }

# ── Helpers ─────────────────────────────────────────────────────────
confirm() {
    read -rp "$1 [Y/n] " ans
    [[ -z "$ans" || "$ans" =~ ^[Yy] ]]
}

# ── Clone repos ─────────────────────────────────────────────────────
clone_repos() {
    info "Setting up repositories..."
    mkdir -p "$GITHUB_DIR"

    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        ok "Dotfiles repo already at $DOTFILES_DIR"
    else
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
        ok "Cloned dotfiles"
    fi

    if [[ -d "$INIR_DIR/.git" ]]; then
        ok "iNiR repo already at $INIR_DIR"
    else
        git clone "$INIR_REPO" "$INIR_DIR"
        cd "$INIR_DIR"
        git remote add upstream "$INIR_UPSTREAM" 2>/dev/null || true
        ok "Cloned iNiR (upstream: snowarch/iNiR)"
    fi
}

# ── Install packages ────────────────────────────────────────────────
install_packages() {
    info "Installing packages..."

    # Core
    local core=(
        fish starship fzf ripgrep bat eza broot
        yazi kitty foot ghostty alacritty
        neovim git lazygit paru less
        btop htop fastfetch
        niri fuzzel zathura
        matugen swww
    )

    # Media
    local media=(
        mpd rmpc cava mpv ffmpeg
    )

    # System
    local system=(
        pipewire wireplumber polkit-gnome
        wl-clipboard cliphist
        dolphin firefox
        rsync curl trash-cli bc jq exiftool
    )

    # Theming
    local theming=(
        ttf-jetbrains-mono-nerd
        papirus-icon-theme
        qt5ct qt6ct
    )

    # Development
    local dev=(
        python python-pip
        rustup nodejs npm
    )

    # Archive tools
    local archive=(
        tar unzip p7zip unrar
    )

    local all=("${core[@]}" "${media[@]}" "${system[@]}" "${theming[@]}" "${dev[@]}" "${archive[@]}")

    # Filter to only missing packages
    local to_install=()
    for pkg in "${all[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        ok "All packages already installed"
        return
    fi

    echo ""
    info "Installing ${#to_install[@]} packages:"
    printf '  %s\n' "${to_install[@]}"
    echo ""

    if confirm "Proceed?"; then
        # Use paru if available, fall back to pacman
        if command -v paru &>/dev/null; then
            paru -S --needed "${to_install[@]}"
        else
            sudo pacman -S --needed "${to_install[@]}"
        fi
        ok "Packages installed"
    else
        warn "Skipped package installation"
    fi
}

# ── Deploy dotfiles ─────────────────────────────────────────────────
deploy_dotfiles() {
    info "Deploying dotfiles to ~/.config..."

    local configs=(
        kitty fish niri starship yazi lazygit btop foot ghostty
        matugen nvim fastfetch mpv zathura fuzzel git alacritty
        bat cava fontconfig gtk-3.0 gtk-4.0 qt5ct qt6ct paru mpd rmpc
    )

    for d in "${configs[@]}"; do
        if [[ -d "$DOTFILES_DIR/$d" ]]; then
            # Back up existing config if it exists and isn't a previous deploy
            if [[ -d "$HOME/.config/$d" && ! -f "$HOME/.config/$d/.bootstrapped" ]]; then
                warn "Backing up existing $d → $d.bak"
                mv "$HOME/.config/$d" "$HOME/.config/$d.bak"
            fi
            rsync -a --delete \
                --exclude='fish_history' \
                --exclude='fish_variables' \
                --exclude='completions/' \
                "$DOTFILES_DIR/$d/" "$HOME/.config/$d/"
            touch "$HOME/.config/$d/.bootstrapped"
        fi
    done
    ok "Dotfiles deployed"
}

# ── Deploy iNiR ─────────────────────────────────────────────────────
deploy_inir() {
    info "Deploying iNiR to ~/.config/quickshell/ii/..."
    mkdir -p "$HOME/.config/quickshell/ii"
    rsync -a --delete \
        --exclude='.git/' \
        --exclude='__pycache__/' \
        --exclude='.venv/' \
        --exclude='node_modules/' \
        --exclude='*.pyc' \
        --exclude='.claude/' \
        --exclude='.vscode/' \
        "$INIR_DIR/" "$HOME/.config/quickshell/ii/"
    ok "iNiR deployed"
}

# ── Post-install ────────────────────────────────────────────────────
post_install() {
    info "Running post-install tasks..."

    # Set fish as default shell
    if [[ "$SHELL" != *fish* ]]; then
        if confirm "Set fish as default shell?"; then
            chsh -s "$(which fish)"
            ok "Default shell set to fish"
        fi
    else
        ok "Fish is already default shell"
    fi

    # Set up git
    git config --global user.name "Ayaz Rashid"
    git config --global user.email "rashid.ayaz@gmail.com"
    git config --global init.defaultBranch main
    git config --global core.editor nvim
    git config --global core.pager "less -FRX"
    git config --global core.autocrlf input
    git config --global core.excludesFile "~/.config/git/ignore"
    git config --global push.default current
    git config --global push.autoSetupRemote true
    git config --global fetch.prune true
    git config --global pull.rebase true
    git config --global merge.conflictstyle zdiff3
    git config --global rebase.autoStash true
    git config --global rerere.enabled true
    git config --global diff.algorithm histogram
    git config --global diff.colorMoved default
    git config --global column.ui auto
    git config --global branch.sort -committerdate
    git config --global tag.sort -version:refname
    ok "Git configured"

    # gh auth reminder
    if ! gh auth status &>/dev/null 2>&1; then
        warn "GitHub CLI not authenticated — run: gh auth login"
    fi

    # Firefox symlink for pywalfox
    if [[ -d "$HOME/.config/mozilla/firefox" && ! -L "$HOME/.mozilla/firefox" ]]; then
        mkdir -p "$HOME/.mozilla"
        ln -sf "$HOME/.config/mozilla/firefox" "$HOME/.mozilla/firefox"
        ok "Firefox symlink created"
    fi

    # Kitty remote control
    if ! grep -q "allow_remote_control" "$HOME/.config/kitty/kitty.conf" 2>/dev/null; then
        warn "Add 'allow_remote_control yes' and 'listen_on unix:/tmp/kitty-{kitty_pid}' to kitty.conf for live reload"
    fi

    ok "Post-install complete"
}

# ── Main ────────────────────────────────────────────────────────────
main() {
    echo ""
    echo -e "${cyan}╔══════════════════════════════════════╗${reset}"
    echo -e "${cyan}║     Lord Rashid's System Bootstrap   ║${reset}"
    echo -e "${cyan}╚══════════════════════════════════════╝${reset}"
    echo ""

    clone_repos

    if confirm "Install packages?"; then
        install_packages
    fi

    deploy_dotfiles
    deploy_inir
    post_install

    echo ""
    ok "Bootstrap complete. Open a new terminal or run: exec fish"
    echo ""
}

main "$@"
