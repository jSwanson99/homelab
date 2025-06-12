# Create an intermediate Cert for Nginx, so it can dynamically sign things
resource "tls_private_key" "intermediate_ca" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "tls_cert_request" "intermediate_ca" {
  private_key_pem = tls_private_key.intermediate_ca.private_key_pem
  subject {
    common_name  = "NGINX CA"
    organization = "JonCorpIncLLC"
    country      = "US"
  }
}
resource "tls_locally_signed_cert" "intermediate_ca" {
  cert_request_pem      = tls_cert_request.intermediate_ca.cert_request_pem
  ca_private_key_pem    = var.ca_private_key_pem # Root CA private key
  ca_cert_pem           = var.ca_cert_pem        # Root CA certificate
  validity_period_hours = 87600                  # 10 years
  is_ca_certificate     = true
  allowed_uses = [
    "cert_signing",
    "key_encipherment",
    "digital_signature",
    "crl_signing"
  ]
  set_subject_key_id = true
}

resource "tls_locally_signed_cert" "nginx" {
  cert_request_pem      = tls_cert_request.nginx.cert_request_pem
  ca_private_key_pem    = tls_private_key.intermediate_ca.private_key_pem
  ca_cert_pem           = tls_locally_signed_cert.intermediate_ca.cert_pem
  validity_period_hours = 43800
  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}

resource "tls_private_key" "nginx" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "nginx" {
  private_key_pem = tls_private_key.nginx.private_key_pem
  subject {
    common_name  = "nginx"
    country      = "US"
    organization = "JonCorpIncLLC"
  }
  ip_addresses = ["127.0.0.1", split("/", var.nginx_ip)[0]]
}
