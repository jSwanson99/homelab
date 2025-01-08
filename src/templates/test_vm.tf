resource "proxmox_vm_qemu" "TEMPLATE" {
  name        = "TEMPLATE"
  target_node = "pve"
  clone       = var.vm_template_id
  cores       = 2
  memory      = 2048
  scsihw      = "virtio-scsi-single"
  os_type     = "cloud-init"
  boot        = "order=scsi0;ide2"

  ipconfig0  = "ip=${var.TEMPLATE_ip},gw=${var.gateway_ip}"
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
    connection {
      type     = "ssh"
      user     = var.user
      password = var.password
      host     = split("/", var.gitlab_ip)[0]
    }
   provisioner "remote-exec" {
    script = "${path.module}/../gitlab/provision.sh"
  }
}

output "TEMPLATE_ip" {
  value = split("/", var.TEMPLATE_ip)[0]
}
