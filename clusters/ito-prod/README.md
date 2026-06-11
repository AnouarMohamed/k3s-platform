# ITO Production Cluster

This folder is reserved for production cluster notes and future overlays.

The active production Kustomize entrypoint is still the repository root:

```bash
kubectl kustomize .
kubectl diff -k .
kubectl apply -k .
```

Before applying to a real server, replace every value in `platform/settings.yaml`, commit `secrets/production.enc.yaml`, and confirm backup restore has been tested.

A future `base/` restructure can support multiple overlays cleanly. This repo intentionally avoids nested overlays that require disabling Kustomize load restrictions.
