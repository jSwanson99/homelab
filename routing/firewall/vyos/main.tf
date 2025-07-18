# TODO:
# 1. Setup ssh key in vyos
# 2. Setup dhcp server on ifs
# 3. Setup NAT on WAN
# 4. VPN?
# 5. DDNS?

resource "proxmox_vm_qemu" "vyos" {
  name        = "vyos"
  target_node = "pve2"
  cores       = 2
  memory      = 4096
  scsihw      = "virtio-scsi-single"
  boot        = "order=scsi0;ide2"
  onboot      = true

  ciuser  = var.user
  sshkeys = <<EOF
${file("~/.ssh/id_ed25519.pub")}
EOF

  disks {
    scsi {
      scsi0 {
        disk {
          storage = "local-lvm"
          size    = "100G"
        }
      }
    }
    ide {
      ide2 {
        cdrom {
          iso = "local:iso/vyos-2025.05.10-0018-rolling-generic-amd64.iso"
        }
      }
    }
  }
  network {
    firewall = false
    bridge   = "vmbr0"
    model    = "virtio"
  }
  network {
    firewall = false
    bridge   = "vmbr1"
    model    = "virtio"
  }
  #  connection {
  #    type     = "ssh"
  #    user     = "vyos"
  #    password = "vyos3200!"
  #    host     = "10.0.0.1"
  #  }
  #  provisioner "remote-exec" {
  #    inline = [
  #      "configure",
  #      "delete service ntp allow-client",
  #      "commit; save",
  #    ]
  #  }
}
