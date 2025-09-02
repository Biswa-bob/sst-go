package models

import "time"

// Dummy represents a simple dummy entity for demonstration
type Dummy struct {
	ID          int       `json:"id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	IsActive    bool      `json:"is_active"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// DummyCollection represents a collection of dummy entities
type DummyCollection []Dummy

// GetByID finds a dummy by its ID
func (dc DummyCollection) GetByID(id int) (*Dummy, bool) {
	for _, dummy := range dc {
		if dummy.ID == id {
			return &dummy, true
		}
	}
	return nil, false
}

// Filter returns dummies that match the given predicate
func (dc DummyCollection) Filter(predicate func(Dummy) bool) DummyCollection {
	var filtered DummyCollection
	for _, dummy := range dc {
		if predicate(dummy) {
			filtered = append(filtered, dummy)
		}
	}
	return filtered
}

// GetActive returns only active dummies
func (dc DummyCollection) GetActive() DummyCollection {
	return dc.Filter(func(d Dummy) bool {
		return d.IsActive
	})
}
