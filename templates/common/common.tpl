package {{ .AggregatePackage }}

import (
	"github.com/pkg/errors"
	"github.com/roblaszczak/icedrill"
)

func New{{ .AggregateType }}FromHistory(events []icedrill.Event) (*{{ .AggregateType }}, error) {
	a := &{{ .AggregateType }}{}

	for _, e := range events {
		err := a.update(e)
		if err != nil {
			return nil, err
		}

		a.PopChanges() // todo - test
	}

	return a, nil
}

func (a *{{ .AggregateType }}) recordThat(event icedrill.Event) {
	if event == nil {
		return
	}
	a.es.Changes = append(a.es.Changes, event)
	a.es.Version += 1
}

// todo - test without pitor
// todo - does we need pop?
func (a *{{ .AggregateType }}) PopChanges() []icedrill.Event {
	defer func() { a.es.Changes = nil }()
	return a.es.Changes
}

func (a *{{ .AggregateType }}) update(event icedrill.Event) error {
	switch v := event.(type) {
	{{ range $key, $eventName := .Events -}}
		case {{ $eventName }}:
			a.handle{{ $eventName }}(v)
	{{ end -}}
	default:
		return errors.Errorf("event %T is not supported", v)
	}

	a.recordThat(event)

	return nil
}

func (a *{{ .AggregateType }}) Version() uint64 {
	return a.es.Version
}

type {{ .AggregateType }}Repository interface {
	Save(aggregate *{{ .AggregateType }}) error
	Find(id {{ .IDType }}) (*{{ .AggregateType }}, error)
}
