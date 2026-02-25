# ~/.config/fish/conf.d/03-development.fish
# Development environment configuration

# Python
set -gx PYTHONDONTWRITEBYTECODE 1
set -gx PYTHONUNBUFFERED 1
set -gx PIPENV_VENV_IN_PROJECT 1

# Rust
set -gx RUST_BACKTRACE 1

# ROCm
set -gx PYTORCH_ROCM_ARCH gfx1200

# Node.js
set -gx NODE_OPTIONS "--max-old-space-size=4096"

# Go
set -gx GO111MODULE on
set -gx GOPROXY direct

# AI Keys - loaded from secure file
if test -f $HOME/.config/secrets/ai-keys.fish
    source $HOME/.config/secrets/ai-keys.fish
end
