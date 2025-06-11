# Argo CD Demo Repository

This repository contains a demo application setup for Argo CD deployment on an AKS cluster.

## Repository Structure

```
├── apps/                    # Argo CD Application definitions
├── demo-app/               # Demo application source code
├── manifests/              # Kubernetes manifests for the demo app
├── argo-setup/             # Argo CD installation scripts and configs
└── environments/           # Environment-specific configurations
```

## Quick Start

### 1. Install Argo CD on your AKS cluster

```bash
# Create argocd namespace
kubectl create namespace argocd

# Install Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=ready pod --all -n argocd --timeout=300s

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to access UI (run in separate terminal)
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### 2. Deploy the Demo Application

```bash
# Apply the demo application
kubectl apply -f apps/demo-app.yaml

# Access Argo CD UI at https://localhost:8080
# Username: admin
# Password: (from step 1)
```

### 3. Access the Demo Application

```bash
# Get the demo app service
kubectl get svc demo-app-service -n demo

# Port forward to access the demo app
kubectl port-forward svc/demo-app-service -n demo 3000:80
```

Then visit http://localhost:3000 to see your demo application.

## Demo Application

The demo application is a simple Node.js web server that displays:
- Current time
- Environment information
- Pod metadata
- Health check endpoints

## Argo CD Features Demonstrated

- GitOps workflow
- Automatic synchronization
- Health monitoring
- Rollback capabilities
- Multi-environment deployments

## Environments

- `dev/` - Development environment configuration
- `staging/` - Staging environment configuration  
- `prod/` - Production environment configuration

Each environment can have different:
- Resource limits
- Replica counts
- Environment variables
- Ingress configurations
