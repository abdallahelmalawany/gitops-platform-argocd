#!/usr/bin/env bash
# Seal a secret value read from stdin so it is safe to commit.
# Usage: printf '%s' "$VALUE" | scripts/seal-secret.sh <namespace> <secret-name> <key> > out.yaml
set -euo pipefail

NS="${1:?namespace}"
NAME="${2:?secret name}"
KEY="${3:?key}"

command -v kubeseal >/dev/null || { echo "missing dependency: kubeseal" >&2; exit 1; }

kubectl create secret generic "$NAME" --namespace "$NS" \
  --from-file="$KEY=/dev/stdin" --dry-run=client -o yaml \
  | kubeseal --controller-name sealed-secrets-controller --controller-namespace kube-system -o yaml
