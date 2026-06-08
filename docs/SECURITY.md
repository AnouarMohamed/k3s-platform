# Security Model

## Security Objective

The objective is not to make the lab look complicated. The objective is to establish security habits that can survive a real migration:

- no secrets in Git.
- explicit namespaces.
- default-deny network posture.
- TLS automation.
- readiness checks before routing.
- separated platform controllers and application workloads.

## Secrets

Secrets are created from `.env` through `scripts/create-lab-secrets.sh`. The `.env` file is ignored.

Never commit:

- `.env`
- kubeconfig
- TLS private keys
- database dumps
- generated password hashes
- service account tokens

For production, replace local secret creation with one of:

- SOPS + age/GPG.
- Sealed Secrets.
- External Secrets Operator.
- cloud secret manager integration.

## TLS

The default issuer is staging. Production issuance should be a deliberate change after HTTP-01 validation.

Security rule:

```text
If staging does not work, production must not be attempted.
```

## Network Policies

The repo applies default-deny ingress policies for `apps` and `data`. It then allows ingress controller traffic and internal app namespace traffic.

Production hardening should replace namespace-wide internal allow with app-level policies:

- ingress controller -> frontend service only.
- frontend -> database only on database port.
- CI/CD -> only required endpoints.
- monitoring -> metrics endpoints only.

## RBAC

The lab keeps RBAC minimal. Production should add:

- named service accounts per app.
- least-privilege roles.
- no default service account tokens unless required.
- restricted admin access.
- audit logs if running on managed Kubernetes.

## Pod Security

Namespaces enforce baseline Pod Security Admission. Production should evaluate restricted mode for apps that can support it.

Expected future improvements:

- `runAsNonRoot`
- read-only root filesystems
- dropped Linux capabilities
- resource requests and limits
- image digest pinning

## Public Exposure

Admin applications such as Jenkins, Portainer, Passbolt, and GLPI should not be treated like public marketing websites.

Before production:

- add authentication at ingress or application layer.
- consider VPN or IP allowlist.
- enable rate limiting.
- verify headers.
- monitor login failures.

## Supply Chain

This lab uses public images for clarity. Production should use:

- pinned image tags or digests.
- vulnerability scanning.
- build provenance where custom images exist.
- private registry for internal images.

## Security Review Checklist

Before merging a change:

- Does it introduce a new public host?
- Does it require a new secret?
- Is the secret referenced, not committed?
- Is there a readiness probe?
- Is there a service endpoint?
- Is the ingress TLS-enabled?
- Does NetworkPolicy permit only what is required?
- Is rollback obvious?

## Threat Model

| Threat | Control in this repo | Production improvement |
| --- | --- | --- |
| Secret leak through Git | `.env` ignored, examples only | SOPS, Sealed Secrets, External Secrets |
| Accidental public exposure | Ingress objects are explicit | VPN, IP allowlist, external auth |
| Weak TLS rollout | staging issuer first | monitoring and renewal alerts |
| Lateral movement | default-deny ingress baseline | per-app policies and egress controls |
| Broken app receiving traffic | readiness probes | stricter probes and SLO checks |
| Data loss | retained PVCs | off-node backups and restore drills |
| Supply-chain drift | visible image references | pinned tags, digests, scanning |
