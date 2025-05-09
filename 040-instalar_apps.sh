#!/bin/bash
#
# ------------------------------------------------------------------------------
# Título: Script de Instalação de Aplicativos para Arch Linux
# Descrição: Instala múltiplos pacotes via yay e pacman no Arch Linux
# Autor: Elder M. Fouraux		
# Data: 20/04/2025
# ------------------------------------------------------------------------------

# Definição de cores para melhor visualização
VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
AZUL='\033[0;34m'
SEM_COR='\033[0m'

# Função para exibir mensagens de log
log() {
    local tipo=$1
    local mensagem=$2
    
    case $tipo in
        info) echo -e "[${VERDE}INFO${SEM_COR}] $mensagem" ;;
        aviso) echo -e "[${AMARELO}AVISO${SEM_COR}] $mensagem" ;;
        erro) echo -e "[${VERMELHO}ERRO${SEM_COR}] $mensagem" ;;
        secao) echo -e "\n[${AZUL}${mensagem}${SEM_COR}]" ;;
    esac
}

# Função para verificar se um comando existe
verificar_comando() {
    command -v "$1" >/dev/null 2>&1
}

# Função para verificar se o yay está instalado
verificar_yay() {
    if ! verificar_comando yay; then
        log aviso "O yay não está instalado no sistema"
        log info "Instalando o yay..."
        
        # Verificar se o git está instalado
        if ! verificar_comando git; then
            log info "Instalando git..."
            sudo pacman -S --needed --noconfirm git
            if [ $? -ne 0 ]; then
                log erro "Falha ao instalar o git. Abortando..."
                exit 1
            fi
        fi
        
        # Clonar e instalar o yay
        temp_dir=$(mktemp -d)
        git clone https://aur.archlinux.org/yay.git "$temp_dir"
        if [ $? -ne 0 ]; then
            log erro "Falha ao clonar o repositório do yay. Abortando..."
            rm -rf "$temp_dir"
            exit 1
        fi
        
        cd "$temp_dir" || exit 1
        makepkg -si --noconfirm
        if [ $? -ne 0 ]; then
            log erro "Falha ao compilar e instalar o yay. Abortando..."
            cd - >/dev/null
            rm -rf "$temp_dir"
            exit 1
        fi
        
        cd - >/dev/null
        rm -rf "$temp_dir"
        log info "yay instalado com sucesso!"
    fi
}

# Função para instalar pacotes com o yay
instalar_pacotes_yay() {
    log secao "INSTALANDO PACOTES VIA YAY"
    
    # Lista de pacotes para instalar com yay
    declare -a pacotes_yay=(
        "qt6-5compat"
        "bash-pipes"
        "visual-studio-code-bin"
    )
    
    # Instalar cada pacote
    for pacote in "${pacotes_yay[@]}"; do
        log info "Instalando $pacote..."
        yay -S --needed --noconfirm "$pacote"
        
        # Verifica se houve erro, mas continua com os próximos pacotes
        if [ $? -ne 0 ]; then
            log aviso "Falha ao instalar $pacote. Continuando com os próximos..."
        else
            log info "$pacote instalado com sucesso!"
        fi
    done
}

# Função para instalar pacotes com o pacman
instalar_pacotes_pacman() {
    log secao "INSTALANDO PACOTES VIA PACMAN"
    
    # Lista de pacotes para instalar com pacman
    declare -a pacotes_pacman=(
        "eza"
        "yad"
        "numlockx"
        "man-pages-pt_br"
        "v4l-utils"
        "lib32-v4l-utils"
        "cmatrix"
        "mpc"
        "mpd"
        "ncmpcpp"
        "htop"
        "cava"
        "meld"
        "mpv"
        "gdb"
        "ffmpeg"
        "gst-plugins-bad"
        "gst-plugins-good"
        "gst-plugins-ugly"
        "gst-plugins-base"
        "xfce4-appfinder"
        "viewnior"
        "flameshot"
        "atril"
        "java-runtime"
        "java-environment"
    )
    
    # Atualizar o sistema primeiro
    log info "Atualizando as listas de pacotes..."
    sudo pacman -Sy
    if [ $? -ne 0 ]; then
        log aviso "Falha ao atualizar as listas de pacotes. Tentando continuar..."
    fi
    
    # Instalar cada pacote
    for pacote in "${pacotes_pacman[@]}"; do
        log info "Instalando $pacote..."
        sudo pacman -S --needed --noconfirm "$pacote"
        
        # Verifica se houve erro, mas continua com os próximos pacotes
        if [ $? -ne 0 ]; then
            log aviso "Falha ao instalar $pacote. Continuando com os próximos..."
        else
            log info "$pacote instalado com sucesso!"
        fi
    done
}

# Função para verificar espaço em disco antes da instalação
verificar_espaco_disco() {
    log info "Verificando espaço em disco disponível..."
    
    # Verificar espaço livre em /
    espaco_livre=$(df -h / | awk 'NR==2 {print $4}')
    log info "Espaço livre em /: $espaco_livre"
    
    # Verificar se o espaço é menor que 2GB (aproximadamente)
    espaco_bytes=$(df / | awk 'NR==2 {print $4}')
    if [ "$espaco_bytes" -lt 2000000 ]; then
        log aviso "Você tem pouco espaço em disco. A instalação pode falhar."
        read -p "Deseja continuar mesmo assim? (s/n): " resposta
        if [[ "$resposta" != "s" && "$resposta" != "S" ]]; then
            log info "Instalação cancelada pelo usuário."
            exit 0
        fi
    fi
}

# Função para exibir resumo final
exibir_resumo() {
    log secao "INSTALAÇÃO CONCLUÍDA"
    log info "Os seguintes programas foram instalados:"
    
    log info "Via yay:"
    log info "- qt6-5compat"
    log info "- bash-pipes"
    log info "- visual-studio-code-bin"
    
    log info "Via pacman:"
    log info "- eza, yad, numlockx, man-pages-pt_br"
    log info "- v4l-utils, lib32-v4l-utils, cmatrix"
    log info "- mpc, mpd, ncmpcpp, htop, cava, meld"
    log info "- mpv, ffmpeg"
    log info "- gst-plugins-bad, gst-plugins-good, gst-plugins-ugly, gst-plugins-base"
    log info "- xfce4-appfinder, viewnior, flameshot, atril"
    log info "- java-runtime, java-environment"
}

# Função principal
main() {
    log secao "INICIANDO INSTALAÇÃO DE APLICATIVOS"
    
    # Verificar espaço em disco
    verificar_espaco_disco
    
    # Verificar e instalar yay se necessário
    verificar_yay
    
    # Instalar pacotes
    instalar_pacotes_yay
    instalar_pacotes_pacman
    
    # Exibir resumo
    exibir_resumo
    
    log info "Script de instalação concluído com sucesso!"
}

# Executa o script
main

cat << "EOF"

  ___         _    
 / _ \       | |   
/ /_\ \_ _ __| |__ 
|  _  | '_/ _` '_/ 
| | | | | \__,| |  
\_| |_|_| |___|_|  
                   
EOF
