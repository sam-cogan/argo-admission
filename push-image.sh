#!/bin/bash

set -e

echo "🚀 Pushing Docker image to GitHub Container Registry..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if user is logged in to ghcr.io
print_status "🔐 Checking GitHub Container Registry authentication..."
if ! docker info 2>/dev/null | grep -q "Username"; then
    echo "Please login to GitHub Container Registry first:"
    echo "  docker login ghcr.io"
    echo "  Username: your-github-username"
    echo "  Password: your-github-personal-access-token"
    exit 1
fi

# Image details
REPO_OWNER="samcorrea"
IMAGE_NAME="ghcr.io/${REPO_OWNER}/argo-admission/argo-demo-app"
GIT_SHA=$(git rev-parse --short HEAD)

print_status "📦 Tagging images for registry..."
docker tag argo-demo-app:latest ${IMAGE_NAME}:latest
docker tag argo-demo-app:latest ${IMAGE_NAME}:${GIT_SHA}

print_status "⬆️  Pushing images to registry..."
docker push ${IMAGE_NAME}:latest
docker push ${IMAGE_NAME}:${GIT_SHA}

print_success "✅ Images pushed successfully!"

print_status "📋 Image URLs:"
echo "   • ${IMAGE_NAME}:latest"
echo "   • ${IMAGE_NAME}:${GIT_SHA}"

print_status "🔧 To update your Kubernetes deployment:"
echo "   kubectl set image deployment/demo-app demo-app=${IMAGE_NAME}:latest -n demo"

print_success "🎉 Push completed! Your images are now available in GitHub Container Registry."
