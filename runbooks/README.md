# Runbooks

Focused procedures:

- [Restore WordPress](RESTORE_WORDPRESS.md)
- [Restore Passbolt](RESTORE_PASSBOLT.md)
- [Secret Rotation](SECRET_ROTATION.md)

## 1. Cluster Health

```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl top nodes || true
kubectl describe node
```

If the node is not ready:

1. check disk pressure.
2. check memory pressure.
3. check `k3s` service.
4. check container runtime.

```bash
systemctl status k3s
journalctl -u k3s -n 200 --no-pager
df -h
free -m
```

## 2. Ingress Down

```bash
kubectl -n ingress-nginx get pods,svc
kubectl -n ingress-nginx logs deploy/ingress-nginx-controller --tail=200
kubectl get ingress -A
```

Recovery:

```bash
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --values platform/ingress-nginx/values.yaml
```

## 3. Certificate Failure

```bash
kubectl -n apps get certificate,order,challenge
kubectl -n apps describe certificate <name>
kubectl -n cert-manager logs deploy/cert-manager --tail=200
```

Check:

- DNS A record points to node.
- port 80 reaches ingress-nginx.
- ClusterIssuer exists.
- staging works before production.

## 4. Application 502/504

```bash
kubectl -n apps get pods,svc,endpoints,ingress
kubectl -n apps describe ingress <name>
kubectl -n apps describe pod <pod>
kubectl -n apps logs <pod> --tail=200
```

Most common causes:

- readiness probe failing.
- Service selector does not match Pod labels.
- container port mismatch.
- app startup not complete.
- PVC not bound.

## 5. PVC Problem

```bash
kubectl -n apps get pvc,pv
kubectl -n apps describe pvc <name>
kubectl describe pv <name>
```

For local-path storage, remember:

- data is node-local.
- moving the pod to another node can break access.
- `Retain` means deleted PVCs can leave PVs behind intentionally.

## 6. Emergency Disable Public Route

Remove or patch the Ingress:

```bash
kubectl -n apps delete ingress <name>
```

or scale the app:

```bash
kubectl -n apps scale deploy/<name> --replicas=0
```

## 7. Full Reapply

```bash
make addons
make secrets
make production-check
make apply
make validate
```

This is safe only if `secrets/production.enc.yaml` decrypts correctly and the Git tree is clean.

## 8. Roll Back A Bad Manifest Change

```bash
git log --oneline -n 5
git revert <bad_commit>
kubectl diff -k .
make apply
make validate
```

If the bad change only affected one Deployment image:

```bash
kubectl -n apps rollout undo deploy/<name>
kubectl -n apps rollout status deploy/<name>
```

## 9. Move A Host Back To Swarm

During migration, DNS remains the safest rollback lever.

1. keep the Swarm service running.
2. lower DNS TTL before cutover.
3. validate the K3s route under a staging hostname.
4. move the production hostname only after validation.
5. if the K3s service fails, point DNS back to the Swarm edge IP.

## 10. Check For Secret Exposure Before Push

```bash
rg -n "BEGIN|PRIVATE KEY|password=|PASSWORD=|token=|TOKEN=|acme|htpasswd|kubeconfig" .
git status --short
```

Only placeholders and examples should appear.

## 11. Alerting

Prometheus sends alerts to Alertmanager through `platform/telemetry/alertmanager.yaml`. The receiver config lives in SOPS-managed `alertmanager-secret`, not plaintext manifests.

Check alerting:

```bash
kubectl -n ops get deploy prometheus alertmanager grafana
kubectl -n ops logs deploy/prometheus --tail=100
kubectl -n ops logs deploy/alertmanager --tail=100
kubectl -n ops port-forward svc/alertmanager 9093:9093
```

The production gate is not satisfied until the encrypted Alertmanager config routes to a real receiver and a test alert reaches the operator.
