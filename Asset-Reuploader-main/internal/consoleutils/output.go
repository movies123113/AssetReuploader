package consoleutils

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"runtime"
)

var buffer bytes.Buffer

func Println(a ...any) {
	fmt.Println(a...)
	buffer.WriteString(fmt.Sprintln(a...))
}

func GetOutput() string {
	return buffer.String()
}

func runCommand(command string, args ...string) {
	c := exec.Command(command, args...)
	c.Stdout = os.Stdout
	c.Run()
}

func ClearScreen() {
	buffer.Reset()

	switch runtime.GOOS {
	case "windows":
		runCommand("cmd", "/c", "cls")
	default:
		runCommand("clear")
	}
}
