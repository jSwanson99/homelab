variable "gateway_ip" {
  description = "IP of router"
  type        = string
  default     = "192.168.1.1"
}
variable "pg_vault_ip" {
  description = "IP of VM for Postgres and Vault"
  type        = string
  default     = "192.168.1.20/24"
}
variable "kubernetes_server_ip" {
  description = "IP of VM for Postgres and Vault"
  type        = string
  default     = "192.168.1.30/24"
}
variable "kubernetes_node_one_ip" {
  description = "IP of VM for Postgres and Vault"
  type        = string
  default     = "192.168.1.31/24"
}
variable "kubernetes_node_two_ip" {
  description = "IP of VM for Postgres and Vault"
  type        = string
  default     = "192.168.1.32/24"
}
variable "lxc_template_id" {
  description = "ID of LXC Template to Clone"
  type        = number
  default     = 2001
}
variable "vm_template_id" {
  description = "ID of VM Template to Clone"
  type        = string
  default     = "rocky-template-vm"
}
variable "pg_database_terraform" {
  description = "Name of database for terraform to use"
  type        = string
  default     = "terraform"
}
