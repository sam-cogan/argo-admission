# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the admission controller
RUN CGO_ENABLED=0 GOOS=linux go build -o admission-controller main.go

# Final stage
FROM alpine:3.18

# Install ca-certificates for TLS
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy the binary from builder stage
COPY --from=builder /app/admission-controller .

# Create certs directory
RUN mkdir -p /etc/certs

# Expose port
EXPOSE 8443

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider https://localhost:8443/health --no-check-certificate || exit 1

# Run the admission controller
CMD ["./admission-controller"]
