resource "tls_private_key" "kubernetes_server" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "kubernetes_server" {
  private_key_pem = tls_private_key.kubernetes_server.private_key_pem
  subject {
    common_name  = "kubernetes_server"
    country      = "US"
    organization = "JonCorpIncLLC"
  }
  ip_addresses = ["127.0.0.1", split("/", var.kubernetes_server_ip)[0]]
}

resource "tls_locally_signed_cert" "kubernetes_server" {
  cert_request_pem      = tls_cert_request.kubernetes_server.cert_request_pem
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

resource "proxmox_vm_qemu" "kubernetes_server" {
  depends_on = [
    postgresql_role.kubernetes_user,
    postgresql_database.kubernetes_db,
    postgresql_grant.database_privileges,
    postgresql_grant.schema_privileges
  ]
  name        = "kubernetes-server"
  target_node = "pve"
  clone       = var.vm_template_id
  full_clone  = true
  cores       = 2
  memory      = 4096
  scsihw      = "virtio-scsi-single"
  os_type     = "cloud-init"
  boot        = "order=scsi0;ide2"

  ipconfig0 = "ip=${var.kubernetes_server_ip},gw=${var.gateway_ip}"
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
    host        = split("/", var.kubernetes_server_ip)[0]
  }
  provisioner "remote-exec" {
    inline = [
      "sudo dnf install -y curl",
      "sudo mkdir -p /etc/rancher/k3s",
      "sudo mkdir -p /etc/ssl/certs",
    ]
  }
  provisioner "file" {
    content     = tls_locally_signed_cert.kubernetes_server.cert_pem
    destination = "/etc/ssl/certs/kubernetes_server.crt"
  }
  provisioner "file" {
    content     = tls_private_key.kubernetes_server.private_key_pem
    destination = "/etc/ssl/certs/kubernetes_server.key"
  }
  provisioner "file" {
    content     = var.ca_cert_pem
    destination = "/etc/ssl/certs/ca.crt"
  }
  provisioner "file" {
    content = templatefile("${path.module}/config/server.yaml.tftpl", {
      pg_user_kubernetes     = var.pg_user_kubernetes,
      pg_password_kubernetes = var.pg_password_kubernetes,
      pg_database_kubernetes = var.pg_database_kubernetes,
      pg_vault_ip            = split("/", var.pg_vault_ip)[0],
      cafile                 = "/etc/ssl/certs/ca.crt",
      certfile               = "/etc/ssl/certs/kubernetes_server.crt",
      keyfile                = "/etc/ssl/certs/kubernetes_server.key"
    })
    destination = "/etc/rancher/k3s/config.yaml"
  }
  provisioner "remote-exec" {
    inline = [
      "curl -sfL https://get.k3s.io | sh -s - server",
      "sudo firewall-cmd --add-port=6443/tcp --permanent",
      "sudo firewall-cmd --reload",
    ]
  }
}
data "external" "k3s_node_token" {
  depends_on = [proxmox_vm_qemu.kubernetes_server]
  program = [
    "ssh",
    "-o", "StrictHostKeyChecking=no",
    "root@${split("/", var.kubernetes_server_ip)[0]}",
    "cat /var/lib/rancher/k3s/server/node-token | jq -R '{token: .}'",
  ]
}
resource "null_resource" "node_labels" {
  depends_on = [
    proxmox_vm_qemu.kubernetes_server,
    proxmox_vm_qemu.kubernetes_node_one,
    proxmox_vm_qemu.kubernetes_node_two,
  ]

  connection {
    type        = "ssh"
    user        = var.user
    private_key = file("~/.ssh/id_ed25519")
    host        = split("/", var.kubernetes_server_ip)[0]
  }

  provisioner "remote-exec" {
    inline = [
      "kubectl label node kubernetes-node-one node-role.kubernetes.io/worker=true",
      "kubectl label node kubernetes-node-two node-role.kubernetes.io/worker=true",
    ]
  }
}

output "kubernetes_server_ip" {
  value = split("/", var.kubernetes_server_ip)[0]
}
output "kubernetes_node_token" {
  value = data.external.k3s_node_token.result.token
}
