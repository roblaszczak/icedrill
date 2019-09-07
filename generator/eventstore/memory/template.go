package memory

import (
	"github.com/pkg/errors"
	"github.com/roblaszczak/icedrill"
	"github.com/roblaszczak/icedrill/generator/placeholder"
)

type Repository struct {
	events map[placeholder.AggregateID][]icedrill.Event
}

func NewRepository() *Repository {
	return &Repository{
		events: map[placeholder.AggregateID][]icedrill.Event{},
	}
}

func (r *Repository) Save(aggregate *placeholder.AggregateType) error {
	key := aggregate.AggregateID()

	if _, ok := r.events[key]; !ok {
		r.events[key] = []icedrill.Event{}
	}

	r.events[key] = append(r.events[key], aggregate.PopChanges()...)

	return nil
}

func (r Repository) Find(id placeholder.AggregateID) (*placeholder.AggregateType, error) {
	events, err := r.findEvents(id)
	if err != nil {
		return nil, err
	}

	return placeholder.NewAggregateTypeFromHistory(events)
}

func (r Repository) findEvents(id placeholder.AggregateID) ([]icedrill.Event, error) {
	events, ok := r.events[id]
	if !ok {
		return nil, errors.Errorf("events for aggregate %T %s not found", placeholder.AggregateType{}, id)
	}

	return events, nil
}
