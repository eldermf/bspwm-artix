#!/bin/bash

# Script para configurar pacman.conf e mirrors do Arch Linux no Artix
# Autor: Script criado com base nos requisitos solicitados

# Cores para melhor visualização
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções para exibição de mensagens
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

# 1. Baixar o arquivo pacman.conf do GitHub
print_step "Baixando o arquivo pacman.conf do GitHub"
wget -c -O /tmp/pacman.conf "https://raw.githubusercontent.com/eldermf/bspwm-artix/master/etc/pacman.conf"

if [ $? -ne 0 ]; then
    print_error "Falha ao baixar o arquivo pacman.conf!"
    exit 1
fi
print_success "Arquivo pacman.conf baixado com sucesso!"

# 2. Fazer backup do pacman.conf original e substituir pelo novo
print_step "Fazendo backup do pacman.conf original e substituindo pelo novo"
if [ -f "/etc/pacman.conf" ]; then
    cp /etc/pacman.conf /etc/pacman.conf-old
    print_info "Backup do pacman.conf original criado como /etc/pacman.conf-old"
else
    print_error "Arquivo /etc/pacman.conf não encontrado no sistema!"
    exit 1
fi

# Substituir o arquivo original pelo novo
cp /tmp/pacman.conf /etc/pacman.conf
if [ $? -ne 0 ]; then
    print_error "Falha ao substituir o arquivo pacman.conf!"
    exit 1
fi
print_success "Arquivo pacman.conf substituído com sucesso!"

# 3. Baixar mirrors do Arch Linux
print_step "Baixando mirrors do Arch Linux"
mkdir -p /etc/pacman.d
wget -c -O /etc/pacman.d/mirrorlist-arch "https://archlinux.org/mirrorlist/?country=US&country=GB&protocol=http&protocol=https&ip_version=4&use_mirror_status=on"

if [ $? -ne 0 ]; then
    print_error "Falha ao baixar os mirrors do Arch Linux!"
    exit 1
fi
print_success "Mirrors do Arch Linux baixados com sucesso!"

# 3.1. Remover todos os # dos Servers no arquivo de mirrors
print_step "Descomentando os servidores no arquivo de mirrors"
sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist-arch
print_success "Servidores descomentados com sucesso!"

# 4. Instalar o archlinux-keyring e atualizar as chaves
print_step "Instalando archlinux-keyring e atualizando chaves"
pacman -Sy --noconfirm
pacman -S --noconfirm archlinux-keyring

if [ $? -ne 0 ]; then
    print_error "Falha ao instalar o archlinux-keyring!"
    exit 1
fi

# Atualizar as chaves
print_info "Atualizando chaves do pacman"
pacman-key --init
pacman-key --populate archlinux
pacman-key --refresh-keys

print_success "Instalação do archlinux-keyring e atualização de chaves concluídas!"

# Finalização do script
print_step "Configuração concluída"
print_info "O pacman foi configurado para usar os repositórios do Arch Linux."
print_info "Backup do arquivo original está em /etc/pacman.conf-old"
print_info "Novas configurações aplicadas com sucesso!"

cat << "EOF"

  ___         _   _      
 / _ \       | | (_)     
/ /_\ \_ __  | |_ ___  __
|  _  | '__| | __| \ \/ /
| | | | |    | |_| |>  < 
\_| |_/_|     \__|_/_/\_\
                         
EOF

exit 0
