// Package mobile provides gomobile-compatible bindings for Aether Server.
//
// gomobile bind restrictions:
//   - Exported functions only (capitalized)
//   - Parameters and return values must be basic types or gomobile-compatible types
//   - No goroutine-safe state without sync primitives
//   - Package-level functions are bound as Java static methods / ObjC class methods
package mobile

import (
	"context"
	"fmt"
	"log"
	"net"
	"net/http"
	"strings"
	"sync"
	"time"

	"aether-server/internal/emby"
	"aether-server/internal/handler"
	"aether-server/internal/middleware"
)

var (
	mu       sync.Mutex
	server   *http.Server
	running  bool
	listener net.Listener
)

// StartServer starts the Aether HTTP server on the given port.
// Returns an error string if the server fails to start.
// Returns "" on success.
//
// gomobile will expose this as:
//
//	Java:  AetherServer.startServer(port) -> String
//	Swift: AetherServerStartServer(port) -> String
func StartServer(port int) string {
	mu.Lock()
	defer mu.Unlock()

	if running {
		return ""
	}

	addr := fmt.Sprintf("127.0.0.1:%d", port)
	mux := buildMux()

	h := middleware.Logger(middleware.CORS(middleware.BodyLimit(mux)))

	// Create listener first to catch bind errors early
	ln, err := net.Listen("tcp", addr)
	if err != nil {
		return fmt.Sprintf("listen error: %v", err)
	}

	server = &http.Server{
		Handler:           h,
		ReadHeaderTimeout: 10 * time.Second,
	}
	listener = ln
	running = true

	go func() {
		log.Printf("[AetherServer] Listening on %s", addr)
		if err := server.Serve(ln); err != nil && err != http.ErrServerClosed {
			log.Printf("[AetherServer] Serve error: %v", err)
		}
		mu.Lock()
		running = false
		mu.Unlock()
	}()

	return ""
}

// StopServer gracefully shuts down the server.
// Returns "" on success.
func StopServer() string {
	mu.Lock()
	defer mu.Unlock()

	if !running || server == nil {
		return ""
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	err := server.Shutdown(ctx)
	running = false
	server = nil
	listener = nil

	if err != nil {
		return fmt.Sprintf("shutdown error: %v", err)
	}
	return ""
}

// IsRunning returns whether the server is currently running.
func IsRunning() bool {
	mu.Lock()
	defer mu.Unlock()
	return running
}

// GetPort returns the port the server is listening on, or 0 if not running.
func GetPort() int {
	mu.Lock()
	defer mu.Unlock()
	if listener != nil {
		return listener.Addr().(*net.TCPAddr).Port
	}
	return 0
}

// Ping performs a self-health-check. Returns "ok" or an error string.
func Ping() string {
	mu.Lock()
	addr := ""
	if listener != nil {
		addr = listener.Addr().String()
	}
	mu.Unlock()

	if addr == "" {
		return "server not running"
	}

	client := &http.Client{Timeout: 2 * time.Second}
	resp, err := client.Get("http://" + addr + "/api/health")
	if err != nil {
		return fmt.Sprintf("ping failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == 200 {
		return "ok"
	}
	return fmt.Sprintf("ping status: %d", resp.StatusCode)
}

// buildMux creates the HTTP handler with all routes.
// Extracted from cmd/api/main.go for reuse.
func buildMux() *http.ServeMux {
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

	// Catch-all proxy
	mux.Handle("/api/", proxyHandler)

	return mux
}

// playbackRouter dispatches /api/playback/ sub-routes.
func playbackRouter(h *handler.PlaybackHandler) http.HandlerFunc {
	userHandler := handler.NewUserHandler(h.EmbyClient)
	return func(w http.ResponseWriter, r *http.Request) {
		path := r.URL.Path[len("/api/playback/"):]

		if path == "started" {
			h.HandleReportPlaybackStarted(w, r)
			return
		}
		if path == "progress" {
			h.HandleReportPlaybackProgress(w, r)
			return
		}
		if path == "stopped" {
			h.HandleReportPlaybackStopped(w, r)
			return
		}
		if strings.HasSuffix(path, "/audio/stream") {
			userHandler.HandleGetAudioStreamURL(w, r)
			return
		}
		if strings.HasSuffix(path, "/stream") {
			h.HandleGetVideoStreamURL(w, r)
			return
		}
		if strings.HasSuffix(path, "/info") {
			h.HandleGetPlaybackInfo(w, r)
			return
		}
		if strings.HasSuffix(path, "/transcode") {
			h.HandleGetTranscodeStream(w, r)
			return
		}
		http.NotFound(w, r)
	}
}
