#!/usr/bin/env bash
# Purpose: Bootstraps a K3s cluster on a target node and prepares a local kubeconfig.
# This script automates the installation of K3s with specific flags required for this platform.
#
# Environment Variables (usually loaded from .env):
#   K3S_NODE_NAME: The name to assign to the K3s node (defaults to ito-k3s-prod-01).
#   K3S_PUBLIC_IP: The public IP of the node. Required for TLS SAN and remote access.

set -Eeuo pipefail

# Ensure we are in the repository root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_DIR}"

# Load environment variables from .env if it exists
if [[ -f ".env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source ".env"
  set +a
fi

# Set defaults or validate required variables
K3S_NODE_NAME="${K3S_NODE_NAME:-ito-k3s-prod-01}"
K3S_PUBLIC_IP="${K3S_PUBLIC_IP:-}"

if [[ -z "${K3S_PUBLIC_IP}" ]]; then
  echo "Error: K3S_PUBLIC_IP must be set in .env" >&2
  exit 1
fi

# Install K3s using the official installer script.
# Flags explained:
#   --node-name: Sets the internal node name.
#   --tls-san: Adds the public IP to the API server certificate so we can use kubectl remotely.
#   --disable traefik: We disable the default Traefik ingress to use our own ingress-nginx setup.
echo "Installing K3s on $(hostname)..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
  --node-name ${K3S_NODE_NAME} \
  --tls-san ${K3S_PUBLIC_IP} \
  --disable traefik" sh -

# Prepare local kubeconfig for administrative access.
# We copy the K3s-generated config and fix permissions.
echo "Configuring local kubeconfig..."
sudo cp /etc/rancher/k3s/k3s.yaml ./kubeconfig
sudo chown "$(id -u):$(id -g)" ./kubeconfig

# Replace the loopback address with the public IP so the config works from outside the node.
sed -i "s/127.0.0.1/${K3S_PUBLIC_IP}/g" ./kubeconfig

echo "K3s installation complete."
echo "Export KUBECONFIG=${REPO_DIR}/kubeconfig to start using the cluster."
