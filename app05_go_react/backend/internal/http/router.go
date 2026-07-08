package http

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	chimiddleware "github.com/go-chi/chi/v5/middleware"

	"gosentry/internal/http/handler"
	"gosentry/internal/http/middleware"
)

type Deps struct {
	FrameworkHandler *handler.FrameworkHandler
	ThreatHandler    *handler.ThreatHandler
	AuthHandler      *handler.AuthHandler
	Authenticator    *middleware.Authenticator
}

func NewRouter(d Deps) http.Handler {
	r := chi.NewRouter()

	r.Use(chimiddleware.Logger)
	r.Use(middleware.Recover)
	r.Use(middleware.SecurityHeaders)
	r.Use(d.Authenticator.Middleware)

	r.Route("/api/v1", func(r chi.Router) {
		r.Get("/health", handler.Health)

		r.Get("/frameworks", d.FrameworkHandler.List)
		r.Get("/frameworks/{code}", d.FrameworkHandler.GetByCode)

		r.Get("/threats", d.ThreatHandler.Search)
		r.Get("/threats/{id}", d.ThreatHandler.GetByID)

		r.Post("/auth/login", d.AuthHandler.Login)
	})

	return r
}
