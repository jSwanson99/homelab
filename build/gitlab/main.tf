resource "proxmox_vm_qemu" "gitlab" {
  name        = "gitlab"
  target_node = "pve1"
  clone       = var.vm_template_id
  full_clone  = true
  cores       = 4
  memory      = 8192
  scsihw      = "virtio-scsi-single"
  os_type     = "cloud-init"
  boot        = "order=scsi0"
  onboot      = true

  ipconfig0 = "ip=${var.gitlab_ip},gw=${var.gateway_ip}"
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
    host        = split("/", var.gitlab_ip)[0]
  }

  provisioner "remote-exec" {
    script = "${path.module}/provision.sh"
  }
  provisioner "file" {
    content     = tls_locally_signed_cert.gitlab.cert_pem
    destination = "/etc/gitlab/ssl/gitlab.jds.net.crt"
  }
  provisioner "file" {
    content     = tls_private_key.gitlab.private_key_pem
    destination = "/etc/gitlab/ssl/gitlab.jds.net.key"
  }
  provisioner "file" {
    source      = "${path.module}/gitlab.rb"
    destination = "/etc/gitlab/gitlab.rb"
  }
  provisioner "remote-exec" {
    script = "${path.module}/start.sh"
  }
}

output "gitlab_ip" {
  value = split("/", var.gitlab_ip)[0]
}

data "external" "gitlab_pw" {
  depends_on = [proxmox_vm_qemu.gitlab]
  program = [
    "ssh",
    "-o", "StrictHostKeyChecking=no",
    "root@${split("/", var.gitlab_ip)[0]}",
    "cat /etc/gitlab/initial_root_password | grep 'Password:' | sed 's/Password: //' | jq -R -c '{value: .}'"
  ]
}

resource "null_resource" "bootstrap_gitlab" {
  depends_on = [
    proxmox_vm_qemu.gitlab
  ]
  triggers = {
    vm_id     = proxmox_vm_qemu.gitlab.id
    gitlab_ip = split("/", var.gitlab_ip)[0]
    user      = var.user
  }
  connection {
    type        = "ssh"
    user        = self.triggers.user
    private_key = file("~/.ssh/id_ed25519")
    host        = self.triggers.gitlab_ip
  }

  provisioner "file" {
    source      = "${path.module}/setup.rb"
    destination = "/tmp/setup.rb"
  }
  provisioner "file" {
    source      = "${path.module}/setup.sh"
    destination = "/tmp/setup.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup.sh",
      "/tmp/setup.sh '${var.github_token}",
      "rm /tmp/setup.sh",
      "rm /tmp/setup.rb",
    ]
  }
}

data "external" "gitlab_token" {
  depends_on = [null_resource.bootstrap_gitlab]
  program = [
    "ssh",
    "-o", "StrictHostKeyChecking=no",
    "-i", "~/.ssh/id_ed25519",
    "${var.user}@${split("/", var.gitlab_ip)[0]}",
    "gitlab-rails runner - <<< 'user=User.find_by(username:\"root\");puts user.personal_access_tokens.find_by(name:\"terraform-token\")&.token||user.personal_access_tokens.create!(name:\"terraform-token\",scopes:[\"api\"],expires_at:1.year.from_now).token' | jq -R '{token: .}'"
  ]
}
