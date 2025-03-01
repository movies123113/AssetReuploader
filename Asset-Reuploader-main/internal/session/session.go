package session

import (
	"net/http"
	"time"
)

type Session struct {
	client *http.Client
}

func Timeout(timeout time.Duration) func(*Session) {
	return func(o *Session) {
		o.client.Timeout = timeout
	}
}

func NewSession(options ...func(*Session)) *Session {
	newSession := &Session{
		client: &http.Client{
			Timeout: time.Duration(10 * time.Second),
		},
	}

	for _, option := range options {
		option(newSession)
	}

	return newSession
}

func (s *Session) Do(req *http.Request) (*http.Response, error) {
	resp, err := s.client.Do(req)
	if err != nil {
		return nil, err
	}

	return resp, nil
}
