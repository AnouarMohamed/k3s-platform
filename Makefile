.PHONY: help bootstrap addons secrets apply validate diff

help:
	@printf '%s\n' \
	  'Targets:' \
	  '  make bootstrap  Install K3s on the current Linux node' \
	  '  make addons     Install ingress-nginx and cert-manager with Helm' \
	  '  make secrets    Create lab secrets from .env' \
	  '  make apply      Apply the platform and app manifests' \
	  '  make validate   Run cluster validation checks' \
	  '  make diff       Show server-side diff for the Kustomize tree'

bootstrap:
	./scripts/bootstrap-k3s.sh

addons:
	./scripts/install-addons.sh

secrets:
	./scripts/create-lab-secrets.sh

apply:
	./scripts/apply-platform.sh

validate:
	./scripts/validate.sh

diff:
	kubectl diff -k . || true
