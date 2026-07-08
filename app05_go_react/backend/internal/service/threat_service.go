package service

import (
	"context"
	"fmt"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"

	"gosentry/internal/domain"
	"gosentry/internal/store/sqlcgen"
)

type ThreatService struct {
	q *sqlcgen.Queries
}

func NewThreatService(q *sqlcgen.Queries) *ThreatService {
	return &ThreatService{q: q}
}

func narg(v string) pgtype.Text {
	if v == "" {
		return pgtype.Text{Valid: false}
	}
	return pgtype.Text{String: v, Valid: true}
}

func (s *ThreatService) Search(ctx context.Context, f domain.ThreatFilter) (domain.Page[domain.ThreatSummary], error) {
	rows, err := s.q.SearchThreats(ctx, sqlcgen.SearchThreatsParams{
		FrameworkCode: narg(f.FrameworkCode),
		Severity:      narg(f.Severity),
		Stride:        narg(f.Stride),
		Category:      narg(f.Category),
		Tag:           narg(f.Tag),
		Q:             narg(f.Q),
	})
	if err != nil {
		return domain.Page[domain.ThreatSummary]{}, fmt.Errorf("search threats: %w", err)
	}

	summaries := make([]domain.ThreatSummary, 0, len(rows))
	for _, r := range rows {
		summaries = append(summaries, domain.ThreatSummary{
			ID:            toUUID(r.ID),
			FrameworkCode: r.FrameworkCode,
			Code:          r.Code,
			Title:         r.Title,
			Severity:      domain.Severity(r.Severity),
			Category:      r.Category,
			Stride:        splitStride(r.Stride),
			Tags:          splitCSV(r.Tags),
		})
	}

	return domain.NewPage(summaries, f.Page, f.Size), nil
}

func (s *ThreatService) GetByID(ctx context.Context, id uuid.UUID) (domain.ThreatDetail, error) {
	r, err := s.q.GetThreatByID(ctx, pgtype.UUID{Bytes: id, Valid: true})
	if err != nil {
		return domain.ThreatDetail{}, err
	}
	return domain.ThreatDetail{
		ID:            toUUID(r.ID),
		FrameworkCode: r.FrameworkCode,
		FrameworkName: r.FrameworkName,
		Code:          r.Code,
		Title:         r.Title,
		Severity:      domain.Severity(r.Severity),
		Category:      r.Category,
		Description:   r.Description,
		AttackVector:  r.AttackVector,
		AttackSurface: r.AttackSurface,
		Stride:        splitStride(r.Stride),
		CVEReferences: splitCSV(r.CveReferences),
		Tags:          splitCSV(r.Tags),
	}, nil
}
