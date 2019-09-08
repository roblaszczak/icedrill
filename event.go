package icedrill

type Event interface{}

type EventSourced struct {
	Version uint64
	Changes []Event
}
