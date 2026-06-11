# Architecture Decisions

## ADR-001: Use K3s For The Server Platform

Decision: use K3s as the Kubernetes distribution for the production server config set.

Reasoning:

- K3s is lightweight enough for VPS and small bare-metal servers.
- It preserves standard Kubernetes APIs and object models.
- It reduces bootstrap complexity while keeping real cluster concepts.
- It leaves a future path to managed Kubernetes if the platform grows.

Tradeoff:

- Single-node K3s is not highly available.
- Backups, monitoring, and security discipline remain operator responsibilities.

Status: accepted.

## ADR-002: Disable Bundled Traefik And Use ingress-nginx

Decision: install K3s with `--disable traefik` and use ingress-nginx.

Reasoning:

- ingress-nginx keeps edge behavior explicit.
- Nginx is familiar from existing server operations.
- annotations and logs are widely understood.
- cert-manager HTTP-01 integration is standard.

Tradeoff:

- ingress-nginx adds a Helm-managed platform component.

Status: accepted.

## ADR-003: Use cert-manager For ACME

Decision: use cert-manager ClusterIssuers for ACME certificates.

Reasoning:

- certificate lifecycle becomes Kubernetes-native.
- certificates are represented by API objects.
- HTTP-01 challenge handling integrates with Ingress.
- staging and production issuers both exist for safer operations.

Tradeoff:

- cert-manager adds CRDs and controllers that must be monitored.
- DNS and ingress reachability must be correct before issuance works.

Status: accepted.

## ADR-004: Use Kustomize For Local App Manifests

Decision: write local apps as plain manifests composed by Kustomize.

Reasoning:

- the repo stays readable and reviewable.
- every Deployment, Service, Ingress, PVC, and Secret reference is visible.
- Kustomize is built into kubectl and works well with GitOps.
- central replacements allow production settings without hiding app manifests.

Tradeoff:

- full application charts can be more complete.
- the operator must maintain manifests directly.

Status: accepted.

## ADR-005: Keep Plaintext Secrets Out Of Git

Decision: use SOPS + Age for production Secrets committed as encrypted YAML.

Reasoning:

- the repo can stay sanitized.
- secret references remain visible without exposing values.
- cluster state is reproducible from Git.
- `make production-check` fails when encrypted secrets are missing.

Tradeoff:

- the operator must manage Age private keys outside the repo.
- `.env` remains only as a break-glass bootstrap path.

Status: accepted.

## ADR-006: Use local-path-retain As The Default StorageClass

Decision: use the K3s local-path provisioner through a retained StorageClass.

Reasoning:

- it is simple and available in K3s.
- it works for single-server deployments.
- `Retain` reduces accidental data deletion during iteration.

Tradeoff:

- storage is node-local.
- node failure can mean service and data outage.
- production requires external backups or a stronger storage design.

Status: accepted with explicit risk.

## ADR-009: Add Restic Backups For Stateful Data

Decision: render CronJobs for logical database dumps and PVC content backups to S3-compatible storage.

Reasoning:

- `local-path-retain` is runtime storage, not backup.
- backups must leave the node to survive disk or provider failure.
- database dumps are more restorable than crash-consistent DB file copies.

Tradeoff:

- restore drills still have to be executed per application before cutover.
- S3 credentials and Restic password become required production secrets.

Status: accepted.

## ADR-010: Add Lightweight Telemetry

Decision: include Prometheus, Alertmanager, kube-state-metrics, node-exporter, Grafana, Loki, and Promtail manifests.

Reasoning:

- pod readiness alone is not enough operational visibility.
- kube-state-metrics exposes restarts, unavailable workloads, quotas, jobs, and PVC state.
- node-exporter exposes host disk and node-level metrics that matter for local-path storage.
- Alertmanager turns backup, pod, PVC, and disk failures into routed alerts.
- Loki and Promtail provide basic log aggregation without a managed logging service.

Tradeoff:

- receiver endpoints must live in encrypted Secret material and be tested by the operator.
- telemetry consumes local storage and must also be monitored.

Status: accepted.

## ADR-007: Enforce Default-Deny NetworkPolicy

Decision: default deny both ingress and egress for application namespaces, then add explicit allow policies.

Reasoning:

- public access should arrive through ingress only.
- internal service traffic should be deliberate.
- egress should be explainable and reviewable.
- lateral movement risk is reduced.

Tradeoff:

- policies require real CNI enforcement.
- each new app needs policy work before it functions.

Status: accepted.

## ADR-008: Pin Application Images With Digests

Decision: app containers use tags plus manifest digests.

Reasoning:

- prevents silent image drift.
- preserves human-readable version context.
- makes changes reviewable in Git.

Tradeoff:

- digest updates are manual until an image update workflow exists.

Status: accepted.
