# Architecture

## Executive Summary

This repository defines a production-oriented K3s platform for ITO servers. It keeps the operational control of a small VPS-style deployment while adopting Kubernetes primitives that are useful in production: Deployments, Services, Ingress, Secrets, PVCs, probes, NetworkPolicy, Pod Security Admission labels, resource guardrails, and Git-friendly desired state.

## Target Model

```mermaid
flowchart TB
  dns[DNS / Public Users] --> lb[K3s ServiceLB / Public IP]
  lb --> ingress[ingress-nginx Controller]
  ingress --> routes[Kubernetes Ingress Objects]
  routes --> apps[apps namespace]
  apps --> services[Services]
  services --> pods[Deployments / Pods]
  pods --> pvc[(PVC / local-path-retain)]
  cert[cert-manager] --> ingress
  issuer[ClusterIssuer] --> cert
  git[Git repository] --> kustomize[Kustomize root]
  kustomize --> cluster[K3s API Server]
```

## Namespace Design

| Namespace | Responsibility | Why it exists |
| --- | --- | --- |
| `ingress-nginx` | Helm-managed ingress controller | Public HTTP/S entry layer. |
| `cert-manager` | Helm-managed certificate controller | ACME automation and certificate lifecycle. |
| `apps` | Application workloads | Keeps business workloads separate from controllers. |
| `data` | Dedicated data workloads when split out later | Reserved for stricter data isolation. |
| `ops` | Operations and observability | Holds platform settings, Prometheus, Alertmanager, Grafana, Loki, and cluster-state collectors. |
| `node-observability` | Node-level observability | Holds hostPath collectors such as Promtail and node-exporter. |
| `edge` | Future edge helpers | Reserved for custom edge tools if the architecture grows. |

## Ingress Strategy

K3s is installed with bundled Traefik disabled and ingress-nginx installed by Helm. This keeps the edge explicit and familiar for operators coming from Nginx-based server routing.

The Ingress model replaces Nginx `server{}` blocks with Kubernetes `Ingress` resources:

| Nginx concept | Kubernetes equivalent |
| --- | --- |
| `server_name` | `spec.rules[].host` |
| `proxy_pass` | `Service` backend |
| Certbot webroot | cert-manager HTTP-01 solver |
| auth include | ingress annotations, external auth, VPN, or app auth |
| rate-limit include | ingress-nginx rate-limit annotations |
| security headers | ingress-nginx config, app headers, or policy |

Public hostnames and the selected cert-manager issuer are centralized in `platform/settings.yaml` and injected by Kustomize replacements.

## TLS Strategy

cert-manager owns certificate lifecycle. The repository defines:

- `letsencrypt-staging` for validation.
- `letsencrypt-production` for real public certificates.

The selected issuer comes from `platform/settings.yaml`. `make apply` blocks example hostnames and email addresses so production apply requires deliberate values.

## Storage Strategy

The default StorageClass is `local-path-retain`:

```yaml
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

This is acceptable for a small single-server K3s deployment when the operator accepts node-local storage risk and has external backups. The repo includes Restic CronJobs for off-node database and PVC backups. For stronger production resilience, also evaluate:

- Longhorn for replicated block storage.
- managed databases outside the cluster.
- Velero snapshots for cluster-level restore.

## Network Policy Strategy

The network model is default-deny for ingress and egress in `apps` and `data`.

Allowed traffic is specific:

- ingress-nginx reaches only frontend pods on their published ports.
- app frontends reach only their matching database pods on TCP 3306.
- pods reach kube-dns on TCP/UDP 53.
- selected apps reach public web endpoints on TCP 80/443.
- selected apps reach SMTP endpoints on TCP 25/465/587.
- backup jobs reach their database targets and S3-compatible HTTPS endpoints.
- Jenkins reaches Git SSH on TCP 22.
- labelled Jenkins agents reach Jenkins TCP 50000.

There is no namespace-wide internal allow.

## Application Mapping

| Service | K3s object set |
| --- | --- |
| WordPress | Deployment, MySQL Deployment, Services, Ingress, PVCs |
| Jenkins | Deployment, Service, Ingress, PVC |
| GLPI | Deployment, Service, Ingress, PVC |
| Superset | Deployment, Service, Ingress, PVC |
| Passbolt | Passbolt Deployment, MariaDB Deployment, Services, Ingress, PVCs |
| Portainer | Deployment, Service, Ingress, PVC |

## Production Upgrade Path

The next architectural upgrades are:

- restore automation for the remaining stateful apps.
- ingress external auth for admin surfaces.
- CI checks with kubeconform and policy-as-code.
- per-server overlays if the same repo manages staging and production.
- Cilium if FQDN egress enforcement becomes mandatory.
