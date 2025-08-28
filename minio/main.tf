resource "proxmox_vm_qemu" "minio" {
  name        = "minio"
  target_node = "pve1"
  cores       = 4
  clone       = var.vm_template_id
  full_clone  = true
  memory      = 8192
  scsihw      = "virtio-scsi-single"
  os_type     = "cloud-init"
  boot        = "order=scsi0"
  onboot      = true

  ipconfig0 = "ip=${var.minio_ip},gw=${var.gateway_ip}"
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
    host        = split("/", var.minio_ip)[0]
  }
  provisioner "remote-exec" {
    script = "${path.module}/provision.sh"
  }
  provisioner "file" {
    content     = tls_locally_signed_cert.minio.cert_pem
    destination = "/etc/minio/pki/public.crt"
  }
  provisioner "file" {
    content     = tls_private_key.minio.private_key_pem
    destination = "/etc/minio/pki/private.key"
  }
  provisioner "file" {
    content     = var.ca_cert_pem
    destination = "/etc/minio/pki/CAs/tf-ca.crt"
  }
  provisioner "file" {
    source      = "${path.module}/otelcol.yaml"
    destination = "/etc/otelcol-contrib/config.yaml"
  }
  provisioner "file" {
    source      = "${path.module}/minio.service"
    destination = "/usr/lib/systemd/system/minio.service"
  }
  provisioner "file" {
    content = templatefile("${path.module}/minio.env", {
      minio_admin_user = var.minio_admin_user
      minio_admin_pw   = var.minio_admin_pw
      minio_ip         = split("/", var.minio_ip)[0]
    })
    destination = "/etc/default/minio"
  }
  provisioner "remote-exec" {
    script = "${path.module}/start.sh"
  }
}
