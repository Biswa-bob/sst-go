package store

import (
	"sync"
	"time"

	"hello-world-api/internal/models"
)

// Store defines the interface for data persistence
type Store interface {
	GetAllDummies() []models.Dummy
	GetDummy(id int) (models.Dummy, bool)
	CreateDummy(dummy models.Dummy) models.Dummy
	UpdateDummy(dummy models.Dummy) (models.Dummy, bool)
	DeleteDummy(id int) bool
}

// InMemoryStore implements Store interface using in-memory storage
type InMemoryStore struct {
	dummies map[int]models.Dummy
	nextID  int
	mutex   sync.RWMutex
}

// NewInMemoryStore creates a new in-memory store with sample data
func NewInMemoryStore() *InMemoryStore {
	store := &InMemoryStore{
		dummies: make(map[int]models.Dummy),
		nextID:  1,
	}

	// Add some sample data
	store.seedData()

	return store
}

func (s *InMemoryStore) seedData() {
	sampleDummies := []models.Dummy{
		{
			Name:        "Sample Dummy 1",
			Description: "This is a sample dummy record",
			IsActive:    true,
		},
		{
			Name:        "Sample Dummy 2",
			Description: "Another sample dummy record",
			IsActive:    false,
		},
	}

	for _, dummy := range sampleDummies {
		s.CreateDummy(dummy)
	}
}

func (s *InMemoryStore) GetAllDummies() []models.Dummy {
	s.mutex.RLock()
	defer s.mutex.RUnlock()

	dummies := make([]models.Dummy, 0, len(s.dummies))
	for _, dummy := range s.dummies {
		dummies = append(dummies, dummy)
	}

	return dummies
}

func (s *InMemoryStore) GetDummy(id int) (models.Dummy, bool) {
	s.mutex.RLock()
	defer s.mutex.RUnlock()

	dummy, exists := s.dummies[id]
	return dummy, exists
}

func (s *InMemoryStore) CreateDummy(dummy models.Dummy) models.Dummy {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	dummy.ID = s.nextID
	dummy.CreatedAt = time.Now().UTC()
	dummy.UpdatedAt = dummy.CreatedAt

	s.dummies[s.nextID] = dummy
	s.nextID++

	return dummy
}

func (s *InMemoryStore) UpdateDummy(dummy models.Dummy) (models.Dummy, bool) {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	existing, exists := s.dummies[dummy.ID]
	if !exists {
		return models.Dummy{}, false
	}

	dummy.CreatedAt = existing.CreatedAt
	dummy.UpdatedAt = time.Now().UTC()

	s.dummies[dummy.ID] = dummy

	return dummy, true
}

func (s *InMemoryStore) DeleteDummy(id int) bool {
	s.mutex.Lock()
	defer s.mutex.Unlock()

	_, exists := s.dummies[id]
	if !exists {
		return false
	}

	delete(s.dummies, id)
	return true
}
