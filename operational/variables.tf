variable "coredns_ip" {
  description = "IP of CoreDNS"
  type        = string
  default     = "192.168.1.11/24"
}
variable "minio_ip" {
  description = "IP of Minio"
  type        = string
  default     = "192.168.1.12/24"
}
variable "gitlab_ip" {
  description = "IP of Gitlab"
  type        = string
  default     = "192.168.1.13/24"
}
variable "postgres_ip" {
  description = "IP of Postgres"
  type        = string
  default     = "192.168.1.14/24"
}
variable "test_ip" {
  description = "IP of OpenWebUI"
  type        = string
  default     = "192.168.1.15/24"
}

variable "gateway_ip" {
  description = "IP of router"
  type        = string
  default     = "192.168.1.1"
}
variable "lxc_template_id" {
  description = "ID of LXC Template to Clone"
  type        = number
  default     = 101
}
variable "vm_template_id" {
  description = "ID of VM Template to Clone"
  type        = string
  default     = "rocky-template-vm"
}

