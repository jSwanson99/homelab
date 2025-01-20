#!/bin/bash
set -e  # Exit on any error
set -o pipefail  # Exit if any command in a pipe fails
exec 1> >(tee -a "/tmp/kubernetes_install.log") 2>&1

sudo dnf install -y curl tar telnet iputils
sudo dnf clean all
sudo dnf update -y

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

# containerd
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y containerd.io
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# crictl to use containerd
cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.32/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.32/rpm/repodata/repomd.xml.key
EOF
sudo dnf makecache

sudo firewall-cmd --permanent --add-port=6443/tcp  # API server
sudo firewall-cmd --permanent --add-port=2379-2380/tcp  # etcd
sudo firewall-cmd --permanent --add-port=10250/tcp  # Kubelet API
sudo firewall-cmd --permanent --add-port=10251/tcp  # kube-scheduler
sudo firewall-cmd --permanent --add-port=10252/tcp  # kube-controller-manager still needed?
sudo firewall-cmd --permanent --add-port=10257/tcp  # kube-controller-manager
sudo firewall-cmd --reload

sudo dnf install -y kubelet kubeadm kubectl
sudo systemctl enable kubelet
sudo systemctl start kubelet

sudo kubeadm init phase preflight --dry-run
kubeadm config images pull

sudo kubeadm init \
	--pod-network-cidr=10.244.0.0/16 \
	--skip-phases=addon/kube-proxy \
	--apiserver-advertise-address=192.168.1.30
#	--cert-dir=/etc/ssl/certs

export KUBECONFIG=/etc/kubernetes/admin.conf
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
