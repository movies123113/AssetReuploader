package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/app/animation"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/cache"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/client"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/consoleutils"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/edittext"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/event"
	"github.com/movies123113/AssetReuploader/Asset-Reuploader-main/internal/uploadrequest"
)

var assetModules = map[string]func(uploadRequest uploadrequest.UploadRequest, pauseEvent *event.Event, debugMode bool){
	"Animation": animation.Reupload,
}

var finished bool

func handleUploadRequest(rawUploadRequest uploadrequest.RawUploadRequest) {
	consoleutils.ClearScreen()

	req := uploadrequest.New(rawUploadRequest)
	pauseEvent := event.NewEvent()
	start := time.Now()

	if !client.Cookie.CanCollaborate(req.UniverseId) {
		consoleutils.ClearScreen()
		fmt.Println(edittext.Error + client.CookieCannotCollaborateError)
		client.Cookie.PromptInputWithUniverseId(req.UniverseId)
	}

	assetModules[rawUploadRequest.AssetType](req, pauseEvent, rawUploadRequest.DebugMode)

	elapsed := time.Since(start)
	fmt.Printf(edittext.Reset+"Reuploading took %d hours, %d minutes, and %d seconds.\n", int(elapsed.Hours()), int(elapsed.Minutes())%60, int(elapsed.Seconds())%60)
	fmt.Println("Waiting for client to finish changing ids...")
	finished = true
}

func newRouter(port int) {
	// var savedResponses map[string]string
	cache := cache.GetCache()

	http.HandleFunc("GET /", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(200)
		if cache.IsEmpty() && finished {
			fmt.Fprint(w, "done")
			finished = false
			return
		}

		cache.EncodeJson(json.NewEncoder(w))
		cache.Clear()
	})

	http.HandleFunc("POST /upload", func(w http.ResponseWriter, r *http.Request) {
		var rawUploadRequest uploadrequest.RawUploadRequest
		json.NewDecoder(r.Body).Decode(&rawUploadRequest)

		if rawUploadRequest.PluginVersion != compatiblePluginVersion {
			w.WriteHeader(409)
			return
		}

		go handleUploadRequest(rawUploadRequest)
		w.WriteHeader(200)
	})

	if err := http.ListenAndServe(fmt.Sprintf(":%v", port), nil); err != nil {
		log.Fatal(err)
	}
}
