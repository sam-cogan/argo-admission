#!/bin/bash

set -e

echo "🚀 Deploying demo application to Argo CD..."

# Check if argocd namespace exists
if ! kubectl get namespace argocd &> /dev/null; then
    echo "❌ Argo CD is not installed. Please run install-argocd.sh first."
    exit 1
fi

# Update the repository URL in the application manifest
REPO_URL="https://github.com/your-username/argo-admission.git"
read -p "🔗 Enter your repository URL [$REPO_URL]: " INPUT_REPO_URL
REPO_URL=${INPUT_REPO_URL:-$REPO_URL}

# Create a temporary file with updated repo URL
TEMP_APP_FILE=$(mktemp)
sed "s|repoURL: https://github.com/your-username/argo-admission.git|repoURL: $REPO_URL|g" ../apps/demo-app.yaml > "$TEMP_APP_FILE"

echo "📦 Deploying demo application..."
kubectl apply -f "$TEMP_APP_FILE"

# Clean up temp file
rm "$TEMP_APP_FILE"

echo "⏳ Waiting for application to sync..."
sleep 10

# Check application status
echo "📊 Application status:"
kubectl get application demo-app -n argocd -o wide

echo ""
echo "✅ Demo application deployed!"
echo ""
echo "🔍 To check the application:"
echo "   kubectl get pods -n demo"
echo "   kubectl get svc -n demo"
echo ""
echo "🌐 To access the demo app:"
echo "   kubectl port-forward svc/demo-app-service -n demo 3000:80"
echo "   Then visit: http://localhost:3000"
echo ""
echo "📱 View in Argo CD UI:"
echo "   https://localhost:8080 (if port-forward is running)"
echo ""
