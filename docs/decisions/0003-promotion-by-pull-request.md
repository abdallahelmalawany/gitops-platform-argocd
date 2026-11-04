# 0003. Promotion by pull request, manual sync for prod

Status: accepted

## Context
Environments share one chart. We want traceable, reviewable promotion and a human gate in production without a separate deployment tool.

## Decision
Each environment pins its own image tag in `environments/<env>/values.yaml`. Promotion copies the tag forward on a branch (`scripts/promote.sh`) and goes through a pull request protected by CI. dev and staging auto-sync on merge. prod is merged the same way but its ArgoCD Application has no automated sync, so an operator syncs it explicitly.

## Consequences
- Full audit trail in Git; rollback is `git revert`.
- Single branch (`main`) keeps the model simple; the trade-off is that prod config is visible as pending in Git before it is live.
- A merged but unsynced prod change can be forgotten; ArgoCD notifications for OutOfSync prod are on the roadmap.
