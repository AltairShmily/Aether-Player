package handler

import (
	"encoding/json"
	"net/http"

	"aether-server/internal/emby"
)

type AuthHandler struct {
	EmbyClient *emby.Client
}

func NewAuthHandler(client *emby.Client) *AuthHandler {
	return &AuthHandler{EmbyClient: client}
}

type ConnectRequest struct {
	ServerURL string `json:"server_url"`
}

type LoginRequest struct {
	ServerURL string `json:"server_url"`
	Username  string `json:"username"`
	Password  string `json:"password"`
}

func (h *AuthHandler) HandleConnect(w http.ResponseWriter, r *http.Request) {
	var req ConnectRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	info, err := h.EmbyClient.TestConnection(req.ServerURL)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(info)
}

func (h *AuthHandler) HandleLogin(w http.ResponseWriter, r *http.Request) {
	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	result, err := h.EmbyClient.Authenticate(req.ServerURL, req.Username, req.Password)
	if err != nil {
		http.Error(w, err.Error(), http.StatusUnauthorized)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(result)
}
