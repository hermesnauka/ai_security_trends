package service

import (
	"context"
	"fmt"

	"gosentry/internal/domain"
	"gosentry/internal/store/sqlcgen"
)

type FrameworkService struct {
	q *sqlcgen.Queries
}

func NewFrameworkService(q *sqlcgen.Queries) *FrameworkService {
	return &FrameworkService{q: q}
}

func (s *FrameworkService) List(ctx context.Context) ([]domain.Framework, error) {
	rows, err := s.q.ListFrameworks(ctx)
	if err != nil {
		return nil, fmt.Errorf("list frameworks: %w", err)
	}
	out := make([]domain.Framework, 0, len(rows))
	for _, r := range rows {
		out = append(out, domain.Framework{
			ID:           toUUID(r.ID),
			Code:         r.Code,
			Name:         r.Name,
			Version:      r.Version,
			Description:  toText(r.Description),
			ReferenceURL: toText(r.ReferenceUrl),
		})
	}
	return out, nil
}

func (s *FrameworkService) GetByCode(ctx context.Context, code string) (domain.Framework, error) {
	r, err := s.q.GetFrameworkByCode(ctx, code)
	if err != nil {
		return domain.Framework{}, err
	}
	return domain.Framework{
		ID:           toUUID(r.ID),
		Code:         r.Code,
		Name:         r.Name,
		Version:      r.Version,
		Description:  toText(r.Description),
		ReferenceURL: toText(r.ReferenceUrl),
	}, nil
}
