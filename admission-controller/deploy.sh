#!/bin/bash

set -e

echo "🚀 Deploying Admission Controller..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if openssl is available
if ! command -v openssl &> /dev/null; then
    print_error "openssl is not installed or not in PATH"
    exit 1
fi

# Navigate to the admission controller directory
cd "$(dirname "$0")"

print_status "📦 Step 1: Generating TLS certificates..."
chmod +x generate-certs.sh
./generate-certs.sh

print_status "🏗️  Step 2: Building and deploying admission controller..."

# Check if we need to build the image
if [ "$1" = "--build-image" ]; then
    print_status "🐳 Building Docker image..."
    docker build -t ghcr.io/samcorrea/argo-admission/admission-controller:latest .
    
    print_warning "⚠️  Remember to push the image to your registry:"
    echo "   docker push ghcr.io/samcorrea/argo-admission/admission-controller:latest"
fi

print_status "📋 Deploying Kubernetes manifests..."

# Deploy manifests
kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/rbac.yaml
kubectl apply -f manifests/service.yaml
kubectl apply -f manifests/deployment.yaml

# Wait for deployment to be ready
print_status "⏳ Waiting for admission controller pods to be ready..."
kubectl wait --for=condition=ready pod -l app=admission-controller -n admission-controller --timeout=60s

# Deploy webhook configuration
if [ -f "manifests/webhook-config-with-ca.yaml" ]; then
    print_status "🔗 Deploying webhook configuration..."
    kubectl apply -f manifests/webhook-config-with-ca.yaml
else
    print_warning "⚠️  Webhook configuration with CA bundle not found. Please run generate-certs.sh first."
fi

print_success "✅ Admission controller deployed successfully!"

print_status "📊 Checking deployment status..."
kubectl get pods -n admission-controller
kubectl get service -n admission-controller

echo ""
print_status "🧪 To test the admission controller:"
echo "1. Enable validation on the demo namespace:"
echo "   kubectl label namespace demo change-validation=enabled"
echo ""
echo "2. Update your demo app deployment with a change ID annotation:"
echo "   kubectl annotate deployment demo-app -n demo change.company.com/id=CHG-2025-001"
echo ""
echo "3. Try to update the deployment and watch the admission controller logs:"
echo "   kubectl logs -f deployment/admission-controller -n admission-controller"
echo ""

print_status "🔧 Useful commands:"
echo "• View admission controller logs: kubectl logs -f deployment/admission-controller -n admission-controller"
echo "• Check webhook config: kubectl get validatingadmissionwebhook change-validation-webhook -o yaml"
echo "• Test with invalid change ID: kubectl annotate deployment demo-app -n demo change.company.com/id=CHG-2025-000 --overwrite"
echo ""

print_success "🎊 Setup completed! Your admission controller is ready to validate changes."
