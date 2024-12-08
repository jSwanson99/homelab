resource "proxmox_lxc" "basic" {
  target_node  = "pve"
  hostname     = "coredns"
  ostemplate   = "local:vztmpl/rockylinux-9-default_20240912_amd64.tar.xz"
  password     = "BasicLXCContainer"
  unprivileged = true
  onboot = true
  start = true

  cores = 2
  memory = 2048
  swap = 512

  rootfs {
    storage = "local-lvm"
    size    = "32G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "192.168.1.11/24"
    gw     = "192.168.1.1"
  }


  nameserver = "8.8.8.8"
  searchdomain = "local"

  description = "CoreDNS"
}
