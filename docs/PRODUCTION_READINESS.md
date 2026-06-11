# Production Readiness

## Position

This repository is a production-oriented K3s configuration set. The manifests are structured for real server use, but production readiness is only complete when the operator supplies real domains, secrets, backups, monitoring, and access controls.

The repo now treats unsafe defaults as deployment blockers:

- `make apply` refuses example domains and `admin@example.com`.
- `make secrets` refuses empty or placeholder secret values.
- `make check` renders the tree and rejects floating `latest` images.
- app images use pinned tags with digests.
- NetworkPolicy defaults to deny ingress and egress.

## Readiness Matrix

| Area | Current repo state | Operator must provide |
| --- | --- | --- |
| Cluster | K3s bootstrap, Traefik disabled | HA decision or accepted single-node risk |
| Ingress | ingress-nginx LoadBalancer Service | public DNS and firewall rules |
| TLS | cert-manager staging and production issuers | real ACME email and successful issuance checks |
| Settings | central `platform/settings.yaml` | real hostnames before apply |
| Secrets | `.env`-driven bootstrap with placeholder rejection | SOPS, Sealed Secrets, or External Secrets for GitOps |
| Storage | retained local-path PVCs | backup target, restore drills, or stronger storage backend |
| Network | default-deny plus per-app allow rules | CNI enforcement verification on the server |
| Runtime | service accounts, token automount disabled, resource limits | ongoing capacity monitoring |
| Images | pinned tags with manifest digests | vulnerability scanning and update cadence |
| Operations | Makefile, scripts, docs, runbooks | incident ownership and maintenance windows |

## Production Gate

Do not cut over a service until these are true:

1. `platform/settings.yaml` contains real production domains and email.
2. `.env` contains real secret values and is not committed.
3. `make check` passes.
4. `make secrets` has created required runtime Secrets.
5. `kubectl diff -k .` has been reviewed.
6. cert-manager can issue the certificate for the host.
7. the app has a tested backup and restore process.
8. DNS rollback is documented.
9. monitoring can detect pod, ingress, certificate, disk, and backup failures.
10. admin apps are protected by auth plus VPN, IP allowlist, or another network control.

## Remaining High-Value Additions

- SOPS or Sealed Secrets for encrypted Git-managed secrets.
- Prometheus, Grafana, Loki, and Alertmanager in `ops`.
- scheduled backup jobs for MySQL, MariaDB, and PVC data.
- CI workflow for `make check`, kubeconform, and policy checks.
- external auth or ingress IP allowlists for admin surfaces.
- server inventory and disaster recovery documentation.
