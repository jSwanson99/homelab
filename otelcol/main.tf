resource "null_resource" "otelcol" {
  #depends_on = []
  #triggers = {}
  connection {
    type        = "ssh"
    user        = var.user
    private_key = file("~/.ssh/id_ed25519")
    host        = var.target_ip
  }
  provisioner "remote-exec" {
    script = "${path.module}/install.sh"
  }
  provisioner "file" {
    content = templatefile("${path.module}/config.yaml", {
      systemd_unit = var.systemd_unit,
      target_ip    = split("/", var.target_ip)[0],
    })
    destination = "/etc/otelcol-contrib/config.yaml"
  }
  provisioner "remote-exec" {
    inline = [
      "systemctl restart otelcol-contrib"
    ]
  }
}
