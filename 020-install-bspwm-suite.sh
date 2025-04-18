#!/bin/bash

# ------------------------------------------------------------------------------
# BSPWM Suite Installer - Arch Linux
# Installs bspwm and a full set of essential tools for a minimal DE
# Author: Elder M. Fouraux		09/04/2025
# ------------------------------------------------------------------------------

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
LOGFILE="bspwm-install-$TIMESTAMP.log"

# Functions
print_heading() {
    echo -e "\n${CYAN}==> $1${NC}"
    echo "==> $1" >> "$LOGFILE"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
    echo "✓ $1" >> "$LOGFILE"
}

print_warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
    echo "⚠ $1" >> "$LOGFILE"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
    echo "✗ $1" >> "$LOGFILE"
    exit 1
}

confirm() {
    read -rp "$1 [y/N]: " answer
    [[ "${answer,,}" == "y" ]]
}

# Ensure script is run as root
if [[ "$EUID" -ne 0 ]]; then
    print_error "This script must be run as root (use sudo)."
fi

print_heading "Updating system packages..."
pacman -Syu --noconfirm >> "$LOGFILE" 2>&1
print_success "System updated."

# Install yay if not already installed
if ! command -v yay &>/dev/null; then
    print_heading "Installing yay..."
    pacman -S --noconfirm yay >> "$LOGFILE" 2>&1
    print_success "yay installed."
fi

print_heading "Installing SDDM and theme via yay..."

# Install SDDM and theme
yay -S --noconfirm sddm sddm-openrc sddm-catppuccin-git >> "$LOGFILE" 2>&1
print_success "SDDM and theme installed."

print_heading "Enabling SDDM service with OpenRC..."
rc-update add sddm default >> "$LOGFILE" 2>&1
print_success "SDDM service enabled."

# --- Packages list ---
PACKAGES=(
    bspwm sxhkd polybar rofi dunst lxappearance dmenu nitrogen bat clipcat
    thunar tumbler thunar-volman thunar-shares-plugin thunar-archive-plugin
    gvfs gvfs-afc gvfs-nfs gvfs-smb gvfs-gphoto2 gvfs-mtp
    polkit-gnome pamixer pacman-contrib imagemagick jq maim
    firefox firefox-esr-i18n-pt-br
    geany geany-plugins
    zsh zsh-autosuggestions zsh-history-substring-search zsh-syntax-highlighting
    ttf-inconsolata ttf-jetbrains-mono ttf-jetbrains-mono-nerd
    ttf-terminus-nerd ttf-ubuntu-mono-nerd
    ueberzugpp
)

print_heading "Installing BSPWM suite and tools..."

for pkg in "${PACKAGES[@]}"; do
    if pacman -Q "$pkg" &>/dev/null; then
        print_warn "$pkg is already installed. Skipping..."
    else
        print_heading "Installing $pkg..."
        if pacman -S --noconfirm --needed "$pkg" >> "$LOGFILE" 2>&1; then
            print_success "$pkg installed successfully."
        else
            print_error "Failed to install $pkg. See $LOGFILE for details."
        fi
    fi
done

print_success "All requested packages are installed."
echo -e "${CYAN}Installation log saved to: $LOGFILE${NC}"

# Prompt to change shell to zsh
if confirm "Do you want to change the default shell to zsh for user '$SUDO_USER'?"; then
    if chsh -s /bin/zsh "$SUDO_USER"; then
        print_success "Shell changed to zsh for user $SUDO_USER."
    else
        print_error "Failed to change shell."
    fi
else
    print_warn "Shell change skipped."
fi

cat << "EOF"

  ___         _   _      
 / _ \       | | (_)     
/ /_\ \_ __  | |_ ___  __
|  _  | '__| | __| \ \/ /
| | | | |    | |_| |>  < 
\_| |_/_|     \__|_/_/\_\
                         
EOF

exit 0
