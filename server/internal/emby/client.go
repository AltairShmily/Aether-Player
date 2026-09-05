package emby

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"

	"aether-server/internal/security"
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
	User   User   `json:"User"`
	Token  string `json:"AccessToken"`
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
	ID              string   `json:"Id"`
	Name            string   `json:"Name"`
	Type            string   `json:"Type"`
	Overview        string   `json:"Overview,omitempty"`
	CommunityRating float64  `json:"CommunityRating,omitempty"`
	OfficialRating  string   `json:"OfficialRating,omitempty"`
	Genres          []string `json:"Genres,omitempty"`
	ProductionYear  int      `json:"ProductionYear,omitempty"`
	RunTimeTicks    int64    `json:"RunTimeTicks,omitempty"`
	DateCreated     string   `json:"DateCreated,omitempty"`
	ImageTags       struct {
		Primary  string `json:"Primary,omitempty"`
		Backdrop string `json:"Backdrop,omitempty"`
	} `json:"ImageTags,omitempty"`
	BackdropImageTags []string  `json:"BackdropImageTags,omitempty"`
	SeriesName        string    `json:"SeriesName,omitempty"`
	IndexNumber       int       `json:"IndexNumber,omitempty"`
	ParentIndexNumber int       `json:"ParentIndexNumber,omitempty"`
	SeriesID          string    `json:"SeriesId,omitempty"`
	SeasonId          string    `json:"SeasonId,omitempty"`
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
	ID              string  `json:"Id"`
	Name            string  `json:"Name"`
	Type            string  `json:"Type"`
	Overview        string  `json:"Overview,omitempty"`
	CommunityRating float64 `json:"CommunityRating,omitempty"`
	ProductionYear  int     `json:"ProductionYear,omitempty"`
	PrimaryImageTag string  `json:"PrimaryImageTag,omitempty"`
}

type MediaStreamInfo struct {
	MediaSources  []MediaSource `json:"MediaSources"`
	PlaySessionId string        `json:"PlaySessionId,omitempty"`
}

type MediaSource struct {
	ID        string `json:"Id"`
	Name      string `json:"Name"`
	Path      string `json:"Path,omitempty"`
	Container string `json:"Container,omitempty"`
	Size      int64  `json:"Size,omitempty"`
	Bitrate   int    `json:"Bitrate,omitempty"`
	// RunTimeTicks 是元数据给出的权威时长（单位 100 纳秒）。
	// 转码走 HLS 时播放器从流中读到的时长并不可靠，客户端需要用它兜底。
	RunTimeTicks         int64         `json:"RunTimeTicks,omitempty"`
	MediaStreams         []MediaStream `json:"MediaStreams,omitempty"`
	DirectStreamUrl      string        `json:"DirectStreamUrl,omitempty"`
	TranscodingUrl       string        `json:"TranscodingUrl,omitempty"`
	IsRemote             bool          `json:"IsRemote"`
	SupportsDirectPlay   bool          `json:"SupportsDirectPlay"`
	SupportsDirectStream bool          `json:"SupportsDirectStream"`
	SupportsTranscoding  bool          `json:"SupportsTranscoding"`
}

type MediaStream struct {
	Type          string `json:"Type"`
	Codec         string `json:"Codec,omitempty"`
	Language      string `json:"Language,omitempty"`
	DisplayTitle  string `json:"DisplayTitle,omitempty"`
	Width         int    `json:"Width,omitempty"`
	Height        int    `json:"Height,omitempty"`
	BitRate       int    `json:"BitRate,omitempty"`
	ChannelLayout string `json:"ChannelLayout,omitempty"`
	Index         int    `json:"Index"`
	// 外挂字幕相关。文本字幕无法内嵌进转码流，Emby 会以 External 方式
	// 通过 DeliveryUrl 提供字幕文件地址，需由客户端自行拉取加载。
	// 客户端模型早已定义这些字段，此前因 Go 结构体缺失而在序列化时被丢弃。
	DeliveryUrl          string `json:"DeliveryUrl,omitempty"`
	DeliveryMethod       string `json:"DeliveryMethod,omitempty"`
	IsExternal           bool   `json:"IsExternal"`
	IsTextSubtitleStream bool   `json:"IsTextSubtitleStream"`
}

// PlaybackInfoRequest is sent to Emby POST /Items/{Id}/PlaybackInfo
type PlaybackInfoRequest struct {
	MediaSourceId       string         `json:"MediaSourceId,omitempty"`
	DeviceProfile       *DeviceProfile `json:"DeviceProfile,omitempty"`
	DeviceId            string         `json:"DeviceId,omitempty"`
	MaxStreamingBitrate int            `json:"MaxStreamingBitrate,omitempty"`
}

type DeviceProfile struct {
	Name                    string               `json:"Name"`
	Id                      string               `json:"Id"`
	Type                    string               `json:"Type"`
	DirectPlayProfiles      []DirectPlayProfile  `json:"DirectPlayProfiles,omitempty"`
	DirectStreamingProfiles []DirectPlayProfile  `json:"DirectStreamingProfiles,omitempty"`
	TranscodingProfiles     []TranscodingProfile `json:"TranscodingProfiles,omitempty"`
	CodecProfiles           []CodecProfile       `json:"CodecProfiles,omitempty"`
	ContainerProfiles       []ContainerProfile   `json:"ContainerProfiles,omitempty"`
	SubtitleProfiles        []SubtitleProfile    `json:"SubtitleProfiles,omitempty"`
}

type DirectPlayProfile struct {
	Container  string `json:"Container"`
	AudioCodec string `json:"AudioCodec"`
	VideoCodec string `json:"VideoCodec"`
	Type       string `json:"Type"`
}

type TranscodingProfile struct {
	Container             string `json:"Container"`
	Type                  string `json:"Type"`
	VideoCodec            string `json:"VideoCodec"`
	AudioCodec            string `json:"AudioCodec"`
	MaxAudioChannels      int    `json:"MaxAudioChannels,omitempty"`
	Protocol              string `json:"Protocol"`
	EstimateContentLength bool   `json:"EstimateContentLength,omitempty"`
	CopyTimestamps        bool   `json:"CopyTimestamps,omitempty"`
}

type CodecProfile struct {
	Type            string             `json:"Type"`
	Codec           string             `json:"Codec,omitempty"`
	Container       string             `json:"Container,omitempty"`
	Conditions      []ProfileCondition `json:"Conditions,omitempty"`
	ApplyConditions []ProfileCondition `json:"ApplyConditions,omitempty"`
}

type ProfileCondition struct {
	Condition  string `json:"Condition"`
	Property   string `json:"Property"`
	Value      string `json:"Value"`
	IsRequired bool   `json:"IsRequired"`
}

type ContainerProfile struct {
	Type       string             `json:"Type"`
	Container  string             `json:"Container,omitempty"`
	Conditions []ProfileCondition `json:"Conditions,omitempty"`
}

type SubtitleProfile struct {
	Format    string `json:"Format"`
	Method    string `json:"Method"`
	Didlize   bool   `json:"Didlize,omitempty"`
	Language  string `json:"Language,omitempty"`
	Container string `json:"Container,omitempty"`
}

func NewClient() *Client {
	return &Client{
		// 安全 Transport 在建连前校验解析后的 IP，覆盖所有 handler 入口。
		// 不设整体 Timeout：它会连 body 读取一起计时，
		// 使 GetItemImage 等返回流式 body 的大响应在传输途中被截断。
		HTTPClient: security.NewSafeClient(),
	}
}

func (c *Client) TestConnection(serverURL string) (*SystemInfo, error) {
	serverURL = strings.TrimRight(serverURL, "/")
	url := fmt.Sprintf("%s/System/Info/Public", serverURL)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Client", Version="0.0.1"`)

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

	authBody := map[string]string{"Username": username, "Pw": password}
	jsonBody, err := json.Marshal(authBody)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal auth body: %w", err)
	}

	req, err := http.NewRequest("POST", url, strings.NewReader(string(jsonBody)))
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Client", Version="0.0.1"`)

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
	endpoint := fmt.Sprintf("%s/Users/%s/Items", serverURL, url.PathEscape(params["userId"]))

	// 用 url.Values 构造查询串：手工拼接不做转义，
	// 搜索词含 &、空格、#、中文时会破坏查询串或注入额外的上游参数。
	// Encode() 会按键排序，故遍历 map 的顺序不影响结果
	q := url.Values{}
	for param, key := range map[string]string{
		"startIndex":       "StartIndex",
		"limit":            "Limit",
		"sortBy":           "SortBy",
		"sortOrder":        "SortOrder",
		"includeItemTypes": "IncludeItemTypes",
		"recursive":        "Recursive",
		"searchTerm":       "SearchTerm",
		"genres":           "Genres",
		"years":            "Years",
		"parentId":         "ParentId",
		"fields":           "Fields",
	} {
		if v, ok := params[param]; ok && v != "" {
			q.Set(key, v)
		}
	}

	fullURL := endpoint
	if encoded := q.Encode(); encoded != "" {
		fullURL += "?" + encoded
	}

	req, err := http.NewRequest("GET", fullURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("X-Emby-Token", token)
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Client", Version="0.0.1"`)

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
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Client", Version="0.0.1"`)

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
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Client", Version="0.0.1"`)

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

	// 搜索词来自用户输入，必须编码：直接拼接时 &、空格、# 等字符
	// 会破坏查询串或注入额外的上游参数
	q := url.Values{}
	q.Set("UserId", userID)
	q.Set("SearchTerm", searchTerm)
	q.Set("Limit", strconv.Itoa(limit))
	endpoint := fmt.Sprintf("%s/Search/Hints?%s", serverURL, q.Encode())

	req, err := http.NewRequest("GET", endpoint, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("X-Emby-Token", token)
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Client", Version="0.0.1"`)

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
		DeviceId:            "Aether-Client",
		MaxStreamingBitrate: 80000000,
		DeviceProfile: &DeviceProfile{
			Name: "Aether Player",
			Id:   "aether-player",
			Type: "DigitalMediaPlayer",
			// 必须显式声明容器与编码：全空字符串会让 Emby 无法判定
			// 兼容性而不返回 DirectStreamUrl，客户端只能一律走转码，
			// 进而导致时长不准与字幕缺失。libmpv 解码能力覆盖下列全部格式。
			DirectPlayProfiles: []DirectPlayProfile{
				{
					Container:  "mkv,mp4,m4v,avi,mov,wmv,flv,webm,ts,m2ts,mpg,mpeg,3gp,ogv",
					VideoCodec: "h264,hevc,h265,mpeg4,mpeg2video,vp8,vp9,av1,vc1,msmpeg4,h263",
					AudioCodec: "aac,mp3,ac3,eac3,dts,dca,truehd,flac,alac,opus,vorbis,pcm_s16le,pcm_s24le,wavpack,wma,wmav2",
					Type:       "Video",
				},
				{
					Container:  "mp3,flac,aac,m4a,wav,ogg,opus,wma,alac,aiff,ape",
					AudioCodec: "mp3,flac,aac,alac,pcm,vorbis,opus,wma,ape",
					Type:       "Audio",
				},
			},
			DirectStreamingProfiles: []DirectPlayProfile{
				{Container: "ts,mpegts", VideoCodec: "h264,hevc,mpeg2video", AudioCodec: "aac,mp3,ac3,dts", Type: "Video"},
			},
			TranscodingProfiles: []TranscodingProfile{
				// 用渐进式 mp4 而非 hls：HLS 分片流的总时长对播放器不可靠，
				// 表现为进度条与时长显示错误
				{Container: "mp4", Type: "Video", VideoCodec: "h264", AudioCodec: "aac,mp3", MaxAudioChannels: 6, Protocol: "http", CopyTimestamps: true},
				{Container: "mp3", Type: "Audio", AudioCodec: "mp3", MaxAudioChannels: 2, Protocol: "http"},
			},
			// 不再设置 CodecProfiles 限制。
			// 此前的 AudioProfile(仅 AAC/MP3)、VideoLevel(≤51)、VideoProfile
			// 三条限制与上面声明的直连能力自相矛盾，会把 AC3/DTS/TrueHD 音轨、
			// 高规格 4K、High10 等内容全部压到转码路径上 —— 而 libmpv
			// 对这些格式均原生支持，限制只会带来时长不准与字幕缺失。
			CodecProfiles: []CodecProfile{},
			SubtitleProfiles: []SubtitleProfile{
				{Format: "srt", Method: "External"},
				{Format: "ass", Method: "External"},
				{Format: "subrip", Method: "External"},
				{Format: "vtt", Method: "External"},
				{Format: "sub", Method: "External"},
				{Format: "smi", Method: "External"},
				{Format: "srt", Method: "Embed"},
				{Format: "ass", Method: "Embed"},
				{Format: "ssa", Method: "Embed"},
				{Format: "subrip", Method: "Embed"},
				{Format: "pgssub", Method: "Embed"},
				{Format: "dvdsub", Method: "Embed"},
				{Format: "dvbsub", Method: "Embed"},
				{Format: "pgs", Method: "Embed"},
				{Format: "vtt", Method: "Embed"},
				{Format: "sub", Method: "Embed"},
				{Format: "smi", Method: "Embed"},
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
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Client", Version="0.0.1"`)

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

// GetTranscodeStreamURL constructs a transcode stream URL with h264/aac codecs
func (c *Client) GetTranscodeStreamURL(serverURL, token, itemID string, maxBitrate, maxHeight int) string {
	serverURL = strings.TrimRight(serverURL, "/")
	url := fmt.Sprintf("%s/Videos/%s/stream?api_key=%s&VideoCodec=h264&AudioCodec=aac&MaxStreamingBitrate=%d",
		serverURL, itemID, token, maxBitrate)
	if maxHeight > 0 {
		url += fmt.Sprintf("&MaxHeight=%d", maxHeight)
	}
	return url
}

// ReportPlaybackStarted notifies Emby that playback has started
// POST /Sessions/Playing
func (c *Client) ReportPlaybackStarted(serverURL, token, itemID, mediaSourceID, playSessionID string) error {
	serverURL = strings.TrimRight(serverURL, "/")
	url := fmt.Sprintf("%s/Sessions/Playing", serverURL)

	body := map[string]interface{}{
		"ItemId":        itemID,
		"MediaSourceId": mediaSourceID,
		"PlaySessionId": playSessionID,
		"CanSeek":       true,
		"IsPaused":      false,
	}
	jsonBody, _ := json.Marshal(body)

	req, err := http.NewRequest("POST", url, strings.NewReader(string(jsonBody)))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Emby-Token", token)
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Client", Version="0.0.1"`)

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
		"ItemId":        itemID,
		"MediaSourceId": mediaSourceID,
		"PlaySessionId": playSessionID,
		"PositionTicks": positionTicks,
		"IsPaused":      isPaused,
		"CanSeek":       true,
	}
	jsonBody, _ := json.Marshal(body)

	req, err := http.NewRequest("POST", url, strings.NewReader(string(jsonBody)))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Emby-Token", token)
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Client", Version="0.0.1"`)

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
		"ItemId":        itemID,
		"MediaSourceId": mediaSourceID,
		"PlaySessionId": playSessionID,
		"PositionTicks": positionTicks,
	}
	jsonBody, _ := json.Marshal(body)

	req, err := http.NewRequest("POST", url, strings.NewReader(string(jsonBody)))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Emby-Token", token)
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Client", Version="0.0.1"`)

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
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Client", Version="0.0.1"`)

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
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Client", Version="0.0.1"`)

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
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Client", Version="0.0.1"`)

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
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Client", Version="0.0.1"`)

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

// ══════════════════════════════════════════════════
//  Favorites
// ══════════════════════════════════════════════════

// ToggleFavorite toggles the favorite status of an item.
func (c *Client) ToggleFavorite(serverURL, token, userID, itemID string, isFavorite bool) (bool, error) {
	serverURL = strings.TrimRight(serverURL, "/")
	var embyURL string
	if isFavorite {
		embyURL = fmt.Sprintf("%s/Users/%s/Items/%s/UnmarkFavorite", serverURL, userID, itemID)
	} else {
		embyURL = fmt.Sprintf("%s/Users/%s/Items/%s/MarkFavorite", serverURL, userID, itemID)
	}

	req, err := http.NewRequest("POST", embyURL, nil)
	if err != nil {
		return false, fmt.Errorf("failed to create request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("X-Emby-Token", token)
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Client", Version="0.0.1"`)

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return false, fmt.Errorf("failed to toggle favorite: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusNoContent {
		return false, fmt.Errorf("server returned status: %d", resp.StatusCode)
	}
	return !isFavorite, nil
}

// GetFavoriteItems returns all favorited items for a user.
func (c *Client) GetFavoriteItems(serverURL, token, userID string, limit int) (*ItemListResponse, error) {
	serverURL = strings.TrimRight(serverURL, "/")
	embyURL := fmt.Sprintf("%s/Users/%s/Items?Filters=IsFavorite&Limit=%d&Recursive=true&Fields=UserData", serverURL, userID, limit)

	req, err := http.NewRequest("GET", embyURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}
	req.Header.Set("X-Emby-Token", token)
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Client", Version="0.0.1"`)

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to get favorites: %w", err)
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

// ══════════════════════════════════════════════════
//  Audio Stream URL
// ══════════════════════════════════════════════════

// GetAudioStreamURL returns the direct play / transcode audio URL.
func (c *Client) GetAudioStreamURL(serverURL, token, itemID string) string {
	serverURL = strings.TrimRight(serverURL, "/")
	return fmt.Sprintf("%s/Audio/%s/stream?Static=true&api_key=%s",
		serverURL, itemID, token)
}

// ══════════════════════════════════════════════════
//  User Profile
// ══════════════════════════════════════════════════

// UserProfile holds detailed user information from Emby.
type UserProfile struct {
	ID               string      `json:"Id"`
	Name             string      `json:"Name"`
	ServerID         string      `json:"ServerId,omitempty"`
	HasPassword      bool        `json:"HasPassword,omitempty"`
	PrimaryImageTag  string      `json:"PrimaryImageTag,omitempty"`
	LastActivityDate string      `json:"LastActivityDate,omitempty"`
	LastLoginDate    string      `json:"LastLoginDate,omitempty"`
	IsAdministrator  bool        `json:"IsAdministrator,omitempty"`
	IsDisabled       bool        `json:"IsDisabled,omitempty"`
	Policy           *UserPolicy `json:"Policy,omitempty"`
}

// UserPolicy holds user access policy from Emby.
type UserPolicy struct {
	IsAdministrator   bool `json:"IsAdministrator"`
	IsDisabled        bool `json:"IsDisabled"`
	MaxParentalRating int  `json:"MaxParentalRating,omitempty"`
}

// GetUserProfile returns detailed user profile information.
func (c *Client) GetUserProfile(serverURL, token, userID string) (*UserProfile, error) {
	serverURL = strings.TrimRight(serverURL, "/")
	embyURL := fmt.Sprintf("%s/Users/%s", serverURL, userID)

	req, err := http.NewRequest("GET", embyURL, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}
	req.Header.Set("X-Emby-Token", token)
	req.Header.Set("X-Emby-Authorization", `MediaBrowser Client="Aether", Device="Linux", DeviceId="Aether-Client", Version="0.0.1"`)

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to get user profile: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("server returned status: %d", resp.StatusCode)
	}
	var profile UserProfile
	if err := json.NewDecoder(resp.Body).Decode(&profile); err != nil {
		return nil, fmt.Errorf("failed to decode response: %w", err)
	}
	return &profile, nil
}
