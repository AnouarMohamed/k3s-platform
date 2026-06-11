# Secret Rotation

Changing a Kubernetes Secret does not automatically rotate credentials inside an initialized application database. Treat the encrypted Secret as the source of desired bootstrap/runtime values, then rotate the application or database credential at the real authority.

## Standard Workflow

1. Open a maintenance window for the affected app.
2. Generate the new credential locally.
3. Rotate the credential inside the app or database first.
4. Update `secrets/production.plain.yaml`.
5. Run `make encrypt-secrets`.
6. Apply with `make secrets`.
7. Restart only the workloads that read the changed value.
8. Verify login, background jobs, and backups.
9. Commit only `secrets/production.enc.yaml`.

## WordPress Admin Password

The Bitnami bootstrap values create the initial admin user. After first install, rotate the password through WordPress itself:

```bash
kubectl -n apps exec deploy/wordpress-demo -- wp user update <admin-user> --user_pass='<new-password>' --allow-root
```

Then update `WORDPRESS_ADMIN_PASSWORD` in the SOPS plaintext and re-encrypt so Git reflects the current emergency bootstrap value.

## Superset Admin Password

Rotate in Superset's application database:

```bash
kubectl -n apps exec deploy/superset -- superset fab reset-password --username <admin-user> --password '<new-password>'
```

Then update `SUPERSET_ADMIN_PASSWORD` in the encrypted secret source. Restart Superset only if the changed value is still read by startup automation.

## Portainer Admin Password

Generate a new bcrypt hash and update Portainer through its supported admin flow or by recreating the bootstrap admin state during a controlled maintenance window. Then update `PORTAINER_ADMIN_PASSWORD_HASH` and roll the Deployment:

```bash
make secrets
kubectl -n apps rollout restart deploy/portainer
kubectl -n apps rollout status deploy/portainer
```

Do not assume changing the hash file will modify an already initialized Portainer database without testing it.

## Passbolt Database Password

Rotate the database credential at MariaDB first, then update the app Secret:

```bash
db_pod="$(kubectl -n data get pod -l app.kubernetes.io/name=passbolt-db -o jsonpath='{.items[0].metadata.name}')"
kubectl -n data exec "${db_pod}" -- sh -ec 'mariadb -u passbolt -p"${MYSQL_PASSWORD}" -e "ALTER USER '\''passbolt'\''@'\''%'\'' IDENTIFIED BY '\''<new-password>'\''; FLUSH PRIVILEGES;"'
```

Update `PASSBOLT_DB_PASSWORD`, run `make encrypt-secrets`, `make secrets`, then restart Passbolt and verify login:

```bash
kubectl -n apps rollout restart deploy/passbolt
kubectl -n apps rollout status deploy/passbolt
```

## WordPress Database Password

Rotate the database user and Secret together during downtime:

```bash
kubectl -n apps scale deploy/wordpress-demo --replicas=0
db_pod="$(kubectl -n data get pod -l app.kubernetes.io/name=wordpress-db -o jsonpath='{.items[0].metadata.name}')"
kubectl -n data exec "${db_pod}" -- sh -ec 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "ALTER USER '\''wordpress'\''@'\''%'\'' IDENTIFIED BY '\''<new-password>'\''; FLUSH PRIVILEGES;"'
```

Update `WORDPRESS_DB_PASSWORD`, encrypt/apply secrets, and bring WordPress back:

```bash
make encrypt-secrets
make secrets
kubectl -n apps scale deploy/wordpress-demo --replicas=1
kubectl -n apps rollout status deploy/wordpress-demo
```

## Backup Repository Password

Rotating `RESTIC_PASSWORD` creates access to a different encrypted repository unless the Restic repository password is changed with Restic itself. Use the Restic password-change operation from a controlled pod or workstation that has the old password, then update `backup-s3-secret`.

After rotation:

```bash
kubectl -n apps create job --from=cronjob/backup-wordpress-db backup-wordpress-db-rotation-test
kubectl -n apps logs -f job/backup-wordpress-db-rotation-test
```

Run at least one backup and one restore listing before closing the rotation.
