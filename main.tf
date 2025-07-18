module "pki" {
  source = "./pki"
}

module "storage" {
  source         = "./storage"
  user           = var.user
  gateway_ip     = var.gateway_ip
  vm_template_id = "truenas-templ"
  truenas_ip     = var.truenas_ip
}

module "routing" {
  source           = "./routing"
  user             = var.user
  gateway_ip       = var.gateway_ip
  proxmox_ip       = var.proxmox_ip
  vm_template_id   = var.vm_template_id
  coredns_ip       = var.coredns_ip
  coredns2_ip      = var.coredns2_ip
  forward_proxy_ip = var.forward_proxy_ip
  corefile = templatefile("Corefile.tftpl", {
    gateway_ip             = split("/", var.gateway_ip)[0]
    forward_proxy_ip       = split("/", var.forward_proxy_ip)[0]
    truenas_ip             = split("/", var.truenas_ip)[0]
    coredns_ip             = split("/", var.coredns_ip)[0]
    vault_ip               = split("/", var.vault_ip)[0]
    minio_ip               = split("/", var.minio_ip)[0]
    clickhouse_ip          = split("/", var.clickhouse_ip)[0]
    otelcol_ip             = split("/", var.otelcol_ip)[0]
    grafana_ip             = split("/", var.grafana_ip)[0]
    argocd_ip              = split("/", var.argocd_ip)[0]
    hubble_ip              = split("/", var.hubble_ip)[0]
    kubernetes_server_ip   = split("/", var.kubernetes_server_ip)[0]
    kubernetes_node_one_ip = split("/", var.kubernetes_node_one_ip)[0]
    kubernetes_node_two_ip = split("/", var.kubernetes_node_two_ip)[0]
  })
  ca_private_key_pem = module.pki.pki_ca_key
  ca_cert_pem        = module.pki.pki_ca_crt
}

module "kubernetes" {
  source               = "./kubernetes"
  gateway_ip           = var.gateway_ip
  vm_template_id       = var.vm_template_id
  user                 = var.user
  kubernetes_server_ip = var.kubernetes_server_ip
  #   kubernetes_node_one_ip   = var.kubernetes_node_one_ip
  #   kubernetes_node_two_ip   = var.kubernetes_node_two_ip
  #   kubernetes_node_three_ip = var.kubernetes_node_three_ip
  argocd_ip          = var.argocd_ip
  hubble_ip          = var.hubble_ip
  k8s_app_ip_range   = var.k8s_app_ip_range
  ca_private_key_pem = module.pki.pki_ca_key
  ca_cert_pem        = module.pki.pki_ca_crt

  workers = [
    {
      name        = "worker-one"
      target_node = "pve"
      cpu         = 4
      mem         = 8192
      ip          = var.kubernetes_node_one_ip
    },
    {
      name        = "worker-two"
      target_node = "pve"
      cpu         = 6
      mem         = 8192
      ip          = var.kubernetes_node_two_ip
    },
    {
      name        = "worker-three"
      target_node = "pve1"
      cpu         = 8
      mem         = 24576
      ip          = var.kubernetes_node_three_ip
    },
    {
      name        = "worker-four"
      target_node = "pve1"
      cpu         = 8
      mem         = 24576
      ip          = var.kubernetes_node_three_ip
    }
  ]
}
