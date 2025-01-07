resource "proxmox_vm_qemu" "gitlab" {
  name        = "gitlab"
  target_node = "pve"
  clone       = var.vm_template_id
  cores       = 2
  memory      = 2048
  scsihw      = "virtio-scsi-single"
  os_type     = "cloud-init"
  boot        = "order=scsi0;ide2"

  ipconfig0  = "ip=${var.gitlab_ip},gw=${var.gateway_ip}"
  ciuser     = var.user
  cipassword = var.password
  sshkeys    = <<EOF
${var.ssh_public_key}
EOF

  disks {
    scsi {
      scsi0 {
        disk {
          storage = "local-lvm"
          size    = "32G"
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
          iso = "local:iso/Rocky-9.4-x86_64-minimal.iso"
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

output "gitlab_ip" {
  value = split("/", var.gitlab_ip)[0]
}
