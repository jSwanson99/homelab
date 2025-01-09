resource "proxmox_lxc" "coredns" {
  target_node  = "pve"
  hostname     = "coredns"
  clone        = var.lxc_template_id
  unprivileged = true
  onboot       = true
  start        = true

  cores  = 1
  memory = 512

  rootfs {
    storage = "local-lvm"
    size    = "32G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = var.coredns_ip
    gw     = var.gateway_ip
  }

  connection {
    type        = "ssh"
    user        = var.user
    private_key = file("~/.ssh/id_ed25519")
    host        = split("/", var.coredns_ip)[0]
  }

  provisioner "local-exec" {
    command = "sleep 10"
  }

  provisioner "remote-exec" {
    script = "${path.module}/../coredns/provision.sh"
  }

  provisioner "file" {
    content = templatefile("${path.module}/../coredns/Corefile.tftpl", {
      minio_ip = split("/", var.minio_ip)[0]
    })
    destination = "/etc/coredns/Corefile"
  }

  provisioner "file" {
    source      = "${path.module}/../coredns/coredns.service"
    destination = "/etc/systemd/system/coredns.service"
  }

  provisioner "remote-exec" {
    script = "${path.module}/../coredns/startup.sh"
  }
}

output "coredns_ip" {
  value       = split("/", var.coredns_ip)[0]
  description = "CoreDNS Server IP Address"
}
