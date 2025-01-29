output "join_cmd" {
  value = data.external.k8s_join_cmd.result.token
}
