// Package security 集中收敛代理层的地址校验与输入净化。
//
// 关键设计：校验发生在**连接层**而非各个 handler 入口。
// server/internal/handler 下有 20 余处从 X-Emby-Server 头取地址的代码，
// 逐个加校验既冗长又会被后续新增的 handler 遗漏；而所有上游请求最终都要
// 经过同一个 http.Transport 建连，因此在 DialContext 中校验解析后的 IP
// 可以一次性覆盖全部入口，并同时防住 DNS rebinding 与重定向绕过。
package security

import (
	"context"
	"errors"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"
)

// ErrBlockedTarget 表示目标地址属于禁止代理的范围。
var ErrBlockedTarget = errors.New("blocked target address")

// ErrInvalidServerURL 表示服务器地址本身不合法（scheme 或 host 缺失）。
var ErrInvalidServerURL = errors.New("invalid server URL")

// defaultDeviceID 在调用方未提供或提供值不合法时使用。
const defaultDeviceID = "Aether-Client"

// IsBlockedIP 判断 IP 是否禁止被代理访问。
//
// 环回、链路本地（含云元数据 169.254.169.254）、未指定与组播地址一律拦截。
// 私网地址默认放行：家用 Emby 服务器几乎都部署在局域网内，默认拦截会让
// 产品对主要用户群完全不可用。需要严格隔离时设置
// AETHER_BLOCK_PRIVATE_NETWORK=true。
func IsBlockedIP(ip net.IP) bool {
	if ip == nil {
		return true
	}
	if ip.IsLoopback() || ip.IsLinkLocalUnicast() || ip.IsLinkLocalMulticast() ||
		ip.IsUnspecified() || ip.IsMulticast() || ip.IsInterfaceLocalMulticast() {
		return true
	}
	if os.Getenv("AETHER_BLOCK_PRIVATE_NETWORK") == "true" && ip.IsPrivate() {
		return true
	}
	return false
}

// parseIPLiteral 解析各种 IP 字面量写法。
//
// net.ParseIP 只接受点分十进制与标准 IPv6 形式，而 curl、浏览器等客户端
// 还接受 32 位整数与十六进制写法（如 2852039166 == 169.254.169.254），
// 这类写法可绕过基于字符串前缀匹配的黑名单。
func parseIPLiteral(host string) net.IP {
	if ip := net.ParseIP(host); ip != nil {
		return ip
	}

	var (
		n   uint64
		err error
	)
	switch {
	case strings.HasPrefix(host, "0x"), strings.HasPrefix(host, "0X"):
		n, err = strconv.ParseUint(host[2:], 16, 32)
	default:
		n, err = strconv.ParseUint(host, 10, 32)
	}
	if err != nil {
		return nil
	}
	return net.IPv4(byte(n>>24), byte(n>>16), byte(n>>8), byte(n)).To4()
}

// ValidateServerURL 做早期的语法校验，以便返回明确的错误而不是等到建连才失败。
// 真正的强制点在 NewSafeTransport 的 DialContext —— 那里校验的是解析后的 IP，
// 因此十进制 IP、IPv6、主机名等各种写法都无法绕过。
func ValidateServerURL(raw string) error {
	u, err := url.Parse(strings.TrimSpace(raw))
	if err != nil {
		return fmt.Errorf("%w: %v", ErrInvalidServerURL, err)
	}
	if u.Scheme != "http" && u.Scheme != "https" {
		return fmt.Errorf("%w: scheme must be http or https", ErrInvalidServerURL)
	}
	host := u.Hostname()
	if host == "" {
		return fmt.Errorf("%w: empty host", ErrInvalidServerURL)
	}
	// 字面量 IP 可立即判定；主机名留给 DialContext 解析后校验
	if ip := parseIPLiteral(host); ip != nil && IsBlockedIP(ip) {
		return fmt.Errorf("%w: %s", ErrBlockedTarget, host)
	}
	return nil
}

// NewSafeTransport 返回在建立连接前校验目标 IP 的 Transport。
//
// 未设置整体 Client.Timeout —— 它会连 body 读取一起计时，
// 导致图片与流式响应在传输途中被腰斩；超时改由连接层与响应头阶段约束。
func NewSafeTransport() *http.Transport {
	dialer := &net.Dialer{
		Timeout:   15 * time.Second,
		KeepAlive: 30 * time.Second,
	}

	return &http.Transport{
		DialContext: func(ctx context.Context, network, addr string) (net.Conn, error) {
			host, port, err := net.SplitHostPort(addr)
			if err != nil {
				return nil, err
			}

			ips, err := net.DefaultResolver.LookupIPAddr(ctx, host)
			if err != nil {
				return nil, err
			}
			if len(ips) == 0 {
				return nil, fmt.Errorf("%w: no address for %s", ErrBlockedTarget, host)
			}
			// 任一解析结果落在禁止范围即拒绝：否则攻击者可在合法域名下
			// 混入一条指向元数据服务的 A 记录
			for _, ipAddr := range ips {
				if IsBlockedIP(ipAddr.IP) {
					return nil, fmt.Errorf("%w: %s resolves to %s", ErrBlockedTarget, host, ipAddr.IP)
				}
			}

			// 用已校验过的 IP 直接建连，消除"校验时解析一次、建连时再解析一次"
			// 之间的 DNS rebinding 窗口
			return dialer.DialContext(ctx, network, net.JoinHostPort(ips[0].IP.String(), port))
		},

		// 只约束到收到响应头为止的等待，不限制 body 传输时长
		ResponseHeaderTimeout: 30 * time.Second,
		TLSHandshakeTimeout:   15 * time.Second,
		ExpectContinueTimeout: 1 * time.Second,
		MaxIdleConns:          32,
		MaxIdleConnsPerHost:   8,
		IdleConnTimeout:       90 * time.Second,
	}
}

// NewSafeClient 返回使用安全 Transport 的共享 http.Client。
// 应当全局复用以保持连接池，不要每个请求新建。
func NewSafeClient() *http.Client {
	return &http.Client{Transport: NewSafeTransport()}
}

// SanitizeDeviceID 净化调用方提供的设备标识。
//
// 该值会被拼进 X-Emby-Authorization 的引号内，未过滤的引号或控制字符
// 可以突破字段边界、篡改授权头语义，因此只保留安全字符集。
func SanitizeDeviceID(id string) string {
	if strings.TrimSpace(id) == "" {
		return defaultDeviceID
	}

	const maxLen = 64
	var b strings.Builder
	b.Grow(maxLen)
	for _, r := range id {
		if b.Len() >= maxLen {
			break
		}
		switch {
		case r >= 'a' && r <= 'z', r >= 'A' && r <= 'Z', r >= '0' && r <= '9':
			b.WriteRune(r)
		case r == '.', r == '_', r == '-':
			b.WriteRune(r)
		}
	}
	if b.Len() == 0 {
		return defaultDeviceID
	}
	return b.String()
}
