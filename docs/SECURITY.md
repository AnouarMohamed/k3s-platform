# Security Model

## Security Objective

The security objective is to make server configuration explicit, reviewable, and hard to apply accidentally with unsafe defaults.

The repository uses:

- no plaintext production secrets in Git.
- explicit namespaces.
- Pod Security Admission labels.
- default-deny ingress and egress.
- per-app NetworkPolicies.
- TLS automation.
- readiness and liveness probes.
- pinned images with digests.
- dedicated service accounts with token automount disabled.
- resource quotas and limits.
- SOPS-encrypted production secrets.
- admin ingress IP allowlists.

## Secrets

Production Secrets are encrypted in Git with SOPS + Age. `make secrets` decrypts and applies `secrets/production.enc.yaml`.

`.env` plus `make local-secrets` remains available only as a break-glass bootstrap path. It is not the normal production state model.

Never commit:

- `.env`
- kubeconfig
- TLS private keys
- database dumps
- generated password hashes
- service account tokens

The repo includes `secrets/production.plain.example.yaml` as the local starting point. Commit only `*.enc.yaml`.

## TLS

The root Kustomize tree uses `platform/settings.yaml` to select the issuer injected into every Ingress. The default setting is `letsencrypt-production`, but `make apply` blocks the example ACME email and example hostnames.

Keep the staging issuer available for validation and incident work. Production issuance should happen only after DNS and HTTP-01 routing are confirmed.

## Network Policies

The repo applies default-deny ingress and egress in `apps` and `data`.

Allowed paths are explicit:

- ingress-nginx namespace -> each frontend app on its service port.
- WordPress -> WordPress DB on TCP 3306.
- Passbolt -> Passbolt DB on TCP 3306.
- backup jobs -> their database targets and public S3-compatible HTTPS endpoint.
- app pods -> kube-dns on TCP/UDP 53.
- selected app pods -> public TCP 80/443.
- selected mail-capable app pods -> public SMTP ports 25/465/587.
- Jenkins -> public TCP 22 for Git SSH.
- Jenkins agents labelled `jenkins.io/agent=true` -> Jenkins TCP 50000.

The old namespace-wide internal allow has been removed.

Vanilla Kubernetes NetworkPolicy cannot restrict egress by FQDN. The repo includes `policies/examples/cilium-fqdn-egress.example.yaml` for a future Cilium migration.

## RBAC

Each workload has a named ServiceAccount and `automountServiceAccountToken: false`. This prevents application pods from receiving Kubernetes API tokens unless a future workload explicitly needs one.

If Portainer or Jenkins is later allowed to manage the cluster, add deliberate RBAC in a separate reviewed manifest.

## Pod Security

Namespaces enforce `baseline` Pod Security and warn/audit against `restricted`, except `node-observability`, which is explicitly `privileged` because Promtail and node-exporter need hostPath access to node logs and metrics. Workloads set non-root security contexts where the image supports it. The privileged namespace should contain only node-level collectors.

## Public Exposure

Admin applications such as Jenkins, Portainer, Passbolt, GLPI, and Superset should not be treated like public marketing websites.

Current admin ingresses include an ingress-nginx source allowlist and basic rate limit annotations. Before production exposure:

- add application authentication.
- prefer VPN or external auth at ingress.
- monitor login failures.
- document emergency disable steps.

## Supply Chain

Application images are pinned with tags and manifest digests. Production operation should add:

- vulnerability scanning.
- digest refresh process.
- image promotion through staging.
- private registry for internal images.

## Security Review Checklist

Before merging a change:

- Does it introduce a new public host?
- Does it require a new secret?
- Is the secret referenced, not committed?
- Does it use a pinned image digest?
- Is there a readiness probe?
- Is there a service endpoint?
- Is the ingress TLS-enabled?
- Does NetworkPolicy permit only what is required?
- Is rollback obvious?
