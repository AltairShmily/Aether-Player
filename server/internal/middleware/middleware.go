package middleware

import (
	"log"
	"net/http"
	"os"
	"strings"
	"time"
)

func Logger(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		log.Printf("Started %s %s", r.Method, r.URL.Path)
		next.ServeHTTP(w, r)
		log.Printf("Completed %s %s %s", r.Method, r.URL.Path, time.Since(start))
	})
}

// CORS 只在显式配置了具体来源时才放行跨域。
//
// 本服务是供 Flutter 客户端经 localhost 直连的本地代理，并非浏览器跨域场景，
// 默认无需任何 CORS 头。此前的默认值 "*" 配合允许 X-Emby-Server / X-Emby-Token
// 自定义头，会让用户浏览器中任意恶意网页都能驱动本机代理发起请求、
// 跨域读取响应并窃取令牌。
func CORS(next http.Handler) http.Handler {
	allowedOrigin := strings.TrimSpace(os.Getenv("CORS_ALLOW_ORIGIN"))

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if allowedOrigin != "" && allowedOrigin != "*" {
			w.Header().Set("Access-Control-Allow-Origin", allowedOrigin)
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Emby-Server, X-Emby-Token, X-Emby-User, X-Device-Id")
			w.Header().Set("Access-Control-Expose-Headers", "Content-Type")
			w.Header().Set("Vary", "Origin")
		}

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func BodyLimit(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		r.Body = http.MaxBytesReader(w, r.Body, 1<<20) // 1MB
		next.ServeHTTP(w, r)
	})
}
