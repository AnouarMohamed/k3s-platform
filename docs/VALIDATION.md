# Validation Guide

## Local Repository Validation

Run shell syntax checks:

```bash
bash -n scripts/*.sh
```

Render the Kustomize tree if `kubectl` is installed:

```bash
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

Move to production issuer only after staging works.

## Storage Validation

```bash
kubectl -n apps get pvc,pv
kubectl -n apps describe pvc <name>
```

A PVC being bound proves runtime allocation. It does not prove backup.

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

## Presentation Checklist

Before presenting the repo:

- README explains why K3s exists.
- docs explain architecture and migration.
- manifests show real Kubernetes primitives.
- secrets are placeholders only.
- runbooks exist for failures.
- validation commands are documented.
- Git history is clean.
