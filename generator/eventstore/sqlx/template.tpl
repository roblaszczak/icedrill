package {{ .AggregatePackage }}

import (
	"encoding/json"
	"fmt"
	"strings"

	// todo - better comment for linters
	_ "github.com/go-sql-driver/mysql"
	"github.com/jmoiron/sqlx"
	"github.com/pkg/errors"
	"github.com/roblaszczak/icedrill"
)

type Repository struct {
	db *sqlx.DB
}

func NewRepository() *Repository {
	db, err := sqlx.Connect("mysql", "root:@/icedrill")
	if err != nil {
		panic(err)
	}

	// todo - better
	// todo - inect it?
	//	db.MustExec(`
	//CREATE TABLE events (
	//  event_no BIGINT NOT NULL AUTO_INCREMENT,
	//  event_name VARCHAR(64) NOT NULL,
	//  event_payload JSON NOT NULL,
	//  aggregate_id VARCHAR(32) NOT NULL,
	//  aggregate_type VARCHAR(32) NOT NULL,
	//  PRIMARY KEY (event_no)
	//);
	//`)
	// todo - add occurred on
	// todo - addaggregate version
	// add unique on aggregate version

	return &Repository{db}
}

type EventTransport struct {
	EventNo       int           `db:"event_no"`
	EventName     string        `db:"event_name"`
	Payload       string        `db:"event_payload"`
	AggregateID   {{ .IDType }} `db:"aggregate_id"`
	AggregateType string        `db:"aggregate_type"`
}

func (r *Repository) Save(aggregate *{{ .AggregateType }}) error {
	events := aggregate.PopChanges()

	for _, event := range events {
		payload, err := json.Marshal(event)
		if err != nil {
			// todo - better (+context)
			panic(err)
		}

		dbEvent := &EventTransport{
			EventName:     r.generateEventName(event), // todo - abstract
			Payload:       string(payload),
			AggregateID:   aggregate.{{ .IDGetter }}(),
			AggregateType: r.aggregateType(),
		}

		// todo - ctx support
		// todo - bulk
		// todo - tx
		_, err = r.db.NamedExec(
			`INSERT INTO icedrill.events (event_name, event_payload, aggregate_id, aggregate_type)
			VALUES (:event_name, :event_payload, :aggregate_id, :aggregate_type)`,
			dbEvent,
		)
		if err != nil {
			// todo - better err context
			return err
		}
	}

	return nil
}

func (r Repository) Find(id {{ .IDType }}) (*{{ .AggregateType }}, error) {
	events, err := r.findEvents(id)
	if err != nil {
		return nil, err
	}

	return New{{ .AggregateType }}FromHistory(events)
}

func (r Repository) aggregateType() string {
	return "{{ .AggregateType }}"
}

func (r Repository) findEvents(id {{ .IDType }}) ([]icedrill.Event, error) {
	var dbEvents []EventTransport
	var events []icedrill.Event

	// todo - order by!
	err := r.db.Select(
		&dbEvents,
		"SELECT * FROM icedrill.events WHERE aggregate_type = ?",
		r.aggregateType(),
	)
	if err != nil {
		return nil, err
	}

	for _, dbEvent := range dbEvents {
		var event icedrill.Event

		switch dbEvent.EventName {
			{{ range $key, $eventName := .Events -}}
				case "{{ $eventName }}":
					typedEvent := {{ $eventName }}{}
					if err := json.Unmarshal([]byte(dbEvent.Payload), &typedEvent); err != nil {
						// todo - better
						panic(err)
					}
					event = typedEvent
			{{ end -}}
			default:
				return nil, errors.Errorf("event %s is not supported", dbEvent.EventName)
		}

		events = append(events, event)
	}

	return events, nil
}


func (r Repository) generateEventName(event icedrill.Event) string {
	nameParts := strings.Split(fmt.Sprintf("%T", event), ".")

	if len(nameParts) == 1 {
		return nameParts[0]
	}

	return nameParts[1]
}
