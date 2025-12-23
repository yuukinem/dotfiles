#!/bin/bash
# Dotfiles installation script
# Supports macOS (brew) and Linux (emerge/apt/pacman)

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config-backup/$(date +%Y%m%d_%H%M%S)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Backup existing configs
backup_configs() {
    local need_backup=false

    for dir in kitty fish; do
        if [ -e "$CONFIG_DIR/$dir" ] && [ ! -L "$CONFIG_DIR/$dir" ]; then
            need_backup=true
            break
        fi
    done

    if [ "$need_backup" = true ]; then
        info "Backing up existing configs to $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"

        for dir in kitty fish; do
            if [ -e "$CONFIG_DIR/$dir" ] && [ ! -L "$CONFIG_DIR/$dir" ]; then
                cp -r "$CONFIG_DIR/$dir" "$BACKUP_DIR/"
                info "  Backed up $dir"
            fi
        done

        success "Backup complete: $BACKUP_DIR"
    else
        info "No existing configs to backup (or already symlinked)"
    fi
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin) OS="macos" ;;
        Linux)  OS="linux" ;;
        *)      error "Unsupported OS: $(uname -s)" ;;
    esac
    info "Detected OS: $OS"
}

# Detect package manager
detect_pkg_manager() {
    if command -v brew &>/dev/null; then
        PKG_MANAGER="brew"
    elif command -v emerge &>/dev/null; then
        PKG_MANAGER="emerge"
    elif command -v apt &>/dev/null; then
        PKG_MANAGER="apt"
    elif command -v pacman &>/dev/null; then
        PKG_MANAGER="pacman"
    else
        error "No supported package manager found (brew/emerge/apt/pacman)"
    fi
    info "Detected package manager: $PKG_MANAGER"
}

# Detect display server (for Linux clipboard)
detect_display_server() {
    if [ "$OS" = "linux" ]; then
        if [ -n "$WAYLAND_DISPLAY" ]; then
            DISPLAY_SERVER="wayland"
        else
            DISPLAY_SERVER="x11"
        fi
        info "Detected display server: $DISPLAY_SERVER"
    fi
}

# Install dependencies
install_deps() {
    info "Installing dependencies..."

    case "$PKG_MANAGER" in
        brew)
            brew install kitty fish fzf git
            ;;
        emerge)
            # Copy sets file and install
            if [ -f "$DOTFILES_DIR/gentoo/sets/dotfiles" ]; then
                info "Installing Gentoo sets file..."
                sudo mkdir -p /etc/portage/sets
                sudo cp "$DOTFILES_DIR/gentoo/sets/dotfiles" /etc/portage/sets/dotfiles
                success "Sets file installed to /etc/portage/sets/dotfiles"
                info "Installing packages with: emerge @dotfiles"
                sudo emerge --ask @dotfiles
            else
                error "Gentoo sets file not found"
            fi
            ;;
        apt)
            sudo apt update
            sudo apt install -y kitty fish fzf xclip git
            ;;
        pacman)
            sudo pacman -Sy --needed kitty fish fzf xclip git
            ;;
    esac

    success "Dependencies installed"
}

# Generate platform-specific keybindings.conf
generate_keybindings() {
    local src="$DOTFILES_DIR/kitty/.config/kitty/keybindings.conf.template"
    local dst="$DOTFILES_DIR/kitty/.config/kitty/keybindings.conf"

    if [ ! -f "$src" ]; then
        warn "keybindings.conf.template not found, skipping"
        return
    fi

    info "Generating keybindings.conf for $OS..."

    if [ "$OS" = "macos" ]; then
        # macOS: use cmd+ keys
        sed -e 's/__MOD__/cmd/g' \
            -e 's/__MOD_SHIFT__/cmd+shift/g' \
            -e 's/__MOD_CTRL__/cmd+ctrl/g' \
            -e "s|__KITTY_CONFIG__|$HOME/.config/kitty|g" \
            "$src" > "$dst"
    else
        # Linux: use ctrl+ keys
        sed -e 's/__MOD__/ctrl/g' \
            -e 's/__MOD_SHIFT__/ctrl+shift/g' \
            -e 's/__MOD_CTRL__/ctrl+alt/g' \
            -e "s|__KITTY_CONFIG__|$HOME/.config/kitty|g" \
            "$src" > "$dst"
    fi

    success "Generated keybindings.conf"
}

# Generate platform-specific fzf-copy.sh
generate_fzf_copy() {
    local src="$DOTFILES_DIR/kitty/.config/kitty/fzf-copy.sh.template"
    local dst="$DOTFILES_DIR/kitty/.config/kitty/fzf-copy.sh"

    if [ ! -f "$src" ]; then
        warn "fzf-copy.sh.template not found, skipping"
        return
    fi

    info "Generating fzf-copy.sh for $OS..."

    if [ "$OS" = "macos" ]; then
        sed -e 's|__FZF__|/opt/homebrew/bin/fzf|g' \
            -e 's|__COPY__|/usr/bin/pbcopy|g' \
            "$src" > "$dst"
    else
        # Linux: detect clipboard command
        if [ "$DISPLAY_SERVER" = "wayland" ]; then
            COPY_CMD="wl-copy"
        else
            COPY_CMD="xclip -selection clipboard"
        fi
        sed -e 's|__FZF__|fzf|g' \
            -e "s|__COPY__|$COPY_CMD|g" \
            "$src" > "$dst"
    fi

    chmod +x "$dst"
    success "Generated fzf-copy.sh"
}

# Create symlinks
create_symlinks() {
    info "Creating symlinks..."
    mkdir -p "$CONFIG_DIR"

    # Remove existing (already backed up)
    for dir in kitty fish; do
        if [ -e "$CONFIG_DIR/$dir" ]; then
            rm -rf "$CONFIG_DIR/$dir"
        fi
    done

    # Create symlinks
    ln -sfn "$DOTFILES_DIR/kitty/.config/kitty" "$CONFIG_DIR/kitty"
    ln -sfn "$DOTFILES_DIR/fish/.config/fish" "$CONFIG_DIR/fish"

    success "Symlinks created"
}

# Install fish plugins
install_fish_plugins() {
    info "Setting up fish plugins..."

    if ! command -v fish &>/dev/null; then
        warn "Fish not found, skipping plugin setup"
        return
    fi

    # If fish config is symlinked from dotfiles, plugins are already there
    if [ -L "$CONFIG_DIR/fish" ]; then
        info "Fish config is symlinked, plugins already in place"
        # Just verify fisher works
        if fish -c "type -q fisher" 2>/dev/null; then
            success "Fisher is available"
        else
            warn "Fisher not found, you may need to run: fisher install jorgebucaran/fisher"
        fi
        return
    fi

    # Fresh install: install fisher and plugins
    if ! fish -c "type -q fisher" 2>/dev/null; then
        info "Installing fisher..."
        fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
    fi

    if [ -f "$CONFIG_DIR/fish/fish_plugins" ]; then
        info "Installing plugins from fish_plugins..."
        fish -c "fisher update"
    fi

    success "Fish plugins installed"
}

# Print font installation instructions
print_font_instructions() {
    echo
    info "Font installation:"
    echo "  This config uses 'FiraCode Nerd Font Mono'"
    echo
    case "$PKG_MANAGER" in
        brew)
            echo "  Install with: brew install --cask font-fira-code-nerd-font"
            ;;
        emerge)
            echo "  Option 1: Enable guru overlay and emerge media-fonts/nerd-fonts-fira-code"
            echo "  Option 2: Download from https://www.nerdfonts.com/font-downloads"
            ;;
        apt)
            echo "  Download from https://www.nerdfonts.com/font-downloads"
            echo "  Extract to ~/.local/share/fonts/ and run: fc-cache -fv"
            ;;
        pacman)
            echo "  Install with: sudo pacman -S ttf-firacode-nerd"
            ;;
    esac
    echo
}

# Main
main() {
    echo "========================================"
    echo "  Dotfiles Installation Script"
    echo "========================================"
    echo

    detect_os
    detect_pkg_manager
    detect_display_server

    echo
    read -p "Install dependencies? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        install_deps
    fi

    generate_keybindings
    generate_fzf_copy
    backup_configs
    create_symlinks
    install_fish_plugins
    print_font_instructions

    echo
    success "Installation complete!"
    echo
    echo "Next steps:"
    echo "  1. Install the Nerd Font (see above)"
    echo "  2. Restart your terminal or run: kitty"
    echo "  3. Start fish shell: fish"
    echo
}

main "$@"
