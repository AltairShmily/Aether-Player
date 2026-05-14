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
	MediaSources  []MediaSource `json:"MediaSources"`
	PlaySessionId string        `json:"PlaySessionId,omitempty"`
}

type MediaSource struct {
	ID           string       `json:"Id"`
	Name         string       `json:"Name"`
	Path         string       `json:"Path,omitempty"`
	Container    string       `json:"Container,omitempty"`
	Size         int64        `json:"Size,omitempty"`
	Bitrate      int          `json:"Bitrate,omitempty"`
	MediaStreams []MediaStream `json:"MediaStreams,omitempty"`
	DirectStreamUrl string   `json:"DirectStreamUrl,omitempty"`
	TranscodingUrl  string   `json:"TranscodingUrl,omitempty"`
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

// PlaybackInfoRequest is sent to Emby POST /Items/{Id}/PlaybackInfo
type PlaybackInfoRequest struct {
	MediaSourceId      string        `json:"MediaSourceId,omitempty"`
	DeviceProfile      *DeviceProfile `json:"DeviceProfile,omitempty"`
	DeviceId           string        `json:"DeviceId,omitempty"`
	MaxStreamingBitrate int          `json:"MaxStreamingBitrate,omitempty"`
}

type DeviceProfile struct {
	Name    string   `json:"Name"`
	Id      string   `json:"Id"`
	Type    string   `json:"Type"`
	AlbumPolicies []DirectPlayProfile `json:"DirectPlayProfiles,omitempty"`
	DirectStreamingProfiles []DirectPlayProfile `json:"DirectStreamingProfiles,omitempty"`
	TranscodingProfiles    []TranscodingProfile `json:"TranscodingProfiles,omitempty"`
	CodecProfiles          []CodecProfile       `json:"CodecProfiles,omitempty"`
	ContainerProfiles      []ContainerProfile   `json:"ContainerProfiles,omitempty"`
	SubtitleProfiles       []SubtitleProfile    `json:"SubtitleProfiles,omitempty"`
}

type DirectPlayProfile struct {
	Container  string   `json:"Container"`
	AudioCodec string   `json:"AudioCodec"`
	VideoCodec string   `json:"VideoCodec"`
	Type       string   `json:"Type"`
}

type TranscodingProfile struct {
	Container            string `json:"Container"`
	Type                 string `json:"Type"`
	VideoCodec           string `json:"VideoCodec"`
	AudioCodec           string `json:"AudioCodec"`
	MaxAudioChannels     int    `json:"MaxAudioChannels,omitempty"`
	Protocol             string `json:"Protocol"`
	EstimateContentLength bool  `json:"EstimateContentLength,omitempty"`
	CopyTimestamps       bool   `json:"CopyTimestamps,omitempty"`
}

type CodecProfile struct {
	Type          string   `json:"Type"`
	Codec         string   `json:"Codec,omitempty"`
	Container     string   `json:"Container,omitempty"`
	Conditions    []ProfileCondition `json:"Conditions,omitempty"`
	ApplyConditions []ProfileCondition `json:"ApplyConditions,omitempty"`
}

type ProfileCondition struct {
	Condition string `json:"Condition"`
	Property  string `json:"Property"`
	Value     string `json:"Value"`
	IsRequired bool  `json:"IsRequired"`
}

type ContainerProfile struct {
	Type      string `json:"Type"`
	Container string `json:"Container,omitempty"`
	Conditions []ProfileCondition `json:"Conditions,omitempty"`
}

type SubtitleProfile struct {
	Format        string `json:"Format"`
	Method        string `json:"Method"`
	Didlize       bool   `json:"Didlize,omitempty"`
	Language      string `json:"Language,omitempty"`
	Container     string `json:"Container,omitempty"`
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
	if v, ok := params["startIndex"]; ok && v != "" { q += "StartIndex=" + v + "&" }
	if v, ok := params["limit"]; ok && v != "" { q += "Limit=" + v + "&" }
	if v, ok := params["sortBy"]; ok && v != "" { q += "SortBy=" + v + "&" }
	if v, ok := params["sortOrder"]; ok && v != "" { q += "SortOrder=" + v + "&" }
	if v, ok := params["includeItemTypes"]; ok && v != "" { q += "IncludeItemTypes=" + v + "&" }
	if v, ok := params["recursive"]; ok && v != "" { q += "Recursive=" + v + "&" }
	if v, ok := params["searchTerm"]; ok && v != "" { q += "SearchTerm=" + v + "&" }
	if v, ok := params["genres"]; ok && v != "" { q += "Genres=" + v + "&" }
	if v, ok := params["years"]; ok && v != "" { q += "Years=" + v + "&" }
	if v, ok := params["parentId"]; ok && v != "" { q += "ParentId=" + v + "&" }
	if v, ok := params["fields"]; ok && v != "" { q += "Fields=" + v + "&" }
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

// GetItemDetail fetches a single item via GET /Users/{UserId}/Items/{Id}
// Requests People, ProviderIds, MediaStreams, and other detail fields
func (c *Client) GetItemDetail(serverURL, token, userID, itemID string) (*MediaItem, error) {
	serverURL = strings.TrimRight(serverURL, "/")
	url := fmt.Sprintf("%s/Users/%s/Items/%s?Fields=MediaStreams,People,ProviderIds,Overview,Genres,ChildCount,Status", serverURL, userID, itemID)

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

// GetPlaybackInfo sends POST /Items/{Id}/PlaybackInfo with device profile
func (c *Client) GetPlaybackInfo(serverURL, token, userID, itemID string) (*MediaStreamInfo, error) {
	serverURL = strings.TrimRight(serverURL, "/")
	url := fmt.Sprintf("%s/Items/%s/PlaybackInfo", serverURL, itemID)

	reqBody := PlaybackInfoRequest{
		DeviceId: "Aether-Dev-001",
		MaxStreamingBitrate: 80000000,
		DeviceProfile: &DeviceProfile{
			Name: "Aether Player",
			Id:   "aether-player",
			Type: "DigitalMediaPlayer",
			DirectPlayProfiles: []DirectPlayProfile{
				{Container: "mp4,mkv,mov,m4v", VideoCodec: "h264,h265,hevc,vp8,vp9,av1", AudioCodec: "aac,mp3,flac,opus,vorbis,eac3,ac3", Type: "Video"},
				{Container: "mp3,flac,ogg,m4a,wav", AudioCodec: "mp3,flac,aac,opus,vorbis", Type: "Audio"},
			},
			TranscodingProfiles: []TranscodingProfile{
				{Container: "ts", Type: "Video", VideoCodec: "h264", AudioCodec: "aac", MaxAudioChannels: 6, Protocol: "hls"},
				{Container: "mp3", Type: "Audio", AudioCodec: "mp3", MaxAudioChannels: 2, Protocol: "http"},
			},
			CodecProfiles: []CodecProfile{
				{
					Type: "VideoAudio",
					Conditions: []ProfileCondition{
						{Condition: "EqualsAny", Property: "AudioProfile", Value: "HE-AAC,LC,AAC,MP3", IsRequired: false},
					},
				},
				{
					Type: "Video",
					Codec: "h264",
					Conditions: []ProfileCondition{
						{Condition: "EqualsAny", Property: "VideoProfile", Value: "High|Main|Baseline|Constrained Baseline", IsRequired: false},
						{Condition: "LessThanEqual", Property: "VideoLevel", Value: "51", IsRequired: false},
					},
				},
			},
			SubtitleProfiles: []SubtitleProfile{
				{Format: "srt", Method: "External"},
				{Format: "ass", Method: "External"},
				{Format: "subrip", Method: "External"},
			},
		},
	}

	jsonBody, err := json.Marshal(reqBody)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequest("POST", url, strings.NewReader(string(jsonBody)))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
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

// GetVideoStreamURL constructs the direct play / transcode stream URL
func (c *Client) GetVideoStreamURL(serverURL, token, itemID, container string) string {
	serverURL = strings.TrimRight(serverURL, "/")
	return fmt.Sprintf("%s/Videos/%s/stream?Static=true&api_key=%s&Container=%s",
		serverURL, itemID, token, container)
}

// ReportPlaybackStarted notifies Emby that playback has started
// POST /Sessions/Playing
func (c *Client) ReportPlaybackStarted(serverURL, token, itemID, mediaSourceID, playSessionID string) error {
	serverURL = strings.TrimRight(serverURL, "/")
	url := fmt.Sprintf("%s/Sessions/Playing", serverURL)

	body := map[string]interface{}{
		"ItemId":         itemID,
		"MediaSourceId":  mediaSourceID,
		"PlaySessionId":  playSessionID,
		"CanSeek":        true,
		"IsPaused":       false,
	}
	jsonBody, _ := json.Marshal(body)

	req, err := http.NewRequest("POST", url, strings.NewReader(string(jsonBody)))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Emby-Token", token)
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Dev-001", Version="0.0.1"`)

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to report playback started: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusNoContent {
		return fmt.Errorf("server returned status: %d", resp.StatusCode)
	}
	return nil
}

// ReportPlaybackProgress notifies Emby of playback progress
// POST /Sessions/Playing/Progress
func (c *Client) ReportPlaybackProgress(serverURL, token, itemID, mediaSourceID, playSessionID string, positionTicks int64, isPaused bool) error {
	serverURL = strings.TrimRight(serverURL, "/")
	url := fmt.Sprintf("%s/Sessions/Playing/Progress", serverURL)

	body := map[string]interface{}{
		"ItemId":              itemID,
		"MediaSourceId":       mediaSourceID,
		"PlaySessionId":       playSessionID,
		"PositionTicks":       positionTicks,
		"IsPaused":            isPaused,
		"CanSeek":             true,
	}
	jsonBody, _ := json.Marshal(body)

	req, err := http.NewRequest("POST", url, strings.NewReader(string(jsonBody)))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Emby-Token", token)
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Dev-001", Version="0.0.1"`)

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to report playback progress: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusNoContent {
		return fmt.Errorf("server returned status: %d", resp.StatusCode)
	}
	return nil
}

// ReportPlaybackStopped notifies Emby that playback has stopped
// POST /Sessions/Playing/Stopped
func (c *Client) ReportPlaybackStopped(serverURL, token, itemID, mediaSourceID, playSessionID string, positionTicks int64) error {
	serverURL = strings.TrimRight(serverURL, "/")
	url := fmt.Sprintf("%s/Sessions/Playing/Stopped", serverURL)

	body := map[string]interface{}{
		"ItemId":              itemID,
		"MediaSourceId":       mediaSourceID,
		"PlaySessionId":       playSessionID,
		"PositionTicks":       positionTicks,
	}
	jsonBody, _ := json.Marshal(body)

	req, err := http.NewRequest("POST", url, strings.NewReader(string(jsonBody)))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Emby-Token", token)
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Dev-001", Version="0.0.1"`)

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return fmt.Errorf("failed to report playback stopped: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusNoContent {
		return fmt.Errorf("server returned status: %d", resp.StatusCode)
	}
	return nil
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

func (c *Client) GetSeasons(serverURL, token, userID, seriesID string) (*ItemListResponse, error) {
	serverURL = strings.TrimRight(serverURL, "/")
	url := fmt.Sprintf("%s/Shows/%s/Seasons?UserId=%s&Fields=UserData,ChildCount", serverURL, seriesID, userID)

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
	url := fmt.Sprintf("%s/Shows/%s/Episodes?SeasonId=%s&Fields=UserData,MediaStreams,People,ProviderIds&Limit=%d", serverURL, seriesID, seasonID, limit)

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
