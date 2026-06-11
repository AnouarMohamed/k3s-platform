# Implementation Notes

This document records the production-hardening work currently represented in the repository. It is meant for reviewers who need to understand what changed and why.

## Summary

The repo moved from a static config set toward an operational K3s platform. The major additions are:

- encrypted secret workflow with SOPS + Age.
- off-node Restic backup CronJobs.
- restore helper and application restore runbooks.
- Prometheus, Alertmanager, Grafana, Loki, Promtail, kube-state-metrics, and node-exporter.
- baseline alert rules for backups, workloads, PVCs, targets, and root disk.
- admin ingress source allowlists.
- stricter NetworkPolicies and default-deny egress.
- database workloads moved into the `data` namespace.
- stronger runtime hardening and resource guardrails.
- production checks that block unsafe placeholders.

## Secret Workflow

Production Secrets are expected in `secrets/production.enc.yaml`. The plaintext working file is `secrets/production.plain.yaml`, which is ignored.

Relevant files:

- `.sops.yaml.example`
- `secrets/README.md`
- `secrets/production.plain.example.yaml`
- `scripts/encrypt-sops-secrets.sh`
- `scripts/apply-sops-secrets.sh`
- `scripts/create-secrets.sh`

The `.env` path remains only for break-glass bootstrap through `make local-secrets`.

## Backup And Restore

Database backups use logical dumps before Restic upload. PVC backups mount the source PVC read-only and upload content snapshots to the same Restic repository.

Relevant files:

- `platform/backups/database-backups.yaml`
- `platform/backups/volume-backups.yaml`
- `scripts/restore-restic-volume.sh`
- `runbooks/RESTORE_WORDPRESS.md`
- `runbooks/RESTORE_PASSBOLT.md`

The restore helper requires `RESTORE_TAG`, `TARGET_PVC`, and `CONFIRM_RESTORE=yes` so it cannot write into a PVC by accident.

## Observability And Alerts

Prometheus uses static and Kubernetes service discovery, loads alert rules from `prometheus-rules`, and sends alerts to Alertmanager. Alertmanager receiver config comes from `alertmanager-secret` so webhooks and routing details can be encrypted with SOPS.

Relevant files:

- `platform/telemetry/prometheus.yaml`
- `platform/telemetry/prometheus-rules.yaml`
- `platform/telemetry/alertmanager.yaml`
- `platform/telemetry/grafana.yaml`
- `platform/telemetry/loki.yaml`
- `platform/telemetry/promtail.yaml`
- `platform/telemetry/kube-state-metrics.yaml`
- `platform/telemetry/node-exporter.yaml`

Baseline rules currently cover target availability, crash loops, deployment replica mismatch, pending PVCs, root disk pressure, failed backup jobs, stale backup CronJobs, and suspended backup CronJobs.

## Network And Public Exposure

The repository now uses default-deny ingress and egress for application namespaces, then allows only documented flows:

- ingress-nginx to frontend services.
- frontend apps in `apps` to their own database in `data`.
- backup jobs in `apps` to their database in `data` and S3-compatible HTTPS endpoint.
- DNS egress.
- selected app web egress.
- selected app SMTP egress.
- Jenkins Git SSH egress.
- Jenkins agent port access.

Admin Ingress resources include source allowlists and rate limits. This is a baseline; VPN or external auth is still recommended.

## Runtime Hardening

Workloads now favor:

- dedicated ServiceAccounts.
- disabled service account token automount where practical.
- non-root users where the image supports it.
- dropped Linux capabilities.
- resource requests and limits.
- namespace quotas and LimitRanges.
- pinned image digests.

Some third-party images still need runtime testing because container entrypoint assumptions can differ by version.

## Validation

Use these checks before applying:

```bash
bash -n scripts/*.sh
make check
kubectl kustomize . >/tmp/ito-k3s-rendered.yaml
```

Use these checks before production cutover:

```bash
make secrets
make production-check
kubectl diff -k .
make apply
make validate
```

`make production-check` validates structural controls against the sanitized repo. Set `REQUIRE_REAL_PRODUCTION_VALUES=true` to require real settings and `secrets/production.enc.yaml` before cutover.

## Known Remaining Work

- Add external auth for Jenkins, GLPI, Passbolt, Superset, and Portainer.
- Add restore runbooks for Jenkins, GLPI, Superset, and Portainer.
- Add server inventory and disaster recovery documentation.
- Add CI checks with kubeconform and policy-as-code.
- Add vulnerability scanning and image refresh policy.
- Move to Cilium if FQDN egress enforcement becomes mandatory.
