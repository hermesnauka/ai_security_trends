package middleware

import (
	"log/slog"
	"net/http"
)

// Recover - D-01: panic is only ever used for genuine programming bugs, not
// expected error paths (those return an error value). This middleware turns
// any panic into a generic 500 with full detail logged server-side only -
// never leaked to the client, unlike a raw stack trace in a dev-mode
// framework error page.
func Recover(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if rec := recover(); rec != nil {
				slog.Error("panic recovered", "error", rec, "path", r.URL.Path, "method", r.Method)
				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(http.StatusInternalServerError)
				_, _ = w.Write([]byte(`{"error":"internal server error"}`))
			}
		}()
		next.ServeHTTP(w, r)
	})
}
