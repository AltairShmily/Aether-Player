package handler

import (
	"io"
	"log"
	"net"
	"net/http"
	"net/url"
	"strings"
	"time"
)

// ProxyHandler transparently proxies unmatched /api/* requests to the Emby server.
// It reads X-Emby-Server and X-Emby-Token headers to target the correct server.
type ProxyHandler struct{}

func NewProxyHandler() *ProxyHandler {
	return &ProxyHandler{}
}

// validateServerURL checks that the server URL is safe to proxy to.
func validateServerURL(serverURL string) error {
	u, err := url.Parse(serverURL)
	if err != nil {
		return err
	}
	if u.Scheme != "http" && u.Scheme != "https" {
		return &url.Error{Op: "validate", URL: serverURL, Err: net.InvalidAddrError("scheme must be http or https")}
	}
	if u.Hostname() == "" {
		return &url.Error{Op: "validate", URL: serverURL, Err: net.InvalidAddrError("empty host")}
	}
	// Block cloud metadata endpoints
	host := u.Hostname()
	if strings.HasPrefix(host, "169.254.") || host == "0.0.0.0" {
		return &url.Error{Op: "validate", URL: serverURL, Err: net.InvalidAddrError("blocked host")}
	}
	return nil
}

// ServeHTTP forwards the request to the Emby server.
// Only activates for paths not matched by explicit routes above.
func (h *ProxyHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	serverURL := r.Header.Get("X-Emby-Server")
	token := r.Header.Get("X-Emby-Token")
	deviceID := r.Header.Get("X-Device-Id")
	if deviceID == "" {
		deviceID = "Aether-Client"
	}

	if serverURL == "" {
		http.Error(w, `{"error":"Missing X-Emby-Server header"}`, http.StatusBadRequest)
		return
	}

	if err := validateServerURL(serverURL); err != nil {
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
		// Skip hop-by-hop headers
		switch strings.ToLower(key) {
		case "host", "connection", "keep-alive", "transfer-encoding":
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

	// Execute request with timeout
	client := &http.Client{Timeout: 30 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		log.Printf("Proxy error: %v", err)
		http.Error(w, `{"error":"Failed to reach Emby server"}`, http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	// Forward response headers
	for key, values := range resp.Header {
		switch strings.ToLower(key) {
		case "transfer-encoding", "connection":
			continue
		}
		for _, v := range values {
			w.Header().Add(key, v)
		}
	}

	// Forward status code and body
	w.WriteHeader(resp.StatusCode)
	io.Copy(w, resp.Body)
}
