#!/bin/bash

# Script para rodar Ansible via Docker (compatível com Git Bash no Windows)

echo "🚀 Executando Ansible Playbook"
echo ""

# Verificar se vault.yml existe
if [ ! -f "group_vars/all/vault.yml" ]; then
    echo "❌ Arquivo group_vars/all/vault.yml não encontrado!"
    exit 1
fi

echo "✓ vault.yml encontrado"
echo ""

# Converter path do Git Bash para formato Windows
# /c/path/to/dir -> C:/path/to/dir
CURRENT_DIR="$(pwd | sed 's|^/\([a-z]\)/|\U\1:/|')"
SSH_DIR="$HOME/.ssh"
SSH_DIR_WIN="$(echo "$SSH_DIR" | sed 's|^/\([a-z]\)/|\U\1:/|')"

echo "📂 Diretório: $CURRENT_DIR"
echo ""
echo "Executando playbook..."
echo ""

# Desabilitar conversão de path do Git Bash
export MSYS_NO_PATHCONV=1

# Rodar com paths do Windows
# Corrigir permissões da chave SSH dentro do container e executar playbook
docker run --rm -it \
    -v "$CURRENT_DIR:/ansible" \
    -v "$SSH_DIR_WIN:/root/.ssh-mount:ro" \
    -w /ansible \
    -e ANSIBLE_HOST_KEY_CHECKING=False \
    willhallonline/ansible:alpine \
    sh -c "mkdir -p /root/.ssh && cp -r /root/.ssh-mount/* /root/.ssh/ && chmod 600 /root/.ssh/* && chmod 700 /root/.ssh && ansible-playbook -i inventory.ini playbook.yml"

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "✅ Playbook executado com sucesso!"
else
    echo ""
    echo "❌ Erro ao executar playbook (exit code: $EXIT_CODE)"
    exit $EXIT_CODE
fi
