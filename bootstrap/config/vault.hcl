# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

# Full configuration options can be found at https://developer.hashicorp.com/vault/docs/configuration

ui = true
api_addr = "https://${split("/", pg_vault_ip)[0]}:8200"

listener "tcp" {
  address       = "${split("/", pg_vault_ip)[0]}:8200"
  tls_cert_file = "/etc/ssl/certs/vault.crt"
  tls_key_file  = "/etc/ssl/certs/vault.key"
}

storage "postgresql" {
  connection_url = "postgres://${pg_user_vault}:${pg_password_vault}@localhost:5432/${pg_database_vault}"
}
