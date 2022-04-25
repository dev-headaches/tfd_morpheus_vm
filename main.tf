provider "azurerm" {
  environment     = var.ARM_ENVIRONMENT
  tenant_id       = var.ARM_TENANT_ID
  subscription_id = var.ARM_SUBSCRIPTION_ID
  client_id       = var.ARM_CLIENT_ID
  client_secret   = var.ARM_CLIENT_SECRET
  features {}
}


locals {
  hubnamesplitlist = split("-", var.hubname)
}

module "morpheus_vm" {
    source  = "app.terraform.io/roman2025/vm-morpheus/azurerm"
    version = ">= 0.0.9"
    name = var.name
    prjnum = local.hubnamesplitlist[2]
    enviro = local.hubnamesplitlist[1]
    orgname = local.hubnamesplitlist[0]
    vmsize = var.vmsize
    morph_url = var.morph_url
    nbmorph_api_key = var.nbmorph_api_key
}

/*
AZ-VM-NAME
nb-vm-kv-name
nb-vm-prjnum
nb-vm-enviro
nb-vm-orgname


kv-vmsecretskv75941111
1111
dev
morphcld
*/