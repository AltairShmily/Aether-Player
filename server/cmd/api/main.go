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
	// This enables access to ALL Emby endpoints (System/Info, Configuration, Plugins, etc.)
	mux.Handle("/api/", proxyHandler)

	h := middleware.Logger(middleware.CORS(mux))

	log.Println("Starting Aether Server on :19800")
	if err := http.ListenAndServe(":19800", h); err != nil {
		log.Fatal(err)
	}
}

// playbackRouter dispatches /api/playback/ sub-routes
func playbackRouter(h *handler.PlaybackHandler) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		path := r.URL.Path[len("/api/playback/"):]

		// POST /api/playback/started
		if path == "started" && r.Method == "POST" {
			h.HandleReportPlaybackStarted(w, r)
			return
		}

		// POST /api/playback/progress
		if path == "progress" && r.Method == "POST" {
			h.HandleReportPlaybackProgress(w, r)
			return
		}

		// POST /api/playback/stopped
		if path == "stopped" && r.Method == "POST" {
			h.HandleReportPlaybackStopped(w, r)
			return
		}

		// GET /api/playback/{itemId}/info
		if strings.HasSuffix(path, "/info") && r.Method == "GET" {
			h.HandleGetPlaybackInfo(w, r)
			return
		}

		// GET /api/playback/{itemId}/audio/stream (must check before /stream)
		if strings.HasSuffix(path, "/audio/stream") && r.Method == "GET" {
			userHandler := handler.NewUserHandler(h.EmbyClient)
			userHandler.HandleGetAudioStreamURL(w, r)
			return
		}

		// GET /api/playback/{itemId}/stream (video)
		if strings.HasSuffix(path, "/stream") && r.Method == "GET" {
			h.HandleGetVideoStreamURL(w, r)
			return
		}

		http.NotFound(w, r)
	}
}
