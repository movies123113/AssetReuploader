package event

import "sync"

type Event struct {
	mu   sync.Mutex
	cond *sync.Cond
	set  bool
}

func NewEvent() *Event {
	e := &Event{
		set: true,
	}
	e.cond = sync.NewCond(&e.mu)
	return e
}

func (e *Event) Wait() {
	e.mu.Lock()
	for !e.set {
		e.cond.Wait()
	}
	e.mu.Unlock()
}

func (e *Event) Release() {
	e.mu.Lock()
	e.set = true
	e.cond.Broadcast()
	e.mu.Unlock()
}

func (e *Event) Reset() {
	e.mu.Lock()
	e.set = false
	e.mu.Unlock()
}

func (e *Event) IsSet() bool {
	return e.set
}
