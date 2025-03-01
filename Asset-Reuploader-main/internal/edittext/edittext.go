package edittext

import "fmt"

const (
	Red    = "31"
	Yellow = "33"
	Green  = "32"
)

const (
	Bold = 1 << iota
	Dim
	Italic
	Underline
	Blink
	FastBlink
	Reverse
	Hidden
	Strikethrough
	Normal
)

var (
	Reset   = fmt.Sprintf("\033[%sm", "0")
	Error   = fmt.Sprintf("\033[%sm", Red)
	Warning = fmt.Sprintf("\033[%sm", Yellow)
	Success = fmt.Sprintf("\033[%sm", Green)
)

var styleMap = map[int]string{
	Bold:          "1",
	Dim:           "2",
	Italic:        "3",
	Underline:     "4",
	Blink:         "5",
	FastBlink:     "6",
	Reverse:       "7",
	Hidden:        "8",
	Strikethrough: "9",
	Normal:        "22",
}

type TextEdit struct {
	Color string
	Flags int
}

func (t TextEdit) String() string {
	edit := fmt.Sprintf("\033[%s", t.Color)

	for i := 0; i < t.Flags; i++ {
		flag := 1 << i

		if t.Flags&flag != 0 {
			edit += fmt.Sprintf(";%s", styleMap[flag])
		}
	}

	return edit + "m"
}
