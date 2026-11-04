#!/usr/bin/env bash
# Render Helm + Kustomize and validate with kubeconform (CRDs via the datree catalog).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
K8S="${K8S_VERSION:-1.31.0}"
CRDS='https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json'

for bin in helm kubectl kubeconform; do
  command -v "$bin" >/dev/null || { echo "missing dependency: $bin" >&2; exit 1; }
done

cd "$ROOT"
for env in dev staging prod; do
  echo "== chart / $env"
  helm template demo-web charts/demo-web -f "environments/$env/values.yaml" \
    | kubeconform -strict -summary -kubernetes-version "$K8S"
  echo "== kustomize / environments/$env"
  kubectl kustomize "environments/$env" \
    | kubeconform -strict -summary -ignore-missing-schemas -schema-location default \
        -schema-location "$CRDS" -kubernetes-version "$K8S"
done

for dir in platform/config/*; do
  echo "== kustomize / $dir"
  kubectl kustomize "$dir" \
    | kubeconform -strict -summary -ignore-missing-schemas -schema-location default \
        -schema-location "$CRDS" -kubernetes-version "$K8S"
done

echo "== argocd manifests"
kubeconform -strict -summary -ignore-missing-schemas -schema-location default \
  -schema-location "$CRDS" apps bootstrap/root-app.yaml bootstrap/projects.yaml
