#!/usr/bin/env bash

# wallpaper-selector.sh - Script para selecionar wallpapers usando rofi
# Autor: Claude
# Data: 18/04/2025
# Descrição: Este script usa o rofi para mostrar uma grade de wallpapers
#           e permite selecionar um para definir como plano de fundo usando o feh.

# Definir variáveis
WALLPAPER_DIR="$HOME/Imagens/walls/News"
CACHE_DIR="$HOME/.cache/wallpaper-selector"
CONFIG_DIR="$HOME/.config/wallpaper-selector"
THUMBNAIL_SIZE="200x112"  # Tamanho adequado para o layout 3x2

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
    for dir in "$CACHE_DIR" "$CONFIG_DIR"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
        fi
    done
}

# Criar arquivo de configuração do rofi
create_config_file() {
    cat > "$CONFIG_DIR/config.rasi" << 'EOF'
configuration {
    show-icons: true;
    icon-theme: "Papirus";
    drun-display-format: "{name}";
}

* {
    background:     #00000099;
    background-alt: #111111FF;
    foreground:     #FFFFFFFF;
    selected:       #1F87FFFF;
    active:         #00CCFFFF;
    urgent:         #FF5555FF;
    font:           "Sans 10";
}

window {
    transparency:    "real";
    background-color: @background;
    text-color:       @foreground;
    border-radius:    12px;
    width:            1000px;
    height:           720px;
    location:         center;
    anchor:           center;
}

mainbox {
    background-color: transparent;
    children:         [ "listview" ];
    padding:          12px;
}

listview {
    background-color: transparent;
    dynamic:          true;
    columns:          3;
    lines:            2;
    spacing:          12px;
    cycle:            true;
    layout:           vertical;
    padding:          12px;
}

element {
    background-color: transparent;
    text-color:       @foreground;
    orientation:      vertical;
    border-radius:    8px;
    padding:          8px;
}

element-icon {
    size:             280px;
    border-radius:    8px;
    background-color: @background-alt;
}

element-text {
    horizontal-align: 0.5;
    vertical-align:   0.5;
    margin:           6px 0 0 0;
    background-color: transparent;
    text-color:       inherit;
}

element selected {
    background-color: @selected;
    text-color:       @foreground;
    border-radius:    8px;
}
EOF
    echo "Arquivo de configuração criado em $CONFIG_DIR/config.rasi"
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
    done < "$temp_file" | rofi -dmenu -i -theme "$CONFIG_DIR/config.rasi")
    
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
