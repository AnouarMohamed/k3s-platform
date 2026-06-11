KUSTOMIZE_PATH ?= .

.PHONY: help bootstrap addons secrets local-secrets encrypt-secrets apply validate diff check production-check restore-volume

help:
	@printf '%s\n' \
	  'Targets:' \
	  '  make bootstrap  Install K3s on the current Linux node' \
	  '  make addons     Install ingress-nginx and cert-manager with Helm' \
	  '  make secrets    Apply SOPS-encrypted Kubernetes Secrets' \
	  '  make local-secrets Create Kubernetes Secrets from .env for break-glass bootstrap' \
	  '  make encrypt-secrets Encrypt secrets/production.plain.yaml with SOPS + Age' \
	  '  make apply      Apply the platform and app manifests' \
	  '  make validate   Run cluster validation checks' \
	  '  make diff       Show server-side diff for the Kustomize tree' \
	  '  make check      Render manifests and run static repository checks' \
	  '  make production-check Run structural production readiness checks; set REQUIRE_REAL_PRODUCTION_VALUES=true for cutover gates' \
	  '  make restore-volume Restore a Restic volume snapshot into a PVC; requires RESTORE_TAG, TARGET_PVC, CONFIRM_RESTORE=yes'

bootstrap:
	./scripts/bootstrap-k3s.sh

addons:
	./scripts/install-addons.sh

secrets:
	./scripts/apply-sops-secrets.sh

local-secrets:
	./scripts/create-secrets.sh

encrypt-secrets:
	./scripts/encrypt-sops-secrets.sh

apply:
	./scripts/apply-platform.sh

validate:
	./scripts/validate.sh

diff:
	kubectl diff -k $(KUSTOMIZE_PATH) || true

check:
	./scripts/check-manifests.sh

production-check:
	./scripts/check-production-readiness.sh

restore-volume:
	./scripts/restore-restic-volume.sh
