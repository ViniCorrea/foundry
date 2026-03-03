output "resource_group_name" {
  description = "Nome do Resource Group"
  value       = data.azurerm_resource_group.foundry.name
}

output "public_ip_address" {
  description = "IP Público da VM (para acessar Foundry VTT)"
  value       = azurerm_public_ip.foundry.ip_address
}

output "vm_name" {
  description = "Nome da VM"
  value       = azurerm_linux_virtual_machine.foundry.name
}

output "storage_account_name" {
  description = "Nome do Storage Account"
  value       = azurerm_storage_account.foundry.name
}

output "storage_account_primary_key" {
  description = "Primary Access Key do Storage Account (SENSÍVEL)"
  value       = azurerm_storage_account.foundry.primary_access_key
  sensitive   = true
}

output "fileshare_name" {
  description = "Nome do Azure File Share"
  value       = azurerm_storage_share.foundry.name
}

output "foundry_url" {
  description = "URL de acesso ao Foundry VTT"
  value       = "http://${azurerm_public_ip.foundry.ip_address}:${var.foundry_port}"
}

output "ssh_command" {
  description = "Comando para conectar via SSH"
  value       = "ssh ${var.vm_admin_username}@${azurerm_public_ip.foundry.ip_address}"
}

output "ansible_inventory_path" {
  description = "Path do inventory gerado para Ansible"
  value       = local_file.ansible_inventory.filename
}

output "backup_vault_name" {
  description = "Nome do Recovery Services Vault"
  value       = azurerm_recovery_services_vault.foundry.name
}

output "backup_policy_name" {
  description = "Nome da política de backup"
  value       = azurerm_backup_policy_file_share.foundry.name
}

output "backup_vault_id" {
  description = "ID do Recovery Services Vault (para scripts de restore)"
  value       = azurerm_recovery_services_vault.foundry.id
}
