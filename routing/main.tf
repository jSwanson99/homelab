module "coredns" {
  source         = "./coredns"
  user           = var.user
  gateway_ip     = var.gateway_ip
  vm_template_id = var.vm_template_id
  coredns_ip     = var.coredns_ip
  corefile       = var.corefile
}
