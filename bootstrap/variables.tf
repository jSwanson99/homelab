variable "pg_vault_ip" {
  description = "IP of VM for Postgres and Vault"
  type        = string
}
variable "gateway_ip" {
  description = "IP of router"
  type        = string
}
variable "vm_template_id" {
  description = "ID of VM Template to Clone"
  type        = string
}
variable "pg_database_terraform" {
  description = "Name of database for terraform to use"
  type        = string
}
variable "user" {
  type      = string
  sensitive = true
}
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
