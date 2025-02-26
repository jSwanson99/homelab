#!/bin/bash
set -e  # Exit on any error
set -o pipefail  # Exit if any command in a pipe fails
exec 1> >(tee -a "/tmp/kubernetes_worker_install.log") 2>&1

# Cilium agent listens on 192.168.x.x not 0.0.0.0
# Health check was failing w/o this
