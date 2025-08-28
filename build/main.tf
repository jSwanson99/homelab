module "gitlab" {
  source             = "./gitlab"
  user               = var.user
  gateway_ip         = var.gateway_ip
  vm_template_id     = var.vm_template_id
  gitlab_ip          = var.gitlab_ip
  ca_private_key_pem = var.ca_private_key_pem
  ca_cert_pem        = var.ca_cert_pem
  github_token       = var.github_token
}

