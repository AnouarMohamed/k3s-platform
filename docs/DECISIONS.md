# Architecture Decisions

## ADR-001: Use K3s As The First Kubernetes Step

Decision: use K3s for the lab instead of a full upstream kubeadm cluster or immediate managed Kubernetes.

Reasoning:

- K3s is lightweight enough for a VPS lab.
- It preserves Kubernetes APIs and object models.
- It reduces bootstrap complexity while keeping real cluster concepts.
- It creates a learning bridge toward managed platforms such as GKE.

Tradeoff:

- K3s does not remove the need for backup, monitoring, or security discipline.
- Single-node K3s is not equivalent to a highly available production cluster.

Status: accepted for lab.

## ADR-002: Disable Bundled Traefik And Use ingress-nginx

Decision: install K3s with `--disable traefik` and use ingress-nginx.

Reasoning:

- The current Swarm evolution already moved from dynamic Traefik labels to explicit Nginx routes.
- ingress-nginx makes the Kubernetes edge model easy to compare with the Nginx Swarm edge.
- It is a widely understood Ingress controller with strong documentation and common operational patterns.
- Nginx behavior is familiar from the existing edge repo.

Tradeoff:

- The bundled K3s Traefik controller is simpler to keep.
- ingress-nginx adds a Helm-managed platform component.

Status: accepted.

## ADR-003: Use cert-manager For ACME

Decision: use cert-manager ClusterIssuers for ACME certificates.

Reasoning:

- Certificate lifecycle becomes Kubernetes-native.
- Certificates are represented by API objects.
- HTTP-01 challenge handling integrates with Ingress.
- The staging/production issuer split avoids unnecessary Let's Encrypt production failures.

Tradeoff:

- cert-manager adds CRDs and a controller that must be monitored.
- DNS and ingress reachability must be correct before issuance works.

Status: accepted.

## ADR-004: Use Kustomize Instead Of Helm For Local App Manifests

Decision: write local apps as plain manifests composed by Kustomize.

Reasoning:

- The repo stays readable for report and presentation purposes.
- Every Deployment, Service, Ingress, PVC, and Secret reference is visible.
- Kustomize is built into kubectl and works well with GitOps.
- The approach avoids hiding important learning value inside third-party charts.

Tradeoff:

- Full application charts can be more complete.
- The operator must maintain manifests directly.

Status: accepted for lab.

## ADR-005: Keep Secrets Out Of Git

Decision: commit only secret examples and create runtime Secrets from `.env`.

Reasoning:

- The repo can be public and presentation-safe.
- The workflow matches the sanitized Swarm repos.
- Secret references remain visible without exposing values.

Tradeoff:

- Local `.env` secret creation is not ideal production secret management.
- Production should move to SOPS, Sealed Secrets, External Secrets, or a cloud secret manager.

Status: accepted for lab, replace before production.

## ADR-006: Use local-path-retain For Lab Storage

Decision: use the K3s local-path provisioner through a retained StorageClass.

Reasoning:

- It is simple and available in K3s.
- PVCs can be tested without installing a storage platform.
- `Retain` reduces accidental data deletion during lab iteration.

Tradeoff:

- Storage is node-local.
- Multi-node scheduling and node failure behavior are limited.
- Production needs Longhorn, managed databases, or external storage decisions.

Status: accepted for lab only.

## ADR-007: Apply Default-Deny Ingress Early

Decision: include NetworkPolicy default-deny for `apps` and `data`.

Reasoning:

- It teaches the correct security model early.
- Public access should arrive through ingress, not accidental pod reachability.
- Internal service traffic is allowed deliberately.

Tradeoff:

- NetworkPolicy behavior depends on the CNI enforcing it.
- Coarse namespace-wide allows should be refined before production.

Status: accepted, improve per app later.

