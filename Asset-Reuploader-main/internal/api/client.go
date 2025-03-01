package api

import (
	"fmt"
	"strings"
)

const (
	Version  = "https://api.github.com/repos/kartFr/Asset-Reuploader/releases/latest"
	Download = "https://github.com/movies123113/AssetReuploader/Asset-Reuploader-main/releases/latest/download/" // /AssetReuploader.zip

	AuthenticateCookie = "https://users.roblox.com/v1/users/authenticated"

	Logout = "https://auth.roblox.com/v2/logout"
)

func GetPlaceDetails(placeIds []string) string {
	return fmt.Sprintf("https://games.roblox.com/v1/games/multiget-place-details?placeIds=%s", strings.Join(placeIds, ","))
}

func TeamCreateSettings(universeId string) string {
	return fmt.Sprintf("https://develop.roblox.com/v1/universes/%s/teamcreate", universeId)
}
