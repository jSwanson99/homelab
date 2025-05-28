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
variable "truenas_ip" {
  type = string
}
variable "truenas_user" {
  type = string
}
variable "truenas_apikey" {
  type = string
}
