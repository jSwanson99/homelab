module "dns" {
  source         = "./dns"
  user           = var.user
  gateway_ip     = var.gateway_ip
  vm_template_id = var.vm_template_id
  coredns_ip     = var.coredns_ip
  corefile       = var.corefile
  node_name      = "pve"
}

module "forward_proxy" {
  source             = "./forward_proxy"
  user               = var.user
  gateway_ip         = var.gateway_ip
  proxmox_ip         = var.proxmox_ip
  vm_template_id     = var.vm_template_id
  ca_private_key_pem = var.ca_private_key_pem
  ca_cert_pem        = var.ca_cert_pem
  forward_proxy_ip   = var.forward_proxy_ip
}

#module "coredns2" {
#  source         = "./dns"
#  user           = var.user
#  gateway_ip     = var.gateway_ip
#  vm_template_id = var.vm_template_id
#  coredns_ip     = var.coredns2_ip
#  corefile       = var.corefile
#  node_name      = "pve1"
#}

module "firewall" {
  source = "./firewall"
  user   = var.user
}
