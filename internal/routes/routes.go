package routes

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

// Setup configures all the routes for the application
func Setup() *chi.Mux {
	router := chi.NewRouter()

	// Middleware
	router.Use(middleware.Logger)
	router.Use(middleware.Recoverer)

	// Health check
	router.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte("{\"status\":\"healthy\"}"))
	})

	// API versioning - create a router group
	router.Route("/api/v1", func(r chi.Router) {
		// Hello World endpoints
		r.Get("/hello", func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Content-Type", "application/json")
			w.Write([]byte("{\"message\":\"Hello, World!\"}"))
		})
		r.Get("/hello/{name}", func(w http.ResponseWriter, r *http.Request) {
			name := chi.URLParam(r, "name")
			w.Header().Set("Content-Type", "application/json")
			w.Write([]byte("{\"message\":\"Hello, " + name + "!\"}"))
		})

		// Dummy resource CRUD operations - omitted
	})

	return router
}
