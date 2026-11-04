# 0002. Sealed Secrets now, Vault later

Status: accepted

## Context
Secrets must be deliverable through the same Git workflow but must never be committed in plaintext. The target environment also uses HashiCorp Vault.

## Decision
Start with Bitnami Sealed Secrets: encrypted manifests live in Git, no external dependency, works on a laptop cluster. Plan Vault with External Secrets Operator for dynamic or rotated credentials as a later step.

## Consequences
- Simple and fully GitOps for static secrets.
- SealedSecrets are bound to one cluster key and namespace/name by default; moving them between clusters needs re-sealing.
- The controller private key is a critical backup item.
- No dynamic secrets or audit trail until Vault is added (tracked in the roadmap).
