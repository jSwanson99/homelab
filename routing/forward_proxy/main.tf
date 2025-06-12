module "squid" {
  source             = "./squid"
  vm_template_id     = var.vm_template_id
  user               = var.user
  proxmox_ip         = var.proxmox_ip
  gateway_ip         = var.gateway_ip
  squid_ip           = var.forward_proxy_ip
  ca_private_key_pem = var.ca_private_key_pem
  ca_cert_pem        = var.ca_cert_pem
}

