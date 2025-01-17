module "bootstrap" {
  source      = "./bootstrap"
  user        = var.user
  pg_vault_ip = var.pg_vault_ip

  pg_user_kubernetes     = var.pg_user_kubernetes
  pg_password_kubernetes = var.pg_password_kubernetes
  pg_database_kubernetes = var.pg_database_kubernetes

  pg_user_vault     = var.pg_user_vault
  pg_password_vault = var.pg_password_vault
  pg_database_vault = var.pg_database_vault

  pg_user_terraform     = var.pg_user_terraform
  pg_password_terraform = var.pg_password_terraform
  pg_database_terraform = var.pg_database_terraform

  gateway_ip     = var.gateway_ip
  vm_template_id = var.vm_template_id

  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem
}

module "operational" {
  source         = "./operational"
  gateway_ip     = var.gateway_ip
  vm_template_id = var.vm_template_id
  user           = var.user

  pg_vault_ip = var.pg_vault_ip

  pg_user_vault     = var.pg_user_vault
  pg_password_vault = var.pg_password_vault

  pg_user_terraform     = var.pg_user_terraform
  pg_password_terraform = var.pg_password_terraform
  pg_database_terraform = var.pg_database_terraform

  pg_user_kubernetes     = var.pg_user_kubernetes
  pg_password_kubernetes = var.pg_password_kubernetes
  pg_database_kubernetes = var.pg_database_kubernetes

  kubernetes_server_ip   = var.kubernetes_server_ip
  kubernetes_node_one_ip = var.kubernetes_node_one_ip
  kubernetes_node_two_ip = var.kubernetes_node_two_ip

  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem
}
