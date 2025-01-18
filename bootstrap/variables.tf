variable "pg_vault_ip" {
  type = string
}
variable "gateway_ip" {
  type = string
}
variable "vm_template_id" {
  type = string
}
variable "user" {
  type      = string
  sensitive = false
}

variable "pg_user_kubernetes" {
  type = string
}
variable "pg_password_kubernetes" {
  type      = string
  sensitive = false
}
variable "pg_database_kubernetes" {
  type = string
}

variable "pg_user_vault" {
  type = string
}
variable "pg_password_vault" {
  type = string
}
variable "pg_database_vault" {
  type = string
}

variable "pg_user_terraform" {
  type = string
}
variable "pg_password_terraform" {
  type      = string
  sensitive = false
}
variable "pg_database_terraform" {
  type = string
}
variable "ca_private_key_pem" {
  type      = string
  sensitive = false
}
variable "ca_cert_pem" {
  type      = string
  sensitive = false
}
