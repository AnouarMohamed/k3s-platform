# Server Config Set

## How To Present This Repository

Present this repo as a production-oriented K3s server configuration set:

- `platform/` defines cluster-wide foundations.
- `policies/` defines network boundaries.
- `apps/` defines deployable services.
- `scripts/` defines repeatable operator commands.
- `docs/` and `runbooks/` explain how the server is operated.

The strongest message is that the repository is not just app YAML. It includes the edge layer, TLS automation, network isolation, resource guardrails, image pinning, validation, and operational runbooks.

## What Is Ready Now

- public routing through ingress-nginx.
- certificate automation through cert-manager.
- production issuer selected through central settings.
- default-deny ingress and egress.
- per-app ingress and internal database policies.
- controlled public egress for web, SMTP, and Jenkins Git SSH.
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
| SOPS or Sealed Secrets | Makes secret delivery GitOps-ready without committing plaintext secrets. |
| Backup manifests | Shows scheduled database dumps, PVC snapshots, object storage targets, and restore jobs. |
| Monitoring stack | Adds Prometheus, Grafana, Loki, Alertmanager, dashboards, and alerts. |
| External auth or IP allowlists | Protects Jenkins, GLPI, Passbolt, Superset, and Portainer from broad public exposure. |
| Expanded CI checks | Adds YAML linting, kubeconform, kube-score, and policy checks on every pull request. |
| Image update policy | Documents how image digests are refreshed, scanned, tested, and promoted. |
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
security/
  sops-age-recipients.txt
monitoring/
  prometheus/
  grafana/
backups/
  mysql/
  mariadb/
  pvc-restic/
.github/
  workflows/
    validate.yaml
```

## Production Evidence Checklist

Before presenting this as a ready server config set, be able to show:

- `make check` passes.
- `kubectl kustomize .` renders the full desired state.
- no app image uses `latest`.
- each public app has an ingress policy.
- each internal database has a specific client policy.
- secrets are referenced but not committed.
- applying with placeholder domains is blocked.
- runbooks explain validation, rollback, certificate issues, ingress issues, and backups.
