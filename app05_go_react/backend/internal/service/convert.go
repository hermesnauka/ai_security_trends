package service

import (
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"gosentry/internal/domain"
)

func toUUID(v pgtype.UUID) uuid.UUID {
	return uuid.UUID(v.Bytes)
}

func toText(v pgtype.Text) string {
	if !v.Valid {
		return ""
	}
	return v.String
}

func splitCSV(raw string) []string {
	if strings.TrimSpace(raw) == "" {
		return []string{}
	}
	parts := strings.Split(raw, ",")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if p != "" {
			out = append(out, p)
		}
	}
	return out
}

func splitStride(raw string) []domain.StrideCategory {
	letters := splitCSV(raw)
	out := make([]domain.StrideCategory, 0, len(letters))
	for _, l := range letters {
		out = append(out, domain.StrideCategory(l))
	}
	return out
}
