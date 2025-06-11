#!/bin/bash

set -e

echo "🚀 Installing Argo CD on AKS cluster..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check cluster connectivity
echo "📡 Checking cluster connectivity..."
kubectl cluster-info > /dev/null || {
    echo "❌ Cannot connect to Kubernetes cluster"
    exit 1
}

# Create argocd namespace
echo "📦 Creating argocd namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install Argo CD
echo "📥 Installing Argo CD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for Argo CD to be ready
echo "⏳ Waiting for Argo CD pods to be ready..."
kubectl wait --for=condition=ready pod --all -n argocd --timeout=300s

# Get initial admin password
echo "🔑 Getting initial admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo "✅ Argo CD installation completed!"
echo ""
echo "📋 Access Information:"
echo "   🌐 UI URL: https://localhost:8080"
echo "   👤 Username: admin"
echo "   🔐 Password: $ARGOCD_PASSWORD"
echo ""
echo "🚀 To access the UI, run in another terminal:"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
echo "📱 To install Argo CD CLI:"
echo "   # Linux/WSL"
echo "   curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
echo "   sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd"
echo "   rm argocd-linux-amd64"
echo ""
echo "   # macOS"
echo "   brew install argocd"
echo ""
echo "🔧 To login via CLI:"
echo "   argocd login localhost:8080 --username admin --password $ARGOCD_PASSWORD --insecure"
echo ""

# Save password to file for easy access
echo "$ARGOCD_PASSWORD" > argocd-password.txt
echo "💾 Password saved to: argocd-password.txt"
