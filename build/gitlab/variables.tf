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
variable "gitlab_ip" {
  type = string
}
variable "ca_cert_pem" {
  sensitive = true
  type      = string
}
variable "ca_private_key_pem" {
  sensitive = true
  type      = string
}
variable "github_token" {
  type      = string
  sensitive = true
}
