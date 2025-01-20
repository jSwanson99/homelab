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
  type = string
}
variable "pg_user_kubernetes" {
  type = string
}
variable "pg_password_kubernetes" {
  type      = string
  sensitive = true
}
variable "pg_database_kubernetes" {
  type = string
}
variable "pg_user_terraform" {
  type = string
}
variable "pg_password_terraform" {
  type      = string
  sensitive = true
}
variable "pg_database_terraform" {
  type = string
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

locals {
  pg_dsl_kubernetes = "postgres://${var.pg_user_kubernetes}:${var.pg_password_kubernetes}@${var.pg_vault_ip}:5432/${var.pg_database_kubernetes}"
}
variable "ca_private_key_pem" {
  type      = string
  sensitive = true
}
variable "ca_cert_pem" {
  type      = string
  sensitive = true
}
variable "vault_token" {
  type = string
}
