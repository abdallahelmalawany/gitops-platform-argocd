#!/usr/bin/env bash
# Create a local kind cluster with host ports 80/443 mapped for ingress-nginx.
set -euo pipefail

NAME="${1:-gitops}"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for bin in kind kubectl; do
  command -v "$bin" >/dev/null || { echo "missing dependency: $bin" >&2; exit 1; }
done

if kind get clusters | grep -qx "$NAME"; then
  echo "cluster '$NAME' already exists"
else
  kind create cluster --name "$NAME" --config "$DIR/kind-config.yaml"
fi
kubectl cluster-info --context "kind-$NAME"
