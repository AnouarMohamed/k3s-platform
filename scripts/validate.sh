#!/usr/bin/env bash
# Purpose: Provides a comprehensive health check and status report of the Kubernetes cluster.
# This script inspects platform components, applications, and security guardrails.
#
# Sections:
# 1. Cluster Status: Node health and API version.
# 2. Ingress & Certificates: Verify TLS and external access availability.
# 3. Component Health: Detailed status of ingress-nginx and application workloads.
# 4. Guardrails: Verification of ResourceQuotas, LimitRanges, and NetworkPolicies.

set -Eeuo pipefail

echo "=== 1. Cluster Infrastructure ==="
kubectl version --short || kubectl version
kubectl get nodes -o wide

echo
echo "=== 2. Global Resource Status ==="
kubectl get pods -A
kubectl get ingress -A
kubectl get certificates -A || true
kubectl get clusterissuer || true

echo
echo "=== 3. Ingress Controller Status ==="
# Verify that the NGINX Ingress Controller is running and has an IP assigned.
kubectl -n ingress-nginx get svc,pods

echo
echo "=== 4. Application Workload Health ==="
# Check the 'apps' namespace for deployments, services, ingresses, and persistent volume claims.
kubectl -n apps get deploy,svc,ingress,pvc

echo
echo "=== 5. Runtime Guardrails & Security ==="
# Verify that security and resource constraints are correctly applied.
# This ensures that no single application can consume all cluster resources
# and that network traffic is restricted according to the defined policies.
echo "-- Apps Namespace --"
kubectl -n apps get resourcequota,limitrange,serviceaccount,networkpolicy
echo "-- Data Namespace --"
kubectl -n data get resourcequota,limitrange,networkpolicy
