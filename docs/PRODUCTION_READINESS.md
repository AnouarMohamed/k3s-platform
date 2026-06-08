# Production Readiness

## Position

This repository is intentionally strong as a lab and presentation baseline. It is not labeled production-ready because production Kubernetes requires more than working manifests.

Production readiness means:

- traffic can be restored after failure.
- data can be restored after loss.
- secrets can be rotated.
- changes can be reviewed and rolled back.
- monitoring detects failures before users report them.
- access is controlled and auditable.

## Readiness Matrix

| Area | Lab state | Production requirement |
| --- | --- | --- |
| Cluster | single-node K3s possible | HA control plane or accepted single-node risk |
| Ingress | ingress-nginx with LoadBalancer Service | tested public IP, DNS, rate limits, auth, access restrictions |
| TLS | cert-manager staging and production issuers | staging verified, production issuer enabled intentionally |
| Secrets | local `.env` to Kubernetes Secrets | SOPS, Sealed Secrets, External Secrets, or cloud secret manager |
| Storage | local-path-retain | Longhorn, managed DB, external storage, or documented risk acceptance |
| Backups | documented expectation | scheduled backup jobs, off-node storage, restore drills |
| Monitoring | reserved `ops` namespace | Prometheus, Grafana, Loki, Alertmanager or managed equivalent |
| Security | baseline namespaces and default-deny | per-app policies, RBAC, pod hardening, vulnerability scanning |
| Images | mixed pinned and floating tags | pinned versions or digests |
| Operations | Makefile and runbooks | GitOps, alerts, incident response, access policy |

## Hardening Backlog

High priority:

- replace example domains.
- update `ClusterIssuer` email.
- switch all public routes to the intended issuer only after staging works.
- pin image versions.
- add resource requests and limits.
- add backups for each stateful app.
- restrict admin tools by VPN, IP allowlist, or authentication.
- introduce a real secret management workflow.

Medium priority:

- split databases into `data` namespace.
- add per-app NetworkPolicies.
- add PodDisruptionBudgets where replicas are higher than one.
- add Prometheus metrics and dashboards.
- add log aggregation.
- add CI validation for YAML and Kustomize build.

Future:

- evaluate Longhorn for multi-node K3s.
- evaluate GKE for managed control plane and cloud load balancing.
- adopt Argo CD or Flux.
- introduce policy-as-code checks.

## Production Migration Gate

Do not migrate a production service until these questions are answered:

1. What data does the service own?
2. Where is the backup stored?
3. Has restore been tested?
4. What is the DNS rollback plan?
5. Which secret values must be preserved?
6. Which users/admins need access?
7. What monitoring proves the service is healthy?
8. What command or Git revert rolls back the change?
9. What is the maintenance window?
10. What is the maximum acceptable downtime?

## Why This Is Still Valuable

The lab is valuable because it teaches the real platform primitives before the risk is real. It lets the engineer build confidence with:

- K3s installation.
- ingress-nginx routing.
- cert-manager issuance.
- Kubernetes Services and DNS.
- PVC behavior.
- NetworkPolicy behavior.
- application probes.
- Kustomize and Git-based desired state.

That learning directly improves a future K3s, GKE, or managed Kubernetes migration.

