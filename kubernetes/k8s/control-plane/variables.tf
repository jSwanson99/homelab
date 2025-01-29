variable "vm_template_id" {
  type = string
}
variable "kubernetes_server_ip" {
  type = string
}
variable "gateway_ip" {
  type = string
}
variable "user" {
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
