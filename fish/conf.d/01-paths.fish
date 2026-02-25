# ~/.config/fish/conf.d/01-paths.fish
# PATH Configuration — uses fish_add_path to prevent duplication

# User binaries
fish_add_path -a $HOME/.local/bin
fish_add_path -a $HOME/.local/bin/cron
fish_add_path -a $HOME/.local/bin/statusbar

# Development tools
fish_add_path -a $CARGO_HOME/bin
fish_add_path -a $HOME/.local/share/npm/bin

# System tools
fish_add_path -a /opt/rocm/bin
fish_add_path -a /opt/android-sdk/platform-tools
fish_add_path -a /var/lib/flatpak/exports/bin
