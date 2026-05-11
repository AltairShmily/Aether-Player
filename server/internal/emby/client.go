package emby

import (
	"encoding/json"
	"fmt"
	"io"
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
	User   User       `json:"User"`
	Token  string     `json:"AccessToken"`
	Server SystemInfo
}

type User struct {
	ID   string `json:"Id"`
	Name string `json:"Name"`
}

type ItemListResponse struct {
	Items            []MediaItem `json:"Items"`
	TotalRecordCount int         `json:"TotalRecordCount"`
}

type MediaItem struct {
	ID               string   `json:"Id"`
	Name             string   `json:"Name"`
	Type             string   `json:"Type"`
	Overview         string   `json:"Overview,omitempty"`
	CommunityRating  float64  `json:"CommunityRating,omitempty"`
	OfficialRating   string   `json:"OfficialRating,omitempty"`
	Genres           []string `json:"Genres,omitempty"`
	ProductionYear   int      `json:"ProductionYear,omitempty"`
	RunTimeTicks     int64    `json:"RunTimeTicks,omitempty"`
	DateCreated      string   `json:"DateCreated,omitempty"`
	ImageTags        struct {
		Primary  string `json:"Primary,omitempty"`
		Backdrop string `json:"Backdrop,omitempty"`
	} `json:"ImageTags,omitempty"`
	BackdropImageTags []string `json:"BackdropImageTags,omitempty"`
	SeriesName        string   `json:"SeriesName,omitempty"`
	IndexNumber       int      `json:"IndexNumber,omitempty"`
	ParentIndexNumber int      `json:"ParentIndexNumber,omitempty"`
	SeriesID          string   `json:"SeriesId,omitempty"`
	SeasonId          string   `json:"SeasonId,omitempty"`
	UserData          *UserData `json:"UserData,omitempty"`
}

type UserData struct {
	PlaybackPositionTicks int64   `json:"PlaybackPositionTicks"`
	PlayCount             int     `json:"PlayCount"`
	IsFavorite            bool    `json:"IsFavorite"`
	Played                bool    `json:"Played"`
	PlayedPercentage      float64 `json:"PlayedPercentage,omitempty"`
}

type SearchResult struct {
	SearchHints      []SearchHint `json:"SearchHints"`
	TotalRecordCount int          `json:"TotalRecordCount"`
}

type UserViewsResponse struct {
	Items []UserView `json:"Items"`
}

type UserView struct {
	ID             string `json:"Id"`
	Name           string `json:"Name"`
	CollectionType string `json:"CollectionType,omitempty"`
	ImageTags      struct {
		Primary string `json:"Primary,omitempty"`
	} `json:"ImageTags,omitempty"`
}

type SearchHint struct {
	ID             string  `json:"Id"`
	Name           string  `json:"Name"`
	Type           string  `json:"Type"`
	Overview       string  `json:"Overview,omitempty"`
	CommunityRating float64 `json:"CommunityRating,omitempty"`
	ProductionYear int     `json:"ProductionYear,omitempty"`
	PrimaryImageTag string  `json:"PrimaryImageTag,omitempty"`
}

type MediaStreamInfo struct {
	MediaSources []MediaSource `json:"MediaSources"`
}

type MediaSource struct {
	ID           string       `json:"Id"`
	Name         string       `json:"Name"`
	Path         string       `json:"Path,omitempty"`
	Container    string       `json:"Container,omitempty"`
	Size         int64        `json:"Size,omitempty"`
	Bitrate      int          `json:"Bitrate,omitempty"`
	MediaStreams []MediaStream `json:"MediaStreams,omitempty"`
}

type MediaStream struct {
	Type         string `json:"Type"`
	Codec        string `json:"Codec,omitempty"`
	Language     string `json:"Language,omitempty"`
	DisplayTitle string `json:"DisplayTitle,omitempty"`
	Width        int    `json:"Width,omitempty"`
	Height       int    `json:"Height,omitempty"`
	BitRate      int    `json:"BitRate,omitempty"`
	ChannelLayout string `json:"ChannelLayout,omitempty"`
	Index        int    `json:"Index"`
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

func (c *Client) GetItems(serverURL, token string, params map[string]string) (*ItemListResponse, error) {
	serverURL = strings.TrimRight(serverURL, "/")
	url := fmt.Sprintf("%s/Users/%s/Items", serverURL, params["userId"])

	q := "?"
	if v, ok := params["startIndex"]; ok { q += "StartIndex=" + v + "&" }
	if v, ok := params["limit"]; ok { q += "Limit=" + v + "&" }
	if v, ok := params["sortBy"]; ok { q += "SortBy=" + v + "&" }
	if v, ok := params["sortOrder"]; ok { q += "SortOrder=" + v + "&" }
	if v, ok := params["includeItemTypes"]; ok { q += "IncludeItemTypes=" + v + "&" }
	if v, ok := params["recursive"]; ok { q += "Recursive=" + v + "&" }
	if v, ok := params["searchTerm"]; ok { q += "SearchTerm=" + v + "&" }
	if v, ok := params["genres"]; ok { q += "Genres=" + v + "&" }
	if v, ok := params["years"]; ok { q += "Years=" + v + "&" }
	q = strings.TrimRight(q, "&")
	if q == "?" { q = "" }

	req, err := http.NewRequest("GET", url+q, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("X-Emby-Token", token)
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Dev-001", Version="0.0.1"`)

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to get items: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("server returned status: %d", resp.StatusCode)
	}

	var result ItemListResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &result, nil
}

func (c *Client) GetItemDetail(serverURL, token, itemID string) (*MediaItem, error) {
	serverURL = strings.TrimRight(serverURL, "/")
	url := fmt.Sprintf("%s/Users/%s/Items/%s", serverURL, extractUserID(token), itemID)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("X-Emby-Token", token)
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Dev-001", Version="0.0.1"`)

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to get item: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("server returned status: %d", resp.StatusCode)
	}

	var item MediaItem
	if err := json.NewDecoder(resp.Body).Decode(&item); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &item, nil
}

func (c *Client) GetItemImage(serverURL, token, itemID, imageType string, maxWidth int) (io.ReadCloser, string, error) {
	serverURL = strings.TrimRight(serverURL, "/")
	url := fmt.Sprintf("%s/Items/%s/Images/%s", serverURL, itemID, imageType)
	if maxWidth > 0 {
		url += fmt.Sprintf("?MaxWidth=%d&Quality=90", maxWidth)
	}

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, "", fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("X-Emby-Token", token)

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, "", fmt.Errorf("failed to get image: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		resp.Body.Close()
		return nil, "", fmt.Errorf("server returned status: %d", resp.StatusCode)
	}

	return resp.Body, resp.Header.Get("Content-Type"), nil
}

func (c *Client) Search(serverURL, token, userID, searchTerm string, limit int) (*SearchResult, error) {
	serverURL = strings.TrimRight(serverURL, "/")
	url := fmt.Sprintf("%s/Search/Hints?UserId=%s&SearchTerm=%s&Limit=%d",
		serverURL, userID, searchTerm, limit)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("X-Emby-Token", token)
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Dev-001", Version="0.0.1"`)

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to search: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("server returned status: %d", resp.StatusCode)
	}

	var result SearchResult
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &result, nil
}

func (c *Client) GetPlaybackInfo(serverURL, token, itemID string) (*MediaStreamInfo, error) {
	serverURL = strings.TrimRight(serverURL, "/")
	url := fmt.Sprintf("%s/Items/%s/PlaybackInfo?UserId=%s", serverURL, itemID, extractUserID(token))

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("X-Emby-Token", token)
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Dev-001", Version="0.0.1"`)

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to get playback info: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("server returned status: %d", resp.StatusCode)
	}

	var info MediaStreamInfo
	if err := json.NewDecoder(resp.Body).Decode(&info); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &info, nil
}

func (c *Client) GetUserViews(serverURL, token, userID string) (*UserViewsResponse, error) {
	serverURL = strings.TrimRight(serverURL, "/")
	url := fmt.Sprintf("%s/Users/%s/Views", serverURL, userID)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("X-Emby-Token", token)
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Dev-001", Version="0.0.1"`)

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to get user views: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("server returned status: %d", resp.StatusCode)
	}

	var result UserViewsResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &result, nil
}

func (c *Client) GetResumeItems(serverURL, token, userID string, limit int) (*ItemListResponse, error) {
	serverURL = strings.TrimRight(serverURL, "/")
	url := fmt.Sprintf("%s/Users/%s/Items/Resume?Limit=%d&Recursive=true&Fields=UserData,MediaStreams", serverURL, userID, limit)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("X-Emby-Token", token)
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Dev-001", Version="0.0.1"`)

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to get resume items: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("server returned status: %d", resp.StatusCode)
	}

	var result ItemListResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &result, nil
}

func (c *Client) GetSeasons(serverURL, token, seriesID string) (*ItemListResponse, error) {
	serverURL = strings.TrimRight(serverURL, "/")
	url := fmt.Sprintf("%s/Shows/%s/Seasons?UserId=%s&Fields=UserData", serverURL, seriesID, extractUserID(token))

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("X-Emby-Token", token)
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Dev-001", Version="0.0.1"`)

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to get seasons: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("server returned status: %d", resp.StatusCode)
	}

	var result ItemListResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &result, nil
}

func (c *Client) GetEpisodes(serverURL, token, seriesID, seasonID string, limit int) (*ItemListResponse, error) {
	serverURL = strings.TrimRight(serverURL, "/")
	url := fmt.Sprintf("%s/Shows/%s/Episodes?SeasonId=%s&Fields=UserData,MediaStreams&Limit=%d", serverURL, seriesID, seasonID, limit)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("X-Emby-Token", token)
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Dev-001", Version="0.0.1"`)

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to get episodes: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("server returned status: %d", resp.StatusCode)
	}

	var result ItemListResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}

	return &result, nil
}

func extractUserID(token string) string {
	return ""
}
