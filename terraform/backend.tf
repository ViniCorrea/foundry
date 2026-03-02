terraform {
  backend "azurerm" {
    # Valores vêm do arquivo backend.conf
    # resource_group_name  = "shared"
    # storage_account_name = "iacshared"
    # container_name       = "foundry-tf"
    # key                  = "foundry.tfstate"

    # Autenticação via Storage Account Key (ARM_ACCESS_KEY)
    use_azuread_auth = false
  }
}
