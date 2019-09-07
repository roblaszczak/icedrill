package icedrill

type Event interface{}

type EventSourced struct {
	Version int64
	Changes []Event
}
