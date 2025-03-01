package animation

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"strconv"
	"sync"

	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/cache"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/client"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/consoleutils"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/edittext"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/event"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/pkg/assetinfobulk"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/pkg/types"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/retry"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/session"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/uploadrequest"
)

const assetTypeId = 24 // https://create.roblox.com/docs/reference/engine/enums/AssetType

func Reupload(uploadRequest uploadrequest.UploadRequest, pauseEvent *event.Event, debugMode bool) {
	consoleutils.Println(edittext.Reset + "Reuploading animations...")

	var idsUploaded int

	xsrfToken := client.Cookie.GetXSRFToken()
	cache := cache.GetCache()
	uploadSession := session.NewSession()

	getAssetData := func(location string) (bytes.Buffer, error) {
		req, err := http.NewRequest("GET", location, http.NoBody)
		if err != nil {
			log.Fatal(err)
		}

		assetData, err := retry.Do(
			retry.NewOptions(
				retry.Tries(3),
				retry.BackOff(2),
				retry.Delay(0.5),
			),
			func() (bytes.Buffer, error) {
				resp, err := uploadSession.Do(req)
				if err != nil {
					if debugMode {
						consoleutils.Println(edittext.Warning + "[Debug] Error getting asset data: " + err.Error())
					}
					return bytes.Buffer{}, retry.ContinueRetry
				}
				defer resp.Body.Close()

				if code := resp.StatusCode; code == 200 {
					var buffer bytes.Buffer
					io.Copy(&buffer, resp.Body)
					return buffer, nil
				} else if code == 400 {
					return bytes.Buffer{}, retry.ExitRetry
				}

				return bytes.Buffer{}, retry.ContinueRetry
			},
		)
		if err != nil {
			return bytes.Buffer{}, err
		}

		return assetData, nil
	}

	uploadWithRetry := func(assetInfo types.AssetInfo, assetData bytes.Buffer) (string, error) {
		name := assetInfo.Name
		return retry.Do(
			retry.NewOptions(
				retry.Tries(3),
				retry.BackOff(2),
			),
			func() (string, error) {
				if !pauseEvent.IsSet() {
					pauseEvent.Wait()
				}

				req, err := createUploadRequest(name, uploadRequest, assetData, xsrfToken)
				if err != nil {
					log.Fatal(err)
				}

				resp, err := uploadSession.Do(req)
				if err != nil {
					if debugMode {
						consoleutils.Println(edittext.Warning + "[Debug] Error uploading: " + err.Error())
					}
					return "", retry.ContinueRetry
				}
				defer resp.Body.Close()

				return handleUploadResponse(resp, uploadRequest, assetInfo, &name, &xsrfToken, debugMode, pauseEvent)
			},
		)
	}

	uploadAsset := func(assetInfo types.AssetInfo, location string, waitGroup *sync.WaitGroup) {
		defer waitGroup.Done()

		assetData, err := getAssetData(location)
		if err != nil {
			idsUploaded++
			consoleutils.Println(
				edittext.Error + fmt.Sprintf(
					"[%d/%d] Error getting %s data: %d",
					idsUploaded,
					len(uploadRequest.Ids),
					assetInfo.Name,
					assetInfo.Id,
				),
			)
			return
		}

		newId, err := uploadWithRetry(assetInfo, assetData)
		idsUploaded++
		if err != nil {
			consoleutils.Println(
				edittext.Error +
					fmt.Sprintf("[%d/%d] Failed to upload %s: %d",
						idsUploaded,
						len(uploadRequest.Ids),
						assetInfo.Name,
						assetInfo.Id,
					),
			)
		} else {
			consoleutils.Println(
				edittext.Success +
					fmt.Sprintf("[%d/%d] %s: %d ; %s",
						idsUploaded,
						len(uploadRequest.Ids),
						assetInfo.Name,
						assetInfo.Id,
						newId,
					),
			)

			oldId := strconv.FormatInt(assetInfo.Id, 10)
			cache.Add(oldId, newId)
		}
	}

	parseAssetLocations := func(rawAssetLocations types.AssetDeliveryBatchResponse, assetInfo []types.AssetInfo) map[int64]string {
		locations := make(map[int64]string, len(rawAssetLocations))
		for i, assetDelivery := range rawAssetLocations {
			info := assetInfo[i]

			if len(assetDelivery.Errors) != 0 {
				idsUploaded++
				err := assetDelivery.Errors[0]
				consoleutils.Println(edittext.Warning + fmt.Sprintf(
					"[Debug] Error reading %d location.\nCode: %d\nMessage: %s",
					info.Id,
					err.Code,
					err.Message,
				))
				continue
			}

			locations[info.Id] = assetDelivery.Locations[0].Location
		}
		return locations
	}

	fetchAssetLocationsWithRetry := func(req *http.Request) (types.AssetDeliveryBatchResponse, error) {
		return retry.Do(
			retry.NewOptions(
				retry.BackOff(1.5),
				retry.MaxDelay(5),
			),
			func() (types.AssetDeliveryBatchResponse, error) {
				if !pauseEvent.IsSet() {
					pauseEvent.Wait()
				}

				resp, err := uploadSession.Do(req)
				if err != nil {
					if debugMode {
						consoleutils.Println(edittext.Warning + "[Debug] Error getting asset locations: " + err.Error())
					}
					return nil, retry.ContinueRetry
				}
				defer resp.Body.Close()

				if resp.StatusCode != 200 {
					if debugMode {
						consoleutils.Println(
							edittext.Warning +
								"[Debug] Error getting asset locations.\nStatus:" +
								resp.Status,
						)
					}
					return nil, retry.ContinueRetry
				}

				var locations types.AssetDeliveryBatchResponse
				json.NewDecoder(resp.Body).Decode(&locations)
				return locations, nil
			},
		)
	}

	fetchAssetDeliveryBatch := func(assetInfo []types.AssetInfo) (map[int64]string, error) {
		req, err := createAssetDeliveryBatchRequest(assetInfo)
		if err != nil {
			log.Fatal(err)
		}

		rawAssetLocations, err := fetchAssetLocationsWithRetry(req)
		if err != nil {
			return map[int64]string{}, err
		}

		return parseAssetLocations(rawAssetLocations, assetInfo), nil
	}

	var wg sync.WaitGroup

	filterAssetInfo := func(assetInfo []types.AssetInfo) []types.AssetInfo {
		var filteredAssetInfo []types.AssetInfo
		for _, info := range assetInfo {
			if info.TypeId != assetTypeId || info.Creator.TargetId == 1 || info.Creator.TargetId == uploadRequest.CreatorId || info.Creator.TargetId == client.Cookie.UserInfo.Id {
				idsUploaded++
				continue
			}

			filteredAssetInfo = append(filteredAssetInfo, info)
		}
		return filteredAssetInfo
	}

	bulkUpload := func(assetInfo []types.AssetInfo) {
		defer wg.Done()

		filteredAssetInfo := filterAssetInfo(assetInfo)
		if len(filteredAssetInfo) == 0 {
			return
		}

		locations, err := fetchAssetDeliveryBatch(filteredAssetInfo)
		if err != nil {
			if debugMode {
				consoleutils.Println(edittext.Warning + "[Debug] Error getting asset locations: " + err.Error())
			}
			return
		}

		var bulkwg sync.WaitGroup
		bulkwg.Add(len(filteredAssetInfo))
		for _, info := range filteredAssetInfo {
			location, exists := locations[info.Id]
			if !exists {
				idsUploaded++
				bulkwg.Done()
				continue
			}

			go uploadAsset(info, location, &bulkwg)
		}
		bulkwg.Wait()
	}

	tasks := assetinfobulk.Get(uploadRequest, &idsUploaded, pauseEvent)
	wg.Add(len(tasks))
	for _, taskChan := range tasks {
		go bulkUpload(<-taskChan)
	}
	wg.Wait()
}
