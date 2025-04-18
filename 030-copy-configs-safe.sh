#!/bin/bash

# ------------------------------------------------------------------------------
# Safe Config Restore Script with Keyring Setup - Arch Linux
# Copies etc, root, usr as root, home as user, and sets up keyrings
# Author: Elder M. Fouraux		09/04/2025
# ------------------------------------------------------------------------------

# Verifica se o script está sendo executado como usuário comum
if [ "$(id -u)" -eq 0 ]; then
  echo "Por favor, execute este script como usuário comum."
  exit 1
fi

# Define as variáveis de origem e destino
HOME_SRC="./home"
ETC_SRC="./etc"
ROOT_SRC="./root"
USR_SRC="./usr"

HOME_DEST="/home/$USER"
ETC_DEST="/etc"
ROOT_DEST="/root"
USR_DEST="/usr"

# Função para copiar diretórios com permissões de usuário comum
copy_user() {
  local src=$1
  local dest=$2
  cp -r "$src/." "$dest"
  echo "Copiado $src para $dest"
}

# Função para copiar diretórios com permissões de superusuário
copy_root() {
  local src=$1
  local dest=$2
  sudo cp -r "$src/." "$dest"
  echo "Copiado $src para $dest com sudo"
}

# Copia o conteúdo da pasta home
copy_user "$HOME_SRC" "$HOME_DEST"

# Copia o conteúdo das pastas etc, root e usr com sudo
copy_root "$ETC_SRC" "$ETC_DEST"
copy_root "$ROOT_SRC" "$ROOT_DEST"
copy_root "$USR_SRC" "$USR_DEST"

echo "Cópias concluídas com sucesso!"


cat << "EOF"

  ___         _   _      
 / _ \       | | (_)     
/ /_\ \_ __  | |_ ___  __
|  _  | '__| | __| \ \/ /
| | | | |    | |_| |>  < 
\_| |_/_|     \__|_/_/\_\
                         
EOF

exit 0
