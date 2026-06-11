#!/usr/bin/env bash
# Purpose:
#   Create a one-shot Kubernetes Job that restores a Restic volume snapshot into
#   an existing PVC.
#
# Required environment:
#   RESTORE_TAG       Restic tag to restore, for example wordpress-content.
#   TARGET_PVC        Existing PVC that will receive restored files.
#   CONFIRM_RESTORE   Must be exactly "yes".
#
# Optional environment:
#   NAMESPACE         Kubernetes namespace. Defaults to apps.
#   RESTIC_SNAPSHOT   Restic snapshot ID. Defaults to latest.
#
# This script intentionally does not delete or empty the target PVC. Operators
# should scale the app down and decide whether the target should be clean before
# running the restore.
set -Eeuo pipefail

namespace="${NAMESPACE:-apps}"
restore_tag="${RESTORE_TAG:-}"
target_pvc="${TARGET_PVC:-}"
snapshot="${RESTIC_SNAPSHOT:-latest}"
confirm="${CONFIRM_RESTORE:-}"
job_suffix="$(date -u +%Y%m%d%H%M%S)"
dns_label_re='^[a-z0-9]([-a-z0-9]*[a-z0-9])?$'
simple_ref_re='^[A-Za-z0-9_.-]+$'

if [[ -z "${restore_tag}" || -z "${target_pvc}" ]]; then
  echo "RESTORE_TAG and TARGET_PVC are required." >&2
  echo "Example: RESTORE_TAG=wordpress-content TARGET_PVC=wordpress-content CONFIRM_RESTORE=yes make restore-volume" >&2
  exit 1
fi

if [[ ! "${namespace}" =~ ${dns_label_re} ]]; then
  echo "NAMESPACE must be a Kubernetes DNS label." >&2
  exit 1
fi

if [[ ! "${target_pvc}" =~ ${dns_label_re} ]]; then
  echo "TARGET_PVC must be a Kubernetes DNS label." >&2
  exit 1
fi

if [[ ! "${restore_tag}" =~ ${simple_ref_re} || ! "${snapshot}" =~ ${simple_ref_re} ]]; then
  echo "RESTORE_TAG and RESTIC_SNAPSHOT may contain only letters, numbers, dash, underscore, and dot." >&2
  exit 1
fi

if [[ "${confirm}" != "yes" ]]; then
  echo "Set CONFIRM_RESTORE=yes to create a restore Job that writes into PVC ${namespace}/${target_pvc}." >&2
  exit 1
fi

if ! kubectl -n "${namespace}" get secret backup-s3-secret >/dev/null 2>&1; then
  echo "Missing ${namespace}/backup-s3-secret. Apply SOPS secrets first." >&2
  exit 1
fi

if ! kubectl -n "${namespace}" get pvc "${target_pvc}" >/dev/null 2>&1; then
  echo "Missing PVC ${namespace}/${target_pvc}." >&2
  exit 1
fi

job_tag="$(printf '%s' "${restore_tag}" | tr '[:upper:]' '[:lower:]' | tr '._' '--' | tr -cd 'a-z0-9-')"
job_tag="${job_tag#-}"
job_tag="${job_tag%-}"
job_name="restore-${job_tag}-${job_suffix}"

if [[ -z "${job_tag}" || ${#job_name} -gt 63 ]]; then
  echo "RESTORE_TAG produces an invalid or too-long restore Job name." >&2
  exit 1
fi

kubectl -n "${namespace}" apply -f - <<MANIFEST
apiVersion: batch/v1
kind: Job
metadata:
  name: ${job_name}
  labels:
    app.kubernetes.io/name: ${job_name}
    app.kubernetes.io/component: restore
spec:
  backoffLimit: 0
  template:
    metadata:
      labels:
        app.kubernetes.io/name: ${job_name}
        app.kubernetes.io/component: restore
    spec:
      restartPolicy: Never
      automountServiceAccountToken: false
      securityContext:
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: restic-restore
          image: restic/restic:0.18.1@sha256:39d9072fb5651c80d75c7a811612eb60b4c06b32ffe87c2e9f3c7222e1797e76
          command: ["/bin/sh", "-ec"]
          args:
            - |
              restic snapshots --tag "${restore_tag}"
              restic restore "${snapshot}" --tag "${restore_tag}" --target /restore
              test -d /restore/source
              cp -a /restore/source/. /target/
              find /target -maxdepth 2 -mindepth 1 | sort | head -50
          envFrom:
            - secretRef:
                name: backup-s3-secret
          env:
            - name: RESTIC_CACHE_DIR
              value: /cache
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
                - ALL
          volumeMounts:
            - name: target
              mountPath: /target
            - name: restore
              mountPath: /restore
            - name: cache
              mountPath: /cache
      volumes:
        - name: target
          persistentVolumeClaim:
            claimName: ${target_pvc}
        - name: restore
          emptyDir: {}
        - name: cache
          emptyDir: {}
MANIFEST

echo "Created restore Job ${namespace}/${job_name}."
echo "Watch it with: kubectl -n ${namespace} logs -f job/${job_name}"
