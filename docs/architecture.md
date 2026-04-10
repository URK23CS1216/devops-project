# Architecture Documentation

## System Overview

The DevOps Demo project implements a complete end-to-end deployment pipeline following modern DevOps best practices. The architecture is designed for scalability, reliability, and zero-downtime deployments.

## Architecture Layers

### 1. Application Layer

**Technology:** Node.js 20 + Express.js

The application is a lightweight REST API with:
- Health check endpoints for Kubernetes probes
- Prometheus metrics endpoint for observability
- Structured JSON logging via Winston
- A web dashboard for visual monitoring

**Key Design Decisions:**
- Express.js chosen for simplicity and wide ecosystem support
- `prom-client` provides native Prometheus metrics without sidecar
- Graceful shutdown handling ensures clean termination in K8s
- Multi-stage Docker build keeps production image at ~80MB

### 2. Containerization Layer

**Technology:** Docker with multi-stage builds

```
Stage 1 (builder):    Node 20 Alpine + all deps + lint + test
Stage 2 (production): Node 20 Alpine + production deps only
```

**Security hardening:**
- `dumb-init` for proper PID 1 signal handling
- Non-root user (UID 1001)
- Read-only root filesystem
- No shell access in production image
- HEALTHCHECK instruction for Docker health monitoring

### 3. CI/CD Layer

**CI Technology:** GitHub Actions
**CD Technology:** ArgoCD (GitOps)

```
Push to main/dev
    ↓
[Lint] → ESLint + Hadolint
    ↓
[Test] → Jest + Coverage
    ↓
[Build] → Docker multi-stage build
    ↓
[Scan] → Trivy vulnerability scan
    ↓
[Push] → Docker Hub (tagged: sha-<commit>, branch, latest)
    ↓
[Update] → Helm values.yaml (image tag)
    ↓
[ArgoCD] → Detects Git change → Syncs to K8s
```

**GitOps model:**
- Kubernetes desired state is stored in Git (Helm chart)
- ArgoCD watches for changes and reconciles automatically
- Self-heal reverts manual cluster changes
- Full audit trail via Git history

### 4. Orchestration Layer

**Technology:** Kubernetes (Minikube/EKS/GKE)

**Resources deployed:**
| Resource | Count | Purpose |
|----------|-------|---------|
| Deployment | 1 | 3 replicas with rolling updates |
| Service | 1 | ClusterIP load balancing |
| Ingress | 1 | NGINX external access |
| HPA | 1 | Auto-scale 2→10 on CPU/Memory |
| ConfigMap | 1 | Non-sensitive config |
| Secret | 1 | Sensitive data |
| NetworkPolicy | 1 | Traffic restriction |
| ServiceAccount | 1 | RBAC identity |
| Role/RoleBinding | 1 | Least-privilege permissions |

**Zero-downtime deployment:**
- Rolling update with maxSurge=1, maxUnavailable=0
- Readiness probe gates traffic routing
- Liveness probe detects hung processes
- Startup probe allows slow starts without false positives
- 10-second minReadySeconds stabilization period
- Pod anti-affinity spreads replicas across nodes

### 5. Observability Layer

**Metrics:** Prometheus → Grafana
**Logs:** Promtail → Loki → Grafana
**Alerts:** Prometheus AlertManager

```
                    ┌─────────────┐
                    │   Grafana   │ ← Dashboards + Alerts
                    └──────┬──────┘
                    ┌──────┴──────┐
              ┌─────┤             ├─────┐
              │     └─────────────┘     │
        ┌─────┴─────┐            ┌─────┴─────┐
        │ Prometheus │            │    Loki    │
        │ (Metrics)  │            │   (Logs)   │
        └─────┬─────┘            └─────┬─────┘
              │                        │
        ┌─────┴─────┐            ┌─────┴─────┐
        │ /metrics   │            │  Promtail  │
        │ endpoint   │            │ (DaemonSet)│
        └────────────┘            └────────────┘
```

### 6. Security Layer

**Defense-in-depth approach:**

| Layer | Mechanism |
|-------|-----------|
| Image | Trivy scanning, minimal alpine base |
| Container | Non-root, read-only FS, no capabilities |
| Pod | Security context, seccomp profile |
| Namespace | Pod Security Standards (restricted) |
| Network | NetworkPolicy, ingress-only access |
| RBAC | Least-privilege ServiceAccount |
| Secrets | K8s Secrets (Vault for production) |
| Resources | ResourceQuota, LimitRange |

## Data Flow

1. **User Request** → Ingress Controller → Service → Pod
2. **Health Check** → kubelet → Pod:/api/health → 200 OK
3. **Metrics Scrape** → Prometheus → Pod:/metrics → TSDB
4. **Log Collection** → Promtail → Container stdout → Loki
5. **Alert Trigger** → Prometheus Rules → AlertManager → Notification
6. **Deployment** → ArgoCD → Helm → K8s API → Rolling Update

## Scaling Strategy

| Trigger | Action | Parameters |
|---------|--------|------------|
| CPU > 70% | Scale up | +2 pods/min, max 10 |
| Memory > 80% | Scale up | +2 pods/min, max 10 |
| CPU/Memory normal | Scale down | -1 pod/2min after 5min stabilization |
| Manual | `kubectl scale` | Override HPA temporarily |
