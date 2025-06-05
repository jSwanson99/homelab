resource "proxmox_vm_qemu" "coredns" {
  name        = "coredns"
  target_node = "pve"
  clone       = var.vm_template_id
  full_clone  = true
  cores       = 2
  memory      = 4096
  scsihw      = "virtio-scsi-single"
  os_type     = "cloud-init"
  boot        = "order=scsi0;ide2"
  onboot      = true

  ipconfig0 = "ip=${var.coredns_ip},gw=${var.gateway_ip}"
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
    host        = split("/", var.coredns_ip)[0]
  }

  provisioner "remote-exec" {
    script = "${path.module}/provision.sh"
  }
  provisioner "file" {
    content     = var.corefile
    destination = "/etc/coredns/Corefile"
  }
  provisioner "file" {
    source      = "${path.module}/otelcol.yaml"
    destination = "/etc/otelcol-contrib/config.yaml"
  }
  provisioner "file" {
    source      = "${path.module}/coredns.service"
    destination = "/etc/systemd/system/coredns.service"
  }
  provisioner "remote-exec" {
    script = "${path.module}/start.sh"
  }
}

output "coredns_ip" {
  value = split("/", var.coredns_ip)[0]
}
