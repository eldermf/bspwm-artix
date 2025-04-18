#!/bin/bash

# ------------------------------------------------------------------------------
# Artix Linux Installation Script (OpenRC)
# Author: Elder M. Fouraux		09/04/2025
# ------------------------------------------------------------------------------
#!/bin/bash

# Cores para melhor visualização
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções
print_header() {
    clear
    echo -e "${BLUE}=====================================${NC}"
    echo -e "${GREEN}   INSTALAÇÃO DO ARTIX COM OPENRC   ${NC}"
    echo -e "${BLUE}=====================================${NC}"
    echo ""
}

print_step() {
    echo -e "${YELLOW}[*] Passo $1: $2${NC}"
}

print_info() {
    echo -e "${BLUE}[i] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

print_error() {
    echo -e "${RED}[✗] $1${NC}"
}

confirm_continue() {
    echo ""
    read -p "Pressione Enter para continuar ou Ctrl+C para cancelar..."
    echo ""
}

# Verificar se está rodando como root
if [ "$(id -u)" -ne 0 ]; then
    print_error "Este script precisa ser executado como root!"
    exit 1
fi

# Início da instalação
print_header

# Passo 1: Configurar teclado
print_step "1" "Configurando o teclado para br-abnt2"
loadkeys br-abnt2
print_success "Teclado configurado!"

# Verificar se o sistema está em UEFI mode
if [ ! -d "/sys/firmware/efi/efivars" ]; then
    print_error "O sistema não está em modo UEFI. Este script é apenas para instalações UEFI."
    exit 1
fi

# Confirmar ponto de montagem
print_info "Antes de continuar, verifique se você já criou e montou suas partições."
print_info "A partição raiz deve estar montada em /mnt"
print_info "A partição EFI deve estar montada em /mnt/boot/efi"
echo ""
read -p "As partições estão devidamente criadas e montadas? (s/n): " partitions_ready

if [[ "$partitions_ready" != "s" && "$partitions_ready" != "S" ]]; then
    print_error "Por favor, crie e monte as partições antes de executar este script."
    exit 1
fi

# Passo 2: Instalar pacotes base
print_step "2" "Instalando pacotes base (isso pode demorar um pouco)"
basestrap /mnt base base-devel linux linux-firmware vim openrc elogind-openrc amd-ucode
if [ $? -ne 0 ]; then
    print_error "Falha ao instalar pacotes base!"
    exit 1
fi
print_success "Pacotes base instalados!"

# Passo 3: Gerar fstab
print_step "3" "Gerando fstab"
fstabgen -U /mnt >> /mnt/etc/fstab
if [ $? -ne 0 ]; then
    print_error "Falha ao gerar fstab!"
    exit 1
fi
print_success "Fstab gerado!"

# Criar script para ser executado dentro do chroot
print_step "4" "Preparando ambiente chroot"
cat > /mnt/artix_install_chroot.sh << 'EOL'
#!/bin/bash

# Cores para melhor visualização
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções
print_step() {
    echo -e "${YELLOW}[*] Passo $1: $2${NC}"
}

print_info() {
    echo -e "${BLUE}[i] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

print_error() {
    echo -e "${RED}[✗] $1${NC}"
}

# Passo 5: Criar Swapfile
print_step "5" "Criando Swapfile"
dd if=/dev/zero of=/swapfile bs=3G count=2 status=progress
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile   none    swap    defaults    0 0" >> /etc/fstab
print_success "Swapfile criado e configurado!"

# Passo 6: Configurar fuso horário e localização
print_step "6" "Configurando fuso horário e localização"
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
sed -i 's/#pt_BR.UTF-8/pt_BR.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=pt_BR.UTF-8" > /etc/locale.conf
export LANG="pt_BR.UTF-8"
export LC_COLLATE="C"
echo "KEYMAP=br-abnt2" > /etc/vconsole.conf
print_success "Fuso horário e localização configurados!"

# Passo 7: Configurar hostname
print_step "7" "Configurando hostname"
read -p "Digite o hostname desejado para sua máquina: " hostname_input
echo "$hostname_input" > /etc/hostname
echo "hostname=\"$hostname_input\"" > /etc/conf.d/hostname
cat > /etc/hosts << EOF
127.0.0.1	localhost
::1			localhost
127.0.1.1	$hostname_input.localdomain	$hostname_input
EOF
print_success "Hostname configurado como: $hostname_input"

# Passo 8: Definir senha root
print_step "8" "Definindo senha do usuário root"
print_info "Por favor, defina a senha para o usuário root:"
passwd
print_success "Senha do root configurada!"

# Passo 9: Instalar GRUB e pacotes iniciais
print_step "9" "Instalando GRUB e pacotes iniciais"
pacman -S --noconfirm grub efibootmgr linux-headers dialog mtools dosfstools git xdg-utils xdg-user-dirs bash-completion os-prober
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck
if [ $? -ne 0 ]; then
    print_error "Falha na instalação do GRUB!"
    exit 1
fi
print_success "GRUB instalado!"

# Passo 10: Configurar GRUB
print_step "10" "Configurando GRUB"
sed -i 's/GRUB_DEFAULT=0/GRUB_DEFAULT=saved/' /etc/default/grub
sed -i 's/#GRUB_SAVEDEFAULT=true/GRUB_SAVEDEFAULT=true/' /etc/default/grub
sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
print_success "GRUB configurado!"

# Passo 11: Configurar serviços
print_step "11" "Instalando e configurando serviços"
pacman -S --noconfirm connman-openrc connman-gtk
rc-update add connmand
pacman -S --noconfirm openssh openssh-openrc
rc-update add sshd default
print_success "Serviços configurados!"

# Passo 12: Criar usuário
print_step "12" "Criando usuário"
read -p "Digite o nome do usuário que deseja criar: " username
useradd -m -g users -G wheel,storage,power,network,audio,video,daemon,dbus,disk,lp,optical,input,games,scanner -s /bin/bash "$username"
print_info "Defina a senha para o usuário $username:"
passwd "$username"

# Configurar sudo
print_info "Configurando sudo..."
sed -i '9i Defaults env_reset,pwfeedback,insults' /etc/sudoers
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
print_success "Usuário $username criado e sudo configurado!"

print_info "Instalação dentro do chroot concluída. Retornando ao ambiente de instalação..."
EOL

# Tornar o script executável
chmod +x /mnt/artix_install_chroot.sh

# Passo 4: Executar o script no chroot
print_step "4" "Alterando para ambiente chroot"
artix-chroot /mnt /artix_install_chroot.sh
if [ $? -ne 0 ]; then
    print_error "Houve um problema na execução do script dentro do chroot!"
    exit 1
fi

# Passo 13: Desmontando e concluindo
print_step "13" "Finalizando instalação"
umount -Rl /mnt
if [ $? -ne 0 ]; then
    print_error "Falha ao desmontar partições. Tente desmontá-las manualmente."
    exit 1
fi

# Remover o script temporário do chroot
rm -f /mnt/artix_install_chroot.sh

print_success "Instalação base do Artix Linux com OpenRC concluída com sucesso!"
print_info "A instalação base está completa."
print_info "Por favor, reinicie o sistema e remova a mídia de instalação:"
print_info "# reboot"

cat << "EOF"

  ___         _   _      
 / _ \       | | (_)     
/ /_\ \_ __  | |_ ___  __
|  _  | '__| | __| \ \/ /
| | | | |    | |_| |>  < 
\_| |_/_|     \__|_/_/\_\
                         
EOF

exit 0
