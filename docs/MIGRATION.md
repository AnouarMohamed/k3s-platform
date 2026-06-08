# Migration Strategy

## Position

K3s should not replace the Swarm infrastructure just because Kubernetes is more popular. The correct engineering position is:

```text
Stabilize first. Lab second. Migrate gradually. Move stateful services last.
```

## Why K3s Improves The Platform

K3s introduces:

- standardized deployment objects.
- native readiness and liveness probes.
- service discovery through Kubernetes Services.
- ingress as a first-class routing object.
- cert-manager for certificate lifecycle.
- RBAC and namespace boundaries.
- NetworkPolicy.
- a path to GitOps.
- portability to GKE or another managed platform.

These are real upgrades when the platform grows. They are unnecessary weight if the current platform is small and stable.

## Migration Phases

| Phase | Scope | Exit criteria |
| --- | --- | --- |
| 0 | Keep Swarm + Nginx stable | all current services documented and recoverable |
| 1 | K3s lab | cluster boots, ingress works, staging certs issue |
| 2 | Stateless service | one low-risk service runs on K3s with rollback |
| 3 | GitOps | manifests applied from Git with review process |
| 4 | Stateful rehearsal | database backup and restore proven |
| 5 | Production decision | cost, complexity, and business value accepted |

## Service Migration Order

Recommended order:

1. static/demo WordPress instance.
2. Portainer or internal dashboard.
3. Jenkins after storage and agent strategy are understood.
4. Superset after secrets and metadata backup are clear.
5. GLPI after database restore is tested.
6. Passbolt last, because GPG/JWT/database integrity is critical.

## Rollback Strategy

During migration, DNS remains the rollback lever:

1. keep Swarm service running.
2. deploy K3s equivalent under a lab hostname.
3. validate data and auth flows.
4. lower DNS TTL.
5. move public DNS only when ready.
6. rollback by pointing DNS back to Swarm.

## Decision Matrix

| Criterion | Swarm + Nginx | K3s |
| --- | --- | --- |
| Current operational cost | low | medium |
| Learning value | medium | high |
| Portability | low | high |
| GitOps fit | limited | strong |
| Storage complexity | low | medium/high |
| Production maturity potential | medium | high |

## Final Recommendation

Use K3s as the learning and future architecture path, not as an emergency replacement. The Swarm/Nginx repo remains the stable current edge. This repo proves whether Kubernetes adds enough operational value before ITO pays the complexity cost.
