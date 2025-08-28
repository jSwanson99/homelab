resource "tls_private_key" "gitlab" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "gitlab" {
  private_key_pem = tls_private_key.gitlab.private_key_pem
  subject {
    common_name  = "gitlab"
    country      = "US"
    organization = "JonCorpIncLLC"
  }
  ip_addresses = ["127.0.0.1", split("/", var.gitlab_ip)[0]]
  dns_names = [
    "gitlab.jds.net"
  ]
}

resource "tls_locally_signed_cert" "gitlab" {
  cert_request_pem      = tls_cert_request.gitlab.cert_request_pem
  ca_private_key_pem    = var.ca_private_key_pem
  ca_cert_pem           = var.ca_cert_pem
  validity_period_hours = 43800
  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}

