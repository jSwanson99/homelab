#!/bin/bash
set -e  # Exit on any error
set -o pipefail  # Exit if any command in a pipe fails
exec 1> >(tee -a "/tmp/kubernetes_worker_install.log") 2>&1

sudo firewall-cmd --permanent --add-port=10250/tcp  # Kubelet API
sudo firewall-cmd --reload

# TODO kubeadm join
