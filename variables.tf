variable "name" {
  type = string
  description = "a single word to be added to the VM name to describe the VM (ex. 'WEB01')"
}

/*
variable "kv_name" {
  type        = string
  description = "the name of the existing azure key vault in which to store azureuser password"
}
*/
/*
variable "prjnum" {
  type        = string
  description = "the existing project number used to deploy the hub"
}
variable "enviro" {
  type        = string
  description = "the environment name used for the hub deployment (default is 'dev')"
  default = "dev"
}
variable "orgname" {
  type        = string
  description = "the organization name used for the hub deployment"
}
*/
variable "hubname" {
  type        = string
  description = "the name of the hub you want to deploy to"
}

variable "vmsize" {
  type        = string
  description = "the vmsize sku"
}

variable "morph_url" {
  type = string
  description = "url of the morpheus appliance"
  default = "csb.broker.saic.com"
}

variable "nbmorph_api_key" {
  type = string
  description = "api key for the morpheus appliance"
  sensitive   = true
  default = ""
}

###

variable "ARM_ENVIRONMENT" {
    type = string
}
variable "ARM_CLIENT_ID" {
    type = string
}
variable "ARM_TENANT_ID" {
    type = string
}
variable "ARM_CLIENT_SECRET" {
    type = string
    sensitive = true
}
variable "ARM_SUBSCRIPTION_ID" {
    type = string
}