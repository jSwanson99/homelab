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
variable "coredns_ip" {
  type = string
}
variable "corefile" {
  type = string
}
variable "node_name" {
  type = string
}
