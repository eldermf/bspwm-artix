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

# Obter o diretório onde o script está sendo executado
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Verificar se estamos executando como root
IS_ROOT=0
if [ "$(id -u)" -eq 0 ]; then
    IS_ROOT=1
    print_error "Este script deve ser iniciado como usuário comum, não como root!"
    print_info "Por favor, execute o script novamente como usuário comum."
    exit 1
fi

print_header

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

# Obter o nome de usuário atual
current_user=$(whoami)
print_info "Executando como usuário: $current_user"

# Fase 1: Copiar /home como usuário normal
print_step "Iniciando cópia do diretório /home como usuário normal"

# Listar usuários disponíveis na pasta home de origem
print_info "Usuários disponíveis na pasta home de origem:"
ls -l "$SCRIPT_DIR/home" | grep '^d' | awk '{print $NF}'

# Perguntar qual usuário migrar
read -p "Digite o nome do usuário que deseja copiar (deixe em branco para copiar todos): " selected_user

# Verificar se a pasta de destino existe e criar se necessário
if [ ! -d "${DEST_ROOT}/home" ]; then
    print_info "Criando diretório ${DEST_ROOT}/home"
    mkdir -p "${DEST_ROOT}/home" || {
        print_error "Não foi possível criar o diretório ${DEST_ROOT}/home. Pode ser necessário executar com sudo."
        exit 1
    }
fi

# Copiar arquivos /home
home_status=0
if [ -z "$selected_user" ]; then
    # Copiar todos os usuários
    for user_dir in "$SCRIPT_DIR/home"/*; do
        if [ -d "$user_dir" ]; then
            user_name=$(basename "$user_dir")
            print_info "Copiando home do usuário: $user_name"
            
            # Garantir que o diretório de destino existe
            if [ ! -d "${DEST_ROOT}/home/$user_name" ]; then
                mkdir -p "${DEST_ROOT}/home/$user_name" || {
                    print_error "Não foi possível criar ${DEST_ROOT}/home/$user_name"
                    home_status=1
                    continue
                }
            fi
            
            # Copiar os arquivos
            cp -a "$user_dir/." "${DEST_ROOT}/home/$user_name/" || {
                print_error "Falha ao copiar arquivos para ${DEST_ROOT}/home/$user_name"
                home_status=1
            }
        fi
    done
else
    # Copiar apenas o usuário selecionado
    print_info "Copiando home do usuário: $selected_user"
    if [ -d "$SCRIPT_DIR/home/$selected_user" ]; then
        # Garantir que o diretório de destino existe
        if [ ! -d "${DEST_ROOT}/home/$selected_user" ]; then
            mkdir -p "${DEST_ROOT}/home/$selected_user" || {
                print_error "Não foi possível criar ${DEST_ROOT}/home/$selected_user"
                home_status=1
            }
        fi
        
        # Copiar os arquivos
        cp -a "$SCRIPT_DIR/home/$selected_user/." "${DEST_ROOT}/home/$selected_user/" || {
            print_error "Falha ao copiar arquivos para ${DEST_ROOT}/home/$selected_user"
            home_status=1
        }
    else
        print_error "Diretório home para $selected_user não encontrado!"
        home_status=1
    fi
fi

if [ $home_status -eq 0 ]; then
    print_success "Diretório /home copiado com sucesso como usuário normal!"
else
    print_error "Houve problemas ao copiar o diretório /home"
    print_info "Verifique as permissões e tente novamente"
fi

# Fase 2: Elevar privilégios para copiar o restante dos diretórios
print_step "Precisamos de privilégios de administrador para copiar os diretórios de sistema"
print_info "Solicitando elevação de privilégios via sudo..."

# Criar um script temporário para executar como root
TMP_SCRIPT=$(mktemp)
cat > "$TMP_SCRIPT" << EOF
#!/bin/bash

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "\${BLUE}=====================================${NC}"
echo -e "\${GREEN}  COPIANDO DIRETÓRIOS DE SISTEMA    ${NC}"
echo -e "\${BLUE}=====================================${NC}"

# 1. Copiar /etc (como root)
echo -e "\${YELLOW}[*] Copiando diretório /etc${NC}"
cp -a "$SCRIPT_DIR/etc/." "${DEST_ROOT}/etc/"
if [ \$? -ne 0 ]; then
    echo -e "\${RED}[✗] Falha ao copiar diretório /etc!${NC}"
    etc_status=1
else
    echo -e "\${GREEN}[✓] Diretório /etc copiado com sucesso!${NC}"
    etc_status=0
fi

# 2. Copiar /root (como root)
echo -e "\${YELLOW}[*] Copiando diretório /root${NC}"
cp -a "$SCRIPT_DIR/root/." "${DEST_ROOT}/root/"
if [ \$? -ne 0 ]; then
    echo -e "\${RED}[✗] Falha ao copiar diretório /root!${NC}"
    root_status=1
else
    echo -e "\${GREEN}[✓] Diretório /root copiado com sucesso!${NC}"
    root_status=0
fi

# 3. Copiar /usr (como root)
echo -e "\${YELLOW}[*] Copiando diretório /usr${NC}"
cp -a "$SCRIPT_DIR/usr/." "${DEST_ROOT}/usr/"
if [ \$? -ne 0 ]; then
    echo -e "\${RED}[✗] Falha ao copiar diretório /usr!${NC}"
    usr_status=1
else
    echo -e "\${GREEN}[✓] Diretório /usr copiado com sucesso!${NC}"
    usr_status=0
fi

# Corrigir permissões no diretório home
echo -e "\${YELLOW}[*] Corrigindo permissões em /home${NC}"

# Listar usuários em /home
for user_dir in "${DEST_ROOT}/home"/*; do
    if [ -d "\$user_dir" ]; then
        user_name=\$(basename "\$user_dir")
        if id "\$user_name" &>/dev/null; then
            user_uid=\$(id -u "\$user_name")
            user_gid=\$(id -g "\$user_name")
            echo -e "\${BLUE}[i] Ajustando permissões para \$user_name (UID:\$user_uid, GID:\$user_gid)${NC}"
            chown -R "\${user_uid}:\${user_gid}" "\$user_dir"
        else
            echo -e "\${BLUE}[i] Usuário \$user_name não existe no sistema. As permissões podem precisar de ajustes manuais.${NC}"
        fi
    fi
done

# Sumário da execução
echo -e "\${YELLOW}[*] Sumário da cópia${NC}"
echo -e "\${BLUE}[i] Os seguintes diretórios foram copiados:${NC}"
echo -e "\${BLUE}[i] - $SCRIPT_DIR/etc → ${DEST_ROOT}/etc${NC}"
echo -e "\${BLUE}[i] - $SCRIPT_DIR/root → ${DEST_ROOT}/root${NC}"
echo -e "\${BLUE}[i] - $SCRIPT_DIR/usr → ${DEST_ROOT}/usr${NC}"
echo -e "\${BLUE}[i] - $SCRIPT_DIR/home → ${DEST_ROOT}/home${NC}"

# Status geral
if [ \$etc_status -eq 0 ] && [ \$root_status -eq 0 ] && [ \$usr_status -eq 0 ]; then
    echo -e "\${GREEN}[✓] Cópia de configurações do sistema finalizada com sucesso!${NC}"
    exit 0
else
    echo -e "\${RED}[✗] Houve erros durante a cópia de alguns diretórios.${NC}"
    exit 1
fi
EOF

chmod +x "$TMP_SCRIPT"

# Executar o script com sudo para elevação de privilégios
print_info "Executando com privilégios elevados para copiar diretórios de sistema..."
sudo bash "$TMP_SCRIPT"
super_status=$?

# Limpar script temporário
rm -f "$TMP_SCRIPT"

if [ $super_status -eq 0 ]; then
    print_success "Processo completo! Todos os arquivos foram copiados com sucesso."
else
    print_error "Houve erros durante a cópia dos diretórios de sistema."
    print_info "Por favor, verifique as mensagens acima para mais detalhes."
    exit 1
fi

cat << "EOF"

  ___         _   _      
 / _ \       | | (_)     
/ /_\ \_ __  | |_ ___  __
|  _  | '__| | __| \ \/ /
| | | | |    | |_| |>  < 
\_| |_/_|     \__|_/_/\_\
                         
EOF

exit 0
