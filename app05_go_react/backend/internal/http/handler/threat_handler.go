package handler

import (
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"

	"gosentry/internal/domain"
	"gosentry/internal/service"
)

type ThreatHandler struct {
	svc *service.ThreatService
}

func NewThreatHandler(svc *service.ThreatService) *ThreatHandler {
	return &ThreatHandler{svc: svc}
}

func (h *ThreatHandler) Search(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	page, _ := strconv.Atoi(q.Get("page"))
	size, _ := strconv.Atoi(q.Get("size"))

	result, err := h.svc.Search(r.Context(), domain.ThreatFilter{
		FrameworkCode: q.Get("frameworkCode"),
		Severity:      q.Get("severity"),
		Stride:        q.Get("stride"),
		Category:      q.Get("category"),
		Tag:           q.Get("tag"),
		Q:             q.Get("q"),
		Page:          page,
		Size:          size,
	})
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to search threats")
		return
	}
	writeJSON(w, http.StatusOK, result)
}

func (h *ThreatHandler) GetByID(w http.ResponseWriter, r *http.Request) {
	idParam := chi.URLParam(r, "id")
	id, err := uuid.Parse(idParam)
	if err != nil {
		writeError(w, http.StatusBadRequest, "invalid threat id")
		return
	}
	threat, err := h.svc.GetByID(r.Context(), id)
	if err != nil {
		writeError(w, http.StatusNotFound, "threat not found")
		return
	}
	writeJSON(w, http.StatusOK, threat)
}
