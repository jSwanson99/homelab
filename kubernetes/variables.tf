# project config
variable "vm_template_id" {
  description = "ID of VM Template to Clone"
  type        = string
}
variable "user" {
  type      = string
  sensitive = true
}
variable "gateway_ip" {
  description = "IP of router"
  type        = string
}
variable "kubernetes_server_ip" {
  type = string
}
variable "kubernetes_node_one_ip" {
  type = string
}
variable "kubernetes_node_two_ip" {
  type = string
}
variable "kubernetes_node_three_ip" {
  type = string
}
variable "k8s_app_ip_range" {
  type = list(string)
}
variable "argocd_ip" {
  type = string
}
variable "hubble_ip" {
  type = string
}
variable "ca_private_key_pem" {
  type      = string
  sensitive = true
}
variable "ca_cert_pem" {
  type      = string
  sensitive = true
}
