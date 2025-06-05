resource "proxmox_vm_qemu" "truenas_scale" {
  name        = "truenas"
  target_node = "pve1"
  cores       = 4
  clone       = var.vm_template_id
  full_clone  = true
  memory      = 8192
  scsihw      = "virtio-scsi-single"
  os_type     = "cloud-init"
  boot        = "order=scsi0;ide2"
  onboot      = true

  // NOTE: need to set this in the UI after anyways
  ipconfig0 = "ip=${var.truenas_ip},gw=${var.gateway_ip}"
  ciuser    = var.user
  sshkeys   = <<EOF
${file("~/.ssh/id_ed25519.pub")}
EOF

  disks {
    scsi {
      scsi0 {
        disk {
          storage = "local-lvm"
          size    = "32G"
        }
      }
      scsi1 {
        disk {
          storage = "local-lvm"
          size    = "250G"
        }
      }
    }
    ide {
      ide0 {
        cloudinit {
          storage = "local-lvm"
        }
      }
      ide2 {
        cdrom {
          iso = "local:iso/TrueNAS-SCALE-25.04.1.iso"
        }
      }
    }
  }
  network {
    firewall = true
    bridge   = "vmbr0"
    model    = "virtio"
  }
}
