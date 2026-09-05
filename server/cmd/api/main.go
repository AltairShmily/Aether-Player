package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

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

	// 默认只监听回环地址：本服务是供同机 Flutter 客户端使用的本地代理。
	// 绑定所有网卡会让同网段任意主机都能驱动它访问内网。
	// 确需远程访问时通过 BIND_ADDR 显式放开。
	bindAddr := os.Getenv("BIND_ADDR")
	if bindAddr == "" {
		bindAddr = "127.0.0.1"
	}

	srv := &http.Server{
		Addr:    bindAddr + ":" + port,
		Handler: h,
		// 限制读取请求头的时长，防止 Slowloris 类慢速攻击占用连接
		ReadHeaderTimeout: 10 * time.Second,
	}

	// 优雅关闭：收到信号后停止接收新连接并等待在途请求完成，
	// 而非直接斩断（播放进度上报等请求会因此丢失）
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	go func() {
		log.Printf("Starting Aether Server on %s:%s", bindAddr, port)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatal(err)
		}
	}()

	<-ctx.Done()
	log.Printf("Shutting down Aether Server...")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Printf("Graceful shutdown failed: %v", err)
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
