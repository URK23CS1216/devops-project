# Monitoring Guide

## Overview

The monitoring stack consists of three main components:

| Component | Purpose | Port |
|-----------|---------|------|
| **Prometheus** | Metrics collection & alerting | 9090 |
| **Grafana** | Visualization & dashboards | 3000 (3001 locally) |
| **Loki + Promtail** | Log aggregation | 3100 |

---

## Accessing Monitoring Tools

### Docker Compose (Local)

```bash
docker compose up -d
```

| Tool | URL | Credentials |
|------|-----|-------------|
| Prometheus | http://localhost:9090 | — |
| Grafana | http://localhost:3001 | admin / admin |

### Kubernetes

```bash
# Grafana
kubectl port-forward svc/grafana -n monitoring 3001:80

# Prometheus
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090

# AlertManager
kubectl port-forward svc/prometheus-kube-prometheus-alertmanager -n monitoring 9093:9093
```

---

## Grafana Dashboard

### DevOps Demo — Application Dashboard

The pre-configured dashboard includes these panels:

| Panel | Description | Alert Threshold |
|-------|-------------|-----------------|
| **Request Rate** | Requests per second by method/route/status | — |
| **Response Latency** | p50, p95, p99 percentiles | p95 > 1s |
| **Error Rate** | Percentage of 5xx responses | > 1% |
| **Active Connections** | Current active HTTP connections | > 100 |
| **Pod CPU Usage** | CPU usage per pod (percentage of limit) | > 85% |
| **Pod Memory Usage** | Memory usage per pod (MB) | > 85% |
| **Pod Status** | Table of pod information | — |
| **Deployment Replicas** | Available vs desired replicas | Mismatch |
| **Node.js Heap** | V8 heap used per instance | — |

### Importing Custom Dashboards

1. Open Grafana → Dashboards → Import
2. Upload `monitoring/grafana/dashboards/app-dashboard.json`
3. Select "Prometheus" as the data source

---

## Prometheus Queries

### Useful Queries

```promql
# Request rate per second
rate(devops_demo_http_requests_total[5m])

# 95th percentile latency
histogram_quantile(0.95, rate(devops_demo_http_request_duration_seconds_bucket[5m]))

# Error rate percentage
sum(rate(devops_demo_http_request_errors_total{status_code=~"5.."}[5m])) /
sum(rate(devops_demo_http_requests_total[5m])) * 100

# Active connections
devops_demo_active_connections

# Node.js heap usage (MB)
devops_demo_nodejs_heap_size_used_bytes / 1024 / 1024

# Pod CPU usage
rate(container_cpu_usage_seconds_total{namespace="devops-demo", container="devops-demo"}[5m])

# Pod memory usage (MB)
container_memory_working_set_bytes{namespace="devops-demo", container="devops-demo"} / 1024 / 1024
```

---

## Alerts

### Active Alert Rules

| Alert | Condition | Severity | Action |
|-------|-----------|----------|--------|
| **PodCrashLooping** | Restart rate > 0 for 5m | 🔴 Critical | Check pod logs, investigate OOM or crash |
| **PodNotReady** | Not ready for 5m | 🟡 Warning | Check readiness probe, dependencies |
| **HighCPUUsage** | > 85% of limit for 10m | 🟡 Warning | Consider scaling up or optimizing code |
| **HighMemoryUsage** | > 85% of limit for 10m | 🟡 Warning | Check for memory leaks, increase limits |
| **HighErrorRate** | 5xx > 1% for 5m | 🔴 Critical | Check app logs, investigate error source |
| **HighLatency** | p95 > 1s for 5m | 🟡 Warning | Profile app, check downstream services |
| **DeploymentReplicasMismatch** | Mismatch for 10m | 🟡 Warning | Check HPA, node resources |
| **DeploymentRolloutStuck** | No progress for 15m | 🔴 Critical | Check pod events, image pull issues |
| **HealthCheckFailing** | Target down for 2m | 🔴 Critical | Check pod status, network connectivity |

### Responding to Alerts

**General debugging steps:**

```bash
# 1. Check pod status
kubectl get pods -n devops-demo

# 2. View pod events
kubectl describe pod <pod-name> -n devops-demo

# 3. Check pod logs
kubectl logs <pod-name> -n devops-demo --tail=100

# 4. Check previous container logs (for crashes)
kubectl logs <pod-name> -n devops-demo --previous

# 5. Check resource usage
kubectl top pods -n devops-demo

# 6. Check HPA status
kubectl describe hpa -n devops-demo
```

---

## Log Queries (Loki)

In Grafana → Explore → Select "Loki" datasource:

```logql
# All app logs
{app="devops-demo"}

# Error logs only
{app="devops-demo"} |= "error"

# Specific pod logs
{app="devops-demo", pod="devops-demo-abc123"}

# JSON parsed logs with level filter
{app="devops-demo"} | json | level="error"

# HTTP 500 errors
{app="devops-demo"} | json | statusCode="500"

# Slow requests (> 1000ms)
{app="devops-demo"} | json | duration > 1000
```

---

## Adding Custom Metrics

To add new application metrics, edit `src/middleware/metrics.js`:

```javascript
// Example: Custom business metric
const ordersProcessed = new client.Counter({
  name: 'devops_demo_orders_processed_total',
  help: 'Total orders processed',
  labelNames: ['status'],
});

// Increment in your route handler
ordersProcessed.inc({ status: 'success' });
```

The metric will automatically appear at `/metrics` and can be queried in Prometheus/Grafana.
