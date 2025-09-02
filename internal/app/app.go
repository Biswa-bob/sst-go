package app

import (
	"hello-world-api/internal/api"
	"hello-world-api/internal/routes"
	"hello-world-api/internal/store"

	"github.com/go-chi/chi/v5"
)

// App represents the application with all its dependencies
type App struct {
	Store   store.Store
	Handler *api.Handler
}

// New creates a new application instance
func New() *App {
	// Initialize store (in-memory for this example)
	store := store.NewInMemoryStore()

	// Initialize handler with dependencies
	handler := api.NewHandler(store)

	return &App{
		Store:   store,
		Handler: handler,
	}
}

// SetupRoutes configures and returns the HTTP router
func (a *App) SetupRoutes() *chi.Mux {
	return routes.Setup(a.Handler)
}
