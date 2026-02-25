# ~/.config/fish/conf.d/00-environment.fish
# Environment variables and XDG Base Directory Specification

# ============================================================================
# Default Programs
# ============================================================================
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx TERMINAL kitty
set -gx TERMINAL_PROG kitty
set -gx BROWSER firefox
set -gx PAGER less
set -gx MANPAGER "nvim +Man!"

# ============================================================================
# XDG Base Directory Specification
# ============================================================================
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local/share
set -gx XDG_CACHE_HOME $HOME/.cache
set -gx XDG_STATE_HOME $HOME/.local/state
set -gx XDG_RUNTIME_DIR (test -n "$XDG_RUNTIME_DIR"; and echo $XDG_RUNTIME_DIR; or echo "/run/user/"(id -u))

# ============================================================================
# XDG Compliance - Application Data Directories
# ============================================================================
set -gx XINITRC $XDG_CONFIG_HOME/x11/xinitrc
set -gx NOTMUCH_CONFIG $XDG_CONFIG_HOME/notmuch-config
set -gx GTK2_RC_FILES $XDG_CONFIG_HOME/gtk-2.0/gtkrc-2.0
set -gx WGETRC $XDG_CONFIG_HOME/wget/wgetrc
set -gx INPUTRC $XDG_CONFIG_HOME/shell/inputrc
set -gx ZDOTDIR $XDG_CONFIG_HOME/zsh
set -gx WINEPREFIX $XDG_DATA_HOME/wineprefixes/default
set -gx KODI_DATA $XDG_DATA_HOME/kodi
set -gx PASSWORD_STORE_DIR $XDG_DATA_HOME/password-store
set -gx TMUX_TMPDIR $XDG_RUNTIME_DIR
set -gx ANDROID_SDK_HOME $XDG_CONFIG_HOME/android
set -gx ANDROID_USER_HOME $XDG_DATA_HOME/android
set -gx CARGO_HOME $XDG_DATA_HOME/cargo
set -gx GOPATH $XDG_DATA_HOME/go
set -gx GOMODCACHE $XDG_CACHE_HOME/go/mod
set -gx ANSIBLE_CONFIG $XDG_CONFIG_HOME/ansible/ansible.cfg
set -gx UNISON $XDG_DATA_HOME/unison
set -gx MBSYNCRC $XDG_CONFIG_HOME/mbsync/config
set -gx ELECTRUMDIR $XDG_DATA_HOME/electrum
set -gx PYTHONSTARTUP $XDG_CONFIG_HOME/python/pythonrc
set -gx SQLITE_HISTORY $XDG_DATA_HOME/sqlite_history
set -gx LESSHISTFILE $XDG_CACHE_HOME/less/history
set -gx DOCKER_CONFIG $XDG_CONFIG_HOME/docker
set -gx MACHINE_STORAGE_PATH $XDG_DATA_HOME/docker-machine
set -gx CUDA_CACHE_PATH $XDG_CACHE_HOME/nv
set -gx RUSTUP_HOME $XDG_DATA_HOME/rustup
set -gx NPM_CONFIG_USERCONFIG $XDG_CONFIG_HOME/npm/npmrc
set -gx NODE_REPL_HISTORY $XDG_DATA_HOME/node_repl_history
set -gx JUPYTER_CONFIG_DIR $XDG_CONFIG_HOME/jupyter

# ============================================================================
# ROCM Shit
# ============================================================================
set -gx ROCM_CACHE_PATH $XDG_CACHE_HOME/rocm
set -gx MIOPEN_USER_DB_PATH $XDG_CACHE_HOME/miopen
set -gx TRANSFORMERS_CACHE $XDG_CACHE_HOME/huggingface
set -gx HF_HOME $XDG_CACHE_HOME/huggingface
# ============================================================================
# Terminal Detection (Kitty doesn't set TERM_PROGRAM in 0.45+)
# ============================================================================
if set -q KITTY_PID; and not set -q TERM_PROGRAM
    set -gx TERM_PROGRAM kitty
end

# ============================================================================
# Fix SHELL — ensure it matches the actual login shell (fish)
# ============================================================================
if test "$SHELL" != /bin/fish; and test "$SHELL" != /usr/bin/fish
    set -gx SHELL (command -s fish)
end

# ============================================================================
# Colors and Visual Configuration
# ============================================================================
set -gx CLICOLOR 1

# Color for manpages in less
set -gx LESS_TERMCAP_mb (printf '\e[01;31m')
set -gx LESS_TERMCAP_md (printf '\e[01;31m')
set -gx LESS_TERMCAP_me (printf '\e[0m')
set -gx LESS_TERMCAP_se (printf '\e[0m')
set -gx LESS_TERMCAP_so (printf '\e[01;44;33m')
set -gx LESS_TERMCAP_ue (printf '\e[0m')
set -gx LESS_TERMCAP_us (printf '\e[01;32m')

# ============================================================================
# Security and Privacy
# ============================================================================
set -gx CRYPTOGRAPHY_OPENSSL_NO_LEGACY 1
set -gx LIBVIRT_DEFAULT_URI 'qemu:///system'
set -gx ADB_VENDOR_KEYS $XDG_DATA_HOME/android/adbkey

