package handler

import (
	"io"
	"log"
	"net/http"
	"strings"

	"aether-server/internal/security"
)

// ProxyHandler transparently proxies unmatched /api/* requests to the Emby server.
// It reads X-Emby-Server and X-Emby-Token headers to target the correct server.
type ProxyHandler struct{}

// proxyClient 全局复用，保持连接池。
// 每个请求新建 http.Client 会导致 TCP/TLS 无法复用，代理延迟显著上升。
var proxyClient = security.NewSafeClient()

// hopByHopHeaders 是不应被转发的逐跳头。
var hopByHopHeaders = map[string]struct{}{
	"host":                {},
	"connection":          {},
	"keep-alive":          {},
	"transfer-encoding":   {},
	"te":                  {},
	"trailer":             {},
	"upgrade":             {},
	"proxy-authorization": {},
	"proxy-authenticate":  {},
}

func NewProxyHandler() *ProxyHandler {
	return &ProxyHandler{}
}

// ServeHTTP forwards the request to the Emby server.
// Only activates for paths not matched by explicit routes above.
func (h *ProxyHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	serverURL := r.Header.Get("X-Emby-Server")
	token := r.Header.Get("X-Emby-Token")

	// deviceID 会被拼进 X-Emby-Authorization 的引号内，必须净化，
	// 否则调用方可用引号突破字段边界、篡改授权头语义
	deviceID := security.SanitizeDeviceID(r.Header.Get("X-Device-Id"))

	if serverURL == "" {
		http.Error(w, `{"error":"Missing X-Emby-Server header"}`, http.StatusBadRequest)
		return
	}

	if err := security.ValidateServerURL(serverURL); err != nil {
		log.Printf("Proxy rejected server URL: %v", err)
		http.Error(w, `{"error":"Invalid server URL"}`, http.StatusBadRequest)
		return
	}

	serverURL = strings.TrimRight(serverURL, "/")

	// Build target URL: strip /api prefix, forward rest to Emby
	// /api/System/Info → {server}/System/Info
	path := r.URL.Path
	if strings.HasPrefix(path, "/api/") {
		path = path[4:] // remove "/api"
	}

	targetURL := serverURL + path
	if r.URL.RawQuery != "" {
		targetURL += "?" + r.URL.RawQuery
	}

	// Create outgoing request
	req, err := http.NewRequestWithContext(r.Context(), r.Method, targetURL, r.Body)
	if err != nil {
		http.Error(w, `{"error":"Failed to create proxy request"}`, http.StatusInternalServerError)
		return
	}

	// Forward original headers
	for key, values := range r.Header {
		if _, skip := hopByHopHeaders[strings.ToLower(key)]; skip {
			continue
		}
		for _, v := range values {
			req.Header.Add(key, v)
		}
	}

	// Inject Emby auth headers
	if token != "" {
		req.Header.Set("X-Emby-Token", token)
	}
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="`+deviceID+`", Version="0.0.1"`)

	// 不设整体超时：流式响应与大 body 需要长时间传输，
	// 超时约束由 Transport 的连接与响应头阶段负责
	resp, err := proxyClient.Do(req)
	if err != nil {
		log.Printf("Proxy error: %v", err)
		http.Error(w, `{"error":"Failed to reach Emby server"}`, http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	// Forward response headers
	for key, values := range resp.Header {
		if _, skip := hopByHopHeaders[strings.ToLower(key)]; skip {
			continue
		}
		for _, v := range values {
			w.Header().Add(key, v)
		}
	}

	w.WriteHeader(resp.StatusCode)

	// 边收边转发：io.Copy 写完再 Flush 对流式响应毫无帮助，
	// 数据仍会被缓冲到结束才发出，表现为播放器长时间无数据
	flusher, canFlush := w.(http.Flusher)
	buf := make([]byte, 32*1024)
	for {
		n, readErr := resp.Body.Read(buf)
		if n > 0 {
			if _, writeErr := w.Write(buf[:n]); writeErr != nil {
				log.Printf("Proxy write error (%s %s): %v", r.Method, targetURL, writeErr)
				return
			}
			if canFlush {
				flusher.Flush()
			}
		}
		if readErr != nil {
			if readErr != io.EOF {
				// 状态码已发出，无法再改写，只能记录
				log.Printf("Proxy copy error (%s %s): %v", r.Method, targetURL, readErr)
			}
			return
		}
	}
}
