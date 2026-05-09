package emby

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
)

type Client struct {
	HTTPClient *http.Client
}

type SystemInfo struct {
	ServerName string `json:"ServerName"`
	Version    string `json:"Version"`
	ID         string `json:"Id"`
}

type AuthResult struct {
	User    User   `json:"User"`
	Token   string `json:"AccessToken"`
	Server  SystemInfo
}

type User struct {
	ID   string `json:"Id"`
	Name string `json:"Name"`
}

func NewClient() *Client {
	return &Client{
		HTTPClient: &http.Client{},
	}
}

func (c *Client) TestConnection(serverURL string) (*SystemInfo, error) {
	serverURL = strings.TrimRight(serverURL, "/")
	url := fmt.Sprintf("%s/System/Info/Public", serverURL)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Dev-001", Version="0.0.1"`)

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to server: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("server returned status: %d", resp.StatusCode)
	}

	var info SystemInfo
	if err := json.NewDecoder(resp.Body).Decode(&info); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &info, nil
}

func (c *Client) Authenticate(serverURL, username, password string) (*AuthResult, error) {
	serverURL = strings.TrimRight(serverURL, "/")
	url := fmt.Sprintf("%s/Users/AuthenticateByName", serverURL)

	body := strings.NewReader(fmt.Sprintf(`{"Username": %q, "Pw": %q}`, username, password))
	req, err := http.NewRequest("POST", url, body)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Dev-001", Version="0.0.1"`)

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to authenticate: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("authentication failed with status: %d", resp.StatusCode)
	}

	var result AuthResult
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	sysInfo, err := c.TestConnection(serverURL)
	if err == nil {
		result.Server = *sysInfo
	}

	return &result, nil
}
