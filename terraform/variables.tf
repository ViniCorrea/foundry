variable "project_name" {
  description = "Nome do projeto (usado como prefixo nos recursos)"
  type        = string
  default     = "foundry"
}

variable "storage_account_name" {
  description = "Nome do Storage Account (deve ser globalmente único, 3-24 caracteres alfanuméricos lowercase)"
  type        = string
  default     = ""

  validation {
    condition     = var.storage_account_name == "" || (length(var.storage_account_name) >= 3 && length(var.storage_account_name) <= 24 && can(regex("^[a-z0-9]+$", var.storage_account_name)))
    error_message = "Storage account name deve ter 3-24 caracteres, apenas lowercase e números."
  }
}

variable "location" {
  description = "Região Azure para deploy"
  type        = string
  default     = "brazilsouth"
}

variable "vnet_address_space" {
  description = "CIDR da VNET"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefix" {
  description = "CIDR da Subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "vm_size" {
  description = "Tamanho da VM (Standard_B2s = 2 vCPU, 4GB RAM)"
  type        = string
  default     = "Standard_B2s"
}

variable "vm_admin_username" {
  description = "Username do admin da VM"
  type        = string
  default     = "foundry-admin"
}

variable "ssh_public_key" {
  description = "Chave pública SSH para acesso à VM"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^ssh-rsa|^ssh-ed25519", var.ssh_public_key))
    error_message = "SSH key deve começar com ssh-rsa ou ssh-ed25519."
  }
}

variable "storage_account_tier" {
  description = "Tier do Storage Account"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication" {
  description = "Tipo de replicação (LRS = Local Redundant Storage)"
  type        = string
  default     = "LRS"
}

variable "fileshare_quota_gb" {
  description = "Quota do File Share em GB (dados do Foundry)"
  type        = number
  default     = 50

  validation {
    condition     = var.fileshare_quota_gb >= 1 && var.fileshare_quota_gb <= 102400
    error_message = "Quota deve estar entre 1GB e 100TB."
  }
}

variable "allowed_ssh_ips" {
  description = "Lista de IPs/CIDRs permitidos para SSH (porta 22)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "foundry_port" {
  description = "Porta do Foundry VTT"
  type        = number
  default     = 30000
}

variable "tags" {
  description = "Tags comuns para todos os recursos"
  type        = map(string)
  default = {
    Project   = "FoundryVTT"
    ManagedBy = "Terraform"
    Game      = "Pathfinder2e"
  }
}

variable "foundry_domain" {
  description = "Domain name for Foundry VTT (optional, for HTTPS)"
  type        = string
  default     = ""
}

variable "backup_retention_days" {
  description = "Número de dias para manter backups diários"
  type        = number
  default     = 30

  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 200
    error_message = "Retention deve estar entre 7 e 200 dias."
  }
}

variable "backup_retention_weeks" {
  description = "Número de semanas para manter backups semanais (0 = desabilitado)"
  type        = number
  default     = 12

  validation {
    condition     = var.backup_retention_weeks >= 0 && var.backup_retention_weeks <= 200
    error_message = "Retention deve estar entre 0 e 200 semanas."
  }
}

variable "backup_retention_months" {
  description = "Número de meses para manter backups mensais (0 = desabilitado)"
  type        = number
  default     = 12

  validation {
    condition     = var.backup_retention_months >= 0 && var.backup_retention_months <= 120
    error_message = "Retention deve estar entre 0 e 120 meses."
  }
}

variable "enable_backup" {
  description = "Habilitar Azure Backup para o File Share (pode ser desabilitado para economizar custos)"
  type        = bool
  default     = true
}
