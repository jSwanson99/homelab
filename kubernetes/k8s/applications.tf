resource "null_resource" "bootstrap_k8s" {
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
    script = "${path.module}/scripts/install_dashboards.sh"
  }
}
