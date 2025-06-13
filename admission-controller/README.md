# Argo CD Change Validation Admission Controller

This admission controller validates that deployments managed by Argo CD have approved change requests before allowing them to be deployed. It integrates with external change management systems to ensure proper approval workflows.

## Features

- ✅ **Change ID Validation**: Extracts change IDs from deployment annotations
- 🔍 **External Service Integration**: Validates changes against external APIs
- 🛡️ **Namespace Scoped**: Only validates namespaces with specific labels
- 📊 **Comprehensive Logging**: Detailed logs for audit and debugging
- 🔄 **Fallback Support**: Mock service for testing without external dependencies
- 🚀 **Production Ready**: TLS support, health checks, and proper RBAC

## How It Works

1. **Webhook Intercepts**: Catches CREATE/UPDATE operations on deployments, services, and configmaps
2. **Change ID Extraction**: Looks for change IDs in annotations:
   - `change.company.com/id`
   - `argocd.argoproj.io/change-id`
   - `deployment.company.com/change-id`
3. **External Validation**: Calls external service to verify:
   - Change record exists
   - Change is approved
4. **Allow/Deny**: Permits or blocks the deployment based on validation result

## Architecture

```
┌─────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│   Argo CD       │───▶│  Admission Controller │───▶│ External Change API │
│                 │    │                      │    │                     │
│ Syncs Manifests │    │ Validates Change IDs │    │ Returns Approval    │
└─────────────────┘    └──────────────────────┘    └─────────────────────┘
                                    │
                                    ▼
                       ┌──────────────────────┐
                       │   Kubernetes API     │
                       │                      │
                       │ Allows/Denies Deploy │
                       └──────────────────────┘
```

## Quick Start

### 1. Deploy the Admission Controller

```bash
cd admission-controller
chmod +x deploy.sh
./deploy.sh --build-image
```

### 2. Enable Validation on a Namespace

```bash
kubectl label namespace demo change-validation=enabled
```

### 3. Test with a Deployment

```bash
# Add change ID annotation to your deployment
kubectl annotate deployment demo-app -n demo change.company.com/id=CHG-2025-001

# Try updating the deployment - it should be allowed
kubectl patch deployment demo-app -n demo -p '{"spec":{"replicas":3}}'

# Test with invalid change ID - should be blocked
kubectl annotate deployment demo-app -n demo change.company.com/id=CHG-2025-000 --overwrite
kubectl patch deployment demo-app -n demo -p '{"spec":{"replicas":2}}'
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | HTTPS port for webhook | `8443` |
| `TLS_CERT_PATH` | Path to TLS certificate | `/etc/certs/tls.crt` |
| `TLS_KEY_PATH` | Path to TLS private key | `/etc/certs/tls.key` |
| `EXTERNAL_SERVICE_URL` | External change API URL | (uses mock service) |
| `EXTERNAL_SERVICE_API_KEY` | API key for external service | (none) |

### Mock Service Behavior

When no external service is configured, the mock service provides these responses:

| Change ID | Status | Approved | Description |
|-----------|--------|----------|-------------|
| `CHG-2025-001` | approved | ✅ | Pre-approved change |
| `CHG-2025-002` | approved | ✅ | Pre-approved change |
| `CHG-2025-003` | approved | ✅ | Pre-approved change |
| `CHG-2025-999` | pending | ❌ | Pending approval |
| `CHG-2025-000` | - | ❌ | Not found |
| `CHG-*` | approved | ✅ | Auto-approved (any CHG- prefix) |
| Others | - | ❌ | Invalid format |

## External Service Integration

### API Contract

The admission controller expects the external service to provide an endpoint:

```
GET /api/changes/{changeId}
```

**Response Format:**
```json
{
  "id": "CHG-2025-001",
  "status": "approved",
  "approved": true,
  "title": "Deploy demo application update",
  "requester": "sam.correa@company.com",
  "created_at": "2025-06-11T15:30:00Z"
}
```

**HTTP Status Codes:**
- `200`: Change found
- `404`: Change not found
- `401/403`: Authentication/authorization error
- `500`: Service error

### Configuring External Service

```yaml
# In deployment.yaml
env:
- name: EXTERNAL_SERVICE_URL
  value: "https://your-change-api.company.com"
- name: EXTERNAL_SERVICE_API_KEY
  valueFrom:
    secretKeyRef:
      name: external-service-credentials
      key: api-key
```

## Argo CD Integration

### Adding Change IDs to Deployments

Update your deployment manifests with change ID annotations:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  annotations:
    change.company.com/id: "CHG-2025-001"
    argocd.argoproj.io/change-id: "CHG-2025-001"
spec:
  # ... rest of deployment
```

### Argo CD Application Configuration

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: demo-app
spec:
  # ... other config
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    # Sync will fail if change is not approved
    retry:
      limit: 3
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 1m0s
```

## Testing

### Run Test Scenarios

```bash
chmod +x test-scenarios.sh
./test-scenarios.sh
```

### Manual Testing

```bash
# Watch admission controller logs
kubectl logs -f deployment/admission-controller -n admission-controller

# Test valid change
kubectl annotate deployment demo-app -n demo change.company.com/id=CHG-2025-001 --overwrite
kubectl patch deployment demo-app -n demo -p '{"spec":{"replicas":3}}'

# Test invalid change
kubectl annotate deployment demo-app -n demo change.company.com/id=CHG-2025-000 --overwrite
kubectl patch deployment demo-app -n demo -p '{"spec":{"replicas":2}}'
```

## Monitoring and Troubleshooting

### View Logs

```bash
# Real-time logs
kubectl logs -f deployment/admission-controller -n admission-controller

# Recent logs
kubectl logs --tail=50 deployment/admission-controller -n admission-controller
```

### Check Webhook Configuration

```bash
kubectl get validatingadmissionwebhook change-validation-webhook -o yaml
```

### Debug Webhook Issues

```bash
# Check if webhook is called
kubectl get events -n demo

# Verify TLS certificates
kubectl get secret admission-controller-certs -n admission-controller -o yaml

# Test webhook endpoint directly
kubectl port-forward svc/admission-controller -n admission-controller 8443:443
```

### Common Issues

1. **Certificate Issues**: Regenerate certificates with `generate-certs.sh`
2. **Webhook Not Called**: Check namespace labels and webhook rules
3. **External Service Timeout**: Check network connectivity and API key
4. **Permission Denied**: Verify RBAC configuration

## Security Considerations

- 🔒 **TLS Required**: All webhook communication uses TLS
- 🛡️ **RBAC**: Minimal required permissions
- 🔑 **Secret Management**: API keys stored in Kubernetes secrets
- 📝 **Audit Logging**: All decisions logged for compliance
- 🚫 **Fail Secure**: Blocks deployments when validation fails

## Development

### Building Locally

```bash
# Build the Go binary
go build -o admission-controller main.go

# Run tests
go test ./...

# Build Docker image
docker build -t admission-controller:dev .
```

### Local Development with Kind

```bash
# Create Kind cluster
kind create cluster --name admission-test

# Load image into Kind
kind load docker-image admission-controller:dev --name admission-test

# Deploy with local image
kubectl apply -f manifests/
```

## Integration Examples

### ServiceNow Integration

```go
type ServiceNowChangeService struct {
    BaseURL string
    Username string
    Password string
}

func (s *ServiceNowChangeService) ValidateChange(changeID string) (*ChangeRecord, error) {
    // Implementation for ServiceNow API
}
```

### Jira Integration

```go
type JiraChangeService struct {
    BaseURL string
    Token   string
}

func (j *JiraChangeService) ValidateChange(changeID string) (*ChangeRecord, error) {
    // Implementation for Jira API
}
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for your changes
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details.
