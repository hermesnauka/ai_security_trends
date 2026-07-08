package main

import (
	"context"
	"encoding/json"
	"log/slog"
	"os"
	"path/filepath"
	"strings"

	"github.com/jackc/pgx/v5/pgtype"

	"gosentry/internal/config"
	"gosentry/internal/store"
	"gosentry/internal/store/sqlcgen"
)

type frameworkFixture struct {
	Code         string `json:"code"`
	Name         string `json:"name"`
	Version      string `json:"version"`
	Description  string `json:"description"`
	ReferenceURL string `json:"referenceUrl"`
}

type threatFixture struct {
	Code          string   `json:"code"`
	Title         string   `json:"title"`
	Severity      string   `json:"severity"`
	Category      string   `json:"category"`
	Description   string   `json:"description"`
	AttackVector  string   `json:"attackVector"`
	AttackSurface string   `json:"attackSurface"`
	Stride        string   `json:"stride"`
	Tags          []string `json:"tags"`
}

type fixtureFile struct {
	Framework frameworkFixture `json:"framework"`
	Threats   []threatFixture  `json:"threats"`
}

var fixtureFiles = []string{
	"owasp_web_top10.json",
	"owasp_llm_top10.json",
	"mitre_atlas.json",
	"comptia_secai.json",
}

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

	q := sqlcgen.New(pool)

	dataDir := "data"
	if envDir := os.Getenv("SEED_DATA_DIR"); envDir != "" {
		dataDir = envDir
	}

	frameworkCount := 0
	threatCount := 0

	for _, filename := range fixtureFiles {
		path := filepath.Join(dataDir, filename)
		raw, err := os.ReadFile(path)
		if err != nil {
			slog.Error("failed to read fixture", "path", path, "error", err)
			os.Exit(1)
		}

		var fx fixtureFile
		if err := json.Unmarshal(raw, &fx); err != nil {
			slog.Error("failed to parse fixture", "path", path, "error", err)
			os.Exit(1)
		}

		fw, err := q.UpsertFramework(ctx, sqlcgen.UpsertFrameworkParams{
			Code:         fx.Framework.Code,
			Name:         fx.Framework.Name,
			Version:      fx.Framework.Version,
			Description:  pgtype.Text{String: fx.Framework.Description, Valid: true},
			ReferenceUrl: pgtype.Text{String: fx.Framework.ReferenceURL, Valid: true},
		})
		if err != nil {
			slog.Error("failed to upsert framework", "code", fx.Framework.Code, "error", err)
			os.Exit(1)
		}
		frameworkCount++

		for _, t := range fx.Threats {
			err := q.UpsertThreat(ctx, sqlcgen.UpsertThreatParams{
				FrameworkID:   fw.ID,
				Code:          t.Code,
				Title:         t.Title,
				Severity:      t.Severity,
				Category:      t.Category,
				Description:   t.Description,
				AttackVector:  t.AttackVector,
				AttackSurface: t.AttackSurface,
				Stride:        t.Stride,
				Tags:          strings.Join(t.Tags, ","),
			})
			if err != nil {
				slog.Error("failed to upsert threat", "code", t.Code, "error", err)
				os.Exit(1)
			}
			threatCount++
		}

		slog.Info("seeded framework", "code", fx.Framework.Code, "threats", len(fx.Threats))
	}

	slog.Info("seed complete", "frameworks", frameworkCount, "threats", threatCount)
}
