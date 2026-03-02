# Scripts Auxiliares

Esta pasta contém scripts auxiliares para troubleshooting e manutenção do ambiente Foundry VTT.

## 📁 Estrutura

```
scripts/
└── utils/          # Scripts de diagnóstico e troubleshooting
```

## 🔧 Scripts Disponíveis

### `utils/diagnostico.sh`
Script de diagnóstico completo para verificar o status do Foundry VTT na VM.

**Uso:**
```bash
ssh -i ~/.ssh/foundry_azure foundry-admin@20.206.93.55 "bash /tmp/diagnostico.sh"
```

**Verifica:**
- Status do container Docker
- Logs do Foundry VTT
- Portas em uso
- Status do firewall (UFW)
- Conectividade local

---

### `utils/fix-permissions.sh`
Corrige permissões do Azure File Share para permitir escrita pelo container Docker.

**Uso:**
```bash
cd /c/code/pessoal/vtt/ansible
bash scripts/utils/fix-permissions.sh
```

**Ações:**
- Para o container Foundry VTT
- Desmonta o Azure File Share
- Remonta com `uid=1000,gid=1000`
- Reinicia o container

---

### `utils/verificar-foundry.sh`
Verifica a instalação do Foundry VTT e tenta subir o container manualmente.

**Uso:**
```bash
cd /c/code/pessoal/vtt/ansible
bash scripts/utils/verificar-foundry.sh
```

**Verifica:**
- Se `docker-compose.yml` existe
- Conteúdo da configuração
- Mount do Azure File Share
- Sobe o container manualmente
- Exibe logs de erro

---

### `utils/run-diagnostico.sh`
Script wrapper que copia e executa o `diagnostico.sh` na VM remota.

**Uso:**
```bash
cd /c/code/pessoal/vtt/ansible
bash scripts/utils/run-diagnostico.sh
```

---

## 📝 Notas

- Estes scripts são para **troubleshooting apenas**
- Para operações normais, use os scripts na raiz:
  - `run-ansible.sh` (Linux/Git Bash)
  - `run-playbook.ps1` (PowerShell)
- Todos os scripts assumem que você está usando a chave SSH `~/.ssh/foundry_azure`
