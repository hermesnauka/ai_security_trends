package domain

import "github.com/google/uuid"

// Framework - PLAN.md section 5.2. Zero dependencies: no sqlc/pgx types
// leak in here, the store layer maps its own generated row types onto this.
type Framework struct {
	ID           uuid.UUID `json:"id"`
	Code         string    `json:"code"`
	Name         string    `json:"name"`
	Version      string    `json:"version"`
	Description  string    `json:"description"`
	ReferenceURL string    `json:"referenceUrl"`
}
