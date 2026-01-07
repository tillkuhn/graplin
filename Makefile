.PHONY: help build test test-coverage lint clean fmt vet deps run install

# Default target
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Build targets
build: ## Build the Go binary
	@echo "Building..."
	go build -o bin/graplin ./...

build-all: ## Build for multiple platforms
	@echo "Building for multiple platforms..."
	GOOS=linux GOARCH=amd64 go build -o bin/graplin-linux-amd64 ./...
	GOOS=darwin GOARCH=amd64 go build -o bin/graplin-darwin-amd64 ./...
	GOOS=darwin GOARCH=arm64 go build -o bin/graplin-darwin-arm64 ./...
	GOOS=windows GOARCH=amd64 go build -o bin/graplin-windows-amd64.exe ./...

# Test targets
test: ## Run tests
	@echo "Running tests..."
	go test -v ./...

test-coverage: ## Run tests with coverage report
	@echo "Running tests with coverage..."
	go test -v -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

test-race: ## Run tests with race detection
	@echo "Running tests with race detection..."
	go test -v -race ./...

# Code quality targets
lint: ## Run linter (requires golangci-lint)
	@echo "Running linter..."
	@if command -v golangci-lint >/dev/null 2>&1; then \
		golangci-lint run; \
	else \
		echo "golangci-lint not installed. Install with: go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest"; \
	fi

fmt: ## Format Go code
	@echo "Formatting code..."
	go fmt ./...

vet: ## Run go vet
	@echo "Running go vet..."
	go vet ./...

# Dependency targets
deps: ## Download dependencies
	@echo "Downloading dependencies..."
	go mod download

deps-update: ## Update dependencies
	@echo "Updating dependencies..."
	go mod tidy

deps-verify: ## Verify dependencies
	@echo "Verifying dependencies..."
	go mod verify

# Development targets
run: ## Run the application (if main package exists)
	@echo "Running application..."
	@if [ -f "main.go" ]; then \
		go run main.go; \
	elif [ -f "cmd/graplin/main.go" ]; then \
		go run cmd/graplin/main.go; \
	else \
		echo "No main.go found. Create one or specify the path."; \
	fi

dev: ## Run development workflow (fmt, vet, test)
	@echo "Running development workflow..."
	make fmt
	make vet
	make test

# Installation targets
install: ## Install the binary
	@echo "Installing..."
	go install ./...

uninstall: ## Uninstall the binary
	@echo "Uninstalling..."
	go clean -i

# Utility targets
clean: ## Clean build artifacts
	@echo "Cleaning..."
	rm -rf bin/
	rm -f coverage.out coverage.html
	go clean -testcache

clean-all: ## Clean all artifacts including dependencies
	@echo "Cleaning all..."
	make clean
	go clean -modcache

# Information targets
version: ## Show Go version
	@echo "Go version:"
	@go version

info: ## Show project information
	@echo "Project: graplin"
	@echo "Module: github.com/tillkuhn/graplin"
	@echo "Go version:"
	@go version
	@echo "Working directory: $(PWD)"