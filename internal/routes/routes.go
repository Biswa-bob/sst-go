package routes

import (
	"hello-world-api/internal/api"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

// Setup configures all the routes for the application
func Setup(handler *api.Handler) *chi.Mux {
	router := chi.NewRouter()

	// Middleware
	router.Use(middleware.Logger)
	router.Use(middleware.Recoverer)

	// Health check
	router.Get("/health", handler.HealthCheck)

	// API versioning - create a router group
	router.Route("/api/v1", func(r chi.Router) {
		// Hello World endpoints
		r.Get("/hello", handler.HelloWorld)
		r.Get("/hello/{name}", handler.HelloWithName)

		// Dummy resource CRUD operations
		r.Route("/dummies", func(r chi.Router) {
			r.Get("/", handler.GetDummies)
			r.Post("/", handler.CreateDummy)
			r.Get("/{id}", handler.GetDummy)
			r.Put("/{id}", handler.UpdateDummy)
			r.Delete("/{id}", handler.DeleteDummy)
		})
	})

	return router
}
