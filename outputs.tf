output "vault_unseal_keys" {
  value = module.bootstrap.vault_unseal_keys
}

output "vault_root_token" {
  value = module.bootstrap.vault_root_token
}
