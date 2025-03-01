package utils

import (
	"fmt"

	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/client"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/consoleutils"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/edittext"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/event"
)

func GetNewCookie(universeId string, pauseEvent *event.Event, message string) {
	pauseEvent.Reset()
	oldOutput := consoleutils.GetOutput()
	consoleutils.ClearScreen()

	fmt.Print(edittext.Error + message)
	client.Cookie.PromptInputWithUniverseId(universeId)

	consoleutils.ClearScreen()
	fmt.Print(oldOutput)
	pauseEvent.Release()
}
