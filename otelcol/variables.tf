variable "gateway_ip" {
  type = string
}
variable "user" {
  type      = string
  sensitive = false
}
variable "target_ip" {
  type        = string
  description = "VM Which needs an otelcol installed"
}
variable "systemd_unit" {
  type        = string
  description = "Systemd unit to read logs for"
}
