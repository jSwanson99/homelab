output "vault_unseal_keys" {
  value = module.bootstrap.vault_unseal_keys
}

output "vault_root_token" {
  value = module.bootstrap.vault_root_token
}

output "kubernetes_token" {
  value = module.operational.kubernetes_node_token
}
