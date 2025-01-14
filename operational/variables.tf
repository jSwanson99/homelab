# project config
variable "vm_template_id" {
  description = "ID of VM Template to Clone"
  type        = string
}
variable "user" {
  type      = string
  sensitive = true
}

# Ips
variable "pg_vault_ip" {
  description = "IP of VM for Postgres and Vault"
  type        = string
}
variable "gateway_ip" {
  description = "IP of router"
  type        = string
}

# Postgres Credentials
variable "pg_user_vault" {
  type = string
}
variable "pg_password_vault" {
  type      = string
  sensitive = true
}
variable "pg_user_terraform" {
  type = string
}
variable "pg_password_terraform" {
  type      = string
  sensitive = true
}

# New
variable "kubernetes_server_ip" {
  type = string
}
variable "kubernetes_node_one_ip" {
  type = string
}
variable "kubernetes_node_two_ip" {
  type = string
}
