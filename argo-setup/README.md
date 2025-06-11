# Argo CD Setup and Demo Scripts

This directory contains scripts and configurations for setting up Argo CD and deploying the demo application.

## Files

- `install-argocd.sh` - Installs Argo CD on your AKS cluster
- `deploy-demo-app.sh` - Deploys the demo application using Argo CD
- `uninstall-argocd.sh` - Removes Argo CD from the cluster

## Quick Setup

1. **Install Argo CD:**
   ```bash
   chmod +x install-argocd.sh
   ./install-argocd.sh
   ```

2. **Deploy Demo Application:**
   ```bash
   chmod +x deploy-demo-app.sh
   ./deploy-demo-app.sh
   ```

3. **Access Argo CD UI:**
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```
   Then visit: https://localhost:8080

4. **Access Demo Application:**
   ```bash
   kubectl port-forward svc/demo-app-service -n demo 3000:80
   ```
   Then visit: http://localhost:3000

## Prerequisites

- kubectl configured to connect to your AKS cluster
- bash shell
- Internet connectivity for downloading Argo CD manifests

## Troubleshooting

### Argo CD UI Not Loading
- Check if all pods are running: `kubectl get pods -n argocd`
- Verify port-forward is active
- Try accessing with `--insecure` flag for CLI

### Demo App Not Deploying
- Check application status: `kubectl get application demo-app -n argocd`
- Verify repository URL is correct in the application manifest
- Check Argo CD logs: `kubectl logs -n argocd deployment/argocd-server`

### Permission Issues
- Ensure kubectl has admin access to the cluster
- Check if required namespaces exist
- Verify RBAC permissions

## Advanced Configuration

### Custom Repository
Edit the `repoURL` in the application manifests to point to your fork of this repository.

### Different Environments
Deploy to staging:
```bash
kubectl apply -f ../apps/demo-app-staging.yaml
```

### Project-based Access Control
Apply the demo project for enhanced security:
```bash
kubectl apply -f ../apps/demo-project.yaml
```
