package api

import (
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"hello-world-api/internal/models"
	"hello-world-api/internal/store"

	"github.com/gorilla/mux"
)

// Handler contains all HTTP handlers for the API
type Handler struct {
	store store.Store
}

// NewHandler creates a new handler instance
func NewHandler(s store.Store) *Handler {
	return &Handler{
		store: s,
	}
}

// HealthCheck returns the health status of the service
func (h *Handler) HealthCheck(w http.ResponseWriter, r *http.Request) {
	response := map[string]interface{}{
		"status":    "healthy",
		"timestamp": time.Now().UTC(),
		"service":   "hello-world-api",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// HelloWorld returns a simple hello world message
func (h *Handler) HelloWorld(w http.ResponseWriter, r *http.Request) {
	response := map[string]string{
		"message": "Hello, World!",
		"service": "hello-world-api",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// HelloWithName returns a personalized hello message
func (h *Handler) HelloWithName(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	name := vars["name"]

	response := map[string]string{
		"message": "Hello, " + name + "!",
		"service": "hello-world-api",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// GetDummies returns all dummy records
func (h *Handler) GetDummies(w http.ResponseWriter, r *http.Request) {
	dummies := h.store.GetAllDummies()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(dummies)
}

// CreateDummy creates a new dummy record
func (h *Handler) CreateDummy(w http.ResponseWriter, r *http.Request) {
	var dummy models.Dummy

	if err := json.NewDecoder(r.Body).Decode(&dummy); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	createdDummy := h.store.CreateDummy(dummy)

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(createdDummy)
}

// GetDummy returns a specific dummy record by ID
func (h *Handler) GetDummy(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	idStr := vars["id"]

	id, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "Invalid ID", http.StatusBadRequest)
		return
	}

	dummy, found := h.store.GetDummy(id)
	if !found {
		http.Error(w, "Dummy not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(dummy)
}

// UpdateDummy updates an existing dummy record
func (h *Handler) UpdateDummy(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	idStr := vars["id"]

	id, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "Invalid ID", http.StatusBadRequest)
		return
	}

	var dummy models.Dummy
	if err := json.NewDecoder(r.Body).Decode(&dummy); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	dummy.ID = id
	updatedDummy, found := h.store.UpdateDummy(dummy)
	if !found {
		http.Error(w, "Dummy not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(updatedDummy)
}

// DeleteDummy deletes a dummy record by ID
func (h *Handler) DeleteDummy(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	idStr := vars["id"]

	id, err := strconv.Atoi(idStr)
	if err != nil {
		http.Error(w, "Invalid ID", http.StatusBadRequest)
		return
	}

	if !h.store.DeleteDummy(id) {
		http.Error(w, "Dummy not found", http.StatusNotFound)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
