package retry

import (
	"errors"
	"math"
	"time"
)

var (
	ContinueRetry      = errors.New("retrying")
	ExitRetry          = errors.New("exited retry")
	TriesExceededError = errors.New("tries exceeded")
)

type retryOptions struct {
	MaxTries int
	Delay    float64
	MaxDelay float64
	BackOff  float64
}

func Tries(tries int) func(*retryOptions) {
	return func(o *retryOptions) {
		o.MaxTries = tries
	}
}

func Delay(delay float64) func(*retryOptions) {
	return func(o *retryOptions) {
		o.Delay = delay
	}
}

func MaxDelay(maxDelay float64) func(*retryOptions) {
	return func(o *retryOptions) {
		o.MaxDelay = maxDelay
	}
}

func BackOff(backOff float64) func(*retryOptions) {
	return func(o *retryOptions) {
		o.BackOff = backOff
	}
}

func canRetry(o *retryOptions, tries int) bool {
	if tries == -1 || tries < o.MaxTries {
		return true
	}
	return false
}

func NewOptions(options ...func(*retryOptions)) *retryOptions {
	o := &retryOptions{
		MaxTries: -1,
		Delay:    1,
		MaxDelay: 0,
		BackOff:  1,
	}

	for _, option := range options {
		option(o)
	}

	return o
}

func getDelay(o *retryOptions, tries int) float64 {
	delay := o.Delay * (o.BackOff * float64(tries))

	if o.MaxDelay == 0 {
		return delay
	}

	return math.Min(delay, o.MaxDelay)
}

func Do[T any](options *retryOptions, callback func() (T, error)) (T, error) {
	var tries int
	var nilT T

	for {
		tries++

		res, err := callback()
		if err == nil {
			return res, nil
		}

		switch err {
		case ExitRetry:
			return res, ExitRetry
		case ContinueRetry:
			if !canRetry(options, tries) {
				return nilT, TriesExceededError
			}

			<-time.After(time.Duration(getDelay(options, tries) * float64(time.Second)))
		default:
			return nilT, err
		}
	}
}
