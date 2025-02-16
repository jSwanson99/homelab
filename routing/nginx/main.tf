resource "proxmox_vm_qemu" "nginx" {
  name        = "nginx"
  target_node = "pve"
  clone       = var.vm_template_id
  full_clone  = true
  cores       = 2
  memory      = 4096
  scsihw      = "virtio-scsi-single"
  os_type     = "cloud-init"
  boot        = "order=scsi0;ide2"

  ipconfig0 = "ip=${var.nginx_ip},gw=${var.gateway_ip}"
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
    host        = split("/", var.nginx_ip)[0]
  }

  provisioner "remote-exec" {
    script = "${path.module}/provision.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /etc/pki/nginx",
      "mkdir -p /etc/pki/nginx/private",
      "mkdir -p /etc/nginx/ssl/certs",
      "mkdir -p /etc/pki/nginx/ca",
    ]
  }
  # {{{
  provisioner "file" {
    source      = "${path.module}/sign.sh"
    destination = "/etc/pki/nginx/sign.sh"
  }
  provisioner "file" {
    content     = tls_locally_signed_cert.intermediate_ca.cert_pem
    destination = "/etc/pki/nginx/ca/ca.crt"
  }
  provisioner "file" {
    content     = tls_private_key.intermediate_ca.private_key_pem
    destination = "/etc/pki/nginx/ca/ca.key"
  }
  provisioner "file" {
    content     = tls_locally_signed_cert.nginx.cert_pem
    destination = "/etc/pki/nginx/server.crt"
  }
  provisioner "file" {
    content     = tls_private_key.nginx.private_key_pem
    destination = "/etc/pki/nginx/private/server.key"
  } # }}}
  provisioner "file" {
    content = templatefile("${path.module}/nginx.conf", {
      coredns_ip   = split("/", var.coredns_ip)[0],
      ssl_cert_lua = file("${path.module}/ssl_cert.lua")
    })
    destination = "/usr/local/openresty/nginx/conf/nginx.conf"
  }
  provisioner "file" {
    source      = "${path.module}/nginx.service"
    destination = "/etc/systemd/system/nginx.service"
  }
  provisioner "remote-exec" {
    script = "${path.module}/start.sh"
  }
}

output "nginx_ip" {
  value = split("/", var.nginx_ip)[0]
}
