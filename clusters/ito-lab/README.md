# ITO Lab Cluster

This folder is reserved for cluster-specific notes and future overlays.

The active Kustomize entrypoint is the repository root:

```bash
kubectl apply -k .
kubectl diff -k .
```

The root entrypoint is intentional because `kubectl kustomize` enforces load restrictions when a nested kustomization references files outside its directory. Keeping the active entrypoint at the root makes the lab work with plain `kubectl` and without custom flags.
