variable "vm_template_id" {
  description = "ID of VM Template to Clone"
  type        = string
}
variable "user" {
  type      = string
  sensitive = true
}
variable "gateway_ip" {
  type = string
}
variable "proxmox_ip" {
  type = string
}
variable "nginx_ip" {
  type = string
}
variable "coredns_ip" {
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
