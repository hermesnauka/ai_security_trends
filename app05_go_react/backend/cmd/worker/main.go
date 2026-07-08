package main

import (
	"log/slog"
	"os"
)

// cmd/worker - Phase 1 scope is the process boundary existing (D-05's "two
// separate compiled binaries sharing one Go module" claim needs a second
// binary to be true), not real job processing. River wiring (export,
// deck re-ingestion, periodic integrity re-check) is Phase 6+ - see README.
func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(logger)
	slog.Info("gosentry worker starting (Phase 1: no jobs registered yet)")
	select {}
}
