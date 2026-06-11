# Encrypted Secrets

Production secrets belong in `secrets/production.enc.yaml`, encrypted with SOPS + Age.

Create the plaintext file locally from the example:

```bash
cp secrets/production.plain.example.yaml secrets/production.plain.yaml
vim secrets/production.plain.yaml
```

Encrypt it:

```bash
export SOPS_AGE_RECIPIENTS=age1...
make encrypt-secrets
```

Apply encrypted secrets:

```bash
make secrets
```

`secrets/production.plain.yaml` is intentionally ignored. Commit only `*.enc.yaml`.

`alertmanager-secret` contains `alertmanager.yml`, including receiver URLs. Keep that config encrypted and route it to a real operator-owned webhook, email gateway, or paging integration before production cutover.
