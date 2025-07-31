#!/bin/bash

set -e

cilium status --wait

# Primarily here so that if things break on a rebuild,
# at least there is a reachable UI for argo without extra work
cat <<EOF | kubectl apply -n argocd -f -
apiVersion: "cilium.io/v2alpha1"
kind: CiliumLoadBalancerIPPool
metadata:
  name: main-pool
spec:
  blocks:
  - start: ${ip_range_start}
    stop: ${ip_range_end}
EOF


kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for initial Argo CD deployment..."
kubectl wait --for=condition=Available deployment -l app.kubernetes.io/part-of=argocd -n argocd --timeout=300s

# Enable otel for argocd
cat <<EOF | kubectl apply -n argocd -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cmd-params-cm
  labels:
    app.kubernetes.io/name: argocd-cmd-params-cm
    app.kubernetes.io/part-of: argocd
data:
  otlp.address: "otelcol.jds.net:4317"
  otlp.insecure: "true"
  server.insecure: "true" # terminal tls @ gateway TODO something is broken here, needed to patch deploy last time
EOF

# Avoid argo trying to prune CiliumIdentity
kubectl patch configmap argocd-cm -n argocd --type merge -p '
data:
  repositories: |
    - url: https://github.com/jSwanson99/homelab-gitops
      type: git
  resource.exclusions: |
    - apiGroups:
      - cilium.io
      kinds:
      - CiliumIdentity
      clusters:
      - "*"
'

kubectl rollout restart deployment -n argocd 
kubectl wait --for=condition=Available deployment -l app.kubernetes.io/part-of=argocd -n argocd --timeout=300s

echo "setup argo cli, gitops repo"
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm -f argocd-linux-amd64
argocd login ${argocd_ip} --insecure \
	--username admin \
	--password $(argocd admin initial-password -n argocd | head -n 1)
argocd repo add https://github.com/jSwanson99/homelab-gitops.git

echo "Configuring github sync"
kubectl apply -f /tmp/all_apps.yaml -n argocd

