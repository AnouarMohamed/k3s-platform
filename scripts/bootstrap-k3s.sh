#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_DIR}"

if [[ -f ".env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source ".env"
  set +a
fi

K3S_NODE_NAME="${K3S_NODE_NAME:-ito-k3s-lab-01}"
K3S_PUBLIC_IP="${K3S_PUBLIC_IP:-}"

if [[ -z "${K3S_PUBLIC_IP}" ]]; then
  echo "K3S_PUBLIC_IP must be set in .env" >&2
  exit 1
fi

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server \
  --node-name ${K3S_NODE_NAME} \
  --tls-san ${K3S_PUBLIC_IP} \
  --disable traefik" sh -

sudo cp /etc/rancher/k3s/k3s.yaml ./kubeconfig
sudo chown "$(id -u):$(id -g)" ./kubeconfig
sed -i "s/127.0.0.1/${K3S_PUBLIC_IP}/g" ./kubeconfig

echo "K3s installed. Export KUBECONFIG=${REPO_DIR}/kubeconfig"
