resource "tls_private_key" "minio" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "minio" {
  private_key_pem = tls_private_key.minio.private_key_pem
  subject {
    common_name  = "minio"
    country      = "US"
    organization = "JonCorpIncLLC"
  }
  ip_addresses = ["127.0.0.1", split("/", var.minio_ip)[0]]
  dns_names = [
    "minio.jds.net"
  ]
}

resource "tls_locally_signed_cert" "minio" {
  cert_request_pem      = tls_cert_request.minio.cert_request_pem
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

