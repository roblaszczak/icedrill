package {{ .AggregatePackage }}

import (
	"github.com/pkg/errors"
	"github.com/roblaszczak/icedrill"
	"github.com/roblaszczak/icedrill/generator/placeholder"
)

type Repository struct {
	events map[{{ .IDType }}][]icedrill.Event
}

func NewRepository() *Repository {
	return &Repository{
		events: map[{{ .IDType }}][]icedrill.Event{},
	}
}

func (r *Repository) Save(aggregate *{{ .AggregateType }}) error {
	key := aggregate.{{ .IDGetter }}()

	if _, ok := r.events[key]; !ok {
		r.events[key] = []icedrill.Event{}
	}

	r.events[key] = append(r.events[key], aggregate.PopChanges()...)

	return nil
}

func (r Repository) Find(id {{ .IDType }}) (*{{ .AggregateType }}, error) {
	events, err := r.findEvents(id)
	if err != nil {
		return nil, err
	}

	return New{{ .AggregateType }}FromHistory(events)
}

func (r Repository) findEvents(id {{ .IDType }}) ([]icedrill.Event, error) {
	events, ok := r.events[id]
	if !ok {
		return nil, errors.Errorf("events for aggregate %T %s not found", {{ .AggregateType }}{}, id)
	}

	return events, nil
}
