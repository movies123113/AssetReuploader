package cache

import (
	"encoding/json"
	"sync"
)

type Cache struct {
	response map[string]string
}

var handler *Cache

var once sync.Once

func GetCache() *Cache {
	once.Do(func() {
		handler = &Cache{
			response: make(map[string]string),
		}
	})
	return handler
}

func (c *Cache) EncodeJson(encoder *json.Encoder) {
	encoder.Encode(c.response)
}

func (c *Cache) Clear() {
	for k := range c.response {
		delete(c.response, k)
	}
}

func (c *Cache) IsEmpty() bool {
	return len(c.response) == 0
}

func (c *Cache) Add(key, value string) {
	c.response[key] = value
}
