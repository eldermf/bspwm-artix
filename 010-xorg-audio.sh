#!/bin/bash

# ------------------------------------------------------------------------------
# Arch Linux Minimal Setup Script for Xorg + Audio + AMDGPU 
# Author: Elder M. Fouraux		09/04/2025
# ------------------------------------------------------------------------------

# Cores para melhor visualização
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções para exibição de mensagens
print_header() {
    echo -e "${BLUE}=====================================${NC}"
    echo -e "${GREEN}   INSTALADOR XORG + AMDGPU + ÁUDIO ${NC}"
    echo -e "${BLUE}=====================================${NC}"
    echo ""
}

print_step() {
    echo -e "${YELLOW}[*] $1${NC}"
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

# Verificar se está rodando como root
if [ "$(id -u)" -ne 0 ]; then
    print_error "Este script precisa ser executado como root!"
    exit 1
fi

# Início da instalação
print_header

# 1. Instalar Xorg mínimo
print_step "Instalando Xorg mínimo"
pacman -S --noconfirm --needed \
    xorg-server \
    xorg-xinit \
    xorg-xrandr \
    xorg-xkill \
    xorg-xset \
    xorg-xsetroot \
    xorg-xwininfo \
    xorg-fonts-misc \
    xclip \
    xcb-util \
    xcb-util-wm \
    xcb-util-keysyms \
    xcb-util-cursor \
    libxcb \
    xorg-xprop \
    xorg-xdpyinfo

if [ $? -ne 0 ]; then
    print_error "Falha ao instalar pacotes do Xorg!"
    exit 1
fi
print_success "Xorg mínimo instalado com sucesso!"

# 2. Instalar driver AMD GPU
print_step "Instalando driver AMDGPU"
pacman -S --noconfirm --needed xf86-video-amdgpu

if [ $? -ne 0 ]; then
    print_error "Falha ao instalar driver AMDGPU!"
    exit 1
fi
print_success "Driver AMDGPU instalado com sucesso!"

# 3. Instalar pacotes de áudio
print_step "Instalando pacotes de áudio"
pacman -S --noconfirm --needed \
    alsa-utils \
    alsa-utils-openrc \
    alsa-plugins \
    alsa-firmware \
    pulseaudio \
    pulseaudio-alsa \
    pavucontrol

if [ $? -ne 0 ]; then
    print_error "Falha ao instalar pacotes de áudio!"
    exit 1
fi

# Habilitar serviço ALSA no OpenRC
print_info "Habilitando serviço ALSA no OpenRC"
rc-update add alsasound default

# Configurar o volume inicial do ALSA
print_info "Configurando volume inicial do ALSA"
amixer sset Master unmute
amixer sset Master 70%
alsactl store

print_success "Pacotes de áudio instalados e configurados com sucesso!"

# Finalização
print_step "Instalação concluída"
print_info "Xorg mínimo, driver AMDGPU e pacotes de áudio foram instalados."
print_info "Para iniciar o Xorg, use o comando: startx"
print_info "Para configurar o áudio, use: pavucontrol"

cat << "EOF"

  ___         _   _      
 / _ \       | | (_)     
/ /_\ \_ __  | |_ ___  __
|  _  | '__| | __| \ \/ /
| | | | |    | |_| |>  < 
\_| |_/_|     \__|_/_/\_\
                         
EOF

print_info "Instalação finalizada com sucesso!"

exit 0
