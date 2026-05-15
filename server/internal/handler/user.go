package handler

import (
	"encoding/json"
	"net/http"
	"strconv"

	"aether-server/internal/emby"
)

// UserHandler handles user-related API routes.
type UserHandler struct {
	EmbyClient *emby.Client
}

func NewUserHandler(client *emby.Client) *UserHandler {
	return &UserHandler{EmbyClient: client}
}

// HandleToggleFavorite toggles favorite status.
// POST /api/users/favorites/toggle
func (h *UserHandler) HandleToggleFavorite(w http.ResponseWriter, r *http.Request) {
	serverURL := r.Header.Get("X-Emby-Server")
	token := r.Header.Get("X-Emby-Token")
	userID := r.Header.Get("X-Emby-User")

	var req struct {
		ItemID     string `json:"itemId"`
		IsFavorite bool   `json:"isFavorite"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	if serverURL == "" || token == "" || userID == "" || req.ItemID == "" {
		http.Error(w, "Missing required parameters", http.StatusBadRequest)
		return
	}

	newState, err := h.EmbyClient.ToggleFavorite(serverURL, token, userID, req.ItemID, req.IsFavorite)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadGateway)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]bool{"isFavorite": newState})
}

// HandleGetFavorites returns all favorited items.
// GET /api/users/favorites
func (h *UserHandler) HandleGetFavorites(w http.ResponseWriter, r *http.Request) {
	serverURL := r.Header.Get("X-Emby-Server")
	token := r.Header.Get("X-Emby-Token")
	userID := r.Header.Get("X-Emby-User")

	if serverURL == "" || token == "" || userID == "" {
		http.Error(w, "Missing Emby headers", http.StatusBadRequest)
		return
	}

	limit := 50
	if l, err := strconv.Atoi(r.URL.Query().Get("limit")); err == nil && l > 0 {
		limit = l
	}

	result, err := h.EmbyClient.GetFavoriteItems(serverURL, token, userID, limit)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadGateway)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(result)
}

// HandleGetAudioStreamURL returns the audio stream URL.
// GET /api/playback/{itemId}/audio/stream
func (h *UserHandler) HandleGetAudioStreamURL(w http.ResponseWriter, r *http.Request) {
	serverURL := r.Header.Get("X-Emby-Server")
	token := r.Header.Get("X-Emby-Token")

	path := r.URL.Path[len("/api/playback/"):]
	itemID := ""
	for _, c := range path {
		if c == '/' {
			break
		}
		itemID += string(c)
	}

	if serverURL == "" || token == "" || itemID == "" {
		http.Error(w, "Missing required parameters", http.StatusBadRequest)
		return
	}

	streamURL := h.EmbyClient.GetAudioStreamURL(serverURL, token, itemID)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"streamUrl": streamURL})
}

// HandleGetUserProfile returns user profile info.
// GET /api/users/profile
func (h *UserHandler) HandleGetUserProfile(w http.ResponseWriter, r *http.Request) {
	serverURL := r.Header.Get("X-Emby-Server")
	token := r.Header.Get("X-Emby-Token")
	userID := r.Header.Get("X-Emby-User")

	if serverURL == "" || token == "" || userID == "" {
		http.Error(w, "Missing Emby headers", http.StatusBadRequest)
		return
	}

	profile, err := h.EmbyClient.GetUserProfile(serverURL, token, userID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadGateway)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(profile)
}
