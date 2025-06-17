#!/bin/bash

set -e

NAMESPACE="admission-controller"
SERVICE_NAME="admission-controller"
SECRET_NAME="admission-controller-certs"

echo "🔒 Generating TLS certificates for admission controller..."

# Create a temporary directory for certificate generation
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Generate CA private key
openssl genrsa -out ca.key 2048

# Generate CA certificate
openssl req -new -x509 -days 365 -key ca.key -subj "/C=US/ST=CA/L=San Francisco/O=Company/CN=Admission Controller CA" -out ca.crt

# Generate server private key
openssl genrsa -out server.key 2048

# Create certificate signing request
openssl req -new -key server.key -subj "/C=US/ST=CA/L=San Francisco/O=Company/CN=${SERVICE_NAME}.${NAMESPACE}.svc" -out server.csr

# Create extensions file for SAN
cat > server.ext << EOF
[v3_req]
authorityKeyIdentifier=keyid,issuer:always
basicConstraints=CA:FALSE
keyUsage=keyEncipherment,dataEncipherment
extendedKeyUsage=serverAuth
subjectAltName=@alt_names

[alt_names]
DNS.1=${SERVICE_NAME}
DNS.2=${SERVICE_NAME}.${NAMESPACE}
DNS.3=${SERVICE_NAME}.${NAMESPACE}.svc
DNS.4=${SERVICE_NAME}.${NAMESPACE}.svc.cluster.local
EOF

# Generate server certificate
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 365 -extensions v3_req -extfile server.ext

echo "✅ Certificates generated successfully!"

# Create namespace if it doesn't exist
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Create or update secret with certificates
kubectl create secret generic "$SECRET_NAME" \
    --from-file=tls.crt=server.crt \
    --from-file=tls.key=server.key \
    --from-file=ca.crt=ca.crt \
    --namespace="$NAMESPACE" \
    --dry-run=client -o yaml | kubectl apply -f -

# Get the base64 encoded CA certificate for webhook configuration
CA_BUNDLE=$(base64 < ca.crt | tr -d '\n')

echo "📋 CA Bundle for webhook configuration:"
echo "$CA_BUNDLE"

# Update webhook configuration with CA bundle
if [ -f "manifests/webhook-config.yaml" ]; then
    # Create updated webhook config with CA bundle
    cat > manifests/webhook-config-with-ca.yaml << EOF
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionWebhook
metadata:
  name: change-validation-webhook
spec:
  clientConfig:
    service:
      name: ${SERVICE_NAME}
      namespace: ${NAMESPACE}
      path: "/admit"
    caBundle: ${CA_BUNDLE}
  rules:
  - operations: ["CREATE", "UPDATE"]
    apiGroups: ["apps"]
    apiVersions: ["v1"]
    resources: ["deployments"]
  - operations: ["CREATE", "UPDATE"]
    apiGroups: [""]
    apiVersions: ["v1"] 
    resources: ["services", "configmaps"]
  namespaceSelector:
    matchLabels:
      change-validation: "enabled"
  admissionReviewVersions: ["v1", "v1beta1"]
  sideEffects: None
  failurePolicy: Fail
EOF
    
    echo "✅ Webhook configuration updated with CA bundle"
    echo "📄 Updated file: manifests/webhook-config-with-ca.yaml"
fi

# Cleanup
cd - > /dev/null
rm -rf "$TEMP_DIR"

echo ""
echo "🎉 TLS setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Deploy the admission controller: kubectl apply -f manifests/"
echo "2. Enable validation on a namespace: kubectl label namespace demo change-validation=enabled"
echo "3. Test with a deployment that has change ID annotation"
