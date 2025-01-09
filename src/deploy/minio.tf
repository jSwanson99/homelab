resource "proxmox_lxc" "minio" {
  target_node  = "pve"
  hostname     = "minio"
  clone        = var.lxc_template_id
  unprivileged = true
  onboot       = true
  start        = true

  cores  = 2
  memory = 2048

  rootfs {
    storage = "local-lvm"
    size    = "128G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = var.minio_ip
    gw     = var.gateway_ip
  }

  connection {
    type        = "ssh"
    user        = var.user
    private_key = file("~/.ssh/id_ed25519")
    host        = split("/", var.minio_ip)[0]
  }

  provisioner "local-exec" {
    command = "sleep 10"
  }

  provisioner "remote-exec" {
    script = "${path.module}/../minio/provision.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../minio/minio.service"
    destination = "/etc/systemd/system/minio.service"
  }

  provisioner "file" {
    source      = "${path.module}/../minio/minio"
    destination = "/etc/default/minio"
  }

  provisioner "remote-exec" {
    script = "${path.module}/../minio/startup.sh"
  }
}

output "minio_ip" {
  value = split("/", var.minio_ip)[0]
}
