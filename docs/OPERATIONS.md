# Operations Manual

## Operator Contract

This repository assumes the operator is responsible for four things:

1. The node is healthy.
2. DNS points to the node public IP.
3. secrets exist before workloads depend on them.
4. certificates and ingress routes are validated after every change.

Kubernetes does not remove operational responsibility. It makes it explicit.

## Bootstrap Sequence

```bash
cp secrets/production.plain.example.yaml secrets/production.plain.yaml
vim secrets/production.plain.yaml
export SOPS_AGE_RECIPIENTS=age1...
make encrypt-secrets
make bootstrap
export KUBECONFIG=$PWD/kubeconfig
make addons
make secrets
make check
make production-check
make apply
make validate
```

## Daily Checks

```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl get ingress -A
kubectl get certificates -A
kubectl -n ingress-nginx get svc,pods
kubectl -n ops get deploy,ds,svc,pvc
kubectl -n apps get cronjob
```

Healthy baseline:

- node is `Ready`.
- ingress-nginx controller is `Running`.
- cert-manager deployments are `Available`.
- app pods are either `Running` or have a known pending dependency.
- certificates are `Ready=True`.

## Change Workflow

1. Edit manifests locally.
2. Run `make check`.
3. Run `kubectl diff -k .`.
4. Review every object that will be changed.
5. Apply with `make apply`.
6. Validate with `make validate`.
7. Test each public hostname with `curl -I`.

For review work, also run:

```bash
bash -n scripts/*.sh
kubectl kustomize . >/tmp/ito-k3s-rendered.yaml
```

## Adding A New Application

Create a new folder under `apps/<name>/`:

```text
apps/<name>/
  kustomization.yaml
  <name>.yaml
```

Minimum objects:

- `Deployment` or `StatefulSet`
- `Service`
- `Ingress`
- `PersistentVolumeClaim` if data is stored
- `Secret` reference, not secret values
- readiness and liveness probes
- resource requests and limits
- dedicated ServiceAccount
- NetworkPolicy for ingress, egress, and internal dependencies

Add the app folder to the root `kustomization.yaml`.

## Certificate Operations

Inspect certificate:

```bash
kubectl -n apps describe certificate <name>
kubectl -n apps get challenge,order,certificate
```

Common issues:

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Certificate stuck pending | DNS does not point to cluster | fix DNS and retry |
| HTTP-01 challenge fails | Ingress not reachable on port 80 | check ingress controller service |
| Production issuer rate limited | too many failed attempts | use staging first |

## Ingress Debugging

```bash
kubectl -n ingress-nginx logs deploy/ingress-nginx-controller
kubectl -n apps describe ingress <name>
kubectl -n apps get endpoints <service>
curl -I http://<host>/
curl -Ik https://<host>/
```

Debug path:

1. DNS resolves to node.
2. ServiceLB exposes ingress-nginx.
3. ingress-nginx receives the request.
4. Ingress rule matches host/path.
5. Service has endpoints.
6. Pod readiness probe is passing.

## Rollback

Kustomize is declarative, so rollback is a Git operation:

```bash
git revert <bad_commit>
make apply
make validate
```

For a single deployment image rollback:

```bash
kubectl -n apps rollout undo deploy/<name>
kubectl -n apps rollout status deploy/<name>
```

## Backup Responsibilities

This repository renders Restic CronJobs for database dumps and PVC content. They require `backup-s3-secret` from `secrets/production.enc.yaml`.

Check backup jobs:

```bash
kubectl -n apps get cronjob
kubectl -n apps get jobs
kubectl -n apps logs job/<backup-job-name>
```

Production expectation:

- S3-compatible repository is off-node.
- Restic password is stored only in encrypted secrets.
- restore drills are run before cutover.
- failed backup jobs alert through the telemetry stack.

Restore procedures:

- WordPress: `runbooks/RESTORE_WORDPRESS.md`
- Passbolt: `runbooks/RESTORE_PASSBOLT.md`
- PVC content restore helper: `RESTORE_TAG=<tag> TARGET_PVC=<pvc> CONFIRM_RESTORE=yes make restore-volume`

Check alerting:

```bash
kubectl -n ops get deploy prometheus alertmanager grafana
kubectl -n ops logs deploy/alertmanager --tail=100
```

## Upgrade Workflow

For platform components installed by Helm:

```bash
helm repo update
helm -n ingress-nginx list
helm -n cert-manager list
helm -n ingress-nginx upgrade ingress-nginx ingress-nginx/ingress-nginx \
  --values platform/ingress-nginx/values.yaml
helm -n cert-manager upgrade cert-manager jetstack/cert-manager \
  --values platform/cert-manager/values.yaml
```

Before an upgrade:

- read chart release notes.
- snapshot or back up important data.
- validate on staging or during a maintenance window first.
- avoid upgrading ingress and cert-manager at the same time in production.

## What Not To Do

- Do not switch all stateful services at once.
- Do not commit `.env` or kubeconfig.
- Do not commit `secrets/production.plain.yaml`.
- Do not rely on `latest` tags for production.
- Do not expose admin tools without auth and IP restrictions.
