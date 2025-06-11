# Docker Image Build and Deployment Guide

## Automatic GitHub Container Registry Publishing

The repository is now configured to automatically build and push Docker images to GitHub Container Registry (GHCR) when you push code changes.

### How it Works

1. **Trigger**: When you push changes to the `demo-app/` directory or the workflow file
2. **Build**: GitHub Actions builds the Docker image using the `demo-app/Dockerfile`
3. **Push**: The image is automatically pushed to `ghcr.io/samcorrea/argo-admission/argo-demo-app`
4. **Tag**: Multiple tags are created:
   - `latest` (for main branch)
   - `main-<git-sha>` (for main branch with commit SHA)
   - `develop-<git-sha>` (for develop branch)
   - Version tags (if you create git tags like `v1.0.0`)

### Image Tags Generated

- `ghcr.io/samcorrea/argo-admission/argo-demo-app:latest`
- `ghcr.io/samcorrea/argo-admission/argo-demo-app:main-abc1234`
- `ghcr.io/samcorrea/argo-admission/argo-demo-app:v1.0.0` (for version tags)

### To Deploy Updated Images

After the GitHub Action completes, update your Kubernetes deployment:

```bash
# Update to latest image
kubectl set image deployment/demo-app demo-app=ghcr.io/samcorrea/argo-admission/argo-demo-app:latest -n demo

# Or update to a specific commit
kubectl set image deployment/demo-app demo-app=ghcr.io/samcorrea/argo-admission/argo-demo-app:main-abc1234 -n demo
```

### Argo CD Integration

Since your Argo CD is watching this repository, it will automatically detect changes to the manifest files and deploy the new image when you update the `image:` field in `manifests/dev/deployment.yaml`.

### Manual Build and Push

If you need to build and push manually:

```bash
# Build locally
./build-image.sh

# Push to registry (requires docker login ghcr.io first)
./push-image.sh
```

### Viewing Images

You can view your published images at:
https://github.com/samcorrea/argo-admission/pkgs/container/argo-admission%2Fargo-demo-app

### Next Steps

1. Make a change to the demo app (e.g., update `demo-app/server.js`)
2. Commit and push to the main branch
3. Watch the GitHub Action build and push the image
4. Update your Kubernetes deployment to use the new image
5. Argo CD will sync the changes automatically
