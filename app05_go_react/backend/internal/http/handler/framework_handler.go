package handler

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"

	"gosentry/internal/service"
)

type FrameworkHandler struct {
	svc *service.FrameworkService
}

func NewFrameworkHandler(svc *service.FrameworkService) *FrameworkHandler {
	return &FrameworkHandler{svc: svc}
}

func (h *FrameworkHandler) List(w http.ResponseWriter, r *http.Request) {
	frameworks, err := h.svc.List(r.Context())
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to list frameworks")
		return
	}
	writeJSON(w, http.StatusOK, frameworks)
}

func (h *FrameworkHandler) GetByCode(w http.ResponseWriter, r *http.Request) {
	code := chi.URLParam(r, "code")
	fw, err := h.svc.GetByCode(r.Context(), code)
	if err != nil {
		writeError(w, http.StatusNotFound, "framework not found")
		return
	}
	writeJSON(w, http.StatusOK, fw)
}

func writeJSON(w http.ResponseWriter, status int, v interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func writeError(w http.ResponseWriter, status int, message string) {
	writeJSON(w, status, map[string]string{"error": message})
}
