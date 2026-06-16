package handler

import (
	"encoding/json"
	"log"
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
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req ConnectRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	info, err := h.EmbyClient.TestConnection(req.ServerURL)
	if err != nil {
		log.Printf("Connect error: %v", err)
		http.Error(w, "Failed to connect to server", http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(info); err != nil {
		log.Printf("JSON encode error: %v", err)
	}
}

func (h *AuthHandler) HandleLogin(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	result, err := h.EmbyClient.Authenticate(req.ServerURL, req.Username, req.Password)
	if err != nil {
		log.Printf("Login error: %v", err)
		http.Error(w, "Authentication failed", http.StatusUnauthorized)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(result); err != nil {
		log.Printf("JSON encode error: %v", err)
	}
}
