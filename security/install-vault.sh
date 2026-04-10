#!/bin/bash
set -e

echo "============================================="
echo " Installing HashiCorp Vault & ESO"
echo "============================================="

# 1. Add Helm Repositories
echo "=> Adding Helm repositories..."
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

# 2. Install External Secrets Operator
echo "=> Installing External Secrets Operator..."
helm upgrade --install external-secrets external-secrets/external-secrets \
    -n external-secrets --create-namespace \
    --set installCRDs=true

# 3. Install HashiCorp Vault (Dev Mode for demonstration)
# NOTE: In production, do not use dev mode. Use HA with auto-unseal.
echo "=> Installing HashiCorp Vault..."
helm upgrade --install vault hashicorp/vault \
    -n vault --create-namespace \
    --set "server.dev.enabled=true" \
    --set "server.dev.devRootToken=root" \
    --set "injector.enabled=false"

echo "=> Waiting for Vault to be ready..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=vault -n vault --timeout=120s

# 4. Setup Vault Secret Engine and Dummy Secret
echo "=> Configuring Vault secrets..."
# Port forward so we can configure vault locally via exec
kubectl exec -it vault-0 -n vault -- sh -c '
    vault secrets enable -path=secret kv-v2 && \
    vault kv put secret/devops-demo API_KEY="live-api-key-from-vault" DB_PASSWORD="live-db-password-from-vault"
'

# 5. Create Kubernetes Secret with Vault Token for ESO
echo "=> Creating vault token secret for ESO to authenticate..."
kubectl create namespace devops-demo --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic vault-token \
    -n devops-demo \
    --from-literal=token=root \
    --dry-run=client -o yaml | kubectl apply -f -

echo "============================================="
echo " Installation Complete!"
echo " Vault is running with a dev root token: 'root'"
echo " ESO is installed and CRDs are available."
echo "============================================="
