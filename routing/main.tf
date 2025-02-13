module "coredns" {
  source         = "./coredns"
  user           = var.user
  gateway_ip     = var.gateway_ip
  vm_template_id = var.vm_template_id
  coredns_ip     = var.coredns_ip
  corefile       = var.corefile
}

module "nginx" {
  source             = "./nginx"
  user               = var.user
  gateway_ip         = var.gateway_ip
  vm_template_id     = var.vm_template_id
  nginx_ip           = var.nginx_ip
  ca_cert_pem        = var.ca_cert_pem
  ca_private_key_pem = var.ca_private_key_pem
}
