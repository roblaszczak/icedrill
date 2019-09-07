package placeholder

import "github.com/roblaszczak/icedrill"

type AggregateID interface{}

type AggregateType struct {
	es icedrill.EventSourced
}

func (a AggregateType) AggregateID() AggregateID {
	return nil
}
