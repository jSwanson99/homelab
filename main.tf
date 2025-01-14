module "bootstrap" {
  source                = "./bootstrap"
  user                  = var.user
  pg_vault_ip           = var.pg_vault_ip
  pg_user_vault         = var.pg_user_vault
  pg_password_vault     = var.pg_password_vault
  pg_user_terraform     = var.pg_user_terraform
  pg_password_terraform = var.pg_password_terraform
  pg_database_terraform = var.pg_database_terraform
  gateway_ip            = var.gateway_ip
  vm_template_id        = var.vm_template_id
}

module "operational" {
  source                 = "./operational"
  user                   = var.user
  pg_vault_ip            = var.pg_vault_ip
  pg_user_vault          = var.pg_user_vault
  pg_password_vault      = var.pg_password_vault
  pg_user_terraform      = var.pg_user_terraform
  pg_password_terraform  = var.pg_password_terraform
  gateway_ip             = var.gateway_ip
  vm_template_id         = var.vm_template_id
  kubernetes_server_ip   = var.kubernetes_server_ip
  kubernetes_node_one_ip = var.kubernetes_node_one_ip
  kubernetes_node_two_ip = var.kubernetes_node_two_ip
}
