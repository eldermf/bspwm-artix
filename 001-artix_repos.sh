#!/bin/bash

# ------------------------------------------------------------------------------
# Script to install yay on Arch Linux
# Author: Elder M. Fouraux		09/04/2025
# Source: https://wiki.archlinux.org/title/Yay
# ------------------------------------------------------------------------------

set -e  # Exit immediately on error

# Colors for output messages
GREEN='\033[0;32m'
RED='\033[0;31m'
NEUTRAL='\033[0m'

echo -e "${GREEN}==> Starting yay installation...${NEUTRAL}"

# Check if yay is already installed
if command -v yay >/dev/null 2>&1; then
    echo -e "${GREEN}✓ yay is already installed.${NEUTRAL}"
    exit 0
fi

# Check required dependencies
echo -e "${GREEN}==> Ensuring git and base-devel are installed...${NEUTRAL}"
sudo pacman -Sy --needed --noconfirm git base-devel

# Create temporary working directory
WORKDIR=$(mktemp -d)
cd "$WORKDIR" || exit 1

# Clone yay's official AUR repository
echo -e "${GREEN}==> Cloning yay AUR repository...${NEUTRAL}"
git clone https://aur.archlinux.org/yay.git

cd yay || { echo -e "${RED}✗ Failed to enter yay directory.${NEUTRAL}"; exit 1; }

# Build and install yay
echo -e "${GREEN}==> Building and installing yay...${NEUTRAL}"
makepkg -si --noconfirm

# Clean up temporary files
cd ~
rm -rf "$WORKDIR"

echo -e "${GREEN}✓ yay has been successfully installed!${NEUTRAL}"

cat << "EOF"

  ___         _   _      
 / _ \       | | (_)     
/ /_\ \_ __  | |_ ___  __
|  _  | '__| | __| \ \/ /
| | | | |    | |_| |>  < 
\_| |_/_|     \__|_/_/\_\
                         
EOF

exit 0
