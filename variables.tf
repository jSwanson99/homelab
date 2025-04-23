variable "lxc_template_id" {
  description = "ID of LXC Template to Clone"
  type        = number
  default     = 2001
}
variable "vm_template_id" {
  description = "ID of VM Template to Clone"
  type        = string
  default     = "rocky-vm-templ"
}

variable "gateway_ip" {
  description = "IP of router"
  type        = string
  default     = "192.168.1.1"
}
variable "proxmox_ip" {
  type    = string
  default = "192.168.1.10"
}
variable "pg_vault_ip" {
  type    = string
  default = "192.168.1.20/24"
}
variable "truenas_ip" {
  type    = string
  default = "192.168.1.21/24"
}
variable "coredns_ip" {
  type    = string
  default = "192.168.1.22/24"
}
variable "forward_proxy_ip" {
  type    = string
  default = "192.168.1.23/24"
}

variable "kubernetes_server_ip" {
  type    = string
  default = "192.168.1.30/24"
}
variable "kubernetes_node_one_ip" {
  type    = string
  default = "192.168.1.31/24"
}
variable "kubernetes_node_two_ip" {
  type    = string
  default = "192.168.1.32/24"
}
variable "kubernetes_node_three_ip" {
  type    = string
  default = "192.168.1.33/24"
}

variable "k8s_app_ip_range" {
  type    = string
  default = "192.168.1.240-192.168.1.254"
}
variable "grafana_ip" {
  type    = string
  default = "192.168.1.252/24"
}
variable "argocd_ip" {
  type    = string
  default = "192.168.1.253/24"
}
variable "hubble_ip" {
  type    = string
  default = "192.168.1.254/24"
}
variable "dashboard_ip" {
  type    = string
  default = "192.168.1.252/24"
}

variable "pg_database_kubernetes" {
  description = "Name of database for kubernetes to use"
  type        = string
  default     = "kubernetes"
}
variable "pg_database_vault" {
  description = "Name of database for vault to use"
  type        = string
  default     = "vault"
}
variable "pg_database_terraform" {
  description = "Name of database for terraform to use"
  type        = string
  default     = "terraform"
}
