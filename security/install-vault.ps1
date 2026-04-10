Write-Host "============================================="
Write-Host " Installing HashiCorp Vault & ESO"
Write-Host "============================================="

$helm = ".\windows-amd64\helm.exe"

# 1. Add Helm Repositories
Write-Host "=> Adding Helm repositories..."
& $helm repo add hashicorp https://helm.releases.hashicorp.com
& $helm repo add external-secrets https://charts.external-secrets.io
& $helm repo update

# 2. Install External Secrets Operator
Write-Host "=> Installing External Secrets Operator..."
& $helm upgrade --install external-secrets external-secrets/external-secrets `
    -n external-secrets --create-namespace `
    --set installCRDs=true

# 3. Install HashiCorp Vault (Dev Mode for demonstration)
Write-Host "=> Installing HashiCorp Vault..."
& $helm upgrade --install vault hashicorp/vault `
    -n vault --create-namespace `
    --set "server.dev.enabled=true" `
    --set "server.dev.devRootToken=root" `
    --set "injector.enabled=false"

Write-Host "=> Waiting for Vault to be ready..."
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=vault -n vault --timeout=120s

# 4. Setup Vault Secret Engine and Dummy Secret
Write-Host "=> Configuring Vault secrets..."
kubectl exec -it vault-0 -n vault -- sh -c 'vault secrets enable -path=secret kv-v2 && vault kv put secret/devops-demo API_KEY="live-api-key-from-vault" DB_PASSWORD="live-db-password-from-vault"'

# 5. Create Kubernetes Secret with Vault Token for ESO
Write-Host "=> Creating vault token secret for ESO to authenticate..."
# Check and create namespace safely
$nsExists = kubectl get namespace devops-demo 2>$null
if (-not $nsExists) {
    kubectl create namespace devops-demo
}

# Create secret by piping YAML
(kubectl create secret generic vault-token -n devops-demo --from-literal=token=root --dry-run=client -o yaml) | kubectl apply -f -

Write-Host "============================================="
Write-Host " Installation Complete!"
Write-Host " Vault is running with a dev root token: 'root'"
Write-Host " ESO is installed and CRDs are available."
Write-Host "============================================="
