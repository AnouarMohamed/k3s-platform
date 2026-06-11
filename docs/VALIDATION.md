# Validation Guide

## Local Repository Validation

Run shell syntax checks:

```bash
bash -n scripts/*.sh
```

Render the Kustomize tree if `kubectl` is installed:

```bash
make check
kubectl kustomize . >/tmp/ito-k3s-rendered.yaml
```

or:

```bash
kustomize build . >/tmp/ito-k3s-rendered.yaml
```

Search for accidental secrets:

```bash
rg -n "password|secret|token|private|BEGIN|htpasswd|acme" .
```

Expected result: only examples, placeholders, and secret references should appear.
Real secret values must exist only in `secrets/production.enc.yaml`, a secret manager, or live Kubernetes Secrets. `.env` is only for break-glass local bootstrap.

## Cluster Validation

After applying:

```bash
make validate
```

Manual checks:

```bash
kubectl get nodes -o wide
kubectl -n ingress-nginx get svc,pods
kubectl -n cert-manager get deploy,pods
kubectl -n apps get deploy,svc,ingress,pvc
kubectl get clusterissuer
kubectl get certificates -A
kubectl -n ops get deploy,ds,svc,pvc
kubectl -n apps get cronjob
```

## Ingress Validation

For every hostname:

```bash
dig +short <host>
curl -I http://<host>/
curl -Ik https://<host>/
```

Expected:

- DNS returns the cluster public IP.
- HTTP reaches ingress-nginx.
- HTTPS returns a certificate after cert-manager completes.
- the backend service has endpoints.

## Certificate Validation

```bash
kubectl -n apps describe certificate <certificate-name>
kubectl -n apps get order,challenge
kubectl -n cert-manager logs deploy/cert-manager --tail=200
```

If production issuance fails, switch the configured issuer in `platform/settings.yaml` back to `letsencrypt-staging`, fix DNS or ingress reachability, and retry before returning to production.

## Storage Validation

```bash
kubectl -n apps get pvc,pv
kubectl -n apps describe pvc <name>
```

A PVC being bound proves runtime allocation. It does not prove backup.

## Backup Validation

```bash
kubectl -n apps create job --from=cronjob/backup-wordpress-db backup-wordpress-db-manual
kubectl -n apps logs job/backup-wordpress-db-manual
```

Then verify the Restic repository from a trusted admin machine:

```bash
restic snapshots
restic restore latest --target /tmp/restore-test
```

For an in-cluster PVC restore drill, use a staging PVC or a maintenance window:

```bash
RESTORE_TAG=wordpress-content TARGET_PVC=wordpress-content CONFIRM_RESTORE=yes make restore-volume
```

Do not count backups as production-ready until at least one database restore and one PVC restore have been tested from the S3 repository.

## Application Validation

For a Deployment:

```bash
kubectl -n apps rollout status deploy/<name>
kubectl -n apps get endpoints <service-name>
kubectl -n apps logs deploy/<name> --tail=100
```

The minimum healthy path is:

```text
Ingress -> Service -> Endpoints -> Ready Pod -> Application response
```

## Server Config Presentation Checklist

Before presenting the repo:

- README explains what the production config set provides.
- docs explain architecture, security, operations, and production gates.
- manifests show real Kubernetes primitives.
- app images are pinned with digests.
- default-deny and per-app NetworkPolicies are present.
- real secrets are not committed.
- runbooks exist for failures.
- validation commands are documented.
- Git history is clean.
