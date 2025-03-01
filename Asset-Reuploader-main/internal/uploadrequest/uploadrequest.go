package uploadrequest

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"

	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/api"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/client"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/retry"
)

type RawUploadRequest struct {
	PluginVersion string        `json:"pluginVersion"`
	AssetType     string        `json:"assetType"`
	Ids           []interface{} `json:"ids"`

	CreatorId int64  `json:"creatorId"`
	IsGroup   bool   `json:"isGroup"`
	PlaceId   string `json:"placeId"`

	DefaultPlaceIds []interface{} `json:"defaultPlaceIds"`
	DebugMode       bool          `json:"debugMode"`
}

type UploadRequest struct {
	Ids             []interface{}
	DefaultPlaceIds []interface{}
	PlaceId         string
	UniverseId      string
	CreatorId       int64
	IsGroup         bool
}

type rawPlaceDetails struct {
	UniverseId uint64 `json:"universeId"`
}

func getUniverseId(placeId string) string {
	cookie := client.Cookie.Get()
	httpClient := http.Client{}

	req, err := http.NewRequest("GET", api.GetPlaceDetails([]string{placeId}), http.NoBody)
	if err != nil {
		log.Fatal(err)
	}
	req.AddCookie(&http.Cookie{
		Name:  ".ROBLOSECURITY",
		Value: cookie,
	})

	universeId, _ := retry.Do(
		retry.NewOptions(
			retry.MaxDelay(5),
			retry.BackOff(2),
		),
		func() (string, error) {
			resp, err := httpClient.Do(req)
			if err != nil {
				return "", err
			}

			if resp.StatusCode == 200 {
				var pDetails []rawPlaceDetails
				if err := json.NewDecoder(resp.Body).Decode(&pDetails); err != nil {
					log.Fatal(err)
				}

				return strconv.FormatUint(pDetails[0].UniverseId, 10), nil
			}

			return "", retry.ContinueRetry
		},
	)

	return universeId
}

func New(rawUploadRequest RawUploadRequest) UploadRequest {
	pId := rawUploadRequest.PlaceId
	return UploadRequest{
		Ids:             rawUploadRequest.Ids,
		DefaultPlaceIds: rawUploadRequest.DefaultPlaceIds,
		CreatorId:       rawUploadRequest.CreatorId,
		IsGroup:         rawUploadRequest.IsGroup,
		PlaceId:         pId,
		UniverseId:      getUniverseId(pId),
	}
}
