CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64

if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi

curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin

rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

# Install Cilium with --set=ipam.operator.clusterPoolIPv4PodCIDRList="10.42.0.0/16" to match k3s default podCIDR 10.42.0.0/16.
cilium install --version 1.16.5 --set=ipam.operator.clusterPoolIPv4PodCIDRList="10.42.0.0/16" \
  --set kubeProxyReplacement=strict \
  --set k8sServiceHost=localhost \
  --set k8sServicePort=6443

cilium status --wait
