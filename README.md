# Foundry VTT Infrastructure on Azure

Infraestrutura completa como código (IaC) para hospedar [Foundry VTT](https://foundryvtt.com) no Azure, usando Terraform e Ansible.

## Arquitetura

```
┌─────────────────────────────────────────────────────────┐
│                    Azure (Brazil South)                  │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │ Resource Group: foundry-rg                         │ │
│  │                                                    │ │
│  │  ┌──────────────────────────────────────────────┐ │ │
│  │  │ VNET: 10.0.0.0/16                            │ │ │
│  │  │  ┌────────────────────────────────────────┐  │ │ │
│  │  │  │ Subnet: 10.0.1.0/24                    │  │ │ │
│  │  │  │                                        │  │ │ │
│  │  │  │  ┌──────────────────────────────────┐ │  │ │ │
│  │  │  │  │ VM: Standard_B2s (Ubuntu 22.04) │ │  │ │ │
│  │  │  │  │  - Docker + Foundry VTT         │ │  │ │ │
│  │  │  │  │  - NSG: 22, 80, 443, 30000      │ │  │ │ │
│  │  │  │  └──────────────────────────────────┘ │  │ │ │
│  │  │  └────────────────────────────────────────┘  │ │ │
│  │  │                                              │ │ │
│  │  │  Public IP: XX.XX.XX.XX (Static)             │ │ │
│  │  └──────────────────────────────────────────────┘ │ │
│  │                                                    │ │
│  │  Storage Account: foundryst                       │ │
│  │    └─ File Share: foundrydata (50GB)              │ │
│  │       └─ Mounted at: /opt/foundrydata             │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## Pré-requisitos

### Ferramentas Locais
- [Terraform](https://www.terraform.io/downloads) >= 1.6.0
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) >= 2.15
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (para autenticação)
- SSH key pair

### Azure
- Assinatura Azure ativa
- Permissões para criar recursos (Contributor role)
- Storage Account para tfstate (criado no bootstrap)

## Estrutura do Projeto

```
vtt/
├── terraform/               # Infraestrutura como código
│   ├── providers.tf         # Provider Azure
│   ├── backend.tf           # Backend remoto
│   ├── backend.conf         # Configuração do backend (gitignored)
│   ├── variables.tf         # Variáveis
│   ├── main.tf              # Recursos principais
│   ├── outputs.tf           # Outputs
│   ├── terraform.tfvars     # Valores das variáveis (gitignored)
│   ├── .envrc               # Variáveis de ambiente (gitignored)
│   └── scripts/
│       ├── setup/           # Scripts de inicialização
│       │   ├── init-backend.sh
│       │   ├── init-backend.ps1
│       │   ├── setup-ssh-key.sh
│       │   ├── verify-credentials.sh
│       │   └── verify-credentials.ps1
│       └── README.md
│
├── ansible/                 # Configuração e deploy
│   ├── ansible.cfg          # Config do Ansible
│   ├── playbook.yml         # Playbook principal
│   ├── inventory.ini        # Gerado pelo Terraform (gitignored)
│   ├── run-ansible.sh       # Script principal (Git Bash/Linux)
│   ├── run-playbook.ps1     # Script principal (PowerShell)
│   ├── group_vars/
│   │   └── all/
│   │       └── vault.yml    # Secrets (gitignored)
│   ├── templates/
│   │   └── docker-compose.yml.j2
│   └── scripts/
│       ├── utils/           # Scripts de troubleshooting
│       │   ├── diagnostico.sh
│       │   ├── fix-permissions.sh
│       │   ├── run-diagnostico.sh
│       │   └── verificar-foundry.sh
│       └── README.md
│
├── .gitignore
├── README.md
└── SETUP.md                 # Guia de setup detalhado
```

## Setup Inicial

### 1. Bootstrap do Backend Remoto

**IMPORTANTE**: O Resource Group `foundry-rg` deve ser criado manualmente para melhor controle de permissões. O Terraform irá usar este RG existente (via data source).

Criar Resource Groups e Storage Account:

```bash
# Login no Azure
az login

# Criar Resource Group principal (onde a infra vai rodar)
# Configure as permissões necessárias neste RG
az group create \
  --name foundry-rg \
  --location brazilsouth

# Criar Resource Group para tfstate
az group create \
  --name foundry-tfstate-rg \
  --location brazilsouth

# Criar Storage Account
az storage account create \
  --name foundrytfstate \
  --resource-group foundry-tfstate-rg \
  --location brazilsouth \
  --sku Standard_LRS \
  --encryption-services blob

# Criar Container
az storage container create \
  --name tfstate \
  --account-name foundrytfstate
```

### 2. Configurar Terraform

```bash
cd terraform

# Copiar exemplo de variáveis
cp terraform.tfvars.example terraform.tfvars

# Editar terraform.tfvars com seus valores
nano terraform.tfvars
# IMPORTANTE: Adicionar sua chave SSH pública!

# Inicializar Terraform com backend remoto
terraform init \
  -backend-config="resource_group_name=foundry-tfstate-rg" \
  -backend-config="storage_account_name=foundrytfstate" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=foundry.tfstate"
```

### 3. Deploy da Infraestrutura

```bash
# Planejar mudanças
terraform plan -out=tfplan

# Aplicar (criar recursos)
terraform apply tfplan

# Capturar outputs importantes
terraform output public_ip_address
terraform output -raw storage_account_primary_key
```

**IMPORTANTE**: Salvar a `storage_account_primary_key` para o Ansible!

### 4. Configurar Ansible Vault

```bash
cd ../ansible

# Criar vault.yml com secrets
cp group_vars/all/vault.yml.example group_vars/all/vault.yml
nano group_vars/all/vault.yml

# Preencher:
# - foundry_license_key (da sua conta Foundry VTT)
# - foundry_admin_password (escolher senha forte)
# - azure_storage_account_key (do terraform output)

# Criptografar vault
ansible-vault encrypt group_vars/all/vault.yml
# Digite uma senha forte para o vault!
```

### 5. Deploy do Foundry VTT

```bash
# Verificar conectividade
ansible foundry -m ping --ask-vault-pass

# Rodar playbook completo
ansible-playbook playbook.yml --ask-vault-pass

# Ou usando vault password file:
echo "my-vault-password" > .vault_pass
chmod 600 .vault_pass
ansible-playbook playbook.yml --vault-password-file .vault_pass
```

## Acesso ao Foundry VTT

Após o deploy bem-sucedido:

```bash
# Obter URL
terraform output foundry_url

# Exemplo: http://XX.XX.XX.XX:30000
```

1. Abrir URL no navegador
2. Fazer login com a senha de admin do vault
3. Instalar sistemas e módulos (Pathfinder 2e)
4. Criar mundo e começar a jogar!

## Operação

### Conectar via SSH

```bash
terraform output ssh_command
# ssh foundry-admin@XX.XX.XX.XX

# Ou manualmente:
ssh foundry-admin@$(terraform output -raw public_ip_address)
```

### Ver logs do Foundry

```bash
ssh foundry-admin@<IP>
cd /opt/foundry
docker-compose logs -f foundry
```

### Restart do Foundry

```bash
ssh foundry-admin@<IP>
cd /opt/foundry
docker-compose restart foundry
```

### Backup dos Dados

Os dados do Foundry estão no Azure File Share (`foundrydata`). Para backup:

```bash
# Via Azure CLI
az storage file download-batch \
  --destination ./backup \
  --source foundrydata \
  --account-name foundryst

# Ou montar localmente via SMB e copiar
```

### Atualizar Foundry VTT

```bash
# SSH na VM
ssh foundry-admin@<IP>

# Pull nova imagem
cd /opt/foundry
docker-compose pull foundry

# Restart com nova versão
docker-compose up -d foundry
```

## CI/CD com GitHub Actions

(Opcional) Para automatizar deploy via GitHub Actions:

1. Adicionar secrets no repositório GitHub:
   - `AZURE_CREDENTIALS` (service principal JSON)
   - `ARM_ACCESS_KEY` (storage account key para tfstate)
   - `FOUNDRY_LICENSE_KEY`
   - `FOUNDRY_ADMIN_PASSWORD`
   - `AZURE_STORAGE_KEY`
   - `SSH_PRIVATE_KEY`

2. Workflow será criado em `.github/workflows/deploy.yml`

## Troubleshooting

### Terraform: "Backend initialization failed"

```bash
# Verificar se storage account existe
az storage account show --name foundrytfstate

# Verificar access key
az storage account keys list \
  --account-name foundrytfstate \
  --query '[0].value' -o tsv
```

### Ansible: "Failed to connect to host"

```bash
# Verificar se VM está rodando
terraform output public_ip_address
ping <IP>

# Verificar NSG permite SSH do seu IP
az network nsg rule list \
  --resource-group foundry-rg \
  --nsg-name foundry-nsg \
  --query "[?name=='AllowSSH']"

# Testar SSH manual
ssh -v foundry-admin@<IP>
```

### Azure File Share não monta

```bash
# SSH na VM
ssh foundry-admin@<IP>

# Verificar credenciais
sudo cat /etc/smbcredentials

# Testar mount manual
sudo mount -t cifs \
  //foundryst.file.core.windows.net/foundrydata \
  /opt/foundrydata \
  -o credentials=/etc/smbcredentials,dir_mode=0755

# Ver logs
sudo dmesg | grep -i cifs
```

### Foundry VTT não inicia

```bash
# Ver logs
cd /opt/foundry
docker-compose logs foundry

# Verificar health
docker-compose ps

# Reiniciar
docker-compose restart foundry
```

## Limpeza (Destruir Infraestrutura)

```bash
cd terraform

# Destruir todos os recursos
terraform destroy

# CUIDADO: Isso remove:
# - VM
# - Networking
# - Storage Account (DADOS DO FOUNDRY!)
#
# Fazer backup antes se necessário!
```

## Custos Estimados (Brazil South)

| Recurso | Especificação | Custo Mensal (USD) |
|---------|---------------|-------------------|
| VM Standard_B2s | 2 vCPU, 4GB RAM | ~$60 |
| Public IP Static | Standard SKU | ~$4 |
| Storage Account | Standard LRS, 50GB | ~$2 |
| Bandwidth | ~100GB egress | ~$5 |
| **Total** | | **~$71/mês** |

*Valores aproximados, verificar [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/).*

## Segurança

### Recomendações

1. **SSH**: Restringir `allowed_ssh_ips` no `terraform.tfvars`
2. **HTTPS**: Configurar reverse proxy com Let's Encrypt (futuro)
3. **Backups**: Automatizar backup do File Share
4. **Updates**: Manter VM e Docker atualizados
5. **Monitoring**: Configurar Azure Monitor/Alerts

### Secrets Management

- ✅ `terraform.tfvars`: Gitignored, contém SSH key
- ✅ `vault.yml`: Criptografado com ansible-vault
- ✅ GitHub Secrets: Para CI/CD
- ❌ Nunca commitar secrets em plain text!

## Suporte

- [Foundry VTT Docs](https://foundryvtt.com/kb/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Ansible Docs](https://docs.ansible.com/)

## Licença

Este código é fornecido como está, sem garantias. Use por sua conta e risco.
