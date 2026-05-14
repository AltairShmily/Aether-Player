package handler

import (
	"encoding/json"
	"io"
	"net/http"
	"strconv"

	"aether-server/internal/emby"
)

type LibraryHandler struct {
	EmbyClient *emby.Client
}

func NewLibraryHandler(client *emby.Client) *LibraryHandler {
	return &LibraryHandler{EmbyClient: client}
}

func (h *LibraryHandler) HandleGetUserViews(w http.ResponseWriter, r *http.Request) {
	serverURL := r.Header.Get("X-Emby-Server")
	token := r.Header.Get("X-Emby-Token")
	userID := r.Header.Get("X-Emby-User")

	if serverURL == "" || token == "" || userID == "" {
		http.Error(w, "Missing Emby headers", http.StatusBadRequest)
		return
	}

	result, err := h.EmbyClient.GetUserViews(serverURL, token, userID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadGateway)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(result)
}

func (h *LibraryHandler) HandleGetItems(w http.ResponseWriter, r *http.Request) {
	serverURL := r.Header.Get("X-Emby-Server")
	token := r.Header.Get("X-Emby-Token")
	userID := r.Header.Get("X-Emby-User")

	if serverURL == "" || token == "" || userID == "" {
		http.Error(w, "Missing Emby headers", http.StatusBadRequest)
		return
	}

	params := map[string]string{
		"userId":           userID,
		"startIndex":       r.URL.Query().Get("startIndex"),
		"limit":            r.URL.Query().Get("limit"),
		"sortBy":           r.URL.Query().Get("sortBy"),
		"sortOrder":        r.URL.Query().Get("sortOrder"),
		"includeItemTypes": r.URL.Query().Get("includeItemTypes"),
		"recursive":        r.URL.Query().Get("recursive"),
		"searchTerm":       r.URL.Query().Get("searchTerm"),
		"parentId":         r.URL.Query().Get("parentId"),
		"fields":           r.URL.Query().Get("fields"),
	}

	if params["limit"] == "" {
		params["limit"] = "20"
	}
	if params["sortBy"] == "" {
		params["sortBy"] = "DateCreated"
	}
	if params["sortOrder"] == "" {
		params["sortOrder"] = "Descending"
	}
	if params["recursive"] == "" {
		params["recursive"] = "true"
	}

	result, err := h.EmbyClient.GetItems(serverURL, token, params)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadGateway)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(result)
}

func (h *LibraryHandler) HandleGetItemDetail(w http.ResponseWriter, r *http.Request) {
	serverURL := r.Header.Get("X-Emby-Server")
	token := r.Header.Get("X-Emby-Token")
	userID := r.Header.Get("X-Emby-User")
	itemID := r.URL.Path[len("/api/library/items/"):]

	if serverURL == "" || token == "" || userID == "" {
		http.Error(w, "Missing Emby headers", http.StatusBadRequest)
		return
	}

	item, err := h.EmbyClient.GetItemDetail(serverURL, token, userID, itemID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadGateway)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(item)
}

func (h *LibraryHandler) HandleGetItemImage(w http.ResponseWriter, r *http.Request) {
	serverURL := r.Header.Get("X-Emby-Server")
	token := r.Header.Get("X-Emby-Token")

	path := r.URL.Path[len("/api/images/"):]
	parts := splitImagePath(path)
	if len(parts) < 2 {
		http.Error(w, "Invalid image path", http.StatusBadRequest)
		return
	}

	itemID := parts[0]
	imageType := parts[1]
	maxWidth, _ := strconv.Atoi(r.URL.Query().Get("maxWidth"))

	body, contentType, err := h.EmbyClient.GetItemImage(serverURL, token, itemID, imageType, maxWidth)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadGateway)
		return
	}
	defer body.Close()

	w.Header().Set("Content-Type", contentType)
	w.Header().Set("Cache-Control", "public, max-age=86400")
	io.Copy(w, body)
}

func (h *LibraryHandler) HandleGetResumeItems(w http.ResponseWriter, r *http.Request) {
	serverURL := r.Header.Get("X-Emby-Server")
	token := r.Header.Get("X-Emby-Token")
	userID := r.Header.Get("X-Emby-User")

	if serverURL == "" || token == "" || userID == "" {
		http.Error(w, "Missing Emby headers", http.StatusBadRequest)
		return
	}

	limit := 20
	if l, err := strconv.Atoi(r.URL.Query().Get("limit")); err == nil && l > 0 {
		limit = l
	}

	result, err := h.EmbyClient.GetResumeItems(serverURL, token, userID, limit)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadGateway)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(result)
}

func (h *LibraryHandler) HandleGetSeasons(w http.ResponseWriter, r *http.Request) {
	serverURL := r.Header.Get("X-Emby-Server")
	token := r.Header.Get("X-Emby-Token")
	userID := r.Header.Get("X-Emby-User")
	seriesID := r.URL.Query().Get("seriesId")

	if serverURL == "" || token == "" || userID == "" || seriesID == "" {
		http.Error(w, "Missing parameters", http.StatusBadRequest)
		return
	}

	result, err := h.EmbyClient.GetSeasons(serverURL, token, userID, seriesID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadGateway)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(result)
}

func (h *LibraryHandler) HandleGetEpisodes(w http.ResponseWriter, r *http.Request) {
	serverURL := r.Header.Get("X-Emby-Server")
	token := r.Header.Get("X-Emby-Token")
	seriesID := r.URL.Query().Get("seriesId")
	seasonID := r.URL.Query().Get("seasonId")

	if serverURL == "" || token == "" || seriesID == "" || seasonID == "" {
		http.Error(w, "Missing parameters", http.StatusBadRequest)
		return
	}

	limit := 50
	if l, err := strconv.Atoi(r.URL.Query().Get("limit")); err == nil && l > 0 {
		limit = l
	}

	result, err := h.EmbyClient.GetEpisodes(serverURL, token, seriesID, seasonID, limit)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadGateway)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(result)
}

func (h *LibraryHandler) HandleSearch(w http.ResponseWriter, r *http.Request) {
	serverURL := r.Header.Get("X-Emby-Server")
	token := r.Header.Get("X-Emby-Token")
	userID := r.Header.Get("X-Emby-User")
	term := r.URL.Query().Get("term")
	limitStr := r.URL.Query().Get("limit")

	if serverURL == "" || token == "" || term == "" {
		http.Error(w, "Missing required parameters", http.StatusBadRequest)
		return
	}

	limit := 20
	if l, err := strconv.Atoi(limitStr); err == nil && l > 0 {
		limit = l
	}

	result, err := h.EmbyClient.Search(serverURL, token, userID, term, limit)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadGateway)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(result)
}

func splitImagePath(path string) []string {
	var parts []string
	current := ""
	for _, c := range path {
		if c == '/' {
			if current != "" {
				parts = append(parts, current)
				current = ""
			}
		} else {
			current += string(c)
		}
	}
	if current != "" {
		parts = append(parts, current)
	}
	return parts
}
