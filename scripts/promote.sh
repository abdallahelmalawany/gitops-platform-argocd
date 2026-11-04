#!/usr/bin/env bash
# Copy the image tag from one environment to the next on a new branch (open a PR afterwards).
# Usage: scripts/promote.sh dev staging
set -euo pipefail

FROM="${1:?usage: promote.sh <from-env> <to-env>}"
TO="${2:?usage: promote.sh <from-env> <to-env>}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TAG="$(grep -E '^\s+tag:' "$ROOT/environments/$FROM/values.yaml" | head -1 | sed -E 's/.*tag:\s*"?([^"]+)"?.*/\1/')"
[[ -n "$TAG" ]] || { echo "could not read tag from $FROM" >&2; exit 1; }

BRANCH="promote/$TO-$TAG"
git -C "$ROOT" checkout -b "$BRANCH"
sed -i.bak -E "s|^(\s+tag:\s*).*|\1\"$TAG\"|" "$ROOT/environments/$TO/values.yaml"
rm -f "$ROOT/environments/$TO/values.yaml.bak"
git -C "$ROOT" commit -am "promote demo-web $TAG: $FROM -> $TO"
echo "Branch $BRANCH created. Push it and open a pull request; merging triggers the sync."
[[ "$TO" == "prod" ]] && echo "Prod is not auto-synced: sync demo-web-prod in ArgoCD after merge."
exit 0
