# Deployment Guide

## Prerequisites

Ensure the following tools are installed:

| Tool | Version | Install |
|------|---------|---------|
| Node.js | 20+ | [nodejs.org](https://nodejs.org/) |
| Docker | 24+ | [docs.docker.com](https://docs.docker.com/get-docker/) |
| kubectl | 1.28+ | [kubernetes.io](https://kubernetes.io/docs/tasks/tools/) |
| Helm | 3.14+ | [helm.sh](https://helm.sh/docs/intro/install/) |
| Minikube | 1.32+ | [minikube.sigs.k8s.io](https://minikube.sigs.k8s.io/docs/start/) |

---

## 1. Local Development (No Docker)

```bash
# Clone the repository
git clone https://github.com/your-org/devops-demo.git
cd devops-demo

# Install dependencies
npm install

# Run tests
npm test

# Start dev server
npm run dev
# → http://localhost:3000
```

---

## 2. Docker Compose (Local Full Stack)

This gives you the app + Prometheus + Grafana + Loki locally:

```bash
# Build and start all services
docker compose up -d --build

# Check status
docker compose ps

# View app logs
docker compose logs -f app
```

| Service | URL | Credentials |
|---------|-----|-------------|
| App | http://localhost:3000 | — |
| Prometheus | http://localhost:9090 | — |
| Grafana | http://localhost:3001 | admin / admin |

To stop:
```bash
docker compose down
```

---

## 3. Minikube Deployment

### 3.1 Start Minikube

```bash
# Start cluster with enough resources
minikube start --cpus=4 --memory=8192 --driver=docker

# Enable required addons
minikube addons enable ingress
minikube addons enable metrics-server
```

### 3.2 Build Image in Minikube

```bash
# Point Docker to Minikube's Docker daemon
eval $(minikube docker-env)   # Linux/Mac
# For Windows PowerShell:
# & minikube -p minikube docker-env --shell powershell | Invoke-Expression

# Build the image
docker build -t devops-demo:local .
```

### 3.3 Deploy with Helm

```bash
# Deploy (dev environment)
helm upgrade --install devops-demo helm/devops-demo \
  -f helm/devops-demo/values-dev.yaml \
  --set image.repository=devops-demo \
  --set image.tag=local \
  --set image.pullPolicy=Never \
  --namespace devops-demo \
  --create-namespace \
  --wait

# Check deployment
kubectl get all -n devops-demo
```

### 3.4 Access the Application

```bash
# Option 1: Port-forward
kubectl port-forward svc/devops-demo 8080:80 -n devops-demo
# → http://localhost:8080

# Option 2: Minikube tunnel (for Ingress)
minikube tunnel
# Add to /etc/hosts: 127.0.0.1 devops-demo.dev.local
# → http://devops-demo.dev.local
```

### 3.5 Deploy Monitoring

```bash
# Install full monitoring stack
bash monitoring/install.sh

# Access Grafana
kubectl port-forward svc/grafana -n monitoring 3001:80
# → http://localhost:3001 (admin/admin)
```

### 3.6 Deploy ArgoCD

```bash
# Install ArgoCD
bash argocd/install.sh

# Access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8443:443
# → https://localhost:8443
```

---

## 4. Cloud Deployment (EKS/GKE/AKS)

### AWS EKS

```bash
# Create cluster
eksctl create cluster \
  --name devops-demo \
  --region us-west-2 \
  --nodegroup-name workers \
  --node-type t3.medium \
  --nodes 3

# Deploy
helm upgrade --install devops-demo helm/devops-demo \
  -f helm/devops-demo/values-prod.yaml \
  --namespace devops-demo \
  --create-namespace
```

### GKE

```bash
# Create cluster
gcloud container clusters create devops-demo \
  --zone us-central1-a \
  --num-nodes 3 \
  --machine-type e2-medium

# Deploy
helm upgrade --install devops-demo helm/devops-demo \
  -f helm/devops-demo/values-prod.yaml \
  --namespace devops-demo \
  --create-namespace
```

---

## 5. Verify Deployment

```bash
# Check pods are running
kubectl get pods -n devops-demo

# Check health endpoint
kubectl exec -n devops-demo deploy/devops-demo -- \
  wget -qO- http://localhost:3000/api/health

# Watch rollout status
kubectl rollout status deployment/devops-demo -n devops-demo

# Check HPA status
kubectl get hpa -n devops-demo
```

---

## 6. Rolling Update (Zero-Downtime)

```bash
# Update image tag
helm upgrade devops-demo helm/devops-demo \
  --set image.tag=sha-abc1234 \
  --namespace devops-demo \
  --wait

# Watch the rolling update
kubectl rollout status deployment/devops-demo -n devops-demo -w

# Rollback if needed
helm rollback devops-demo --namespace devops-demo
```

---

## 7. Cleanup

```bash
# Remove application
helm uninstall devops-demo -n devops-demo

# Remove monitoring
helm uninstall prometheus -n monitoring
helm uninstall grafana -n monitoring
helm uninstall loki -n monitoring

# Remove ArgoCD
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Delete namespaces
kubectl delete namespace devops-demo monitoring argocd

# Stop Minikube
minikube stop && minikube delete
```
