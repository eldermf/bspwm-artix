#!/bin/bash

# ------------------------------------------------------------------------------
# Safe Config Restore Script with Keyring Setup - Arch Linux
# Copies etc, root, usr as root, home as user, and sets up keyrings
# Author: Elder M. Fouraux		09/04/2025
# ------------------------------------------------------------------------------

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Timestamp for backups and log
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
LOGFILE="copy-configs-$TIMESTAMP.log"

# Directories
SYSTEM_DIRS=("etc" "root" "usr")
USER_DIR="home"

# Function to print headings
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

# Check if root
if [[ "$EUID" -ne 0 ]]; then
    print_error "This script must be run as root (use sudo)"
fi

print_heading "Starting system config restoration..."
echo "Log file: $LOGFILE"

read -rp "This will copy system configs and update pacman keys. Continue? [y/N]: " CONFIRM
if [[ "${CONFIRM,,}" != "y" ]]; then
    echo "Aborted by user."
    exit 0
fi

# Function to backup and copy
backup_and_copy() {
    local src="$1"
    local dest="/$1"

    if [[ -d "$dest" ]]; then
        local backup="/$1-backup-$TIMESTAMP"
        print_warn "Creating backup of /$1 at $backup"
        cp -a "$dest" "$backup"
    fi

    if [[ -d "$src" ]]; then
        print_heading "Copying $src to $dest ..."
        cp -a "$src/." "$dest/"
        print_success "$src copied."
    else
        print_error "Directory '$src' not found."
    fi
}

# Copy system dirs
for DIR in "${SYSTEM_DIRS[@]}"; do
    backup_and_copy "$DIR"
done

# Copy home dir as user
if [[ -d "$USER_DIR" ]]; then
    print_heading "Copying user home directory..."

    for user_home in "$USER_DIR"/*; do
        USERNAME=$(basename "$user_home")
        DEST_HOME="/home/$USERNAME"

        if id "$USERNAME" &>/dev/null; then
            if [[ -d "$DEST_HOME" ]]; then
                BACKUP_HOME="/home/${USERNAME}-backup-$TIMESTAMP"
                print_warn "Creating backup at $BACKUP_HOME"
                cp -a "$DEST_HOME" "$BACKUP_HOME"
            fi

            print_heading "Copying home for user: $USERNAME"
            sudo -u "$USERNAME" cp -a "$user_home/." "$DEST_HOME/"
            print_success "Home directory copied for $USERNAME"
        else
            print_warn "User $USERNAME does not exist. Skipping."
        fi
    done
else
    print_warn "'home/' directory not found, skipping."
fi

# --- Keyring Setup ---

print_heading "Checking for custom pacman.conf with new repos..."

if grep -q '\[artix\|universe\|omniverse\]' /etc/pacman.conf 2>/dev/null; then
    print_heading "Installing archlinux-keyring and artix-keyring..."
    pacman -Sy --noconfirm archlinux-keyring artix-keyring

    print_heading "Initializing and updating pacman GPG keys..."
    pacman-key --init
    pacman-key --populate archlinux artix

    print_heading "Refreshing keyring from keyservers..."
    pacman-key --refresh-keys
    pacman -Syu

    print_success "Keyring setup complete."
else
    print_warn "No custom repos detected in /etc/pacman.conf. Skipping keyring setup."
fi

print_success "All steps completed successfully."
echo -e "${CYAN}Log saved to: $LOGFILE${NC}"
