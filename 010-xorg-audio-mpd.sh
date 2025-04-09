#!/bin/bash

# ------------------------------------------------------------------------------
# Arch Linux Minimal Setup Script for Xorg + Audio + AMDGPU + MPD Stack
# Author: Elder M. Fouraux		09/04/2025
# ------------------------------------------------------------------------------

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print headings
print_heading() {
    echo -e "\n${CYAN}==> $1${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print warning
print_warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Function to print error and exit
print_error() {
    echo -e "${RED}✗ $1${NC}"
    exit 1
}

# 1. Update system
print_heading "Updating package database..."
sudo pacman -Syu --noconfirm

# 2. Install Xorg minimal
print_heading "Installing minimal Xorg..."
sudo pacman -S --noconfirm xorg-server xorg-xinit xorg-xrandr xorg-xkill xorg-xset xorg-xsetroot xorg-xwininfo
sudo pacman -S --noconfirm xorg-fonts-misc xclip xcb-util xcb-util-wm xcb-util-keysyms xcb-util-cursor libxcb
sudo pacman -S --noconfirm xorg-xprop xorg-xdpyinfo 

# 3. Install AMD GPU driver
print_heading "Installing AMDGPU driver..."
sudo pacman -S --noconfirm xf86-video-amdgpu

# 4. Install audio packages
print_heading "Installing PulseAudio and Pavucontrol..."
sudo pacman -S --noconfirm pulseaudio pavucontrol alsa-utils

# 5. Pre-install bspwm and dependencies
print_heading "Installing bspwm and sxhkd..."
sudo pacman -S --noconfirm bspwm sxhkd

# 6. Ask about mpd/ncmpcpp stack
print_heading "Optional: MPD + MPC + ncmpcpp"

read -rp "Do you want to install and configure MPD, MPC and ncmpcpp? [y/N]: " INSTALL_AUDIO_STACK

if [[ "${INSTALL_AUDIO_STACK,,}" == "y" ]]; then
    print_heading "Installing MPD, MPC and ncmpcpp..."
    sudo pacman -S --noconfirm mpd mpc ncmpcpp

    # Create config directories
    mkdir -p "$HOME/.config/mpd" "$HOME/.ncmpcpp" "$HOME/.mpd/playlists"

    # MPD config
    cat > "$HOME/.config/mpd/mpd.conf" <<EOF
music_directory     "$HOME/Music"
playlist_directory  "$HOME/.mpd/playlists"
db_file             "$HOME/.mpd/database"
log_file            "$HOME/.mpd/log"
pid_file            "$HOME/.mpd/pid"
state_file          "$HOME/.mpd/state"
audio_output {
    type "pulse"
    name "PulseAudio"
}
EOF

    # Symlink for legacy compatibility
    ln -sf "$HOME/.config/mpd/mpd.conf" "$HOME/.mpdconf"

    # ncmpcpp config
    cat > "$HOME/.ncmpcpp/config" <<EOF
mpd_music_dir = "$HOME/Music"
mpd_host = "localhost"
mpd_port = "6600"
ncmpcpp_directory = "$HOME/.ncmpcpp"
EOF

    print_success "MPD, MPC and ncmpcpp installed and configured."
else
    print_warn "Skipped MPD/ncmpcpp setup."
fi

print_success "All base components installed successfully!"
