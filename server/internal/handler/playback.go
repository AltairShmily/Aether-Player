package handler

import (
	"encoding/json"
	"net/http"

	"aether-server/internal/emby"
)

type PlaybackHandler struct {
	EmbyClient *emby.Client
}

func NewPlaybackHandler(client *emby.Client) *PlaybackHandler {
	return &PlaybackHandler{EmbyClient: client}
}

// HandleGetPlaybackInfo proxies POST /Items/{Id}/PlaybackInfo to Emby
func (h *PlaybackHandler) HandleGetPlaybackInfo(w http.ResponseWriter, r *http.Request) {
	serverURL := r.Header.Get("X-Emby-Server")
	token := r.Header.Get("X-Emby-Token")
	userID := r.Header.Get("X-Emby-User")

	// Extract itemID from path: /api/playback/{itemId}/info
	path := r.URL.Path[len("/api/playback/"):]
	itemID := ""
	for _, c := range path {
		if c == '/' {
			break
		}
		itemID += string(c)
	}

	if serverURL == "" || token == "" || userID == "" || itemID == "" {
		http.Error(w, "Missing required parameters", http.StatusBadRequest)
		return
	}

	result, err := h.EmbyClient.GetPlaybackInfo(serverURL, token, userID, itemID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadGateway)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(result)
}

// HandleGetVideoStreamURL returns the direct play / transcode URL
func (h *PlaybackHandler) HandleGetVideoStreamURL(w http.ResponseWriter, r *http.Request) {
	serverURL := r.Header.Get("X-Emby-Server")
	token := r.Header.Get("X-Emby-Token")

	// Extract itemID from path: /api/playback/{itemId}/stream
	path := r.URL.Path[len("/api/playback/"):]
	itemID := ""
	for _, c := range path {
		if c == '/' {
			break
		}
		itemID += string(c)
	}

	container := r.URL.Query().Get("container")
	if container == "" {
		container = "mp4"
	}

	if serverURL == "" || token == "" || itemID == "" {
		http.Error(w, "Missing required parameters", http.StatusBadRequest)
		return
	}

	streamURL := h.EmbyClient.GetVideoStreamURL(serverURL, token, itemID, container)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"streamUrl": streamURL,
	})
}

// HandleReportPlaybackStarted reports playback started to Emby
func (h *PlaybackHandler) HandleReportPlaybackStarted(w http.ResponseWriter, r *http.Request) {
	serverURL := r.Header.Get("X-Emby-Server")
	token := r.Header.Get("X-Emby-Token")

	var req struct {
		ItemId         string `json:"itemId"`
		MediaSourceId  string `json:"mediaSourceId"`
		PlaySessionId  string `json:"playSessionId"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if serverURL == "" || token == "" || req.ItemId == "" {
		http.Error(w, "Missing required parameters", http.StatusBadRequest)
		return
	}

	err := h.EmbyClient.ReportPlaybackStarted(serverURL, token, req.ItemId, req.MediaSourceId, req.PlaySessionId)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadGateway)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// HandleReportPlaybackProgress reports playback progress to Emby
func (h *PlaybackHandler) HandleReportPlaybackProgress(w http.ResponseWriter, r *http.Request) {
	serverURL := r.Header.Get("X-Emby-Server")
	token := r.Header.Get("X-Emby-Token")

	var req struct {
		ItemId         string `json:"itemId"`
		MediaSourceId  string `json:"mediaSourceId"`
		PlaySessionId  string `json:"playSessionId"`
		PositionTicks  int64  `json:"positionTicks"`
		IsPaused       bool   `json:"isPaused"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if serverURL == "" || token == "" || req.ItemId == "" {
		http.Error(w, "Missing required parameters", http.StatusBadRequest)
		return
	}

	err := h.EmbyClient.ReportPlaybackProgress(serverURL, token, req.ItemId, req.MediaSourceId, req.PlaySessionId, req.PositionTicks, req.IsPaused)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadGateway)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// HandleReportPlaybackStopped reports playback stopped to Emby
func (h *PlaybackHandler) HandleReportPlaybackStopped(w http.ResponseWriter, r *http.Request) {
	serverURL := r.Header.Get("X-Emby-Server")
	token := r.Header.Get("X-Emby-Token")

	var req struct {
		ItemId         string `json:"itemId"`
		MediaSourceId  string `json:"mediaSourceId"`
		PlaySessionId  string `json:"playSessionId"`
		PositionTicks  int64  `json:"positionTicks"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if serverURL == "" || token == "" || req.ItemId == "" {
		http.Error(w, "Missing required parameters", http.StatusBadRequest)
		return
	}

	err := h.EmbyClient.ReportPlaybackStopped(serverURL, token, req.ItemId, req.MediaSourceId, req.PlaySessionId, req.PositionTicks)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadGateway)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
