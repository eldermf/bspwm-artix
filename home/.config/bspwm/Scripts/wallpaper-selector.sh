#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Título: Script para selecionar wallpapers usando rofi 
# Descrição: Este script usa o rofi para mostrar uma grade de wallpapers
#            e permite selecionar um para definir como plano de fundo usando o feh.
# Autor: Elder M. Fouraux
# Data: 18/04/2025
# ------------------------------------------------------------------------------

# Definir variáveis
WALLPAPER_DIR="$HOME/Imagens/walls/News"
CACHE_DIR="$HOME/.cache/wallpaper-selector"
THUMBNAIL_SIZE="300x200"  # Tamanho adequado para o layout 3x2

# Verificar dependências
check_dependencies() {
    for cmd in rofi feh convert; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Erro: $cmd não está instalado. Por favor, instale-o e tente novamente."
            exit 1
        fi
    done
}

# Criar diretórios necessários
create_directories() {
    for dir in "$CACHE_DIR"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
        fi
    done
}


# Gerar miniaturas para as imagens
generate_thumbnails() {
    echo "Gerando miniaturas..."
    
    find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) | while read -r img; do
        filename=$(basename "$img")
        thumbnail="$CACHE_DIR/${filename%.*}.png"
        
        # Só gera miniaturas se elas não existirem ou se a imagem original for mais nova
        if [ ! -f "$thumbnail" ] || [ "$img" -nt "$thumbnail" ]; then
            convert "$img" -thumbnail "$THUMBNAIL_SIZE" -background none -gravity center -extent "$THUMBNAIL_SIZE" "$thumbnail"
        fi
    done
}

# Função para criar o menu do rofi com miniaturas
create_rofi_menu() {
    local temp_file=$(mktemp)
    
    # Encontrar todas as imagens e ordená-las
    find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) | sort > "$temp_file"
    
    # Usar o rofi com o arquivo de configuração
    local selected_wallpaper
    selected_wallpaper=$(while read -r img; do
        filename=$(basename "$img")
        thumbnail="$CACHE_DIR/${filename%.*}.png"
        echo -en "$img\0icon\x1f$thumbnail\n"
    done < "$temp_file" | rofi -dmenu -i -theme "$HOME/.config/bspwm/Scripts/config.rasi")
    
    # Limpar arquivos temporários
    rm "$temp_file"
    
    echo "$selected_wallpaper"
}

# Definir o wallpaper usando feh
set_wallpaper() {
    local selected_wallpaper="$1"
    
    if [ -n "$selected_wallpaper" ] && [ -f "$selected_wallpaper" ]; then
        echo "Definindo wallpaper: $selected_wallpaper"
        feh --bg-fill "$selected_wallpaper"
        
        # Salvar a seleção para reuso posterior
        echo "$selected_wallpaper" > "$HOME/.cache/current_wallpaper"
        
        # Notificação (se disponível)
        if command -v notify-send &> /dev/null; then
            notify-send -i "$selected_wallpaper" "Wallpaper Alterado" "$(basename "$selected_wallpaper")"
        fi
        return 0
    else
        echo "Nenhum wallpaper selecionado ou arquivo inválido."
        return 1
    fi
}

# Função principal
main() {
    check_dependencies
    create_directories
    create_config_file
    generate_thumbnails
    
    # Selecionar wallpaper e aplicá-lo
    selected_wallpaper=$(create_rofi_menu)
    
    if [ -n "$selected_wallpaper" ]; then
        set_wallpaper "$selected_wallpaper"
    fi
}

# Executar função principal
main
