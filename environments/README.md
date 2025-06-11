# Environments

This directory contains environment-specific configurations for the demo application.

## Structure

- `dev/` - Development environment settings
- `staging/` - Staging environment settings  
- `prod/` - Production environment settings

## Environment Differences

### Development (`dev/`)
- 2 replicas
- Lower resource limits (128Mi memory, 100m CPU)
- Development-focused styling (blue gradient)
- Faster refresh intervals

### Staging (`staging/`)
- 3 replicas  
- Medium resource limits (256Mi memory, 200m CPU)
- Staging-focused styling (orange gradient)
- Production-like configuration for testing

### Production (`prod/`)
- 5+ replicas
- Higher resource limits (512Mi memory, 500m CPU)
- Production-focused styling (green gradient)
- Enhanced monitoring and logging
- Stricter security policies

## Usage

Deploy to different environments using Argo CD applications:

```bash
# Development
kubectl apply -f ../apps/demo-app.yaml

# Staging  
kubectl apply -f ../apps/demo-app-staging.yaml

# Production (create the app manifest first)
kubectl apply -f ../apps/demo-app-prod.yaml
```

## Customization

Each environment can be customized by:
- Modifying resource requests/limits
- Changing replica counts
- Updating environment variables
- Adjusting probe settings
- Adding environment-specific secrets/configmaps
