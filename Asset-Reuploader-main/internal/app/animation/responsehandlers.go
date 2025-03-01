package animation

import (
	"io"
	"net/http"

	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/consoleutils"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/edittext"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/event"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/pkg/types"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/pkg/utils"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/retry"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/uploadrequest"
)

func printUploadError(name string, id int64, status, content string) {
	consoleutils.Println(
		edittext.Warning + "[Debug] " +
			types.UploadError{
				AssetName: name,
				AssetId:   id,
				Status:    status,
				Content:   content,
			}.Error(),
	)
}

func handleUploadResponse(resp *http.Response, uploadRequest uploadrequest.UploadRequest, assetInfo types.AssetInfo, name, xsrfToken *string, debugMode bool, pauseEvent *event.Event) (string, error) {
	content, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", retry.ContinueRetry
	}

	switch resp.StatusCode {
	case 200:
		return string(content), nil
	case 403:
		if debugMode {
			printUploadError(assetInfo.Name, assetInfo.Id, resp.Status, string(content))
		}
		if string(content) == "NotLoggedIn" {
			if pauseEvent.IsSet() {
				utils.GetNewCookie(uploadRequest.UniverseId, pauseEvent, "Cookie expired.\n")
			}
		} else { // for content: XSRF Token Validation Failed
			*xsrfToken = resp.Header.Get("x-csrf-token")
		}
		return "", retry.ContinueRetry
	case 400, 500:
		return "", retry.ContinueRetry
	case 422: // content: Inappropriate name or description.
		*name = "[Censored Name]"
		return "", retry.ContinueRetry
	default:
		if debugMode {
			printUploadError(assetInfo.Name, assetInfo.Id, resp.Status, string(content))
		}
		return "", retry.ContinueRetry
	}
}
