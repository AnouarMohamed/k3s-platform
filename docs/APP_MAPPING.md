# Application Mapping

## Objective

The K3s lab keeps the same service vocabulary as the Swarm platform, but translates it into Kubernetes objects. This is important for presentation and for engineering control: every migrated service should have a clear equivalent, a clear risk level, and a clear rollback path.

## Mapping Table

| Swarm service | Current role | K3s objects | Migration risk | Recommended position |
| --- | --- | --- | --- | --- |
| WordPress sites | Public websites and demos | Deployment, Service, Ingress, PVC, MySQL Deployment | Medium | First migration candidate if content backup is proven. |
| Jenkins | CI/CD control surface | Deployment, Service, Ingress, PVC | Medium/high | Move after storage, plugin backup, and agent strategy are tested. |
| GLPI | IT service management | Deployment, Service, Ingress, PVC | High | Keep in Swarm until database and attachments restore process is verified. |
| Superset | BI/dashboard service | Deployment, Service, Ingress, PVC | Medium/high | Move after metadata database strategy and secret rotation are documented. |
| Passbolt | Password manager | Deployment, MariaDB Deployment, Services, Ingress, PVCs | Very high | Last migration candidate because identity, GPG keys, JWT keys, and database integrity are critical. |
| Portainer | Container management UI | Deployment, Service, Ingress, PVC | Medium | Useful as lab visibility, but production exposure must be restricted. |

## Translation Rules

| Docker Swarm concept | Kubernetes concept | Reason |
| --- | --- | --- |
| Stack file | Kustomize app directory | Keeps each service reviewable and composable from Git. |
| Service DNS on overlay network | Kubernetes Service DNS | Stable internal service names without depending on Swarm stack naming. |
| Traefik/Nginx route | Ingress object | Route is now an API object with explicit host, TLS, and backend. |
| Docker secret | Kubernetes Secret or external secret backend | Same principle, but a Kubernetes-native reference. |
| Named volume | PVC | Storage becomes schedulable and visible through the Kubernetes API. |
| Healthcheck | Readiness/liveness probe | The platform can stop routing to pods that are not ready. |
| Labels/middlewares | Ingress annotations and policy | Edge behavior is controlled at the route/controller layer. |

## Service-by-Service Notes

### WordPress

WordPress is the best learning target because it exercises every major platform primitive without being as sensitive as Passbolt or GLPI. It needs a web pod, a database pod, two PVCs, a Service, an Ingress, and TLS. The lab manifest is intentionally close to the Swarm pattern so the operational comparison remains clear.

Production improvements:

- use a managed database or a dedicated database StatefulSet.
- separate media backup from database backup.
- pin WordPress and MySQL image versions.
- add resource requests and limits.
- add scheduled dumps and restore drills.

### Jenkins

Jenkins validates persistent application state, long startup time, and reverse proxy behavior. It also forces the operator to think about agents. Running the controller in K3s is simple; running build agents safely requires more design.

Production improvements:

- back up `JENKINS_HOME`.
- decide between Kubernetes plugin agents and external agents.
- restrict ingress to internal IPs or VPN.
- define CPU/memory requests for the controller.
- avoid giving broad cluster permissions to Jenkins.

### GLPI

GLPI should be treated as a stateful business application. The lab deploys the web tier shape, but a real migration must include database, files, plugins, cron jobs, and email behavior.

Production improvements:

- document database engine and version.
- test import/export and attachment restore.
- define maintenance windows.
- restrict administrative paths.
- monitor application errors after cutover.

### Superset

Superset is valuable because it exposes the difference between application runtime storage and application metadata. A production migration should not rely only on a local PVC. Metadata and secrets matter more than the container itself.

Production improvements:

- externalize the metadata database.
- rotate `SUPERSET_SECRET_KEY` safely.
- add a real admin password flow through secrets.
- define dashboard backup/export procedure.
- validate CORS and embedding rules after ingress migration.

### Passbolt

Passbolt must be migrated last. It combines TLS, database state, GPG keys, JWT material, email delivery, and strict application URL assumptions. The lab manifest proves object mapping, not production readiness.

Production improvements:

- preserve GPG and JWT keys outside a disposable pod.
- back up the database and application keys together.
- test account recovery.
- restrict public exposure.
- document exact rollback steps before DNS is touched.

### Portainer

Portainer is useful for visibility, but it is also an administrative tool. In Kubernetes, its role should be reconsidered because `kubectl`, GitOps, and Kubernetes dashboards may replace part of the need.

Production improvements:

- use a dedicated service account.
- restrict ingress.
- rotate admin password hash.
- consider whether Portainer remains necessary after GitOps.

## Migration Priority

The recommended order is not based on technical simplicity alone. It is based on blast radius:

1. WordPress demo or low-risk public site.
2. Portainer lab-only visibility.
3. Jenkins after backup and agent strategy.
4. Superset after metadata persistence design.
5. GLPI after database and attachment restore proof.
6. Passbolt only after full key and restore rehearsal.

