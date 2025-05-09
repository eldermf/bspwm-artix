#!/bin/bash
#
# ------------------------------------------------------------------------------
# Título: Script de Instalação Flatpak e Aplicativos
# Descrição: Instala o Flatpak e diversos aplicativos via flatpak no Arch Linux
# Autor: Elder M. Fouraux
# Data: 18/04/2025
# ------------------------------------------------------------------------------

# Definição de cores para melhor visualização
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
SEM_COR='\033[0m'

# Função para exibir mensagens de log
log() {
    local tipo=$1
    local mensagem=$2
    
    case $tipo in
        info) echo -e "[${VERDE}INFO${SEM_COR}] $mensagem" ;;
        aviso) echo -e "[${AMARELO}AVISO${SEM_COR}] $mensagem" ;;
        erro) echo -e "[${VERMELHO}ERRO${SEM_COR}] $mensagem" ;;
    esac
}

# Função para verificar erros após comandos
verificar_erro() {
    if [ $? -ne 0 ]; then
        log erro "Falha ao executar o último comando!"
        exit 1
    fi
}

# Verifica se o script está sendo executado como root
verificar_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log erro "Este script precisa ser executado como root (sudo)!"
        exit 1
    fi
}

# Função para instalar o Flatpak
instalar_flatpak() {
    log info "Instalando o Flatpak..."
    pacman -S --needed --noconfirm flatpak
    verificar_erro
    
    log info "Adicionando o repositório Flathub..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    verificar_erro
}

# Função para instalar aplicativos Flatpak
instalar_aplicativos_flatpak() {
    log info "Instalando aplicativos Flatpak..."
    
    # Lista de aplicativos para instalar
    declare -a aplicativos=(
        "org.kde.kolourpaint"
        "org.inkscape.Inkscape"
        "org.gimp.GIMP"
        "com.wps.Office"
        "org.libreoffice.LibreOffice"        
        "org.telegram.desktop"
        "org.kde.kdenlive"
        "org.qbittorrent.qBittorrent"
        "com.obsproject.Studio"
        "com.vencord.Vesktop"
    )
    
    # Instalar cada aplicativo
    for app in "${aplicativos[@]}"; do
        log info "Instalando $app..."
        flatpak install --assumeyes flathub "$app"
        
        # Verifica se houve erro, mas continua com os próximos aplicativos
        if [ $? -ne 0 ]; then
            log aviso "Falha ao instalar $app. Continuando com os próximos..."
        else
            log info "$app instalado com sucesso!"
        fi
    done
}

# Função principal
main() {
    log info "Iniciando o script de instalação do Flatpak e aplicativos..."
    
    verificar_root
    instalar_flatpak
    instalar_aplicativos_flatpak
    
    log info "Instalação concluída com sucesso!"
    log info "Os seguintes aplicativos foram instalados:"
    log info "- KolourPaint"
    log info "- Inkscape"
    log info "- GIMP"
    log info "- WPS Office"
    log info "- LibreOffice (pt-BR)"
    log info "- Telegram"
    log info "- Kdenlive"
    log info "- qBittorrent"
    log info "- OBS Studio"
    log info "- Vesktop"
    log info "Você pode encontrar estes aplicativos no menu do seu sistema ou executá-los via terminal com o comando 'flatpak run ID-DO-APP'"
}

# Executa o script
main

cat << "EOF"

  ___         _   _      
 / _ \       | | (_)     
/ /_\ \_ __  | |_ ___  __
|  _  | '__| | __| \ \/ /
| | | | |    | |_| |>  < 
\_| |_/_|     \__|_/_/\_\
                         
EOF
