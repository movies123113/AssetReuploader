package types

import "fmt"

type AssetDeliveryItem struct {
	AssetId   int64 `json:"assetId"`
	RequestId int   `json:"requestId"`
}

type AssetDeliveryBatchBody []AssetDeliveryItem

type AssetDeliveryBatchResponse []struct {
	Errors []struct {
		Code    int    `json:"code"`
		Message string `json:"message"`
	} `json:"errors"`
	Locations []struct {
		Location string `json:"location"`
	} `json:"locations"`
}

type UploadError struct {
	AssetName string
	AssetId   int64
	Status    string
	Content   string
}

func (e UploadError) Error() string {
	var content string
	if len(e.Content) > 50 {
		content = e.Content[:50] + "..."
	} else {
		content = e.Content
	}

	return fmt.Sprintf(
		"Error uploading %s: %d\n Status: %s\n Content: %s",
		e.AssetName,
		e.AssetId,
		e.Status,
		content,
	)
}

type AssetInfo struct {
	Name   string `json:"name"`
	TypeId int    `json:"typeId"`
	Id     int64  `json:"id"`

	Creator struct {
		TargetId int64  `json:"targetId"`
		Type     string `json:"type"`
	} `json:"creator"`

	Location string
}

type BulkAssetInfoResponse struct {
	Data []AssetInfo `json:"data"`
}
