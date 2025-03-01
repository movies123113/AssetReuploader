package consoleutils

import (
	"bufio"
	"fmt"
	"os"
	"runtime"
	"strings"
)

func Input(text string) string {
	fmt.Print(text)

	reader := bufio.NewReader(os.Stdin)
	input, _ := reader.ReadString('\n')

	if runtime.GOOS == "windows" {
		input = strings.TrimSuffix(input, "\r\n")
	}
	return input
}
