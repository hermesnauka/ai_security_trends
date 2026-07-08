package middleware

import (
	"context"
	"crypto/rsa"
	"net/http"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type claimsContextKey struct{}

type Claims struct {
	Subject string
	Role    string
}

// Authenticator - D-03: RS256-signed JWTs, no server-side sessions. The
// keypair is generated fresh on process start (Phase 1 dev scope - a real
// deployment would load a persisted, rotated key instead; there is no admin
// CRUD endpoint yet for this to actually gate, see README).
type Authenticator struct {
	privateKey *rsa.PrivateKey
	publicKey  *rsa.PublicKey
}

func NewAuthenticator(key *rsa.PrivateKey) *Authenticator {
	return &Authenticator{privateKey: key, publicKey: &key.PublicKey}
}

func (a *Authenticator) GenerateToken(subject, role string) (string, error) {
	claims := jwt.MapClaims{
		"sub":  subject,
		"role": role,
		"iat":  time.Now().Unix(),
		"exp":  time.Now().Add(time.Hour).Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodRS256, claims)
	return token.SignedString(a.privateKey)
}

func (a *Authenticator) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		header := r.Header.Get("Authorization")
		if !strings.HasPrefix(header, "Bearer ") {
			next.ServeHTTP(w, r)
			return
		}
		raw := strings.TrimPrefix(header, "Bearer ")
		token, err := jwt.Parse(raw, func(t *jwt.Token) (interface{}, error) {
			return a.publicKey, nil
		}, jwt.WithValidMethods([]string{"RS256"}))
		if err != nil || !token.Valid {
			next.ServeHTTP(w, r)
			return
		}
		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			next.ServeHTTP(w, r)
			return
		}
		sub, _ := claims["sub"].(string)
		role, _ := claims["role"].(string)
		ctx := context.WithValue(r.Context(), claimsContextKey{}, Claims{Subject: sub, Role: role})
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func ClaimsFromContext(ctx context.Context) (Claims, bool) {
	c, ok := ctx.Value(claimsContextKey{}).(Claims)
	return c, ok
}

// RequireRole - not wired to any route in Phase 1 (no admin CRUD endpoint
// exists yet, see PLAN.md's own API map vs. its Phase 1 checklist), but the
// enforcement primitive is here ready for Phase 2+ to use.
func RequireRole(role string, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		claims, ok := ClaimsFromContext(r.Context())
		if !ok || claims.Role != role {
			http.Error(w, `{"error":"forbidden"}`, http.StatusForbidden)
			return
		}
		next.ServeHTTP(w, r)
	})
}
