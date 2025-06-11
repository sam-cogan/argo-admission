#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🐳 Building and pushing Docker image..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Navigate to demo-app directory
cd demo-app

# Build the image
print_status "📦 Building Docker image..."
docker build -t argo-demo-app:latest .

# Tag for GitHub Container Registry
REPO_OWNER="samcorrea"
IMAGE_NAME="ghcr.io/${REPO_OWNER}/argo-admission/argo-demo-app"

docker tag argo-demo-app:latest ${IMAGE_NAME}:latest
docker tag argo-demo-app:latest ${IMAGE_NAME}:$(git rev-parse --short HEAD)

print_success "✅ Image built successfully!"

# Test the image locally
print_status "🧪 Testing the image locally..."
docker run -d -p 3001:3000 --name test-argo-demo ${IMAGE_NAME}:latest

# Wait for the container to start
sleep 5

# Test endpoints
if curl -f http://localhost:3001/health > /dev/null 2>&1; then
    print_success "✅ Health check passed"
else
    print_error "❌ Health check failed"
    docker logs test-argo-demo
    docker stop test-argo-demo
    docker rm test-argo-demo
    exit 1
fi

if curl -f http://localhost:3001/ready > /dev/null 2>&1; then
    print_success "✅ Ready check passed"
else
    print_error "❌ Ready check failed"
    docker logs test-argo-demo
    docker stop test-argo-demo
    docker rm test-argo-demo
    exit 1
fi

# Cleanup test container
docker stop test-argo-demo
docker rm test-argo-demo

print_success "🎉 Image testing completed successfully!"

echo ""
print_status "📋 Next steps:"
echo "   1. Push to registry:"
echo "      docker login ghcr.io"
echo "      docker push ${IMAGE_NAME}:latest"
echo "      docker push ${IMAGE_NAME}:$(git rev-parse --short HEAD)"
echo ""
echo "   2. Or build/push via GitHub Actions by pushing to your repository"
echo ""
echo "   3. Update your Kubernetes deployment to use the new image"
echo ""

print_status "🏷️  Image tags created:"
echo "   • ${IMAGE_NAME}:latest"
echo "   • ${IMAGE_NAME}:$(git rev-parse --short HEAD)"
echo "   • argo-demo-app:latest (local)"

cd ..
print_success "🚀 Build completed!"
