# Server Config Set

## How To Present This Repository

Present this repo as a production-oriented K3s server configuration set:

- `platform/` defines cluster-wide foundations.
- `policies/` defines network boundaries.
- `apps/` defines deployable services.
- `scripts/` defines repeatable operator commands.
- `docs/` and `runbooks/` explain how the server is operated.

The strongest message is that the repository is not just app YAML. It includes the edge layer, TLS automation, encrypted secret workflow, network isolation, resource guardrails, backups, telemetry, image pinning, validation, and operational runbooks.

## What Is Ready Now

- public routing through ingress-nginx.
- certificate automation through cert-manager.
- production issuer selected through central settings.
- SOPS + Age encrypted secret workflow.
- Restic CronJobs for DB dumps and PVC backups.
- Prometheus, Alertmanager, kube-state-metrics, node-exporter, Grafana, Loki, and Promtail.
- baseline alert rules for pods, PVCs, nodes, and backup jobs.
- guarded Restic PVC restore helper plus WordPress and Passbolt restore runbooks.
- default-deny ingress and egress.
- per-app ingress and internal database policies.
- controlled public egress for web, SMTP, and Jenkins Git SSH.
- admin ingress IP allowlists and rate limits.
- service accounts per workload with token automount disabled.
- resource requests, limits, quotas, and limit ranges.
- image tags pinned with digests.
- placeholder checks before apply.
- manifest render checks through `make check`.
- GitHub Actions validation for shell syntax and manifest checks.

## What To Add Next

Add these to make the repo stronger as a complete server configuration package:

| Addition | Why it matters |
| --- | --- |
| `inventory/servers.yaml` | Documents server names, public IPs, roles, CPU, RAM, disk, OS, and SSH access policy. |
| `clusters/<server>/settings.yaml` | Allows one repo to hold multiple server environments without changing app manifests. |
| External auth | Protects Jenkins, GLPI, Passbolt, Superset, and Portainer before app login screens. |
| Expanded CI checks | Adds YAML linting, kubeconform, kube-score, and policy checks on every pull request. |
| Image update policy | Documents how image digests are refreshed, scanned, tested, and promoted. |
| Cilium FQDN policies | Enforces domain-level egress restrictions that vanilla NetworkPolicy cannot express. |
| More restore runbooks | Covers Jenkins, GLPI, Superset, and Portainer recovery in the same detail as WordPress and Passbolt. |
| Disaster recovery runbook | Proves how to rebuild the server, restore data, and repoint DNS. |
| Maintenance calendar | Documents renewal windows, upgrade cadence, and backup restore drills. |

## Suggested Future Tree

```text
inventory/
  servers.yaml
clusters/
  ito-prod/
    README.md
  ito-staging/
    README.md
.github/
  workflows/
    validate.yaml
```

## Production Evidence Checklist

Before presenting this as a ready server config set, be able to show:

- `make check` passes.
- `make production-check` passes after real settings and encrypted secrets are present.
- `kubectl kustomize .` renders the full desired state.
- no app image uses `latest`.
- each public app has an ingress policy.
- each internal database has a specific client policy.
- encrypted secrets are committed as `secrets/production.enc.yaml`.
- backup CronJobs, restore helper, and telemetry workloads render.
- applying with placeholder domains is blocked.
- runbooks explain validation, rollback, certificate issues, ingress issues, restores, rotation, and backups.
