output "pki_ca_key" {
  value = tls_private_key.ca.private_key_pem
}
output "pki_ca_crt" {
  value = tls_self_signed_cert.ca.cert_pem
}
