resource "proxmox_vm_qemu" "kubernetes_node" {
  name        = var.node_name
  target_node = var.target_node
  clone       = var.vm_template_id
  full_clone  = true
  cores       = var.cpu
  memory      = var.mem
  scsihw      = "virtio-scsi-single"
  os_type     = "cloud-init"
  boot        = "order=scsi0"

  ipconfig0 = "ip=${var.kubernetes_node_ip},gw=${var.gateway_ip}"
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
    bridge = "vmbr0"
    model  = "virtio"
  }
  connection {
    type        = "ssh"
    user        = var.user
    private_key = file("~/.ssh/id_ed25519")
    host        = split("/", var.kubernetes_node_ip)[0]
  }
  provisioner "file" {
    source      = "${path.module}/kubelet-config.yaml"
    destination = "/var/lib/kubelet/config.yaml"
  }
  provisioner "remote-exec" {
    script = "${path.module}/../scripts/install_k8s.sh"
  }
  provisioner "remote-exec" {
    script = "${path.module}/install_k8s_worker.sh"
  }
  provisioner "remote-exec" {
    inline = [var.join_cmd]
  }
}

output "kubernetes_node_ip" {
  value = split("/", var.kubernetes_node_ip)[0]
}
