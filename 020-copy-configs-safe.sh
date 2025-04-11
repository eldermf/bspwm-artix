#!/bin/bash

# ------------------------------------------------------------------------------
# Safe Config Restore Script with Keyring Setup - Arch Linux
# Copies etc, root, usr as root, home as user, and sets up keyrings
# Author: Elder M. Fouraux		09/04/2025
# ------------------------------------------------------------------------------

# Cores para melhor visualização
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funções para exibição de mensagens
print_header() {
    echo -e "${BLUE}=====================================${NC}"
    echo -e "${GREEN}      CÓPIA DE CONFIGURAÇÕES        ${NC}"
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

# Função para verificar se diretório existe
check_directory() {
    if [ ! -d "$1" ]; then
        print_error "Diretório $1 não encontrado!"
        return 1
    fi
    return 0
}

# Verificar se está rodando como root
if [ "$(id -u)" -ne 0 ]; then
    print_error "Este script precisa ser executado como root para copiar a maioria dos arquivos!"
    exit 1
fi

print_header

# Obter o diretório onde o script está sendo executado
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
print_info "Executando a partir de: $SCRIPT_DIR"

# Verificar se as pastas necessárias existem no diretório atual
for dir in etc root usr home; do
    if ! check_directory "$SCRIPT_DIR/$dir"; then
        print_error "Pasta $dir não encontrada no diretório atual!"
        exit 1
    fi
done

# Perguntar sobre o destino dos arquivos
print_step "Configurando diretório de destino"

read -p "Você está copiando para um sistema montado (ex: /mnt)? (s/n): " is_mounted
if [[ "$is_mounted" == "s" || "$is_mounted" == "S" ]]; then
    read -p "Digite o ponto de montagem do novo sistema (ex: /mnt): " DEST_ROOT
    if [ -z "$DEST_ROOT" ]; then
        print_error "Ponto de montagem não pode ser vazio!"
        exit 1
    fi
    if ! check_directory "$DEST_ROOT"; then
        exit 1
    fi
else
    # Se não for para sistema montado, usamos / como destino
    DEST_ROOT=""
    print_info "Os arquivos serão copiados para o sistema atual."
fi

# Verificar usuário atual para copiar /home
current_user=$(logname 2>/dev/null || echo "$SUDO_USER" || echo "$USER")
print_info "O usuário atual do sistema é: $current_user"

# Iniciar processo de cópia
print_step "Iniciando processo de cópia"

# 1. Copiar /etc (como root)
print_step "Copiando diretório /etc"
cp -a "$SCRIPT_DIR/etc/." "${DEST_ROOT}/etc/"
if [ $? -ne 0 ]; then
    print_error "Falha ao copiar diretório /etc!"
else
    print_success "Diretório /etc copiado com sucesso!"
fi

# 2. Copiar /root (como root)
print_step "Copiando diretório /root"
cp -a "$SCRIPT_DIR/root/." "${DEST_ROOT}/root/"
if [ $? -ne 0 ]; then
    print_error "Falha ao copiar diretório /root!"
else
    print_success "Diretório /root copiado com sucesso!"
fi

# 3. Copiar /usr (como root)
print_step "Copiando diretório /usr"
cp -a "$SCRIPT_DIR/usr/." "${DEST_ROOT}/usr/"
if [ $? -ne 0 ]; then
    print_error "Falha ao copiar diretório /usr!"
else
    print_success "Diretório /usr copiado com sucesso!"
fi

# 4. Criar script temporário para copiar /home com permissões corretas
print_step "Preparando para copiar diretório /home"

# Listar usuários disponíveis na pasta home de origem
print_info "Usuários disponíveis na pasta home de origem:"
ls -l "$SCRIPT_DIR/home" | grep '^d' | awk '{print $NF}'

# Perguntar qual usuário migrar
read -p "Digite o nome do usuário que deseja copiar (deixe em branco para copiar todos): " selected_user

# Criar um script temporário que será executado como usuário normal
TMP_SCRIPT=$(mktemp)
cat > "$TMP_SCRIPT" << EOF
#!/bin/bash
# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "\${BLUE}[i] Iniciando cópia da pasta home como usuário normal\${NC}"

# Copiar diretório home
if [ ! -d "$SCRIPT_DIR/home" ]; then
    echo -e "\${RED}[✗] Diretório home de origem não encontrado!\${NC}"
    exit 1
fi

# Garantir que o diretório de destino existe
mkdir -p "${DEST_ROOT}/home"

# Copiar os arquivos
copy_status=0
if [ -z "$selected_user" ]; then
    # Copiar todos os usuários
    for user_dir in "$SCRIPT_DIR/home"/*; do
        if [ -d "\$user_dir" ]; then
            user_name=\$(basename "\$user_dir")
            echo -e "\${BLUE}[i] Copiando home do usuário: \$user_name\${NC}"
            mkdir -p "${DEST_ROOT}/home/\$user_name"
            cp -a "\$user_dir/." "${DEST_ROOT}/home/\$user_name/" || copy_status=1
        fi
    done
else
    # Copiar apenas o usuário selecionado
    echo -e "\${BLUE}[i] Copiando home do usuário: $selected_user\${NC}"
    if [ -d "$SCRIPT_DIR/home/$selected_user" ]; then
        mkdir -p "${DEST_ROOT}/home/$selected_user"
        cp -a "$SCRIPT_DIR/home/$selected_user/." "${DEST_ROOT}/home/$selected_user/" || copy_status=1
    else
        echo -e "\${RED}[✗] Diretório home para $selected_user não encontrado!\${NC}"
        copy_status=1
    fi
fi

if [ \$copy_status -eq 0 ]; then
    echo -e "\${GREEN}[✓] Diretório /home copiado com sucesso!\${NC}"
else
    echo -e "\${RED}[✗] Houve erros ao copiar o diretório /home!\${NC}"
fi

exit \$copy_status
EOF

chmod +x "$TMP_SCRIPT"

# Executar o script como usuário normal
if [ "$current_user" != "root" ]; then
    print_info "Executando como usuário $current_user para copiar /home"
    su - "$current_user" -c "$TMP_SCRIPT"
    home_status=$?
else
    # Se estamos rodando diretamente como root (sem sudo), tentar encontrar um usuário não-root
    print_info "Tentando encontrar um usuário não-root para copiar /home"
    non_root_user=$(grep -E "^[^:]+:[^:]+:[0-9]{4}:" /etc/passwd | head -1 | cut -d: -f1)
    
    if [ -n "$non_root_user" ]; then
        print_info "Usando usuário $non_root_user para copiar /home"
        su - "$non_root_user" -c "$TMP_SCRIPT"
        home_status=$?
    else
        print_warning "Não foi possível encontrar um usuário não-root. Copiando /home como root (não recomendado)"
        bash "$TMP_SCRIPT"
        home_status=$?
    fi
fi

# Limpar script temporário
rm -f "$TMP_SCRIPT"

if [ $home_status -eq 0 ]; then
    print_success "Diretório /home copiado com sucesso!"
else
    print_error "Falha ao copiar diretório /home!"
fi

# Corrigir permissões no diretório home
print_step "Corrigindo permissões em /home"

# Listar usuários em /home
for user_dir in "${DEST_ROOT}/home"/*; do
    if [ -d "$user_dir" ]; then
        user_name=$(basename "$user_dir")
        if id "$user_name" &>/dev/null; then
            user_uid=$(id -u "$user_name")
            user_gid=$(id -g "$user_name")
            print_info "Ajustando permissões para $user_name (UID:$user_uid, GID:$user_gid)"
            chown -R "${user_uid}:${user_gid}" "$user_dir"
        else
            print_info "Usuário $user_name não existe no sistema. As permissões podem precisar de ajustes manuais."
        fi
    fi
done

# Sumário da execução
print_step "Sumário da cópia"
print_info "Os seguintes diretórios foram copiados:"
print_info "- $SCRIPT_DIR/etc → ${DEST_ROOT}/etc"
print_info "- $SCRIPT_DIR/root → ${DEST_ROOT}/root"
print_info "- $SCRIPT_DIR/usr → ${DEST_ROOT}/usr"
print_info "- $SCRIPT_DIR/home → ${DEST_ROOT}/home"

cat << "EOF"

  ___         _   _      
 / _ \       | | (_)     
/ /_\ \_ __  | |_ ___  __
|  _  | '__| | __| \ \/ /
| | | | |    | |_| |>  < 
\_| |_/_|     \__|_/_/\_\
                         
EOF

print_success "Cópia de configurações finalizada!"

exit 0
