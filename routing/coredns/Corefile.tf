# Update the existing Coredns service's corefile and bounces
resource "null_resource" "Corefile" {
  depends_on = [
    proxmox_vm_qemu.coredns
  ]
  triggers = {
    hosts = var.corefile
  }
  connection {
    type        = "ssh"
    user        = var.user
    private_key = file("~/.ssh/id_ed25519")
    host        = split("/", var.coredns_ip)[0]
  }
  provisioner "file" {
    content     = var.corefile
    destination = "/etc/coredns/Corefile"
  }
  provisioner "remote-exec" {
    inline = [
      "systemctl restart coredns"
    ]
  }
}
