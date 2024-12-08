resource "proxmox_vm_qemu" "test" {
  name = "test"
  target_node = "pve"
  clone = "rocky-templ-vm"
  agent = 1

  memory = 2048
  cores = 2
  sockets = 1

  network {
    model = "virtio"
    bridge = "vmbr0"
    firewall = true
  }

  disk {
    type    = "disk"
    storage = "local-lvm"
    size    = "32G"
    slot    = "scsi0"
  }

  os_type = "cloud-init"

  lifecycle {
    ignore_changes = [
      disk,
      network
    ]
  }
}
