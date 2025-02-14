module "coredns" {
  source         = "./coredns"
  user           = var.user
  gateway_ip     = var.gateway_ip
  vm_template_id = var.vm_template_id
  coredns_ip     = var.coredns_ip
  corefile       = var.corefile
}

#module "mitmproxy" {
#  source           = "./mitmproxy"
#  user             = var.user
#  gateway_ip       = var.gateway_ip
#  vm_template_id   = var.vm_template_id
#  forward_proxy_ip = var.forward_proxy_ip
#}
module "nginx" {
  source             = "./nginx"
  user               = var.user
  gateway_ip         = var.gateway_ip
  vm_template_id     = var.vm_template_id
  nginx_ip           = var.forward_proxy_ip
  coredns_ip         = var.coredns_ip
  ca_cert_pem        = var.ca_cert_pem
  ca_private_key_pem = var.ca_private_key_pem
}
