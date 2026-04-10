#!/bin/bash
set -euo pipefail

# ============================================
# Monitoring Stack Installation Script
# ============================================
# Deploys Prometheus, Grafana, and Loki on K8s
# ============================================

echo "══════════════════════════════════════════════"
echo "  📊 Installing Monitoring Stack"
echo "══════════════════════════════════════════════"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Create monitoring namespace
echo ""
echo "📦 Creating monitoring namespace..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# 2. Add Helm repositories
echo ""
echo "📥 Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# 3. Install Prometheus + AlertManager
echo ""
echo "🔥 Installing Prometheus (kube-prometheus-stack)..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values "${SCRIPT_DIR}/prometheus/values.yaml" \
  --set prometheus.prometheusSpec.additionalScrapeConfigs[0].job_name=devops-demo \
  --wait --timeout 5m

# 4. Apply custom alert rules
echo ""
echo "🔔 Applying custom alert rules..."
kubectl create configmap prometheus-custom-rules \
  --from-file="${SCRIPT_DIR}/alerts/rules.yaml" \
  --namespace monitoring \
  --dry-run=client -o yaml | kubectl apply -f -

# 5. Install Grafana
echo ""
echo "📊 Installing Grafana..."
helm upgrade --install grafana grafana/grafana \
  --namespace monitoring \
  --values "${SCRIPT_DIR}/grafana/values.yaml" \
  --wait --timeout 3m

# 6. Import Grafana dashboards
echo ""
echo "📋 Creating dashboard ConfigMap..."
kubectl create configmap grafana-dashboards \
  --from-file="${SCRIPT_DIR}/grafana/dashboards/" \
  --namespace monitoring \
  --dry-run=client -o yaml | kubectl apply -f -

# 7. Install Loki + Promtail
echo ""
echo "📝 Installing Loki (log aggregation)..."
helm upgrade --install loki grafana/loki-stack \
  --namespace monitoring \
  --values "${SCRIPT_DIR}/loki/values.yaml" \
  --wait --timeout 3m

# 8. Summary
echo ""
echo "══════════════════════════════════════════════"
echo "  ✅ Monitoring Stack Installed!"
echo "══════════════════════════════════════════════"
echo ""
echo "  📊 Access Grafana:"
echo "    kubectl port-forward svc/grafana -n monitoring 3001:80"
echo "    Open: http://localhost:3001"
echo "    User: admin / Password: admin"
echo ""
echo "  🔥 Access Prometheus:"
echo "    kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090"
echo "    Open: http://localhost:9090"
echo ""
echo "  🔔 Access AlertManager:"
echo "    kubectl port-forward svc/prometheus-kube-prometheus-alertmanager -n monitoring 9093:9093"
echo "    Open: http://localhost:9093"
echo ""
echo "  📝 Query Loki logs in Grafana → Explore → Loki datasource"
echo ""
