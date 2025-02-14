resource "proxmox_vm_qemu" "mitm" {
  name        = "mitm"
  target_node = "pve"
  clone       = var.vm_template_id
  full_clone  = true
  cores       = 2
  memory      = 4096
  scsihw      = "virtio-scsi-single"
  os_type     = "cloud-init"
  boot        = "order=scsi0;ide2"

  ipconfig0 = "ip=${var.forward_proxy_ip},gw=${var.gateway_ip}"
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
    type        = "ssh"
    user        = var.user
    private_key = file("~/.ssh/id_ed25519")
    host        = split("/", var.forward_proxy_ip)[0]
  }

  provisioner "remote-exec" {
    script = "${path.module}/provision.sh"
  }
  provisioner "file" {
    source      = "${path.module}/config.yaml"
    destination = "/etc/mitmproxy/config.yaml"
  }
  provisioner "file" {
    source      = "${path.module}/mitm.service"
    destination = "/etc/systemd/system/mitmproxy.service"
  }
  provisioner "remote-exec" {
    script = "${path.module}/start.sh"
  }
}
