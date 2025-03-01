package client

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/api"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/consoleutils"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/edittext"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/retry"
)

const (
	cookieFile  = "cookie.txt"
	warningText = "WARNING:-DO-NOT-SHARE-THIS"
)

const (
	CookieNoWarningError         = "Include the .ROBLOSECURITY warning."
	CookieCannotCollaborateError = "Account does not have access to collaborate."
	CookieInvalidError           = "ROBLOSECURITY is invalid."
)

type UserInfo struct {
	Id int64 `json:"id"` // only id is used for now...
	// Username    string `json:"username"`
	// DisplayName string `json:"displayName"`
}

type cookieManager struct {
	UserInfo UserInfo
}

var Cookie cookieManager

var clientCookie string

func init() {
	Cookie = cookieManager{}

	data, err := os.ReadFile(cookieFile)
	if err != nil {
		return
	}
	clientCookie = string(data)
}

func (c cookieManager) Get() string {
	return clientCookie
}

func (c cookieManager) save() {
	file, err := os.OpenFile(cookieFile, os.O_CREATE|os.O_WRONLY, 0o660)
	if err != nil {
		fmt.Printf(edittext.Error+"Unable to save cookie: %s\n", err)
	}
	file.WriteString(clientCookie)
	file.Close()
}

func (c *cookieManager) IsValid() bool {
	client := http.Client{}

	req, err := http.NewRequest("GET", api.AuthenticateCookie, http.NoBody)
	if err != nil {
		log.Fatal(err)
	}
	req.AddCookie(&http.Cookie{
		Name:  ".ROBLOSECURITY",
		Value: clientCookie,
	})

	isValid, err := retry.Do(
		retry.NewOptions(
			retry.Tries(3),
			retry.MaxDelay(5),
			retry.BackOff(1.5),
		),
		func() (bool, error) {
			resp, err := client.Do(req)
			if err != nil {
				return false, retry.ContinueRetry
			}
			defer resp.Body.Close()

			switch resp.StatusCode {
			case 200:
				if err := json.NewDecoder(resp.Body).Decode(&c.UserInfo); err != nil {
					return false, retry.ContinueRetry
				}

				return true, nil
			case 401:
				return false, retry.ExitRetry
			default:
				return false, retry.ContinueRetry
			}
		},
	)
	if err != nil {
		return false
	}

	return isValid
}

func (c cookieManager) PromptInput() {
	for {
		clientCookie = consoleutils.Input(edittext.Reset + "ROBLOSECURITY: ")
		consoleutils.ClearScreen()

		if !strings.Contains(clientCookie, warningText) {
			fmt.Println(edittext.Error + CookieNoWarningError)
			continue
		}

		if !c.IsValid() {
			fmt.Println(edittext.Error + CookieInvalidError)
			continue
		}

		c.save()
		return
	}
}

func (c cookieManager) CanCollaborate(universeId string) bool {
	client := http.Client{}

	req, err := http.NewRequest("GET", api.TeamCreateSettings(universeId), http.NoBody)
	if err != nil {
		log.Fatal(err)
	}
	req.AddCookie(&http.Cookie{
		Name:  ".ROBLOSECURITY",
		Value: clientCookie,
	})

	canCollaborate, err := retry.Do(
		retry.NewOptions(
			retry.Tries(3),
			retry.MaxDelay(5),
			retry.BackOff(1.5),
		),

		func() (bool, error) {
			resp, err := client.Do(req)
			if err != nil {
				return false, retry.ContinueRetry
			}
			defer resp.Body.Close()

			switch resp.StatusCode {
			case 200:
				return true, nil
			case 401, 403:
				return false, retry.ExitRetry
			default:
				return false, retry.ContinueRetry
			}
		},
	)
	if err != nil {
		return false
	}

	return canCollaborate
}

func (c cookieManager) PromptInputWithUniverseId(universeId string) {
	for {
		clientCookie = consoleutils.Input(edittext.Reset + "ROBLOSECURITY: ")
		consoleutils.ClearScreen()

		if !strings.Contains(clientCookie, warningText) {
			fmt.Println(edittext.Error + CookieNoWarningError)
			continue
		}

		if !c.CanCollaborate(universeId) {
			fmt.Println(edittext.Error + CookieCannotCollaborateError)
			continue
		}

		if !c.IsValid() {
			fmt.Println(edittext.Error + CookieInvalidError)
			continue
		}

		c.save()
		return
	}
}

func (c cookieManager) GetXSRFToken() string {
	client := http.Client{}

	req, err := http.NewRequest("POST", api.Logout, http.NoBody)
	if err != nil {
		log.Fatal(err)
	}
	req.AddCookie(&http.Cookie{
		Name:  ".ROBLOSECURITY",
		Value: clientCookie,
	})

	token, _ := retry.Do(
		retry.NewOptions(
			retry.Tries(3),
			retry.MaxDelay(5),
			retry.BackOff(1.5),
		),
		func() (string, error) {
			resp, err := client.Do(req)
			if err != nil {
				return "", retry.ContinueRetry
			}
			defer resp.Body.Close()

			if resp.StatusCode == 403 {
				return resp.Header.Get("x-csrf-token"), nil
			}
			return "", retry.ContinueRetry
		},
	)

	return token
}
