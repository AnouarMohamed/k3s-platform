.PHONY: help bootstrap addons secrets apply validate diff check

help:
	@printf '%s\n' \
	  'Targets:' \
	  '  make bootstrap  Install K3s on the current Linux node' \
	  '  make addons     Install ingress-nginx and cert-manager with Helm' \
	  '  make secrets    Create Kubernetes Secrets from .env' \
	  '  make apply      Apply the platform and app manifests' \
	  '  make validate   Run cluster validation checks' \
	  '  make diff       Show server-side diff for the Kustomize tree' \
	  '  make check      Render manifests and run static repository checks'

bootstrap:
	./scripts/bootstrap-k3s.sh

addons:
	./scripts/install-addons.sh

secrets:
	./scripts/create-secrets.sh

apply:
	./scripts/apply-platform.sh

validate:
	./scripts/validate.sh

diff:
	kubectl diff -k . || true

check:
	./scripts/check-manifests.sh
