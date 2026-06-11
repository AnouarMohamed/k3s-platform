# GitOps Model

## Goal

The repository is structured so it can be adopted by Argo CD or Flux after the manual apply workflow is proven. GitOps should be introduced only after manifests, secrets, backups, and rollback behavior are understood.

## Current Manual Flow

```text
local edit -> git diff -> kubectl diff -k . -> kubectl apply -k .
```

This is the right first step because it keeps cause and effect visible.

## Target GitOps Flow

```text
pull request -> review -> merge to main -> GitOps controller detects commit -> cluster reconciles
```

Recommended target:

- one repository per platform layer or one mono-repo with clear folders.
- repository root `kustomization.yaml` as the current cluster entrypoint.
- protected `main` branch.
- pull request review for route, secret reference, and storage changes.
- controller read-only access to Git.
- separate mechanism for secret material.

## Suggested Argo CD Shape

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ito-prod
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/AnouarMohamed/ito-k3s-platform.git
    targetRevision: main
    path: .
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: false
      selfHeal: true
```

Do not enable aggressive pruning until the team is comfortable with how Kubernetes ownership and deletion work.

## Suggested Flux Shape

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: ito-prod
  namespace: flux-system
spec:
  interval: 5m
  path: ./
  prune: false
  sourceRef:
    kind: GitRepository
    name: ito-k3s-platform
  wait: true
```

## Branching Rules

Changes that should require review:

- new public hostname.
- issuer, public hostname, or TLS settings change.
- storage size or reclaim policy change.
- image tag change for stateful service.
- NetworkPolicy change.
- RBAC change.
- secret reference change.

Changes that can be fast-tracked:

- comments.
- documentation-only changes.

## Secret Strategy For GitOps

Do not put raw Kubernetes Secret manifests with real values in Git. Good options:

| Option | Fit | Notes |
| --- | --- | --- |
| SOPS + age | Strong for GitOps | Encrypted values are committed, keys stay outside Git. |
| Sealed Secrets | Simple cluster-bound encryption | Easy for a small cluster, tied to controller key. |
| External Secrets Operator | Strong cloud integration | Best when using a secret manager. |
| Manual secret creation | Break-glass only | Not a reproducible production state model. |

## Promotion Model

Recommended environments:

1. `ito-staging` for DNS, certs, backups, and upgrade rehearsals.
2. `ito-prod` after restore drills and rollback are proven.

This repository does not currently include `clusters/` overlays. The active Kustomize entrypoint is the repository root. A future multi-cluster layout should introduce a shared `base/` plus explicit environment overlays:

```text
base/
clusters/
  ito-staging/
  ito-prod/
```

The overlay directories should point at `base/`, not at the repository root, to avoid recursive Kustomize accumulation.

## Why GitOps Is An Upgrade

GitOps would upgrade the infrastructure because it changes operations from "run commands on a server" to "review desired state and let the cluster reconcile." That gives the startup:

- clearer change history.
- repeatable deployment.
- easier rollback.
- fewer manual server edits.
- better onboarding for future engineers.
- a path toward policy checks and CI validation.
