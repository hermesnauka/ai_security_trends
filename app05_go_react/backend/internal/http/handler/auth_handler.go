package handler

import (
	"encoding/json"
	"net/http"

	"golang.org/x/crypto/bcrypt"

	"gosentry/internal/http/middleware"
)

// AuthHandler - dev-only single-admin login, matching the JWT-skeleton
// pattern the sibling apps use: no user table exists yet, and there is no
// admin CRUD endpoint for this token to actually gate (see README). This
// wires the auth plumbing ahead of it so it isn't bolted on insecurely later.
type AuthHandler struct {
	auth              *middleware.Authenticator
	adminUsername     string
	adminPasswordHash string
}

func NewAuthHandler(auth *middleware.Authenticator, adminUsername, adminPasswordHash string) *AuthHandler {
	return &AuthHandler{auth: auth, adminUsername: adminUsername, adminPasswordHash: adminPasswordHash}
}

type loginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type loginResponse struct {
	Token     string `json:"token"`
	TokenType string `json:"tokenType"`
	Role      string `json:"role"`
}

func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var req loginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.Username != h.adminUsername || bcrypt.CompareHashAndPassword([]byte(h.adminPasswordHash), []byte(req.Password)) != nil {
		writeError(w, http.StatusUnauthorized, "invalid username or password")
		return
	}

	token, err := h.auth.GenerateToken(h.adminUsername, "ADMIN")
	if err != nil {
		writeError(w, http.StatusInternalServerError, "failed to issue token")
		return
	}
	writeJSON(w, http.StatusOK, loginResponse{Token: token, TokenType: "Bearer", Role: "ADMIN"})
}
