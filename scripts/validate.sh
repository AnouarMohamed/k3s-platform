#!/usr/bin/env bash
set -Eeuo pipefail

kubectl version --short || kubectl version
kubectl get nodes -o wide
kubectl get pods -A
kubectl get ingress -A
kubectl get certificates -A || true
kubectl get clusterissuer || true

echo
echo "Ingress controller:"
kubectl -n ingress-nginx get svc,pods

echo
echo "Application health:"
kubectl -n apps get deploy,svc,ingress,pvc
