#!/usr/bin/env bash
# Replace the placeholder repo URL everywhere with the URL of your own fork.
set -euo pipefail

NEW="${1:?usage: set-repo-url.sh <git-repo-url>}"
OLD="https://github.com/example-org/gitops-platform-argocd.git"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

grep -rl --include='*.yaml' -F "$OLD" "$ROOT/apps" "$ROOT/bootstrap" | while read -r f; do
  sed -i.bak "s|$OLD|$NEW|g" "$f" && rm -f "$f.bak"
  echo "updated $f"
done
echo "Commit and push, then run: make bootstrap"
