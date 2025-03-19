#!/bin/bash

cilium status --wait

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.7/config/manifests/metallb-native.yaml
kubectl wait --namespace metallb-system \
 --for=condition=ready pod \
 --selector=app=metallb \
 --timeout=90s

cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
 name: first-pool
 namespace: metallb-system
spec:
 addresses:
 - ${k8s_app_ip_range}
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
 name: l2-advert
 namespace: metallb-system
spec:
 ipAddressPools:
 - first-pool
EOF


kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "Waiting for initial Argo CD deployment..."
kubectl wait --for=condition=Available deployment -l app.kubernetes.io/part-of=argocd -n argocd --timeout=300s

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

kubectl patch service hubble-ui \
	-n kube-system \
	-p '{"spec": {"type": "LoadBalancer", "loadBalancerIP": "${hubble_ip}"}}'
kubectl patch svc argocd-server \
	-n argocd \
	-p '{"spec": {"type": "LoadBalancer", "loadBalancerIP": "${argocd_ip}"}}'

kubectl rollout restart deployment argocd-server argocd-repo-server -n argocd
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

