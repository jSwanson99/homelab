resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "ca" {
  private_key_pem = tls_private_key.ca.private_key_pem

  subject {
    common_name  = "CA"
    organization = "JonCorpIncLLC"
  }

  validity_period_hours = 43800 # 5 years
  is_ca_certificate     = true

  allowed_uses = [
    "digital_signature",
    "cert_signing",
    "crl_signing",
  ]
}

# One-time setup (do before applying):
#   sudo ln -sf $(pwd)/ca-cert.crt /etc/pki/ca-trust/source/anchors/terraform-ca.crt
#   sudo update-ca-trust
resource "local_file" "ca_cert" {
  content  = resource.tls_self_signed_cert.ca.cert_pem
  filename = "${path.module}/ca.crt"
}

