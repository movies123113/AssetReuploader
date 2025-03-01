package assetinfobulk

import (
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/api"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/client"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/event"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/pkg/types"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/pkg/utils"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/retry"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/session"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/uploadrequest"
)

const throttle time.Duration = 60 * time.Second / 95

func splitArray[T any](array []T, size int) [][]T {
	arr := make([][]T, 0, (len(array)+size-1)/size)

	for i := 0; i < len(array); i += size {
		end := i + size
		if end > len(array) {
			end = len(array)
		}

		arr = append(arr, array[i:end])
	}

	return arr
}

func Get(uploadRequest uploadrequest.UploadRequest, idsUploaded *int, pauseEvent *event.Event) []chan []types.AssetInfo {
	splitIds := splitArray(uploadRequest.Ids, 50)
	tasks := make([]chan []types.AssetInfo, len(splitIds))
	sessionHandler := session.NewSession()

	getAssetInfoHandler := func(ids []interface{}, ch chan []types.AssetInfo) {
		assetIds := make([]string, 0, len(ids))

		for _, id := range ids {
			if str, ok := id.(string); ok {
				assetIds = append(assetIds, str)
			} else {
				log.Fatal("Non-string asset id") // if this even happens I/you have royally fucked up
			}
		}

		req, err := http.NewRequest("GET", api.GetAssetInfoBulk(assetIds), http.NoBody)
		if err != nil {
			log.Fatal(err)
		}
		req.AddCookie(&http.Cookie{
			Name:  ".ROBLOSECURITY",
			Value: client.Cookie.Get(),
		})

		assetsInfo, _ := retry.Do(
			retry.NewOptions(
				retry.BackOff(1.5),
				retry.MaxDelay(5),
			),
			func() ([]types.AssetInfo, error) {
				if !pauseEvent.IsSet() {
					pauseEvent.Wait()
				}

				resp, err := sessionHandler.Do(req)
				if err != nil {
					return nil, retry.ContinueRetry
				}
				defer resp.Body.Close()

				if code := resp.StatusCode; code == 401 {
					if pauseEvent.IsSet() {
						utils.GetNewCookie(uploadRequest.UniverseId, pauseEvent, "Cookie expired.\n")
					}
					return nil, retry.ContinueRetry
				} else if code != 200 {
					return nil, retry.ContinueRetry
				}

				var assetData types.BulkAssetInfoResponse
				json.NewDecoder(resp.Body).Decode(&assetData)
				return assetData.Data, nil
			},
		)

		*idsUploaded += len(ids) - len(assetsInfo)

		ch <- assetsInfo
		close(ch)
	}

	var index int
	for _, ids := range splitIds {
		tasks[index] = make(chan []types.AssetInfo)
		go getAssetInfoHandler(ids, tasks[index])
		time.Sleep(throttle)
		index++
	}

	return tasks
}
