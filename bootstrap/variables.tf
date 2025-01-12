variable "pg_vault_ip" {
  description = "IP of VM for Postgres and Vault"
  type        = string
  default     = "192.168.1.20/24"
}
variable "gateway_ip" {
  description = "IP of router"
  type        = string
  default     = "192.168.1.1"
}
variable "lxc_template_id" {
  description = "ID of LXC Template to Clone"
  type        = number
  default     = 101
}
variable "vm_template_id" {
  description = "ID of VM Template to Clone"
  type        = string
  default     = "rocky-template-vm"
}

