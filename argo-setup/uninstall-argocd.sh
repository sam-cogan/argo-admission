#!/bin/bash

set -e

echo "🗑️  Uninstalling Argo CD from AKS cluster..."

# Confirm deletion
read -p "⚠️  Are you sure you want to uninstall Argo CD? This will delete all applications! (y/N): " CONFIRM
if [[ $CONFIRM != [yY] ]]; then
    echo "❌ Uninstallation cancelled."
    exit 0
fi

# Delete applications first
echo "🧹 Deleting Argo CD applications..."
kubectl delete applications --all -n argocd --ignore-not-found=true

# Delete Argo CD
echo "🗑️  Deleting Argo CD installation..."
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --ignore-not-found=true

# Delete namespace
echo "📦 Deleting argocd namespace..."
kubectl delete namespace argocd --ignore-not-found=true

# Clean up demo namespaces
echo "🧹 Cleaning up demo namespaces..."
kubectl delete namespace demo --ignore-not-found=true
kubectl delete namespace demo-staging --ignore-not-found=true

# Remove password file
if [[ -f "argocd-password.txt" ]]; then
    rm argocd-password.txt
    echo "🗑️  Removed password file"
fi

echo ""
echo "✅ Argo CD uninstallation completed!"
echo ""
echo "📝 Note: Some resources may take a few minutes to fully terminate."
