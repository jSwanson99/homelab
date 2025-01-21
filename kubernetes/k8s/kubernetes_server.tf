resource "proxmox_vm_qemu" "kubernetes_server" {
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
  # Place CA info in conventional location to allow k8s
  # to sign keys as needed
  provisioner "remote-exec" {
    inline = ["mkdir -p /etc/kubernetes/pki"]
  }
  provisioner "file" {
    content     = var.ca_cert_pem
    destination = "/etc/kubernetes/pki/ca.crt"
  }
  provisioner "file" {
    content     = var.ca_private_key_pem
    destination = "/etc/kubernetes/pki/ca.key"
  }
  provisioner "remote-exec" {
    script = "${path.module}/scripts/install_k8s.sh"
  }
  provisioner "remote-exec" {
    script = "${path.module}/scripts/install_k8s_server.sh"
  }
}
data "external" "k8s_join_cmd" {
  depends_on = [proxmox_vm_qemu.kubernetes_server]
  program = [
    "ssh",
    "-o", "StrictHostKeyChecking=no",
    "root@${split("/", var.kubernetes_server_ip)[0]}",
    "kubeadm token create --print-join-command | jq -R '{token: .}'",
  ]
}

output "kubernetes_server_ip" {
  value = split("/", var.kubernetes_server_ip)[0]
}
