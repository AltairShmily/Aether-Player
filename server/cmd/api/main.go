package main

import (
	"log"
	"net/http"
	"strings"

	"aether-server/internal/emby"
	"aether-server/internal/handler"
	"aether-server/internal/middleware"
)

func main() {
	embyClient := emby.NewClient()
	authHandler := handler.NewAuthHandler(embyClient)
	libraryHandler := handler.NewLibraryHandler(embyClient)
	playbackHandler := handler.NewPlaybackHandler(embyClient)

	mux := http.NewServeMux()

	mux.HandleFunc("/api/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"status": "ok", "service": "Aether Server"}`))
	})

	// Auth routes
	mux.HandleFunc("/api/auth/connect", authHandler.HandleConnect)
	mux.HandleFunc("/api/auth/login", authHandler.HandleLogin)

	// Library routes
	mux.HandleFunc("/api/library/views", libraryHandler.HandleGetUserViews)
	mux.HandleFunc("/api/library/items", libraryHandler.HandleGetItems)
	mux.HandleFunc("/api/library/items/", libraryHandler.HandleGetItemDetail)
	mux.HandleFunc("/api/library/resume", libraryHandler.HandleGetResumeItems)
	mux.HandleFunc("/api/library/seasons", libraryHandler.HandleGetSeasons)
	mux.HandleFunc("/api/library/episodes", libraryHandler.HandleGetEpisodes)
	mux.HandleFunc("/api/images/", libraryHandler.HandleGetItemImage)
	mux.HandleFunc("/api/search", libraryHandler.HandleSearch)

	// Playback routes
	mux.HandleFunc("/api/playback/", playbackRouter(playbackHandler))

	h := middleware.Logger(middleware.CORS(methodRouter(mux)))

	log.Println("Starting Aether Server on :19800")
	if err := http.ListenAndServe(":19800", h); err != nil {
		log.Fatal(err)
	}
}

func methodRouter(mux *http.ServeMux) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if strings.HasPrefix(r.URL.Path, "/api/library/items/") && r.Method == "GET" {
			mux.ServeHTTP(w, r)
			return
		}
		mux.ServeHTTP(w, r)
	})
}

// playbackRouter dispatches /api/playback/ sub-routes
func playbackRouter(h *PlaybackHandler) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		path := r.URL.Path[len("/api/playback/"):]

		// /api/playback/{itemId}/info
		if strings.HasSuffix(path, "/info") {
			h.HandleGetPlaybackInfo(w, r)
			return
		}

		// /api/playback/{itemId}/stream
		if strings.HasSuffix(path, "/stream") {
			h.HandleGetVideoStreamURL(w, r)
			return
		}

		http.NotFound(w, r)
	}
}
