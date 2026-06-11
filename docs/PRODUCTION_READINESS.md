# Production Readiness

## Position

This repository is a production-oriented K3s configuration set. The manifests are structured for real server use, but production readiness is only complete when the operator supplies real domains, secrets, backups, monitoring, and access controls.

The repo now treats unsafe defaults as deployment blockers:

- `make apply` refuses example domains and `admin@example.com`.
- `make secrets` applies SOPS-encrypted secrets from Git.
- `make production-check` validates production controls structurally; `REQUIRE_REAL_PRODUCTION_VALUES=true make production-check` fails if encrypted secrets or real settings are missing.
- `make check` renders the tree and rejects floating `latest` images.
- app images use pinned tags with digests.
- NetworkPolicy defaults to deny ingress and egress.
- Restic backup CronJobs, restore runbooks, Alertmanager rules, and telemetry are rendered in the platform.

## Readiness Matrix

| Area | Current repo state | Operator must provide |
| --- | --- | --- |
| Cluster | K3s bootstrap, Traefik disabled | HA decision or accepted single-node risk |
| Ingress | ingress-nginx LoadBalancer Service | public DNS and firewall rules |
| TLS | cert-manager staging and production issuers | real ACME email and successful issuance checks |
| Settings | central `platform/settings.yaml` | real hostnames before apply |
| Secrets | SOPS + Age workflow, encrypted file required by production check | real Age recipient and committed `secrets/production.enc.yaml` |
| Storage | retained local-path PVCs plus Restic backup jobs and restore helper | S3-compatible target and completed restore drills |
| Network | default-deny plus per-app allow rules | CNI enforcement verification on the server |
| Runtime | service accounts, token automount disabled, resource limits, non-root where feasible | runtime testing for third-party image assumptions |
| Observability | Prometheus, Alertmanager, kube-state-metrics, node-exporter, Grafana, Loki, Promtail, baseline alert rules | real alert receiver, test alert, dashboard tuning |
| Images | pinned tags with manifest digests | vulnerability scanning and update cadence |
| Operations | Makefile, scripts, docs, runbooks | incident ownership and maintenance windows |

## Production Gate

Do not cut over a service until these are true:

1. `platform/settings.yaml` contains real production domains and email.
2. `secrets/production.enc.yaml` exists and decrypts for the operator or GitOps controller.
3. `make check`, `make production-check`, and `REQUIRE_REAL_PRODUCTION_VALUES=true make production-check` pass.
4. `make secrets` has applied required runtime Secrets.
5. `kubectl diff -k .` has been reviewed.
6. cert-manager can issue the certificate for the host.
7. a Restic restore has been tested for the relevant database or PVC.
8. DNS rollback is documented.
9. monitoring can detect pod, ingress, certificate, disk, and backup failures.
10. admin apps are protected by the ingress allowlist and preferably VPN or external auth.

## Remaining High-Value Additions

- CI workflow for `make check`, kubeconform, and policy checks.
- external auth for admin surfaces.
- restore runbooks for Jenkins, GLPI, Superset, and Portainer.
- Cilium FQDN egress enforcement if strict domain egress is required.
- server inventory and disaster recovery documentation.
