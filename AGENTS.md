# AGENTS.md - Guidelines for Agentic Coding in Graplin Repository

This file contains build commands, code style guidelines, and conventions for agentic coding agents working in this repository.

## Build Commands

### Primary Commands
- `make build` - Build the Go binary to `bin/graplin`
- `make test` - Run all tests with verbose output
- `make test-coverage` - Run tests with coverage report (generates `coverage.html`)
- `make lint` - Run golangci-lint (install with `go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest`)
- `make fmt` - Format Go code using `go fmt`
- `make vet` - Run `go vet` for static analysis
- `make dev` - Run development workflow (fmt, vet, test)

### Single Test Commands
- `go test -v ./pkg/graplin -run TestSpecificFunction` - Run single test
- `go test -v ./pkg/graplin -run TestMeasurement_String` - Example for measurement string tests
- `go test -race ./pkg/graplin` - Run tests with race detection
- `go test -cover ./pkg/graplin` - Quick coverage check

### Other Useful Commands
- `make clean` - Remove build artifacts
- `make deps-update` - Update Go modules (`go mod tidy`)
- `make install` - Install binary to `$GOPATH/bin`

## Code Style Guidelines

### Project Philosophy
- **Zero external dependencies** - Use only Go standard library
- **Minimalism and simplicity** - Clean, idiomatic Go code
- **Production-ready** - Comprehensive error handling and testing
- **Thread-safe design** - Use atomic operations where appropriate

### Import Organization
```go
import (
    "bytes"        // Standard library only
    "context"
    "errors"
    "fmt"
    "io"
    "log"
    "net/http"
    "strings"
    "sync/atomic"
    "time"
)
```

**Rules:**
- Single import block for standard library
- Alphabetical ordering within groups
- No third-party imports unless absolutely necessary
- No blank imports or import aliases

### Naming Conventions

**Types and Interfaces:**
- Exported types: `Client`, `Measurement` (MixedCase)
- Unexported types: `internalConfig` (mixedCase)
- Interface names: Use `-er` suffix when appropriate (`Stringer`)

**Functions:**
- Constructors: `NewClient()`
- Functional options: `WithHost()`, `WithAuth()`, `WithDebug()`, `WithTimeout()`
- Actions: `Push()`, `String()`, `ErrorCount()`
- Private methods: `formatTags()`, `formatFields()`, `formatFieldValue()`

**Variables:**
- Constants: `httpDefaultClientTimeout` (camelCase)
- Package variables: `ErrRequestFailed` (MixedCase for exported)
- Struct fields: Mixed case for exported, lower case for unexported

**Method Receivers:**
- Use single letters: `c *Client`, `m *Measurement`
- Be consistent across the codebase

### Error Handling Patterns

**Error Definition:**
```go
var (
    ErrRequestFailed = errors.New("request failed")
)
```

**Error Handling:**
- Use `fmt.Errorf` with `%w` for error wrapping
- Provide contextual error messages
- Include accumulated state when relevant
- Use atomic operations for error counting

**Examples:**
```go
return fmt.Errorf("failed to create request: %w", err)
return fmt.Errorf("failed to send request (accumulated error count %d): %w", c.errorCount, err)
return fmt.Errorf("%w with status code: %d", ErrRequestFailed, resp.StatusCode)
```

### Testing Patterns

**Test Structure:**
- Table-driven tests for comprehensive coverage
- Subtests using `t.Run()` for organization
- Helper functions for test utilities
- HTTP testing using `httptest.NewServer`

**Test Naming:**
- `TestType_Method` for public methods
- `TestType_Method_Condition` for specific scenarios
- Helper functions: `containsString()`, `findSubstring()`

**Test Patterns:**
```go
func TestMeasurement_String(t *testing.T) {
    tests := []struct {
        name        string
        measurement Measurement
        contains    []string
    }{
        // Test cases...
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := tt.measurement.String()
            for _, expected := range tt.contains {
                if !containsString(got, expected) {
                    t.Errorf("Measurement.String() = %v, want to contain %v", got, expected)
                }
            }
        })
    }
}
```

### Documentation Style

**Package Documentation:**
- Comprehensive package-level documentation in `doc.go`
- Include usage examples
- Explain InfluxDB Line Protocol concepts

**Code Comments:**
- Exported types and functions must have comments
- Explain complex logic with inline comments
- Use Go doc convention (description, params, returns)

**Example:**
```go
// Measurement represents a single InfluxDB Line Protocol measurement
type Measurement struct {
    // Measurement (Required) The measurement name. InfluxDB accepts one measurement per point.
    Measurement string
    // Tags Optional – All tag key-value pairs for the point.
    Tags map[string]string
    // Fields (Required) All field key-value pairs for the point.
    Fields map[string]interface{}
    // Optional – The unix timestamp for the data point.
    Timestamp time.Time
}
```

### Architectural Patterns

**Functional Options Pattern:**
```go
func NewClient(options ...func(client *Client)) *Client {
    client := &Client{
        // Default configuration
    }
    for _, o := range options {
        o(client)
    }
    return client
}
```

**Context Awareness:**
- All I/O operations should accept `context.Context`
- Use `http.NewRequestWithContext()` for HTTP requests
- Respect context cancellation

**Thread Safety:**
- Use `sync/atomic` for simple counters
- Consider mutexes for complex state
- Document thread safety guarantees

### Code Quality Standards

**Before Submitting:**
1. Run `make dev` (fmt, vet, test)
2. Run `make lint` if golangci-lint is available
3. Ensure test coverage is comprehensive
4. Check for race conditions with `go test -race`

**Code Review Checklist:**
- [ ] Error handling is comprehensive
- [ ] Context is properly used and propagated
- [ ] Thread safety is considered
- [ ] Tests cover edge cases and error paths
- [ ] Documentation is clear and accurate
- [ ] No external dependencies unless absolutely necessary

### File Organization

**Structure:**
```
pkg/graplin/
├── client.go         # Main client implementation
├── client_test.go    # Unit tests
└── doc.go           # Package documentation
```

**Guidelines:**
- Keep package structure flat and simple
- Separate tests into `*_test.go` files
- Use `doc.go` for package-level documentation
- Maintain zero external dependency policy

### Performance Considerations

**Guidelines:**
- Pre-allocate slices when size is known
- Use `strings.Builder` for string concatenation in loops
- Minimize allocations in hot paths
- Use appropriate data types for fields

**Example:**
```go
tags := make([]string, 0, len(m.Tags))  // Pre-allocate
for key, value := range m.Tags {
    tags = append(tags, fmt.Sprintf("%s=%s", key, value))
}
```

## Special Notes for Agents

1. **Never add external dependencies** - This project intentionally uses only the Go standard library
2. **Maintain backward compatibility** - Don't break existing APIs
3. **Test thoroughly** - Cover edge cases, error paths, and concurrent scenarios
4. **Document everything** - Exported code must have comprehensive documentation
5. **Follow existing patterns** - Use the same error handling, testing, and architectural patterns established in the codebase