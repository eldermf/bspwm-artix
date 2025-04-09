#!/bin/bash

# ------------------------------------------------------------------------------
# Artix Linux Installation Script (OpenRC)
# Author: Elder M. Fouraux        09/04/2025
# ------------------------------------------------------------------------------

set -euo pipefail

# Cores
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log="install-artix-$(date +%F_%T).log"

log_and_print() {
    echo -e "${CYAN}==> $1${NC}"
    echo "==> $1" >> "$log"
}

run() {
    echo "+ $*" >> "$log"
    "$@" 2>&1 | tee -a "$log"
}

ask_input() {
    read -rp "$1: " result
    echo "$result"
}

# Verificação de root
if [[ "$EUID" -ne 0 ]]; then
    echo -e "${RED}✗ Please run this script as root.${NC}"
    exit 1
fi

log_and_print "Setting keyboard layout to br-abnt2..."
run loadkeys br-abnt2

log_and_print "Enabling NTP..."
run timedatectl set-ntp true

log_and_print "Updating pacman database..."
run pacman -Syyy

log_and_print "Installing base system..."
run basestrap /mnt base base-devel linux linux-firmware vim openrc elogind-openrc amd-ucode

log_and_print "Generating fstab..."
run fstabgen -U /mnt >> /mnt/etc/fstab

log_and_print "Entering chroot environment to configure system..."

artix-chroot /mnt /bin/bash << 'EOF'
# Ambiente interno do chroot

set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_and_print() {
    echo -e "${CYAN}==> $1${NC}"
}

log_and_print "Creating swap file..."
dd if=/dev/zero of=/swapfile bs=1G count=2 status=progress
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile none swap defaults 0 0" >> /etc/fstab

log_and_print "Setting timezone and locale..."
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
sed -i 's/^#pt_BR.UTF-8/pt_BR.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=pt_BR.UTF-8" > /etc/locale.conf
echo "KEYMAP=br-abnt2" > /etc/vconsole.conf

log_and_print "Setting hostname..."
echo "jarwis" > /etc/hostname
cat << HOSTS > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   jarwis.localdomain jarwis
HOSTS

log_and_print "Setting root password..."
passwd

log_and_print "Installing GRUB and essential tools..."
pacman -S --noconfirm --needed grub efibootmgr linux-headers dialog mtools dosfstools git \
    xdg-utils xdg-user-dirs bash-completion os-prober

log_and_print "Installing GRUB bootloader..."
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck

log_and_print "Enabling OS Prober..."
sed -i 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' /etc/default/grub
sed -i 's/^#GRUB_SAVEDEFAULT=true/GRUB_SAVEDEFAULT=true/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

log_and_print "Installing and enabling system services..."
pacman -S --noconfirm --needed connman-openrc connman-gtk
rc-update add connmand

pacman -S --noconfirm --needed openssh openssh-openrc
rc-update add sshd default

EOF

# Solicitar criação do usuário
USERNAME=$(ask_input "Enter a name for the new user")

log_and_print "Creating user: $USERNAME"
artix-chroot /mnt useradd -m -g users -G wheel,storage,power,network,audio,video,daemon,dbus,disk,lp,optical,input,games,rfkill,scanner -s /bin/bash "$USERNAME"
artix-chroot /mnt passwd "$USERNAME"

log_and_print "Installation complete! You may exit chroot, unmount, and reboot."
