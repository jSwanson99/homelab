resource "proxmox_lxc" "minio" {
  target_node  = "pve"
  hostname     = "minio"
  clone = var.lxc_template_id 
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

  provisioner "local-exec" {
    command = "sleep 10"
  }

   provisioner "remote-exec" {
    script = "${path.module}/../minio/provision.sh"
    connection {
      type     = "ssh"
      user     = var.user
      password = var.password
      host     = split("/", var.minio_ip)[0]
    }
  } 

  provisioner "file" {
    source      = "${path.module}/../minio/minio.service"
    destination = "/etc/systemd/system/minio.service"

    connection {
      type     = "ssh"
      user     = var.user
      password = var.password
      host     = split("/", var.minio_ip)[0]
    }
  }

  provisioner "file" {
    source      = "${path.module}/../minio/minio"
    destination = "/etc/default/minio"

    connection {
      type     = "ssh"
      user     = var.user
      password = var.password
      host     = split("/", var.minio_ip)[0]
    }
  }

  provisioner "remote-exec" {
    script = "${path.module}/../minio/startup.sh"

    connection {
      type     = "ssh"
      user     = var.user
      password = var.password
      host     = split("/", var.minio_ip)[0]
    }
  }
}

output "minio_ip" {
  value = split("/", var.minio_ip)[0]
}
