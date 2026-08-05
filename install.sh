#!/bin/bash

# Hyprland Installer
# This script installs Hyprland and its dependencies on Arch Linux or Arch derivatives.
# Configuration files and package lists are provided beforehand.

set -e

# Script directory (where the script is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
HYPRLAND_CONFIG_DIR="$HOME/.config/hypr"
HYPRLAND_DATA_DIR="$HOME/.local/share/hyprland"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root (should NOT be root for this script)
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should NOT be run as root. Please run as regular user."
        exit 1
    fi
}

# Check if pacman is available
check_pacman() {
    if ! command -v pacman &> /dev/null; then
        log_error "pacman not found. This script requires Arch Linux or an Arch derivative."
        exit 1
    fi
}

# Check if yay is available
check_yay() {
    if ! command -v yay &> /dev/null; then
        log_warn "yay not found. Please install yay to install AUR packages."
        log_warn "Install yay from AUR: https://wiki.archlinux.org/title/Arch_User_Repository"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Install packages from a list file
# Builds and executes a command like: pacman -S --needed --noconfirm pkg1 pkg2 ...
install_packages_from_file() {
    local package_file="$1"

    if [[ ! -f "$package_file" ]]; then
        log_warn "Package file not found: $package_file"
        return
    fi

    # Read packages from file, ignoring comments and empty lines
    local packages=()
    while IFS= read -r line; do
        # Skip comments and empty lines
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        # Trim whitespace
        line=$(echo "$line" | xargs)
        if [[ -n "$line" ]]; then
            packages+=("$line")
        fi
    done < "$package_file"

    if [[ ${#packages[@]} -eq 0 ]]; then
        log_warn "No packages to install from $package_file"
        return
    fi

    log_info "Installing ${#packages[@]} package(s) from $package_file..."
    log_info "Command: pacman -S --needed --noconfirm ${packages[*]}"
    sudo pacman -S --needed --noconfirm "${packages[@]}"
}

# Deploy configuration files from project .config/ source directory
# Each subdirectory mirrors the target structure (e.g., Config/hypr/ -> ~/.config/hypr/)
deploy_configs() {
    local config_source_dir="$SCRIPT_DIR/.config"

    if [[ ! -d "$config_source_dir" ]]; then
        log_warn "Configuration directory not found: $config_source_dir"
        log_warn "Skipping configuration deployment."
        return
    fi

    log_info "Deploying configurations from $config_source_dir..."

    # Copy all subdirectories to $HOME/.config/ (preserving directory structure)
    for config_item in "$config_source_dir"/*/; do
        if [[ -d "$config_item" ]]; then
            local dir_name
            dir_name=$(basename "$config_item")
            log_info "Deploying: $dir_name/"
            mkdir -p "$HOME/.config/$dir_name"
            cp -r "$config_item"* "$HOME/.config/$dir_name/"
        fi
    done

    log_info "Configuration deployment complete."
}

# Install AUR packages (optional - ask user for confirmation)
install_aur_packages() {
    local aur_file="$SCRIPT_DIR/Script/pkg_aur.lst"

    if [[ ! -f "$aur_file" ]]; then
        log_warn "AUR package file not found: $aur_file"
        log_warn "Skipping AUR package installation."
        return
    fi

    # Read AUR packages from file, ignoring comments and empty lines
    local packages=()
    while IFS= read -r line; do
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        line=$(echo "$line" | xargs)
        if [[ -n "$line" ]]; then
            packages+=("$line")
        fi
    done < "$aur_file"

    if [[ ${#packages[@]} -eq 0 ]]; then
        log_warn "No AUR packages to install from $aur_file"
        return
    fi

    # Show list and ask user for confirmation
    log_info "The following AUR packages are available for installation:"
    for pkg in "${packages[@]}"; do
        echo -e "  ${YELLOW}•${NC} $pkg"
    done
    echo
    read -p "Install these ${#packages[@]} AUR package(s)? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping AUR package installation."
        return
    fi

    log_info "Installing ${#packages[@]} AUR package(s)..."
    log_info "Command: yay -S --needed --noconfirm ${packages[*]}"
    yay -S --needed --noconfirm "${packages[@]}"
}

# Deploy dotfiles from project Dotfiles/ source directory
# Each file mirrors the target location (e.g., Dotfiles/ -> ~/)
deploy_dotfiles() {
    local dotfile_source_dir="$SCRIPT_DIR/Dotfiles"

    if [[ ! -d "$dotfile_source_dir" ]]; then
        log_warn "Dotfiles directory not found: $dotfile_source_dir"
        log_warn "Skipping dotfile deployment."
        return
    fi

    log_info "Deploying dotfiles from $dotfile_source_dir..."

    # Copy all dotfiles to $HOME/ (preserving filenames)
    for dotfile in "$dotfile_source_dir"/*; do
        if [[ -f "$dotfile" ]]; then
            local dotfile_name
            dotfile_name=$(basename "$dotfile")
            log_info "Deploying: .$dotfile_name"
            cp "$dotfile" "$HOME/.$dotfile_name"
        fi
    done

    log_info "Dotfile deployment complete."
}

# Main function
main() {
    log_info "Starting Hyprland installer..."

    # Pre-install checks
    check_root
    check_pacman
    check_yay

    # Update package database (use -Syu to prevent partial upgrades)
    log_info "Updating package database..."
    sudo pacman -Syu --noconfirm

    # Install Hyprland (use --needed to skip already installed packages)
    log_info "Installing Hyprland..."
    sudo pacman -S --needed --noconfirm hyprland

    # Install core packages
    log_info "Installing core packages..."
    install_packages_from_file "$SCRIPT_DIR/Script/pkg_core.lst"

    # Install extra packages
    log_info "Installing extra packages..."
    install_packages_from_file "$SCRIPT_DIR/Script/pkg_extra.lst"

    # Install AUR packages (optional - ask user)
    install_aur_packages

    # Deploy configuration files
    deploy_configs

    # Deploy dotfiles
    deploy_dotfiles

    log_info "Hyprland installation complete!"
    log_info "You may need to log out and back in for changes to take effect."
}

# Run main function
main
