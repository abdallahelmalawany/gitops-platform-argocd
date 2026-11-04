CLUSTER_NAME ?= gitops
ENVS         ?= dev staging prod
K8S_VERSION  ?= 1.31.0

.DEFAULT_GOAL := help
.PHONY: help cluster bootstrap lint validate trivy argocd-password port-forward promote clean

help: ## Show targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-16s %s\n", $$1, $$2}'

cluster: ## Create a local kind cluster
	./scripts/create-cluster.sh $(CLUSTER_NAME)

bootstrap: ## Install ArgoCD and apply the root app-of-apps
	./scripts/bootstrap.sh

lint: ## yamllint + helm lint for every environment
	yamllint -c .yamllint.yaml .
	@for env in $(ENVS); do helm lint charts/demo-web -f environments/$$env/values.yaml || exit 1; done

validate: ## Render chart/overlays and validate with kubeconform
	./scripts/validate.sh

trivy: ## Trivy config scan of the repository
	trivy config --severity HIGH,CRITICAL .

argocd-password: ## Print the initial ArgoCD admin password
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo

port-forward: ## Expose the ArgoCD UI on https://localhost:8080
	kubectl -n argocd port-forward svc/argocd-server 8080:80

promote: ## Promote an image tag: make promote FROM=dev TO=staging
	./scripts/promote.sh $(FROM) $(TO)

clean: ## Delete the local kind cluster
	kind delete cluster --name $(CLUSTER_NAME)
