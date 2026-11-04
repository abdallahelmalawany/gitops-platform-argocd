#!/usr/bin/env bash
# Install ArgoCD, wait for it, then hand control to Git by applying the AppProjects and root app.
# NOTE: bootstrap/*.yaml reference https://github.com/example-org/gitops-platform-argocd.git.
# Fork/push this repo and run scripts/set-repo-url.sh <your-url> first.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command -v kubectl >/dev/null || { echo "missing dependency: kubectl" >&2; exit 1; }

if grep -rq "example-org/gitops-platform-argocd" "$ROOT/bootstrap/root-app.yaml" && [[ "${ALLOW_PLACEHOLDER_REPO:-0}" != "1" ]]; then
  echo "root-app.yaml still points at the placeholder repo URL." >&2
  echo "Run: scripts/set-repo-url.sh <your-repo-url>   (or ALLOW_PLACEHOLDER_REPO=1 to continue anyway)" >&2
  exit 1
fi

kubectl apply -k "$ROOT/bootstrap/argocd" --server-side
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=300s

kubectl apply -f "$ROOT/bootstrap/projects.yaml"
kubectl apply -f "$ROOT/bootstrap/root-app.yaml"

echo
echo "ArgoCD is up. Next:"
echo "  make argocd-password"
echo "  make port-forward   # https://localhost:8080 (user: admin)"
