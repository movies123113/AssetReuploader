package client

import (
	"encoding/json"
	"log"
	"net/http"
	"os"

	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/api"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/retry"
)

type versionManager struct{}

var Version versionManager

func init() {
	Version = versionManager{}
}

func (v versionManager) Get() string {
	data, err := os.ReadFile(cookieFile)
	if err != nil {
		return ""
	}

	return string(data)
}

func (v versionManager) GetLatest() (string, error) {
	client := http.Client{}

	req, err := http.NewRequest("GET", api.AuthenticateCookie, http.NoBody)
	if err != nil {
		log.Fatal(err)
	}
	req.AddCookie(&http.Cookie{
		Name:  ".ROBLOSECURITY",
		Value: clientCookie,
	})

	version, err := retry.Do(
		retry.NewOptions(
			retry.Tries(3),
			retry.Delay(1),
			retry.MaxDelay(1),
		),
		func() (string, error) {
			resp, err := client.Do(req)
			if err != nil {
				return "", retry.ContinueRetry
			}
			defer resp.Body.Close()

			switch resp.StatusCode {
			case 200:
				var body map[string]string
				json.NewDecoder(resp.Body).Decode(&body)
				resp.Body.Close()

				return body["name"], nil
			case 401:
				return "", retry.ExitRetry
			default:
				return "", retry.ContinueRetry
			}
		},
	)

	return version, err
}
