package security

import (
	"errors"
	"net"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestIsBlockedIP(t *testing.T) {
	blocked := []string{
		"127.0.0.1", // 环回
		"127.255.255.254",
		"::1",             // IPv6 环回
		"169.254.169.254", // 云元数据
		"169.254.1.1",     // 链路本地
		"fe80::1",         // IPv6 链路本地
		"0.0.0.0",         // 未指定
		"::",
		"224.0.0.1", // 组播
		"ff02::1",   // IPv6 组播
	}
	for _, s := range blocked {
		ip := net.ParseIP(s)
		if ip == nil {
			t.Fatalf("bad test case: %s", s)
		}
		if !IsBlockedIP(ip) {
			t.Errorf("IsBlockedIP(%s) = false, want true", s)
		}
	}

	// 私网地址默认放行：家用 Emby 服务器几乎都部署在局域网内
	allowed := []string{
		"192.168.1.10",
		"10.0.0.5",
		"172.16.0.1",
		"8.8.8.8",
		"2606:4700:4700::1111",
	}
	for _, s := range allowed {
		ip := net.ParseIP(s)
		if ip == nil {
			t.Fatalf("bad test case: %s", s)
		}
		if IsBlockedIP(ip) {
			t.Errorf("IsBlockedIP(%s) = true, want false", s)
		}
	}

	if !IsBlockedIP(nil) {
		t.Error("IsBlockedIP(nil) = false, want true")
	}
}

func TestIsBlockedIPStrictMode(t *testing.T) {
	t.Setenv("AETHER_BLOCK_PRIVATE_NETWORK", "true")

	private := []string{"192.168.1.10", "10.0.0.5", "172.16.0.1", "fd00::1"}
	for _, s := range private {
		if !IsBlockedIP(net.ParseIP(s)) {
			t.Errorf("strict mode: IsBlockedIP(%s) = false, want true", s)
		}
	}

	// 严格模式不应影响公网地址
	if IsBlockedIP(net.ParseIP("8.8.8.8")) {
		t.Error("strict mode: IsBlockedIP(8.8.8.8) = true, want false")
	}
}

func TestValidateServerURL(t *testing.T) {
	valid := []string{
		"http://192.168.1.10:8096",
		"https://emby.example.com",
		"http://localhost:8096", // 主机名留待 DialContext 解析后校验
		"  https://emby.example.com  ",
	}
	for _, s := range valid {
		if err := ValidateServerURL(s); err != nil {
			t.Errorf("ValidateServerURL(%q) = %v, want nil", s, err)
		}
	}

	invalid := []struct {
		url  string
		want error
	}{
		{"file:///etc/passwd", ErrInvalidServerURL},
		{"ftp://emby.example.com", ErrInvalidServerURL},
		{"gopher://127.0.0.1:6379", ErrInvalidServerURL},
		{"emby.example.com", ErrInvalidServerURL}, // 缺 scheme
		{"", ErrInvalidServerURL},
		{"http://", ErrInvalidServerURL},
		{"http://127.0.0.1:8096", ErrBlockedTarget},
		{"http://[::1]:8096", ErrBlockedTarget},
		{"http://169.254.169.254/latest/meta-data/", ErrBlockedTarget},
		{"http://0.0.0.0:8096", ErrBlockedTarget},
		{"http://2852039166/", ErrBlockedTarget}, // 十进制形式的 169.254.169.254
		{"http://0xA9FEA9FE/", ErrBlockedTarget}, // 十六进制形式的 169.254.169.254
		{"http://0Xa9fea9fe/", ErrBlockedTarget}, // 大写前缀同样应识别
		{"http://2130706433/", ErrBlockedTarget}, // 十进制形式的 127.0.0.1
	}
	for _, tc := range invalid {
		err := ValidateServerURL(tc.url)
		if err == nil {
			t.Errorf("ValidateServerURL(%q) = nil, want %v", tc.url, tc.want)
			continue
		}
		if !errors.Is(err, tc.want) {
			t.Errorf("ValidateServerURL(%q) = %v, want errors.Is(%v)", tc.url, err, tc.want)
		}
	}
}

// TestValidateServerURLDecimalIP 单独覆盖字符串前缀匹配的绕过手法：
// 旧实现用 strings.HasPrefix(host, "169.254.") 判断，
// 十进制 IP 写法不匹配该前缀因而被放行。
func TestValidateServerURLDecimalIP(t *testing.T) {
	err := ValidateServerURL("http://2852039166/")
	if !errors.Is(err, ErrBlockedTarget) {
		t.Errorf("decimal IP bypass: got %v, want ErrBlockedTarget", err)
	}
}

func TestSanitizeDeviceID(t *testing.T) {
	tests := []struct {
		in   string
		want string
	}{
		{"", defaultDeviceID},
		{"   ", defaultDeviceID},
		{"abc-123_XYZ.9", "abc-123_XYZ.9"},
		// 引号可突破 X-Emby-Authorization 的字段边界
		{`a", Version="9.9.9`, "aVersion9.9.9"},
		{"dev\r\nX-Injected: 1", "devX-Injected1"},
		{"设备abc", "abc"}, // 非 ASCII 字符被剔除
		{"!!!", defaultDeviceID},
	}
	for _, tc := range tests {
		got := SanitizeDeviceID(tc.in)
		if got != tc.want {
			t.Errorf("SanitizeDeviceID(%q) = %q, want %q", tc.in, got, tc.want)
		}
		if strings.ContainsAny(got, "\"\r\n") {
			t.Errorf("SanitizeDeviceID(%q) = %q still contains quote or newline", tc.in, got)
		}
	}

	// 超长输入应被截断
	long := strings.Repeat("a", 500)
	if got := SanitizeDeviceID(long); len(got) != 64 {
		t.Errorf("SanitizeDeviceID(long) len = %d, want 64", len(got))
	}
}

func TestNewSafeClient(t *testing.T) {
	c := NewSafeClient()
	if c == nil || c.Transport == nil {
		t.Fatal("NewSafeClient returned client without transport")
	}
	// 整体 Timeout 必须为零：它会连 body 读取一起计时，
	// 导致流式响应与大图片在传输途中被腰斩
	if c.Timeout != 0 {
		t.Errorf("NewSafeClient().Timeout = %v, want 0", c.Timeout)
	}
}

// TestSafeClientBlocksLoopbackDial 验证连接层的强制拦截确实生效。
//
// 这是整个安全设计的支点：handler 层有 20 余处从 X-Emby-Server 头取地址，
// 并不逐个校验，全部依赖安全 Transport 在 DialContext 中拦截解析后的 IP。
// httptest 服务器监听于 127.0.0.1，正好落在禁止范围内，
// 且测试不依赖外网连通性。
func TestSafeClientBlocksLoopbackDial(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))
	defer srv.Close()

	resp, err := NewSafeClient().Get(srv.URL)
	if err == nil {
		resp.Body.Close()
		t.Fatalf("safe client connected to loopback address %s, want refusal", srv.URL)
	}
	// 错误经 url.Error 包装，errors.Is 应能穿透识别
	if !errors.Is(err, ErrBlockedTarget) {
		t.Errorf("error = %v, want wrapped ErrBlockedTarget", err)
	}
}
