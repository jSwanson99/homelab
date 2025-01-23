#!/bin/bash
set -e  # Exit on any error
set -o pipefail  # Exit if any command in a pipe fails
exec 1> >(tee -a "/tmp/kubernetes_server_install.log") 2>&1

sudo firewall-cmd --permanent --add-port=6443/tcp  # API server
sudo firewall-cmd --permanent --add-port=2379-2380/tcp  # etcd
sudo firewall-cmd --permanent --add-port=10250/tcp  # Kubelet API
sudo firewall-cmd --permanent --add-port=10251/tcp  # kube-scheduler
sudo firewall-cmd --permanent --add-port=10252/tcp  # kube-controller-manager still needed?
sudo firewall-cmd --permanent --add-port=10257/tcp  # kube-controller-manager
sudo firewall-cmd --permanent --add-port=12000/tcp  # hubble
sudo firewall-cmd --permanent --add-port=8472/udp
sudo firewall-cmd --reload

# Init Cluster
sudo kubeadm init \
	--pod-network-cidr=10.244.0.0/16 \
	--skip-phases=addon/kube-proxy \
	--apiserver-advertise-address=192.168.1.30

export KUBECONFIG=/etc/kubernetes/admin.conf
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

cat <<EOF > /etc/modules-load.d/cilium.conf
xt_socket
xt_mark
xt_connmark
xt_set
EOF
sudo systemctl restart systemd-modules-load.service

# Helm
curl -LO https://get.helm.sh/helm-v3.17.0-linux-amd64.tar.gz
tar -zxvf helm-v3*.tar.gz
mv linux-amd64/helm /usr/local/bin/helm

# Cilium CNI
helm repo add cilium https://helm.cilium.io/
helm repo update
helm install cilium cilium/cilium \
	--namespace kube-system \
	--set kubeProxyReplacement=true \
	--set ipam.operator.clusterPoolIPv4PodCIDRList="10.244.0.0/16" \
	--set k8sServiceHost=192.168.1.30 \
	--set k8sServicePort=6443 \
	--set hubble.tls.auto.enabled=true \
	--set hubble.relay.enabled=true \
	--set hubble.ui.enabled=true \
	--set hubble.relay.tls.server.enabled=true

# Cilium CLI
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

cilium hubble enable --ui
# Hubble CLI
curl -L --remote-name-all https://github.com/cilium/hubble/releases/latest/download/hubble-linux-amd64.tar.gz
tar xzvf hubble-linux-amd64.tar.gz
sudo mv hubble /usr/local/bin

