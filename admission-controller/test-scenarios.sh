#!/bin/bash

set -e

echo "🧪 Testing Admission Controller Change Validation"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

print_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# Function to test a change ID
test_change_id() {
    local change_id="$1"
    local expected_result="$2"  # "pass" or "fail"
    local description="$3"
    
    print_status "Testing: $description (Change ID: $change_id)"
    
    # Apply the annotation
    kubectl annotate deployment demo-app -n demo change.company.com/id="$change_id" --overwrite 2>&1 | grep -q "deployment.apps/demo-app annotated" && result="pass" || result="fail"
    
    if [ "$result" = "$expected_result" ]; then
        print_success "✅ $description - Result: $result (as expected)"
    else
        print_error "❌ $description - Expected: $expected_result, Got: $result"
    fi
    
    echo ""
    sleep 2
}

# Check prerequisites
print_status "🔍 Checking prerequisites..."

if ! kubectl get namespace demo &>/dev/null; then
    print_error "Demo namespace not found. Please deploy the demo app first."
    exit 1
fi

if ! kubectl get deployment demo-app -n demo &>/dev/null; then
    print_error "Demo app deployment not found. Please deploy the demo app first."
    exit 1
fi

if ! kubectl get namespace admission-controller &>/dev/null; then
    print_error "Admission controller namespace not found. Please deploy the admission controller first."
    exit 1
fi

# Enable change validation on demo namespace
print_status "🏷️  Enabling change validation on demo namespace..."
kubectl label namespace demo change-validation=enabled --overwrite

echo ""
print_status "🚀 Running test scenarios..."
echo ""

# Test scenarios
test_change_id "CHG-2025-001" "pass" "Valid approved change"
test_change_id "CHG-2025-999" "fail" "Valid but pending change"
test_change_id "CHG-2025-000" "fail" "Non-existent change"
test_change_id "INVALID-ID" "fail" "Invalid change ID format"
test_change_id "CHG-2025-123" "pass" "Auto-approved change (CHG- prefix)"

echo ""
print_status "📊 Checking admission controller logs (last 20 lines)..."
kubectl logs --tail=20 deployment/admission-controller -n admission-controller

echo ""
print_status "🧹 Cleaning up..."
# Remove the annotation to clean up
kubectl annotate deployment demo-app -n demo change.company.com/id- 2>/dev/null || true

print_success "🎊 Test scenarios completed!"
echo ""
print_status "💡 Tips:"
echo "• Watch logs in real-time: kubectl logs -f deployment/admission-controller -n admission-controller"
echo "• Check webhook events: kubectl get events -n demo"
echo "• Disable validation: kubectl label namespace demo change-validation-"
