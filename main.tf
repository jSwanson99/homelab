module "pki" {
  source = "./pki"
}

module "storage" {
  source         = "./storage"
  user           = var.user
  gateway_ip     = var.gateway_ip
  vm_template_id = var.vm_template_id
  truenas_ip     = var.truenas_ip
}

module "routing" {
  source           = "./routing"
  user             = var.user
  gateway_ip       = var.gateway_ip
  proxmox_ip       = var.proxmox_ip
  vm_template_id   = var.vm_template_id
  coredns_ip       = var.coredns_ip
  forward_proxy_ip = var.forward_proxy_ip
  corefile = templatefile("Corefile.tftpl", {
    gateway_ip             = split("/", var.gateway_ip)[0]
    grafana_ip             = split("/", var.grafana_ip)[0]
    argocd_ip              = split("/", var.argocd_ip)[0]
    coredns_ip             = split("/", var.coredns_ip)[0]
    dashboard_ip           = split("/", var.dashboard_ip)[0]
    hubble_ip              = split("/", var.hubble_ip)[0]
    kubernetes_server_ip   = split("/", var.kubernetes_server_ip)[0]
    kubernetes_node_one_ip = split("/", var.kubernetes_node_one_ip)[0]
    kubernetes_node_two_ip = split("/", var.kubernetes_node_two_ip)[0]
    nginx_ip               = split("/", var.forward_proxy_ip)[0]
    truenas_ip             = split("/", var.truenas_ip)[0]
  })
  ca_private_key_pem = module.pki.pki_ca_key
  ca_cert_pem        = module.pki.pki_ca_crt
}

module "bootstrap" {
  source                 = "./bootstrap"
  user                   = var.user
  pg_vault_ip            = var.pg_vault_ip
  pg_user_kubernetes     = var.pg_user_kubernetes
  pg_password_kubernetes = var.pg_password_kubernetes
  pg_database_kubernetes = var.pg_database_kubernetes
  pg_user_vault          = var.pg_user_vault
  pg_password_vault      = var.pg_password_vault
  pg_database_vault      = var.pg_database_vault
  pg_user_terraform      = var.pg_user_terraform
  pg_password_terraform  = var.pg_password_terraform
  pg_database_terraform  = var.pg_database_terraform
  gateway_ip             = var.gateway_ip
  vm_template_id         = var.vm_template_id
  ca_private_key_pem     = module.pki.pki_ca_key
  ca_cert_pem            = module.pki.pki_ca_crt
}

module "kubernetes" {
  source                 = "./kubernetes"
  gateway_ip             = var.gateway_ip
  vm_template_id         = var.vm_template_id
  user                   = var.user
  vault_token            = "module.bootstrap.vault_root_token"
  pg_vault_ip            = var.pg_vault_ip
  pg_user_vault          = var.pg_user_vault
  pg_password_vault      = var.pg_password_vault
  pg_user_terraform      = var.pg_user_terraform
  pg_password_terraform  = var.pg_password_terraform
  pg_database_terraform  = var.pg_database_terraform
  pg_user_kubernetes     = var.pg_user_kubernetes
  pg_password_kubernetes = var.pg_password_kubernetes
  pg_database_kubernetes = var.pg_database_kubernetes
  kubernetes_server_ip   = var.kubernetes_server_ip
  kubernetes_node_one_ip = var.kubernetes_node_one_ip
  kubernetes_node_two_ip = var.kubernetes_node_two_ip
  argocd_ip              = var.argocd_ip
  hubble_ip              = var.hubble_ip
  dashboard_ip           = var.dashboard_ip
  k8s_app_ip_range       = var.k8s_app_ip_range
  ca_private_key_pem     = module.pki.pki_ca_key
  ca_cert_pem            = module.pki.pki_ca_crt
}
