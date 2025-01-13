resource "proxmox_lxc" "TEMPLATE" {
  target_node  = "pve"
  hostname     = "TEMPLATE"
  description  = "TEMPLATE"
  ostemplate   = "local:vztmpl/rockylinux-9-default_20240912_amd64.tar.xz"
  unprivileged = true
  onboot       = true
  start        = true

  cores  = 2
  memory = 2048
  swap   = 512

  rootfs {
    storage = "local-lvm"
    size    = "32G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "${var.TEMPLATE_ip}/24"
    gw     = var.gateway_ip
  }
}
