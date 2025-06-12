resource "proxmox_vm_qemu" "squid" {
  name        = "squid"
  target_node = "pve1"
  clone       = var.vm_template_id
  full_clone  = true
  cores       = 2
  memory      = 4096
  scsihw      = "virtio-scsi-single"
  os_type     = "cloud-init"
  boot        = "order=scsi0"
  onboot      = true

  ipconfig0 = "ip=${var.squid_ip},gw=${var.gateway_ip}"
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
    host        = split("/", var.squid_ip)[0]
  }

  provisioner "remote-exec" {
    script = "${path.module}/provision.sh"
  }

  provisioner "file" {
    source      = "${path.module}/squid.conf"
    destination = "/etc/squid/squid.conf"
  }

  provisioner "file" {
    content     = "${tls_locally_signed_cert.squid.cert_pem}${tls_locally_signed_cert.intermediate_ca.cert_pem}"
    destination = "/etc/squid/squid-cert.pem"
  }
  provisioner "file" {
    content     = tls_private_key.squid.private_key_pem
    destination = "/etc/squid/squid-key.pem"
  }
  provisioner "file" {
    content     = tls_locally_signed_cert.intermediate_ca.cert_pem
    destination = "/etc/squid/squid-ca.pem"
  }
  provisioner "file" {
    content     = tls_private_key.intermediate_ca.private_key_pem
    destination = "/etc/squid/squid-ca-key.pem"
  }

  provisioner "remote-exec" {
    script = "${path.module}/start.sh"
  }
}

output "squid_ip" {
  value = split("/", var.squid_ip)[0]
}
