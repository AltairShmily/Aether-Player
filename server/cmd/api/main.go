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

	mux := http.NewServeMux()

	mux.HandleFunc("/api/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"status": "ok", "service": "Aether Server"}`))
	})

	mux.HandleFunc("/api/auth/connect", authHandler.HandleConnect)
	mux.HandleFunc("/api/auth/login", authHandler.HandleLogin)

	mux.HandleFunc("/api/library/views", libraryHandler.HandleGetUserViews)
	mux.HandleFunc("/api/library/items", libraryHandler.HandleGetItems)
	mux.HandleFunc("/api/library/items/", libraryHandler.HandleGetItemDetail)
	mux.HandleFunc("/api/library/resume", libraryHandler.HandleGetResumeItems)
	mux.HandleFunc("/api/library/seasons", libraryHandler.HandleGetSeasons)
	mux.HandleFunc("/api/library/episodes", libraryHandler.HandleGetEpisodes)
	mux.HandleFunc("/api/images/", libraryHandler.HandleGetItemImage)
	mux.HandleFunc("/api/search", libraryHandler.HandleSearch)

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
