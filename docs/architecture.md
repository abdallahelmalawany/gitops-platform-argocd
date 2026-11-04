# Architecture

## Goals

1. Everything in the cluster beyond ArgoCD itself is declared in Git and reconciled automatically.
2. Adding an environment or a platform component is a small, reviewable diff.
3. Production changes need a human gate; lower environments move fast.

## Control plane

ArgoCD runs in the `argocd` namespace. `bootstrap/root-app.yaml` defines the `root` Application, which syncs the `apps/` directory. That directory contains only `ApplicationSet` objects, so adding a file there adds a family of applications.

| ApplicationSet | Generator | Produces | Sync policy |
|----------------|-----------|----------|-------------|
| `platform-helm` | list (name, chart repo, version, namespace, wave) | one app per upstream Helm chart, values from `platform/<name>/values.yaml` | automated |
| `platform-config` | git directories `platform/config/*` | one Kustomize app per directory (ClusterIssuers, policies, network defaults) | automated, wave 2 |
| `env-baseline` | git directories `environments/*` (excluding `base`) | namespace, quota, limit range, default-deny per environment | automated |
| `demo-web` | list (env, autoSync) | one Helm app per environment from `charts/demo-web` | automated for dev/staging, manual for prod via `templatePatch` |

### Projects

- `platform`: may deploy anywhere, cluster-scoped resources allowed, restricted to this repository and the listed chart repositories.
- `workloads`: destinations limited to `demo-*` namespaces, only the Namespace kind allowed at cluster scope, and ResourceQuota blacklisted so tenants cannot raise their own quota.

## Ordering

Sync waves are set on the generated Applications: Helm charts providing CRDs (cert-manager, Kyverno) are wave 0, monitoring wave 1, config that consumes CRDs (ClusterIssuers, ClusterPolicies) wave 2. Waves between Applications are only honoured by ArgoCD when the parent (here `root`) orders them; because ApplicationSet-generated apps are created together, config apps also use `SkipDryRunOnMissingResource=true` and automated retry/self-heal so they converge once CRDs exist. `demo-web-<env>` has an explicit `retry` block because its namespace is created by `env-baseline-<env>`.

## Workload chart

`charts/demo-web` renders: ServiceAccount (no token automount), Deployment (non-root UID 101, read-only root filesystem, `/tmp` emptyDir, drop ALL capabilities, RuntimeDefault seccomp), Service, Ingress (TLS annotation for cert-manager), optional HPA, optional PDB and a NetworkPolicy that only admits traffic from the ingress-nginx namespace (plus optional extra rules, used in prod for Prometheus).

The image is `nginxinc/nginx-unprivileged`, listening on 8080, so no privileged port or root is needed.

## Environments

| | dev | staging | prod |
|--|-----|---------|------|
| Replicas | 1 | 2 (HPA 2-4) | HPA 3-10 |
| PDB | off | minAvailable 1 | minAvailable 2 |
| Issuer | selfsigned | letsencrypt-staging | letsencrypt-prod |
| ArgoCD sync | automated | automated | manual |
| Quota (requests.cpu) | 1 | 2 | 6 |

Per-environment values live in `environments/<env>/values.yaml`; guardrail objects are a Kustomize overlay (`kustomization.yaml`) over `environments/base`, which renames the namespace and patches the quota.

## Secrets

Sealed Secrets is used for secrets that must live in Git: the controller holds a private key, `kubeseal` encrypts with the public certificate, and only the encrypted `SealedSecret` is committed. See [ADR 0002](decisions/0002-sealed-secrets-now-vault-later.md). Examples in this repo are placeholders.

## Observability

kube-prometheus-stack is configured to discover ServiceMonitors and PrometheusRules in all namespaces. ingress-nginx and cert-manager expose metrics; their ServiceMonitors are switched off by default until the CRDs are installed (enable after first sync). Grafana reads its admin credentials from a pre-created Secret.

## Failure and rollback

- Drift is reverted by `selfHeal` in dev/staging; in prod it is reported as OutOfSync.
- Rollback is `git revert` of the offending commit followed by a sync. ArgoCD history rollback is avoided because it diverges from Git.
- Losing the Sealed Secrets private key makes existing SealedSecrets undecryptable; back it up out of band.

## Known limitations

- Not deployed or load-tested; see the validation table in the README.
- Single cluster, in-cluster destination only.
- ArgoCD admin account, no SSO, no notifications.
- Chart and manifest versions need a fresh check before real use.
