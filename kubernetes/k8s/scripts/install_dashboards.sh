#!/bin/bash

# MetalLB for external IPs
cilium status --wait

# Unclear why the below isnt working
#helm repo add metallb https://metallb.github.io/metallb
#helm install metallb metallb/metallb --namespace metallb-system --create-namespace
#kubectl wait --namespace metallb-system \
#  --for=condition=ready pod \
#  --selector=app.kubernetes.io/name=metallb \
#  --timeout=120s

# Functionalish Alternative
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
 - 192.168.1.240-192.168.1.250 
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


# Change from ClusterIP -> Loadbalancer so its accessible via static ip outside cluster
kubectl patch service hubble-ui \
	-n kube-system \
	-p '{"spec": {"type": "LoadBalancer", "loadBalancerIP": "192.168.1.245"}}'
