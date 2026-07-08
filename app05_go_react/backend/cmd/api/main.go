package main

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"log/slog"
	"net/http"
	"os"

	"gosentry/internal/config"
	apphttp "gosentry/internal/http"
	"gosentry/internal/http/handler"
	"gosentry/internal/http/middleware"
	"gosentry/internal/service"
	"gosentry/internal/store"
	"gosentry/internal/store/sqlcgen"
)

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(logger)

	cfg := config.Load()
	ctx := context.Background()

	pool, err := store.NewPool(ctx, cfg.DatabaseURL())
	if err != nil {
		slog.Error("failed to connect to database", "error", err)
		os.Exit(1)
	}
	defer pool.Close()

	queries := sqlcgen.New(pool)

	// Dev-only: fresh RS256 keypair per process start (D-03). A real
	// deployment would load a persisted, rotated key instead.
	privateKey, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		slog.Error("failed to generate RSA keypair", "error", err)
		os.Exit(1)
	}
	authenticator := middleware.NewAuthenticator(privateKey)

	adminUsername := envOr("ADMIN_USERNAME", "admin")
	adminPasswordHash := envOr("ADMIN_PASSWORD_HASH", "$2b$10$zQSot7Lxlrb5PdIg3SLzMu92L42rne/Rm29sgipNNYDoBVtQzmiju") // "changeme-dev-only"

	frameworkSvc := service.NewFrameworkService(queries)
	threatSvc := service.NewThreatService(queries)

	router := apphttp.NewRouter(apphttp.Deps{
		FrameworkHandler: handler.NewFrameworkHandler(frameworkSvc),
		ThreatHandler:    handler.NewThreatHandler(threatSvc),
		AuthHandler:      handler.NewAuthHandler(authenticator, adminUsername, adminPasswordHash),
		Authenticator:    authenticator,
	})

	addr := ":" + cfg.HTTPPort
	slog.Info("gosentry backend starting", "addr", addr)
	if err := http.ListenAndServe(addr, router); err != nil {
		slog.Error("server exited", "error", err)
		os.Exit(1)
	}
}

func envOr(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
