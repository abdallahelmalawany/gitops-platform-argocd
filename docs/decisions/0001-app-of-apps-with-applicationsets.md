# 0001. App-of-apps with ApplicationSets

Status: accepted

## Context
We need to manage several environments and a growing list of platform components without copy-pasting Application manifests, and without applying anything to the cluster manually.

## Decision
Use a single hand-applied `root` Application that syncs `apps/`. That directory holds `ApplicationSet`s: a list generator for charts and environments, git directory generators for convention-based discovery (`environments/*`, `platform/config/*`). Per-env behaviour (auto vs manual sync) is controlled by `templatePatch`.

## Consequences
- Adding an environment or a config bundle is a new directory or a list entry.
- One bootstrap command recovers a cluster from Git.
- ApplicationSet templating (Go templates) is harder to debug than plain Applications; mistakes surface as controller errors. Pinning a recent ArgoCD (2.10+ for `templatePatch`) is required.
- The root app has broad rights; protect `main` with required reviews.
