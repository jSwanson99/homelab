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
  target_node        = "pve"
  node_name          = "worker-one"
  vm_template_id     = var.vm_template_id
  kubernetes_node_ip = var.kubernetes_node_one_ip
  gateway_ip         = var.gateway_ip
  user               = var.user
  join_cmd           = module.server.join_cmd
  cpu                = 6
  mem                = 8192
}
module "worker_two" {
  source             = "./worker"
  target_node        = "pve"
  node_name          = "worker-two"
  vm_template_id     = var.vm_template_id
  kubernetes_node_ip = var.kubernetes_node_two_ip
  gateway_ip         = var.gateway_ip
  user               = var.user
  join_cmd           = module.server.join_cmd
  cpu                = 6
  mem                = 8192
}
module "worker_three" {
  source             = "./worker"
  target_node        = "pve1"
  node_name          = "worker-three"
  vm_template_id     = var.vm_template_id
  kubernetes_node_ip = var.kubernetes_node_three_ip
  gateway_ip         = var.gateway_ip
  user               = var.user
  join_cmd           = module.server.join_cmd
  cpu                = 8
  mem                = 8192
}

// Once the cluster is ready, install hubble, argocd, dashboard
resource "null_resource" "bootstrap_k8s" {
  depends_on = [
    module.server,
    module.worker_one,
    module.worker_two,
    module.worker_three,
  ]
  connection {
    type        = "ssh"
    user        = var.user
    private_key = file("~/.ssh/id_ed25519")
    host        = split("/", var.kubernetes_server_ip)[0]
  }
  provisioner "file" {
    source      = "${path.module}/all_apps.yaml"
    destination = "/tmp/all_apps.yaml"
  }
  provisioner "file" {
    # TODO this will change, so that git repo to install
    # is configurable by the module
    content = templatefile("${path.module}/scripts/install_dashboards.sh", {
      argocd_ip      = split("/", var.argocd_ip)[0]
      hubble_ip      = split("/", var.hubble_ip)[0]
      ip_range_start = var.k8s_app_ip_range[0]
      ip_range_end   = var.k8s_app_ip_range[1]
    })
    destination = "/tmp/install_dashboards.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_dashboards.sh",
      "bash /tmp/install_dashboards.sh"
    ]
  }
}

data "external" "argocd_pw" {
  depends_on = [null_resource.bootstrap_k8s]
  program = [
    "ssh",
    "-o", "StrictHostKeyChecking=no",
    "root@${split("/", var.kubernetes_server_ip)[0]}",
    "argocd admin initial-password -n argocd | head -n 1 | jq '{value: .}' -R -c",
  ]
}
