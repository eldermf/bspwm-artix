#!/bin/bash

# ------------------------------------------------------------------------------
# Fix Arch/Artix repos
# Enable Arch Linux extra and community repos on Artix
# Author: Elder M. Fouraux		09/04/2025
# ------------------------------------------------------------------------------

sudo pacman -Syu --needed --noconfirm wget
sudo rm -rf /tmp/pacman.conf /tmp/mirrorlist-arch
wget -c https://github.com/eldermf/bspwm-artix/blob/master/etc/pacman.conf -P /tmp
sudo mv /etc/pacman.conf /etc/pacman.conf.old ; sudo chown root:root /tmp/pacman.conf ; sudo mv /tmp/pacman.conf /etc
wget 'archlinux.org/mirrorlist/?country=US&country=GB&protocol=http&protocol=https&ip_version=4&use_mirror_status=on' -O /tmp/mirrorlist-arch
sed -i 's/#Server/Server/' /tmp/mirrorlist-arch ; sudo mv /tmp/mirrorlist-arch /etc/pacman.d
sudo pacman -Syu --needed --noconfirm archlinux-keyring
exit
