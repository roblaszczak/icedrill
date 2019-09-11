package infrastructure

import (
	"github.com/pkg/errors"
	"github.com/roblaszczak/icedrill"
)

type Repository struct {
	events map[{{ .AggregateTypesPrefix }}{{ .IDType }}][]icedrill.Event
}

func NewRepository() *Repository {
	return &Repository{
		events: map[{{ .AggregateTypesPrefix }}{{ .IDType }}][]icedrill.Event{},
	}
}

func (r *Repository) Save(aggregate *{{ .AggregateTypesPrefix }}{{ .AggregateType }}) error {
	key := aggregate.{{ .IDGetter }}()

	if _, ok := r.events[key]; !ok {
		r.events[key] = []icedrill.Event{}
	}

	r.events[key] = append(r.events[key], aggregate.PopChanges()...)

	return nil
}

func (r Repository) Find(id {{ .AggregateTypesPrefix }}{{ .IDType }}) (*{{ .AggregateTypesPrefix }}{{ .AggregateType }}, error) {
	events, err := r.findEvents(id)
	if err != nil {
		return nil, err
	}

	return {{ .AggregateTypesPrefix }}New{{ .AggregateType }}FromHistory(events)
}

func (r Repository) findEvents(id {{ .AggregateTypesPrefix }}{{ .IDType }}) ([]icedrill.Event, error) {
	events, ok := r.events[id]
	if !ok {
		return nil, errors.Errorf("events for aggregate %T %s not found", {{ .AggregateTypesPrefix }}{{ .AggregateType }}{}, id)
	}

	return events, nil
}
