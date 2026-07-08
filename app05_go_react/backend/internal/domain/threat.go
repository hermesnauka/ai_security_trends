package domain

import "github.com/google/uuid"

// ThreatSummary - PLAN.md section 5.3, list-view shape (matches the shape
// the other four sibling apps' /api/v1/threats list endpoint already
// returns, for frontend parity).
type ThreatSummary struct {
	ID            uuid.UUID        `json:"id"`
	FrameworkCode string           `json:"frameworkCode"`
	Code          string           `json:"code"`
	Title         string           `json:"title"`
	Severity      Severity         `json:"severity"`
	Category      string           `json:"category"`
	Stride        []StrideCategory `json:"stride"`
	Tags          []string         `json:"tags"`
}

// ThreatDetail - detail-view shape for GET /api/v1/threats/:id.
type ThreatDetail struct {
	ID            uuid.UUID        `json:"id"`
	FrameworkCode string           `json:"frameworkCode"`
	FrameworkName string           `json:"frameworkName"`
	Code          string           `json:"code"`
	Title         string           `json:"title"`
	Severity      Severity         `json:"severity"`
	Category      string           `json:"category"`
	Description   string           `json:"description"`
	AttackVector  string           `json:"attackVector"`
	AttackSurface string           `json:"attackSurface"`
	Stride        []StrideCategory `json:"stride"`
	CVEReferences []string         `json:"cveReferences"`
	Tags          []string         `json:"tags"`
}

// ThreatFilter - optional query params for GET /api/v1/threats.
type ThreatFilter struct {
	FrameworkCode string
	Severity      string
	Stride        string
	Category      string
	Tag           string
	Q             string
	Page          int
	Size          int
}

// Page - matches the {content, totalElements, totalPages, number, size}
// shape used by all four sibling apps' frontends.
type Page[T any] struct {
	Content       []T `json:"content"`
	TotalElements int `json:"totalElements"`
	TotalPages    int `json:"totalPages"`
	Number        int `json:"number"`
	Size          int `json:"size"`
}

func NewPage[T any](items []T, page, size int) Page[T] {
	if size <= 0 {
		size = 20
	}
	total := len(items)
	totalPages := 1
	if total > 0 {
		totalPages = (total + size - 1) / size
	}
	start := page * size
	if start > total {
		start = total
	}
	end := start + size
	if end > total {
		end = total
	}
	return Page[T]{
		Content:       items[start:end],
		TotalElements: total,
		TotalPages:    totalPages,
		Number:        page,
		Size:          size,
	}
}
