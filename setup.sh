#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# ASCII Art Banner
cat << 'EOF'
  ___                    _____  _____  
 / _ \                  /  __ \/  _  \ 
/ /_\ \_ __ __ _  ___   | /  \/| | | |
|  _  | '__/ _` |/ _ \  | |    | | | |
| | | | | | (_| | (_) | | \__/\| |/ / 
\_| |_/_|  \__, |\___/   \____/|___/  
            __/ |                     
           |___/                      
    Demo Deployment Setup Script
EOF

echo ""
print_status "🚀 Welcome to the Argo CD Demo Setup!"
echo ""

# Check prerequisites
print_status "🔍 Checking prerequisites..."

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check cluster connectivity
if ! kubectl cluster-info > /dev/null 2>&1; then
    print_error "Cannot connect to Kubernetes cluster"
    print_warning "Please ensure kubectl is configured to connect to your AKS cluster"
    exit 1
fi

# Get cluster info
CLUSTER_NAME=$(kubectl config current-context)
print_success "Connected to cluster: $CLUSTER_NAME"

# Check if this is an AKS cluster
if [[ $CLUSTER_NAME == *"aks"* ]] || kubectl get nodes -o wide | grep -q "azure"; then
    print_success "✅ AKS cluster detected"
else
    print_warning "⚠️  This doesn't appear to be an AKS cluster, but continuing anyway..."
fi

echo ""
print_status "📋 Setup Options:"
echo "   1) Full setup (Install Argo CD + Deploy demo app)"
echo "   2) Install Argo CD only"
echo "   3) Deploy demo app only (requires Argo CD)"
echo "   4) Cleanup (Remove everything)"
echo ""

read -p "Select an option (1-4): " OPTION

case $OPTION in
    1)
        print_status "🚀 Starting full setup..."
        
        # Install Argo CD
        print_status "📦 Installing Argo CD..."
        cd argo-setup
        chmod +x install-argocd.sh
        ./install-argocd.sh
        
        echo ""
        print_status "⏳ Waiting 30 seconds for Argo CD to fully initialize..."
        sleep 30
        
        # Deploy demo app
        print_status "🎯 Deploying demo application..."
        chmod +x deploy-demo-app.sh
        ./deploy-demo-app.sh
        
        cd ..
        ;;
    2)
        print_status "📦 Installing Argo CD only..."
        cd argo-setup
        chmod +x install-argocd.sh
        ./install-argocd.sh
        cd ..
        ;;
    3)
        print_status "🎯 Deploying demo application..."
        if ! kubectl get namespace argocd &> /dev/null; then
            print_error "Argo CD is not installed. Please run option 1 or 2 first."
            exit 1
        fi
        cd argo-setup
        chmod +x deploy-demo-app.sh
        ./deploy-demo-app.sh
        cd ..
        ;;
    4)
        print_status "🧹 Starting cleanup..."
        cd argo-setup
        chmod +x uninstall-argocd.sh
        ./uninstall-argocd.sh
        cd ..
        ;;
    *)
        print_error "Invalid option selected"
        exit 1
        ;;
esac

echo ""
print_success "🎉 Setup completed!"
echo ""

if [[ $OPTION == "1" || $OPTION == "2" ]]; then
    print_status "🌐 Access Argo CD UI:"
    echo "   1. Run: kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo "   2. Visit: https://localhost:8080"
    echo "   3. Login with admin and the password from: argo-setup/argocd-password.txt"
    echo ""
fi

if [[ $OPTION == "1" || $OPTION == "3" ]]; then
    print_status "🎯 Access Demo Application:"
    echo "   1. Run: kubectl port-forward svc/demo-app-service -n demo 3000:80"
    echo "   2. Visit: http://localhost:3000"
    echo ""
    
    print_status "📊 Monitor Resources:"
    echo "   • kubectl get pods -n demo"
    echo "   • kubectl get svc -n demo"
    echo "   • kubectl get applications -n argocd"
    echo ""
fi

print_status "🔗 Useful Commands:"
echo "   • View Argo CD apps: kubectl get applications -n argocd"
echo "   • Check pod status: kubectl get pods --all-namespaces"
echo "   • View app logs: kubectl logs -n demo deployment/demo-app"
echo "   • Sync app manually: kubectl patch application demo-app -n argocd -p '{\"spec\":{\"source\":{\"targetRevision\":\"HEAD\"}}}' --type merge"
echo ""

print_success "🎊 Your Argo CD demo environment is ready!"
print_status "📚 Check the README.md for more detailed instructions and troubleshooting tips."
