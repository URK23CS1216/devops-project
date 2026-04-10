.PHONY: help install dev test lint build push deploy deploy-dev deploy-prod monitor argocd clean

# ============================================
# DevOps Demo — Makefile
# ============================================

DOCKER_IMAGE ?= your-dockerhub-username/devops-demo
IMAGE_TAG    ?= latest
NAMESPACE    ?= devops-demo
HELM_RELEASE ?= devops-demo
HELM_CHART   ?= helm/devops-demo

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ==========================================
# Development
# ==========================================

install: ## Install Node.js dependencies
	npm ci --no-audit --no-fund

dev: ## Start development server with auto-reload
	npm run dev

test: ## Run unit tests with coverage
	npm test

lint: ## Run ESLint
	npm run lint

lint-fix: ## Run ESLint with auto-fix
	npm run lint:fix

# ==========================================
# Docker
# ==========================================

build: ## Build Docker image
	docker build \
		--build-arg BUILD_DATE=$$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
		--build-arg COMMIT_SHA=$$(git rev-parse --short HEAD 2>/dev/null || echo "unknown") \
		--build-arg IMAGE_TAG=$(IMAGE_TAG) \
		-t $(DOCKER_IMAGE):$(IMAGE_TAG) .

push: ## Push Docker image to registry
	docker push $(DOCKER_IMAGE):$(IMAGE_TAG)

scan: ## Scan Docker image with Trivy
	trivy image --severity HIGH,CRITICAL $(DOCKER_IMAGE):$(IMAGE_TAG)

compose-up: ## Start local stack with Docker Compose
	docker compose up -d --build

compose-down: ## Stop local stack
	docker compose down

compose-logs: ## Follow local stack logs
	docker compose logs -f app

# ==========================================
# Kubernetes
# ==========================================

deploy: ## Deploy to Kubernetes with Helm (default values)
	helm upgrade --install $(HELM_RELEASE) $(HELM_CHART) \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--wait --timeout 5m

deploy-dev: ## Deploy to Kubernetes (dev environment)
	helm upgrade --install $(HELM_RELEASE) $(HELM_CHART) \
		-f $(HELM_CHART)/values-dev.yaml \
		--namespace $(NAMESPACE)-dev \
		--create-namespace \
		--wait --timeout 5m

deploy-prod: ## Deploy to Kubernetes (production)
	helm upgrade --install $(HELM_RELEASE) $(HELM_CHART) \
		-f $(HELM_CHART)/values-prod.yaml \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--wait --timeout 5m

helm-lint: ## Lint Helm chart
	helm lint $(HELM_CHART)

helm-template: ## Render Helm templates (dry-run)
	helm template $(HELM_RELEASE) $(HELM_CHART) -f $(HELM_CHART)/values-dev.yaml

rollback: ## Rollback to previous Helm release
	helm rollback $(HELM_RELEASE) --namespace $(NAMESPACE) --wait

status: ## Show deployment status
	@echo "=== Pods ==="
	kubectl get pods -n $(NAMESPACE) -o wide
	@echo ""
	@echo "=== Services ==="
	kubectl get svc -n $(NAMESPACE)
	@echo ""
	@echo "=== HPA ==="
	kubectl get hpa -n $(NAMESPACE)

port-forward: ## Port-forward the application to localhost:8080
	kubectl port-forward svc/$(HELM_RELEASE) 8080:80 -n $(NAMESPACE)

# ==========================================
# Monitoring & GitOps
# ==========================================

monitor: ## Deploy monitoring stack (Prometheus + Grafana + Loki)
	bash monitoring/install.sh

argocd: ## Install ArgoCD and configure application
	bash argocd/install.sh

grafana: ## Port-forward Grafana to localhost:3001
	kubectl port-forward svc/grafana -n monitoring 3001:80

prometheus: ## Port-forward Prometheus to localhost:9090
	kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090

# ==========================================
# Cleanup
# ==========================================

clean: ## Remove local artifacts
	rm -rf node_modules coverage dist build

uninstall: ## Uninstall Helm release from cluster
	helm uninstall $(HELM_RELEASE) --namespace $(NAMESPACE)
