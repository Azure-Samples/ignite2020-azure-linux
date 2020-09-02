variable "location" {
  type    = string
  default = "eastus2"
}

variable "admin_username" {
  type        = string
  description = "Administrator user name for virtual machine"
  default     = "bjk"
}

variable "admin_password" {
  type        = string
  description = "Password must meet Azure complexity requirements"
}

variable "prefix" {
  type    = string
  default = "stage0"
}

variable "tags" {
  type = map

  default = {
    Iteration = "1"
  }
}

variable "sku" {
  default = {
    westus2 = "18.04-LTS"
    eastus2 = "18.04-LTS"
  }
}

variable "ssh_key" {
  description = "Path to the public key to be used for ssh access to the VM.  Only used with non-Windows vms and can be left as-is even if using Windows vms. If specifying a path to a certification on a Windows machine to provision a linux vm use the / in the path versus backslash. e.g. c:/home/id_rsa.pub."
  default     = "~/.ssh/id_rsa.pub"
}