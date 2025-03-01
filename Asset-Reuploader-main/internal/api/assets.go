package api

import (
	"fmt"
	"strings"
)

const (
	AssetDeliveryBatch = "https://assetdelivery.roblox.com/v2/assets/batch"
	AssetDelivery      = "https://assetdelivery.roblox.com/v1/asset/?id="
)

func GetAssetInfoBulk(assetIds []string) string {
	return fmt.Sprintf("https://develop.roblox.com/v1/assets?assetIds=%s", strings.Join(assetIds, ","))
}

func PublishAnimation(name string, creatorId int64, isGroup bool) string {
	cleanedName := strings.ReplaceAll(name, " ", "+")
	url := fmt.Sprintf("https://www.roblox.com/ide/publish/uploadnewanimation?assetTypeName=Animation&name=%s&description=", cleanedName)
	if isGroup {
		url += fmt.Sprintf("&groupId=%d", creatorId)
	}

	return url
}
