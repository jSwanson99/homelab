# CoreDNS LXC Container
resource "proxmox_lxc" "jenkins" {
  target_node  = "pve"
  hostname     = "jenkins"
  clone = var.lxc_template_id
  unprivileged = true
  onboot       = true
  start        = true

  cores  = 4
  memory = 4096 

  rootfs {
    storage = "local-lvm" 
    size    = "64G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = var.jenkins_ip
    gw     = var.gateway_ip
  }

  provisioner "local-exec" {
    command = "sleep 10"
  }

   provisioner "remote-exec" {
    script = "${path.module}/../jenkins/provision.sh"
    connection {
      type     = "ssh"
      user     = var.user
      password = var.password
      host     = split("/", var.jenkins_ip)[0]
    }
  } 

  provisioner "remote-exec" {
    script = "${path.module}/../jenkins/startup.sh"
    connection {
      type     = "ssh"
      user     = var.user
      password = var.password
      host     = split("/", var.jenkins_ip)[0]
    }
  }
}

output "jenkins_ip" {
  value = split("/", var.jenkins_ip)[0]
    description = "Jenkins Server IP Address"
}
