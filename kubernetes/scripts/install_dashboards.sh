#!/bin/bash

set -e

cilium status --wait

# TODO can we put this in gitops
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


# TODO pin a version
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for initial Argo CD deployment..."
kubectl wait --for=condition=Available deployment -l app.kubernetes.io/part-of=argocd -n argocd --timeout=300s
echo "Initial deploy is ready"

echo "Patching argocd manifests"
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
  server.insecure: "true" # terminate tls @ gateway
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

echo "bounce argo after config changes"
kubectl rollout restart deployment -n argocd 
kubectl wait --for=condition=Available deployment -l app.kubernetes.io/part-of=argocd -n argocd --timeout=300s

echo "login to argocd and add repo"
kubectl exec -n argocd deploy/argocd-server -- argocd login localhost:8080 --insecure --plaintext \
	--username admin \
	--password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
# do we need this?
kubectl exec -n argocd deploy/argocd-server -- argocd repo add https://github.com/jSwanson99/homelab-gitops.git

echo "Configuring github sync"
kubectl apply -f /tmp/all_apps.yaml -n argocd

