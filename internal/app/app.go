package app

import (
	"hello-world-api/internal/routes"

	"github.com/go-chi/chi/v5"
)

// SetupRoutes configures and returns the HTTP router
func SetupRoutes() *chi.Mux {
	return routes.Setup()
}
