# Restore WordPress

Use this after proving that both `backup-wordpress-db` and `backup-wordpress-content` have recent successful snapshots.

## Preconditions

- `secrets/production.enc.yaml` has been applied with `make secrets`.
- The Restic repository is reachable from the cluster.
- The target PVCs exist: `wordpress-db` and `wordpress-content`.
- WordPress is in a maintenance window.

Check backup state:

```bash
kubectl -n apps get cronjob backup-wordpress-db backup-wordpress-content
kubectl -n apps create job --from=cronjob/backup-wordpress-db backup-wordpress-db-manual
kubectl -n apps create job --from=cronjob/backup-wordpress-content backup-wordpress-content-manual
kubectl -n apps logs -f job/backup-wordpress-db-manual
kubectl -n apps logs -f job/backup-wordpress-content-manual
```

## Restore Content PVC

Scale WordPress down so files are not changing during restore:

```bash
kubectl -n apps scale deploy/wordpress-demo --replicas=0
```

Restore the latest `wordpress-content` Restic snapshot into the existing PVC:

```bash
RESTORE_TAG=wordpress-content TARGET_PVC=wordpress-content CONFIRM_RESTORE=yes make restore-volume
kubectl -n apps logs -f job/restore-wordpress-content-<timestamp>
```

For a specific snapshot, add `RESTIC_SNAPSHOT=<snapshot-id>`.

## Restore Database

Start the database and keep WordPress stopped:

```bash
kubectl -n data scale deploy/wordpress-db --replicas=1
kubectl -n data rollout status deploy/wordpress-db
```

Create a restore Job. The init container pulls the SQL dump from Restic, then the MySQL client container imports it into the running database:

```bash
kubectl -n apps apply -f - <<'MANIFEST'
apiVersion: batch/v1
kind: Job
metadata:
  name: wordpress-db-restore
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
            - restic restore latest --tag wordpress-db --target /restore
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
        - name: mysql-import
          image: mysql:8.4.9@sha256:c36050afdca850f23cef85703f84c7531a5ae155a11b5ee1c60acb09937c4084
          command: ["/bin/sh", "-ec"]
          args:
            - |
              sql_file="$(find /restore/backup -name 'wordpress-*.sql' | sort | tail -1)"
              test -n "${sql_file}"
              mysql -h wordpress-db.data.svc.cluster.local -u root wordpress < "${sql_file}"
          env:
            - name: MYSQL_PWD
              valueFrom:
                secretKeyRef:
                  name: wordpress-demo-secret
                  key: MYSQL_ROOT_PASSWORD
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
kubectl -n apps logs -f job/wordpress-db-restore
```

For a specific snapshot, replace `latest` in the Job manifest with the snapshot ID.

Clean up:

```bash
kubectl -n apps delete job wordpress-db-restore
```

## Validate

```bash
kubectl -n apps scale deploy/wordpress-demo --replicas=1
kubectl -n apps rollout status deploy/wordpress-demo
kubectl -n apps get ingress wordpress-demo
kubectl -n apps logs deploy/wordpress-demo --tail=100
```

Confirm the site loads, media files are present, and admin login works. Do not close the incident until a new manual backup succeeds after restore.
