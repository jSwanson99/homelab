resource "tls_private_key" "kubernetes_node_two" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "kubernetes_node_two" {
  private_key_pem = tls_private_key.kubernetes_node_two.private_key_pem
  subject {
    common_name  = "kubernetes_node_two"
    country      = "US"
    organization = "JonCorpIncLLC"
  }
  ip_addresses = ["127.0.0.1", split("/", var.kubernetes_node_two_ip)[0]]
}

resource "tls_locally_signed_cert" "kubernetes_node_two" {
  cert_request_pem      = tls_cert_request.kubernetes_node_two.cert_request_pem
  ca_private_key_pem    = var.ca_private_key_pem
  ca_cert_pem           = var.ca_cert_pem
  validity_period_hours = 43800
  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}
resource "proxmox_vm_qemu" "kubernetes_node_two" {
  depends_on = [
    proxmox_vm_qemu.kubernetes_server
  ]

  name        = "kubernetes-node-two"
  target_node = "pve"
  clone       = var.vm_template_id
  full_clone  = true
  cores       = 4
  memory      = 6144
  scsihw      = "virtio-scsi-single"
  os_type     = "cloud-init"
  boot        = "order=scsi0;ide2"

  ipconfig0 = "ip=${var.kubernetes_node_two_ip},gw=${var.gateway_ip}"
  ciuser    = var.user
  sshkeys   = <<EOF
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
    host        = split("/", var.kubernetes_node_two_ip)[0]
  }
  provisioner "remote-exec" {
    inline = [
      "echo 'export K3S_TOKEN=${data.external.k3s_node_token.result.token}' >> /etc/profile",
      "echo 'export K3S_URL=https://${split("/", var.kubernetes_server_ip)[0]}:6443' >> /etc/profile",
      "curl -sfL https://get.k3s.io | K3S_URL=https://${split("/", var.kubernetes_server_ip)[0]}:6443 K3S_TOKEN=${data.external.k3s_node_token.result.token} sh -"
    ]
  }
}

output "kubernetes_node_two_ip" {
  value = split("/", var.kubernetes_node_two_ip)[0]
}
