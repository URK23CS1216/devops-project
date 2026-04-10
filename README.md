# 🚀 DevOps Demo — End-to-End CI/CD Pipeline

A production-grade DevOps pipeline featuring a containerized Node.js application deployed to Kubernetes with full CI/CD automation, GitOps delivery, and comprehensive observability.

![Node.js](https://img.shields.io/badge/Node.js-20-green?logo=node.js)
![Docker](https://img.shields.io/badge/Docker-Containerized-blue?logo=docker)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Orchestrated-326CE5?logo=kubernetes)
![Helm](https://img.shields.io/badge/Helm-Chart-0F9D58?logo=helm)
![ArgoCD](https://img.shields.io/badge/ArgoCD-GitOps-EF7B4D?logo=argo)
![Prometheus](https://img.shields.io/badge/Prometheus-Monitoring-E6522C?logo=prometheus)
![Grafana](https://img.shields.io/badge/Grafana-Dashboards-F46800?logo=grafana)

---

## 📋 Table of Contents

- [Architecture](#architecture)
- [Features](#features)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [CI/CD Pipeline](#cicd-pipeline)
- [Kubernetes Deployment](#kubernetes-deployment)
- [Monitoring](#monitoring)
- [Security](#security)
- [API Reference](#api-reference)
- [Contributing](#contributing)

---

## 🏗️ Architecture

```
Developer → GitHub → CI Pipeline → Docker Hub → ArgoCD → Kubernetes
                                                              │
                                                    ┌─────────┴──────────┐
                                                    │                    │
                                              Prometheus/Grafana    Loki/Promtail
                                              (Metrics & Alerts)   (Log Aggregation)
```

**Flow:**
1. Developer pushes code to GitHub
2. GitHub Actions runs lint → test → build → scan → push
3. CI updates Helm values with new image tag
4. ArgoCD detects change and syncs to Kubernetes
5. Rolling update deploys with zero downtime
6. Prometheus scrapes metrics, Grafana visualizes, alerts fire on issues

---

## ✨ Features

| Feature | Implementation |
|---------|---------------|
| **Web Application** | Node.js/Express with health checks and metrics |
| **Containerization** | Multi-stage Docker build, non-root user, ~80MB image |
| **CI Pipeline** | GitHub Actions: lint → test → build → scan → push |
| **CD Pipeline** | ArgoCD GitOps with auto-sync and self-heal |
| **Orchestration** | Kubernetes with Deployment, Service, Ingress, HPA |
| **Zero-Downtime** | Rolling updates (maxSurge:1, maxUnavailable:0) |
| **Helm Chart** | Fully templated with dev/prod value overrides |
| **Autoscaling** | HPA: CPU >70% and Memory >80% triggers |
| **Monitoring** | Prometheus + Grafana dashboards with custom metrics |
| **Logging** | Loki + Promtail centralized log aggregation |
| **Alerting** | Pod crashes, high CPU/memory, error rates, stuck rollouts |
| **Security** | RBAC, NetworkPolicy, Trivy scanning, Pod Security Standards |

---

## 🚀 Quick Start

### Prerequisites

- [Node.js 20+](https://nodejs.org/)
- [Docker](https://docs.docker.com/get-docker/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm 3](https://helm.sh/docs/intro/install/)
- [Minikube](https://minikube.sigs.k8s.io/docs/start/) (for local K8s)

### Option 1: Local Development

```bash
# Install dependencies
npm install

# Run tests
npm test

# Start dev server (auto-reload)
npm run dev

# Open http://localhost:3000
```

### Option 2: Docker Compose (Full Stack)

```bash
# Start app + Prometheus + Grafana + Loki
docker compose up -d --build

# App:        http://localhost:3000
# Prometheus: http://localhost:9090
# Grafana:    http://localhost:3001 (admin/admin)
```

### Option 3: Kubernetes (Minikube)

```powershell
# 1. Start Minikube
minikube start

# 2. Setup Vault & External Secrets Operator
.\security\install-vault.ps1

# 3. Build the Docker Image
# Pass Docker CLI to Minikube daemon
minikube docker-env | Invoke-Expression
docker build -t aldanjoseph2006/devops-demo:latest .

# 4. Deploy with Helm
.\windows-amd64\helm.exe upgrade --install devops-demo helm/devops-demo `
    -f helm/devops-demo/values-dev.yaml `
    --namespace devops-demo-dev --create-namespace `
    --set image.repository=aldanjoseph2006/devops-demo `
    --set image.tag=latest `
    --set image.pullPolicy=IfNotPresent

# 5. Port-forward to access
kubectl port-forward svc/devops-demo 8080:80 -n devops-demo-dev
```

---

## 🛠️ Recent Updates

- **External Secrets API**: Updated `secret.yaml` from `v1beta1` to `v1` to support newer operator versions.
- **Repository**: Updated default storage repository to `aldanjoseph2006/devops-demo`.
- **Vault Integration**: Successfully installed HashiCorp Vault (dev mode) and External Secrets Operator.
- **Environment**: Fixed deployment commands to work directly with `helm.exe` as `make` is not available in the local PowerShell environment.


---

## 📁 Project Structure

```
devops-demo/
├── src/                          # Application source code
│   ├── server.js                 # Express server entry point
│   ├── routes/
│   │   ├── health.js             # Health check endpoints
│   │   └── info.js               # App info endpoint
│   ├── middleware/
│   │   ├── metrics.js            # Prometheus metrics
│   │   └── logger.js             # Winston structured logging
│   └── public/
│       └── index.html            # Dashboard UI
├── tests/                        # Unit tests
├── .github/
│   └── workflows/
│       ├── ci.yml                # Full CI/CD pipeline
│       └── pr-check.yml          # PR validation
├── k8s/                          # Raw Kubernetes manifests
├── helm/devops-demo/             # Helm chart
│   ├── Chart.yaml
│   ├── values.yaml               # Default values
│   ├── values-dev.yaml           # Dev overrides
│   ├── values-prod.yaml          # Prod overrides
│   └── templates/                # K8s templates
├── argocd/                       # ArgoCD GitOps config
├── monitoring/                   # Observability stack
│   ├── prometheus/               # Prometheus config
│   ├── grafana/                  # Grafana dashboards
│   ├── loki/                     # Log aggregation
│   └── alerts/                   # Alert rules
├── security/                     # Security configs
├── Dockerfile                    # Multi-stage build
├── docker-compose.yml            # Local dev stack
├── Makefile                      # Automation commands
└── package.json
```

---

## 🔄 CI/CD Pipeline

### Continuous Integration (GitHub Actions)

| Stage | Trigger | Actions |
|-------|---------|---------|
| **Lint** | Push/PR | ESLint + Hadolint (Dockerfile) |
| **Test** | After Lint | Jest with coverage report |
| **Build** | After Test (main/dev only) | Docker multi-stage build |
| **Scan** | After Build | Trivy vulnerability scan |
| **Deploy** | After Scan (main only) | Update Helm values → ArgoCD sync |

### Continuous Deployment (ArgoCD)

- **GitOps model** — Kubernetes state is defined in Git
- **Auto-sync** — ArgoCD detects Helm value changes and deploys
- **Self-heal** — Reverts manual cluster changes to match Git
- **Prune** — Removes orphaned resources automatically

---

## ☸️ Kubernetes Deployment

### Zero-Downtime Strategy

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1        # Add 1 new pod before removing old
    maxUnavailable: 0  # Never reduce below desired count
minReadySeconds: 10    # Wait 10s before continuing rollout
```

### Key Resources

| Resource | Purpose |
|----------|---------|
| Deployment | 3 replicas with rolling updates |
| Service | ClusterIP on port 80 |
| Ingress | NGINX with rate limiting |
| HPA | Auto-scale 2-10 pods (CPU/Memory) |
| ConfigMap | Environment configuration |
| Secret | Sensitive data (API keys, passwords) |
| NetworkPolicy | Restrict pod communication |
| RBAC | Least-privilege service account |

---

## 📊 Monitoring

### Prometheus Metrics

The application exposes `/metrics` with:
- `devops_demo_http_requests_total` — Request counter by method/route/status
- `devops_demo_http_request_duration_seconds` — Latency histogram (p50/p95/p99)
- `devops_demo_http_request_errors_total` — Error counter
- `devops_demo_active_connections` — Active connection gauge
- Default Node.js metrics (GC, event loop, heap)

### Grafana Dashboard

Pre-configured dashboard includes:
- Request rate and latency percentiles
- Error rate with threshold coloring
- Pod CPU and memory usage
- Deployment replica status
- Node.js heap monitoring

### Alerts

| Alert | Condition | Severity |
|-------|-----------|----------|
| PodCrashLooping | Restarts > 0 in 15m | Critical |
| HighCPUUsage | > 85% for 10m | Warning |
| HighMemoryUsage | > 85% for 10m | Warning |
| HighErrorRate | 5xx > 1% for 5m | Critical |
| HighLatency | p95 > 1s for 5m | Warning |
| DeploymentRolloutStuck | No progress for 15m | Critical |

---

## 🔐 Security

- **Non-root container** — Runs as UID 1001
- **Read-only filesystem** — Container filesystem is immutable
- **Capabilities dropped** — All Linux capabilities removed
- **RBAC** — Least-privilege ServiceAccount
- **NetworkPolicy** — Pod communication restricted
- **Pod Security Standards** — Restricted profile enforced
- **Trivy scanning** — Automated vulnerability scanning in CI
- **Secrets management** — K8s Secrets (use Vault in production)
- **Image scanning** — CRITICAL/HIGH CVEs block deployment
- **ResourceQuota** — Namespace resource limits enforced

---

## 🌐 API Reference

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Dashboard UI |
| `/api/health` | GET | Full health check |
| `/api/health/ready` | GET | Readiness probe |
| `/api/health/live` | GET | Liveness probe |
| `/api/info` | GET | App version, runtime, host info |
| `/metrics` | GET | Prometheus metrics |

---

## 🤝 Contributing

1. Create a feature branch from `dev`
2. Make your changes
3. Run `npm test && npm run lint`
4. Submit a PR against `dev`
5. PRs to `main` require review from CODEOWNERS
6. CI must pass before merge

---

## 📄 License

MIT
