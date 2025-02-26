variable "node_name" {
  type = string
}
variable "vm_template_id" {
  type = string
}
variable "kubernetes_node_ip" {
  type = string
}
variable "gateway_ip" {
  type = string
}
variable "user" {
  type = string
}
variable "join_cmd" {
  type      = string
  sensitive = true
}
