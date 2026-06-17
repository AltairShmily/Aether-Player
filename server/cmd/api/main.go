package main

import (
	"log"
	"net/http"
	"os"
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
	userHandler := handler.NewUserHandler(embyClient)
	proxyHandler := handler.NewProxyHandler()

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

	// User routes
	mux.HandleFunc("/api/users/favorites/toggle", userHandler.HandleToggleFavorite)
	mux.HandleFunc("/api/users/favorites", userHandler.HandleGetFavorites)
	mux.HandleFunc("/api/users/profile", userHandler.HandleGetUserProfile)

	// Catch-all proxy: forwards unmatched /api/* to Emby server
	mux.Handle("/api/", proxyHandler)

	h := middleware.Logger(middleware.CORS(middleware.BodyLimit(mux)))

	port := os.Getenv("PORT")
	if port == "" {
		port = "19800"
	}

	log.Printf("Starting Aether Server on :%s", port)
	if err := http.ListenAndServe(":"+port, h); err != nil {
		log.Fatal(err)
	}
}

// playbackRouter dispatches /api/playback/ sub-routes
func playbackRouter(h *handler.PlaybackHandler) http.HandlerFunc {
	userHandler := handler.NewUserHandler(h.EmbyClient)
	return func(w http.ResponseWriter, r *http.Request) {
		path := r.URL.Path[len("/api/playback/"):]

		// POST /api/playback/started
		if path == "started" {
			h.HandleReportPlaybackStarted(w, r)
			return
		}

		// POST /api/playback/progress
		if path == "progress" {
			h.HandleReportPlaybackProgress(w, r)
			return
		}

		// POST /api/playback/stopped
		if path == "stopped" {
			h.HandleReportPlaybackStopped(w, r)
			return
		}

		// GET /api/playback/{itemId}/audio/stream (must check before /stream)
		if strings.HasSuffix(path, "/audio/stream") {
			userHandler.HandleGetAudioStreamURL(w, r)
			return
		}

		// GET /api/playback/{itemId}/stream (video)
		if strings.HasSuffix(path, "/stream") {
			h.HandleGetVideoStreamURL(w, r)
			return
		}

		// GET /api/playback/{itemId}/info
		if strings.HasSuffix(path, "/info") {
			h.HandleGetPlaybackInfo(w, r)
			return
		}

		// GET /api/playback/{itemId}/transcode
		if strings.HasSuffix(path, "/transcode") {
			h.HandleGetTranscodeStream(w, r)
			return
		}

		http.NotFound(w, r)
	}
}
