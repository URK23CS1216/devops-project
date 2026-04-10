#!/bin/bash
set -euo pipefail

# ============================================
# ArgoCD Installation Script
# ============================================
# This script installs ArgoCD on a Kubernetes cluster
# and configures it for the DevOps Demo project.
#
# Prerequisites:
#   - kubectl configured with cluster access
#   - Helm 3 installed
# ============================================

echo "══════════════════════════════════════════════"
echo "  🔄 Installing ArgoCD"
echo "══════════════════════════════════════════════"

# 1. Create ArgoCD namespace
echo ""
echo "📦 Creating argocd namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# 2. Install ArgoCD using official manifests
echo ""
echo "⬇️  Installing ArgoCD (stable release)..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. Wait for ArgoCD to be ready
echo ""
echo "⏳ Waiting for ArgoCD server to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# 4. Get initial admin password
echo ""
echo "🔑 Initial admin password:"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "   Username: admin"
echo "   Password: ${ARGOCD_PASSWORD}"
echo ""
echo "   ⚠️  Change this password after first login!"

# 5. Apply ArgoCD project
echo ""
echo "📋 Creating ArgoCD project..."
kubectl apply -f "$(dirname "$0")/project.yaml"

# 6. Create devops-demo namespace
echo ""
echo "📦 Creating devops-demo namespace..."
kubectl create namespace devops-demo --dry-run=client -o yaml | kubectl apply -f -

# 7. Apply ArgoCD application
echo ""
echo "🚀 Creating ArgoCD application..."
kubectl apply -f "$(dirname "$0")/application.yaml"

# 8. Port-forward instructions
echo ""
echo "══════════════════════════════════════════════"
echo "  ✅ ArgoCD Installation Complete!"
echo "══════════════════════════════════════════════"
echo ""
echo "  Access ArgoCD UI:"
echo "    kubectl port-forward svc/argocd-server -n argocd 8443:443"
echo "    Open: https://localhost:8443"
echo ""
echo "  Check application sync status:"
echo "    kubectl get applications -n argocd"
echo ""
echo "  Using ArgoCD CLI:"
echo "    argocd login localhost:8443 --username admin --password '${ARGOCD_PASSWORD}' --insecure"
echo "    argocd app list"
echo "    argocd app sync devops-demo"
echo ""
