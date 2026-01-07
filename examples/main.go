package main

import (
	"context"
	"log"
	"math/rand"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/tillkuhn/graplin/pkg/graplin"
)

func main() {
	// Create a context that can be cancelled by signals
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Set up signal handling for graceful shutdown
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)

	// Create a new client with default configuration
	client := graplin.NewClient(
		graplin.WithHost("http://localhost:8086"),
		graplin.WithAuth("my-token"),
		graplin.WithDebug(true),
	)

	// Initialize random seed
	rand.Seed(time.Now().UnixNano())

	// Start the data pusher goroutine
	go func() {
		ticker := time.NewTicker(15 * time.Second)
		defer ticker.Stop()

		for {
			select {
			case <-ctx.Done():
				log.Println("Stopping data pusher...")
				return
			case <-ticker.C:
				pushCoffeeData(ctx, client)
			}
		}
	}()

	log.Println("Coffee data pusher started. Pushing data every 15 seconds.")
	log.Println("Press Ctrl+C to stop...")

	// Wait for signal
	<-sigCh
	log.Println("\nReceived interrupt signal, shutting down...")
	cancel()

	// Give some time for cleanup
	time.Sleep(1 * time.Second)
	log.Println("Shutdown complete.")
}

func pushCoffeeData(ctx context.Context, client *graplin.Client) {
	// Generate random data
	cups := rand.Intn(5) + 1         // 1-5 cups
	happiness := rand.Float64() * 10 // 0-10 happiness score

	// Create measurement with coffee data
	measurement := graplin.Measurement{
		Measurement: "coffee",
		Tags: map[string]string{
			"location": "office",
			"brewer":   "french-press",
		},
		Fields: map[string]interface{}{
			"cups":      cups,
			"happiness": happiness,
		},
		Timestamp: time.Now(),
	}

	// Push the measurement
	err := client.Push(ctx, measurement)
	if err != nil {
		log.Printf("Failed to push coffee data: %v", err)
		return
	}

	log.Printf("Pushed coffee data: %d cups, happiness: %.2f", cups, happiness)
}
