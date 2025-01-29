#
# A k8s cluster made with kubeadm init
# - Cilium for networking
# - Hubble for observability
# - MetalLB for assigning external ips

module "server" {
  source               = "./control-plane"
  vm_template_id       = var.vm_template_id
  user                 = var.user
  gateway_ip           = var.gateway_ip
  kubernetes_server_ip = var.kubernetes_server_ip
  ca_private_key_pem   = var.ca_private_key_pem
  ca_cert_pem          = var.ca_cert_pem
}
module "worker_one" {
  source             = "./worker"
  node_name          = "worker-one"
  vm_template_id     = var.vm_template_id
  kubernetes_node_ip = var.kubernetes_node_one_ip
  gateway_ip         = var.gateway_ip
  user               = var.user
  join_cmd           = module.server.join_cmd
}
module "worker_two" {
  source             = "./worker"
  node_name          = "worker-two"
  vm_template_id     = var.vm_template_id
  kubernetes_node_ip = var.kubernetes_node_two_ip
  gateway_ip         = var.gateway_ip
  user               = var.user
  join_cmd           = module.server.join_cmd
}

resource "null_resource" "bootstrap_k8s" {
  depends_on = [
    module.server,
    module.worker_one,
    module.worker_two,
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

