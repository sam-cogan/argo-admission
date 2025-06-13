package main

import (
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"

	admissionv1 "k8s.io/api/admission/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/runtime/serializer"
	"k8s.io/klog/v2"
)

var (
	scheme = runtime.NewScheme()
	codecs = serializer.NewCodecFactory(scheme)
)

// ChangeRecord represents the structure of a change record from external service
type ChangeRecord struct {
	ID       string `json:"id"`
	Status   string `json:"status"`
	Approved bool   `json:"approved"`
	Title    string `json:"title"`
	Requester string `json:"requester"`
	CreatedAt string `json:"created_at"`
}

// ExternalChangeService interface for validating changes
type ExternalChangeService interface {
	ValidateChange(changeID string) (*ChangeRecord, error)
}

// MockChangeService - A mock implementation of the external service
type MockChangeService struct{}

func (m *MockChangeService) ValidateChange(changeID string) (*ChangeRecord, error) {
	// Simulate some approved and denied changes
	switch changeID {
	case "CHG-2025-001", "CHG-2025-002", "CHG-2025-003":
		return &ChangeRecord{
			ID:       changeID,
			Status:   "approved",
			Approved: true,
			Title:    "Deploy demo application update",
			Requester: "sam.correa@company.com",
			CreatedAt: time.Now().Format(time.RFC3339),
		}, nil
	case "CHG-2025-999":
		return &ChangeRecord{
			ID:       changeID,
			Status:   "pending",
			Approved: false,
			Title:    "Pending change request",
			Requester: "john.doe@company.com",
			CreatedAt: time.Now().Format(time.RFC3339),
		}, nil
	case "CHG-2025-000":
		return nil, fmt.Errorf("change record not found")
	default:
		// For demo purposes, approve any change ID that starts with "CHG-"
		if len(changeID) > 4 && changeID[:4] == "CHG-" {
			return &ChangeRecord{
				ID:       changeID,
				Status:   "approved",
				Approved: true,
				Title:    "Auto-approved change",
				Requester: "system@company.com",
				CreatedAt: time.Now().Format(time.RFC3339),
			}, nil
		}
		return nil, fmt.Errorf("invalid change ID format")
	}
}

// HTTPChangeService - Implementation that calls a real HTTP service
type HTTPChangeService struct {
	BaseURL string
	APIKey  string
}

func (h *HTTPChangeService) ValidateChange(changeID string) (*ChangeRecord, error) {
	client := &http.Client{Timeout: 10 * time.Second}
	
	url := fmt.Sprintf("%s/api/changes/%s", h.BaseURL, changeID)
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %v", err)
	}
	
	if h.APIKey != "" {
		req.Header.Set("Authorization", "Bearer "+h.APIKey)
	}
	req.Header.Set("Content-Type", "application/json")
	
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to call external service: %v", err)
	}
	defer resp.Body.Close()
	
	if resp.StatusCode == 404 {
		return nil, fmt.Errorf("change record not found")
	}
	
	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("external service returned status %d", resp.StatusCode)
	}
	
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %v", err)
	}
	
	var record ChangeRecord
	if err := json.Unmarshal(body, &record); err != nil {
		return nil, fmt.Errorf("failed to parse response: %v", err)
	}
	
	return &record, nil
}

// AdmissionController handles admission requests
type AdmissionController struct {
	changeService ExternalChangeService
}

func NewAdmissionController() *AdmissionController {
	var changeService ExternalChangeService
	
	// Check if external service URL is configured
	externalURL := os.Getenv("EXTERNAL_SERVICE_URL")
	if externalURL != "" {
		changeService = &HTTPChangeService{
			BaseURL: externalURL,
			APIKey:  os.Getenv("EXTERNAL_SERVICE_API_KEY"),
		}
		klog.Infof("Using HTTP change service: %s", externalURL)
	} else {
		changeService = &MockChangeService{}
		klog.Info("Using mock change service")
	}
	
	return &AdmissionController{
		changeService: changeService,
	}
}

func (ac *AdmissionController) admit(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	var admissionReview admissionv1.AdmissionReview
	if err := json.Unmarshal(body, &admissionReview); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	req := admissionReview.Request
	klog.Infof("Processing admission request for %s/%s in namespace %s", 
		req.Kind.Kind, req.Name, req.Namespace)

	// Extract change ID from annotations
	changeID := extractChangeID(req)
	if changeID == "" {
		// Allow resources without change ID annotation (may not be Argo CD managed)
		klog.Infof("No change ID found, allowing request")
		ac.respond(w, &admissionReview, true, "No change ID annotation found")
		return
	}

	klog.Infof("Found change ID: %s", changeID)

	// Validate change with external service
	changeRecord, err := ac.changeService.ValidateChange(changeID)
	if err != nil {
		klog.Errorf("Change validation failed: %v", err)
		ac.respond(w, &admissionReview, false, fmt.Sprintf("Change validation failed: %v", err))
		return
	}

	if !changeRecord.Approved {
		klog.Infof("Change %s is not approved (status: %s)", changeID, changeRecord.Status)
		ac.respond(w, &admissionReview, false, 
			fmt.Sprintf("Change %s is not approved (status: %s)", changeID, changeRecord.Status))
		return
	}

	klog.Infof("Change %s is approved, allowing deployment", changeID)
	ac.respond(w, &admissionReview, true, 
		fmt.Sprintf("Change %s approved by %s", changeID, changeRecord.Requester))
}

func (ac *AdmissionController) respond(w http.ResponseWriter, admissionReview *admissionv1.AdmissionReview, allowed bool, message string) {
	admissionResponse := &admissionv1.AdmissionResponse{
		UID:     admissionReview.Request.UID,
		Allowed: allowed,
		Result: &metav1.Status{
			Message: message,
		},
	}

	admissionReview.Response = admissionResponse
	admissionReview.Request = nil

	respBytes, _ := json.Marshal(admissionReview)
	w.Header().Set("Content-Type", "application/json")
	w.Write(respBytes)
}

func extractChangeID(req *admissionv1.AdmissionRequest) string {
	// Try to extract change ID from object annotations
	obj := req.Object.Raw
	var objMap map[string]interface{}
	if err := json.Unmarshal(obj, &objMap); err != nil {
		return ""
	}

	if metadata, ok := objMap["metadata"].(map[string]interface{}); ok {
		if annotations, ok := metadata["annotations"].(map[string]interface{}); ok {
			// Look for change ID in various annotation formats
			if changeID, ok := annotations["change.company.com/id"].(string); ok {
				return changeID
			}
			if changeID, ok := annotations["argocd.argoproj.io/change-id"].(string); ok {
				return changeID
			}
			if changeID, ok := annotations["deployment.company.com/change-id"].(string); ok {
				return changeID
			}
		}
	}
	return ""
}

func (ac *AdmissionController) health(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Write([]byte("OK"))
}

func main() {
	klog.InitFlags(nil)
	
	controller := NewAdmissionController()
	
	mux := http.NewServeMux()
	mux.HandleFunc("/admit", controller.admit)
	mux.HandleFunc("/health", controller.health)
	mux.HandleFunc("/ready", controller.health)
	
	// Get port from environment or default to 8443
	port := os.Getenv("PORT")
	if port == "" {
		port = "8443"
	}
	
	// Configure TLS
	certPath := os.Getenv("TLS_CERT_PATH")
	keyPath := os.Getenv("TLS_KEY_PATH")
	if certPath == "" {
		certPath = "/etc/certs/tls.crt"
	}
	if keyPath == "" {
		keyPath = "/etc/certs/tls.key"
	}
	
	server := &http.Server{
		Addr:      ":" + port,
		Handler:   mux,
		TLSConfig: &tls.Config{},
	}
	
	klog.Infof("Starting admission controller on port %s", port)
	klog.Infof("TLS cert path: %s", certPath)
	klog.Infof("TLS key path: %s", keyPath)
	
	if err := server.ListenAndServeTLS(certPath, keyPath); err != nil {
		klog.Fatalf("Failed to start server: %v", err)
	}
}
