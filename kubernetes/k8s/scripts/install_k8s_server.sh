#!/bin/bash
set -e  # Exit on any error
set -o pipefail  # Exit if any command in a pipe fails
exec 1> >(tee -a "/tmp/kubernetes_server_install.log") 2>&1

sudo firewall-cmd --permanent --add-port=6443/tcp  # API server
sudo firewall-cmd --permanent --add-port=2379-2380/tcp  # etcd
sudo firewall-cmd --permanent --add-port=10250/tcp  # Kubelet API
sudo firewall-cmd --permanent --add-port=10251/tcp  # kube-scheduler
sudo firewall-cmd --permanent --add-port=10257/tcp  # kube-controller-manager
sudo firewall-cmd --permanent --add-port=12000/tcp  # hubble
sudo firewall-cmd --permanent --add-port=9962-9964/tcp  # Cilium metrics
sudo firewall-cmd --permanent --add-port=4244/tcp  # Hubble UI
sudo firewall-cmd --reload

# Init Cluster
sudo kubeadm init \
	--pod-network-cidr=10.0.0.0/16 \
	--service-cidr=10.96.0.0/16 \
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

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.ipv4.conf.all.forwarding        = 1
EOF
sudo sysctl --system

# Cilium CLI
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

cilium install --version 1.16.6 \
	--set kubeProxyReplacement=true \
	--set l7Proxy=true \
	--set ingressController.enabled=true \
	--set ingressController.loadbalancerMode=dedicated \
	--set loadBalancer.l7.backend=envoy

cilium hubble enable --ui
# Hubble CLI
curl -L --remote-name-all https://github.com/cilium/hubble/releases/latest/download/hubble-linux-amd64.tar.gz
tar xzvf hubble-linux-amd64.tar.gz
sudo mv hubble /usr/local/bin

