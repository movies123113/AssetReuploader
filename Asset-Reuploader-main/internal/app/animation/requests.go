package animation

import (
	"bytes"
	"encoding/json"
	"net/http"

	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/api"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/client"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/pkg/types"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/uploadrequest"
)

func createUploadRequest(name string, uploadRequest uploadrequest.UploadRequest, assetData bytes.Buffer, xsrfToken string) (*http.Request, error) {
	req, err := http.NewRequest("POST", api.PublishAnimation(name, uploadRequest.CreatorId, uploadRequest.IsGroup), &assetData)
	if err != nil {
		return nil, err
	}
	req.AddCookie(&http.Cookie{
		Name:  ".ROBLOSECURITY",
		Value: client.Cookie.Get(),
	})
	req.Header.Set("X-Csrf-Token", xsrfToken)
	req.Header.Set("User-Agent", "RobloxStudio/WinInet")
	return req, nil
}

func createAssetDeliveryBatchRequest(assetInfo []types.AssetInfo) (*http.Request, error) {
	var body types.AssetDeliveryBatchBody
	for _, info := range assetInfo {
		body = append(body, types.AssetDeliveryItem{ // no need to set RequestId because it should be 0
			AssetId: info.Id,
		})
	}

	jsonData, err := json.Marshal(body)
	if err != nil {
		return nil, err
	}

	req, err := http.NewRequest("POST", api.AssetDeliveryBatch, bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")

	return req, nil
}
