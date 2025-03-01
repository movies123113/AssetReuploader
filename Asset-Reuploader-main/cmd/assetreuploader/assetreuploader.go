package main

import (
	"fmt"
	"strings"

	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/client"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/consoleutils"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/edittext"
)

const (
	compatiblePluginVersion = "1.0.0"
	port                    = 51048
)

func main() {
	consoleutils.ClearScreen()

	fmt.Println(edittext.Reset + "Checking version...")

	latestVersion, err := client.Version.GetLatest()
	if err == nil && latestVersion == client.Version.Get() {
		consoleutils.ClearScreen()
		fmt.Println(edittext.Warning + "Out of date. New update is available on github.")

		if strings.ToLower(consoleutils.Input(edittext.Reset+"Update?(y/N): ")) == "y" {
			fmt.Print("Updating")
			return
		}
	}

	consoleutils.ClearScreen()

	if client.Cookie.Get() != "" {
		fmt.Println(edittext.Reset + "Verifying cookie...")

		if !client.Cookie.IsValid() {
			consoleutils.ClearScreen()
			fmt.Println(edittext.Error + "Cookie expired.")
			client.Cookie.PromptInput()
		}
	} else {
		client.Cookie.PromptInput()
	}

	consoleutils.ClearScreen()
	fmt.Println("localhost started. Waiting to start reuploading.")
	newRouter(port)
}
