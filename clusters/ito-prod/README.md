# ITO Production Cluster

This folder is reserved for production cluster notes and future overlays.

The active Kustomize entrypoint is the repository root:

```bash
kubectl kustomize .
kubectl diff -k .
kubectl apply -k .
```

Before applying to a real server, replace every value in `platform/settings.yaml`, create real runtime secrets with `make secrets`, and confirm backups exist for all stateful workloads.
