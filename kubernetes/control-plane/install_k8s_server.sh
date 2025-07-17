#!/bin/bash
set -e  # Exit on any error
set -o pipefail  # Exit if any command in a pipe fails
exec 1> >(tee -a "/tmp/kubernetes_server_install.log") 2>&1

kubernetes_server_ip=$1

firewall-cmd --permanent --add-port=6443/tcp  # API server
firewall-cmd --permanent --add-port=2379-2380/tcp  # etcd
firewall-cmd --permanent --add-port=10251/tcp  # kube-scheduler
firewall-cmd --permanent --add-port=10257/tcp  # kube-controller-manager
firewall-cmd --permanent --add-port=12000/tcp  # hubble
firewall-cmd --permanent --add-port=80/tcp # Ingress traffic
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --reload

# Init Cluster
echo "Init server"
sudo kubeadm init \
	--pod-network-cidr=10.0.0.0/16 \
	--service-cidr=10.96.0.0/16 \
	--skip-phases=addon/kube-proxy \
	--apiserver-advertise-address="$kubernetes_server_ip"

export KUBECONFIG=/etc/kubernetes/admin.conf
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /root/.bashrc

cat <<EOF > /etc/modules-load.d/cilium.conf
xt_socket
xt_mark
xt_connmark
xt_set
EOF
sudo systemctl restart systemd-modules-load.service

echo "Install helm"
curl -LO https://get.helm.sh/helm-v3.17.0-linux-amd64.tar.gz
tar -zxvf helm-v3*.tar.gz
mv linux-amd64/helm /usr/local/bin/helm
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.ipv4.conf.all.forwarding        = 1
EOF
sudo sysctl --system

echo "Installing gateway crds"
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/experimental-install.yaml

echo "Install cillium cli"
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

echo "Install cilium"
cilium install --version 1.17.1 \
	--set kubeProxyReplacement=true \
	--set l7Proxy=true \
	--set l2announcements.enabled=true \
	--set k8sClientRateLimit.qps=10 \
	--set k8sClientRateLimit.burst=15 \
	--set ingressController.default=true \
	--set ingressController.loadbalancerMode=dedicated \
	--set loadBalancer.l7.backend=envoy \
	--set hostPort.enabled=true \
	--set bpf.masquerade=true \
  --set bpf.vlanBypass={0} \
  --set enableIPv4Masquerade=true \
  --set enableIdentityMark=true \
  --set ipam.mode=cluster-pool \
	--set k8sServiceHost=$kubernetes_server_ip \
	--set k8sServicePort=6443 \
  --set prometheus.enabled=true \
  --set operator.prometheus.enabled=true \
	--set gatewayAPI.enabled=true

echo "Enable hubble"
cilium hubble enable --ui

echo "Install hubble cli"
curl -L --remote-name-all https://github.com/cilium/hubble/releases/latest/download/hubble-linux-amd64.tar.gz
tar xzvf hubble-linux-amd64.tar.gz
sudo mv hubble /usr/local/bin

echo "Setup ClusterIssuer Key Pair"
kubectl create ns cert-manager
kubectl create secret tls cluster-issuer-keypair \
  --cert=/etc/kubernetes/pki/ca.crt \
  --key=/etc/kubernetes/pki/ca.key \
  --namespace=cert-manager
