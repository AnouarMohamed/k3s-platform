# Restore Passbolt

Passbolt restore requires both the database and `passbolt-data` PVC. The PVC may contain server-side key material and generated runtime state, so treat it as mandatory.

## Preconditions

- `backup-passbolt-db` and `backup-passbolt-data` have recent successful snapshots.
- `secrets/production.enc.yaml` has been applied.
- The target PVCs exist: `passbolt-db` and `passbolt-data`.
- Users are blocked from changing passwords or secrets during the maintenance window.

Check backup state:

```bash
kubectl -n apps get cronjob backup-passbolt-db backup-passbolt-data
kubectl -n apps create job --from=cronjob/backup-passbolt-db backup-passbolt-db-manual
kubectl -n apps create job --from=cronjob/backup-passbolt-data backup-passbolt-data-manual
kubectl -n apps logs -f job/backup-passbolt-db-manual
kubectl -n apps logs -f job/backup-passbolt-data-manual
```

## Restore Passbolt Data PVC

Scale Passbolt down before writing restored files:

```bash
kubectl -n apps scale deploy/passbolt --replicas=0
```

Restore the latest PVC snapshot:

```bash
RESTORE_TAG=passbolt-data TARGET_PVC=passbolt-data CONFIRM_RESTORE=yes make restore-volume
kubectl -n apps logs -f job/restore-passbolt-data-<timestamp>
```

For a specific snapshot, add `RESTIC_SNAPSHOT=<snapshot-id>`.

## Restore Database

Start the database and keep Passbolt stopped:

```bash
kubectl -n apps scale deploy/passbolt-db --replicas=1
kubectl -n apps rollout status deploy/passbolt-db
```

Create a restore Job. The init container pulls the SQL dump from Restic, then the MariaDB client container imports it into the running database:

```bash
kubectl -n apps apply -f - <<'MANIFEST'
apiVersion: batch/v1
kind: Job
metadata:
  name: passbolt-db-restore
spec:
  backoffLimit: 0
  template:
    spec:
      restartPolicy: Never
      automountServiceAccountToken: false
      initContainers:
        - name: restic-restore
          image: restic/restic:0.18.1@sha256:39d9072fb5651c80d75c7a811612eb60b4c06b32ffe87c2e9f3c7222e1797e76
          command: ["/bin/sh", "-ec"]
          args:
            - restic restore latest --tag passbolt-db --target /restore
          envFrom:
            - secretRef:
                name: backup-s3-secret
          env:
            - name: RESTIC_CACHE_DIR
              value: /cache
          volumeMounts:
            - name: restore
              mountPath: /restore
            - name: cache
              mountPath: /cache
      containers:
        - name: mariadb-import
          image: mariadb:10.11.18@sha256:5a5c675881ef3fd1c1da9b0a3bfd6ee82edbe39cd9e32e06be18034c37235e0e
          command: ["/bin/sh", "-ec"]
          args:
            - |
              sql_file="$(find /restore/backup -name 'passbolt-*.sql' | sort | tail -1)"
              test -n "${sql_file}"
              mariadb -h passbolt-db.apps.svc.cluster.local -u passbolt passbolt < "${sql_file}"
          env:
            - name: MARIADB_PWD
              valueFrom:
                secretKeyRef:
                  name: passbolt-secret
                  key: PASSBOLT_DB_PASSWORD
          volumeMounts:
            - name: restore
              mountPath: /restore
              readOnly: true
      volumes:
        - name: restore
          emptyDir: {}
        - name: cache
          emptyDir: {}
MANIFEST
kubectl -n apps logs -f job/passbolt-db-restore
```

For a specific snapshot, replace `latest` in the Job manifest with the snapshot ID.

Clean up:

```bash
kubectl -n apps delete job passbolt-db-restore
```

## Validate

```bash
kubectl -n apps scale deploy/passbolt --replicas=1
kubectl -n apps rollout status deploy/passbolt
kubectl -n apps logs deploy/passbolt --tail=100
```

Confirm login, user key access, email delivery, and password decrypt operations. Do not close the incident until a new manual `backup-passbolt-db` and `backup-passbolt-data` run succeeds.
