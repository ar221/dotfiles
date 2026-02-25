#!/usr/bin/env bash
# Bootstrap script for fresh CachyOS/Arch install
# 1. Clone & run iNiR setup (packages, system, shell)
# 2. Overlay personal dotfiles on top
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

confirm() {
    read -rp "$1 [Y/n] " ans
    [[ -z "$ans" || "$ans" =~ ^[Yy] ]]
}

# ── Step 1: Clone repos ────────────────────────────────────────────
clone_repos() {
    info "Setting up repositories..."
    mkdir -p "$GITHUB_DIR"

    if [[ -d "$INIR_DIR/.git" ]]; then
        ok "iNiR repo already at $INIR_DIR"
    else
        git clone "$INIR_REPO" "$INIR_DIR"
        cd "$INIR_DIR"
        git remote add upstream "$INIR_UPSTREAM" 2>/dev/null || true
        ok "Cloned iNiR (upstream: snowarch/iNiR)"
    fi

    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        ok "Dotfiles repo already at $DOTFILES_DIR"
    else
        git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
        ok "Cloned dotfiles"
    fi
}

# ── Step 2: Run iNiR setup ─────────────────────────────────────────
run_inir_setup() {
    info "Running iNiR setup (packages, system config, shell)..."
    if [[ -x "$INIR_DIR/setup" ]]; then
        "$INIR_DIR/setup" install
        ok "iNiR setup complete"
    else
        warn "iNiR setup script not found or not executable at $INIR_DIR/setup"
        return 1
    fi
}

# ── Step 3: Overlay personal dotfiles ───────────────────────────────
overlay_dotfiles() {
    info "Overlaying personal dotfiles..."

    local configs=(
        kitty fish niri starship yazi lazygit btop foot ghostty
        matugen nvim fastfetch mpv zathura fuzzel git alacritty
        bat cava fontconfig gtk-3.0 gtk-4.0 qt5ct qt6ct paru mpd rmpc
    )

    for d in "${configs[@]}"; do
        if [[ -d "$DOTFILES_DIR/$d" ]]; then
            mkdir -p "$HOME/.config/$d"
            rsync -a \
                --exclude='fish_history' \
                --exclude='fish_variables' \
                --exclude='completions/' \
                "$DOTFILES_DIR/$d/" "$HOME/.config/$d/"
        fi
    done
    ok "Personal configs overlaid"
}

# ── Step 4: Extra packages iNiR doesn't cover ──────────────────────
install_extras() {
    local extras=(
        ghostty alacritty zathura
        mpd rmpc cava
        lazygit btop htop fastfetch
        eza broot yazi bat
        trash-cli bc exiftool
    )

    local to_install=()
    for pkg in "${extras[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        ok "All extra packages already installed"
        return
    fi

    info "Installing ${#to_install[@]} extra packages not covered by iNiR:"
    printf '  %s\n' "${to_install[@]}"

    if confirm "Proceed?"; then
        if command -v paru &>/dev/null; then
            paru -S --needed "${to_install[@]}"
        else
            sudo pacman -S --needed "${to_install[@]}"
        fi
        ok "Extra packages installed"
    fi
}

# ── Step 5: Git & post-install ──────────────────────────────────────
post_install() {
    info "Configuring git..."
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

    # gh auth
    if command -v gh &>/dev/null && ! gh auth status &>/dev/null 2>&1; then
        warn "Run 'gh auth login' to authenticate GitHub CLI"
    fi

    # Firefox symlink for pywalfox
    if [[ -d "$HOME/.config/mozilla/firefox" && ! -L "$HOME/.mozilla/firefox" ]]; then
        mkdir -p "$HOME/.mozilla"
        ln -sf "$HOME/.config/mozilla/firefox" "$HOME/.mozilla/firefox"
        ok "Firefox symlink created"
    fi

    # Fish as default shell
    if [[ "$SHELL" != *fish* ]]; then
        if confirm "Set fish as default shell?"; then
            chsh -s "$(which fish)"
            ok "Default shell set to fish"
        fi
    fi
}

# ── Main ────────────────────────────────────────────────────────────
main() {
    echo ""
    echo -e "${cyan}╔══════════════════════════════════════╗${reset}"
    echo -e "${cyan}║     Lord Rashid's System Bootstrap   ║${reset}"
    echo -e "${cyan}╚══════════════════════════════════════╝${reset}"
    echo ""

    clone_repos
    run_inir_setup
    install_extras
    overlay_dotfiles
    post_install

    echo ""
    ok "Bootstrap complete. Open a new terminal or run: exec fish"
    echo ""
}

main "$@"
