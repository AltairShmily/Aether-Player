# Aether Player UI 设计方案

> 基于 Jellyfin Media Player 界面分析，融合科幻美学，打造下一代媒体播放器体验

---

## 一、Jellyfin Media Player 界面分析总结

### 1.1 架构概述

| 组件 | 技术 | 说明 |
|------|------|------|
| 外壳窗口 | Qt5 / QML (KonvergoWindow) | 原生桌面窗口，支持全屏切换 |
| UI 层 | QtWebEngine (Chromium) | 嵌入式 Web 客户端 |
| 播放器 | MPV (libmpv) | 硬件直通解码，独立于 Web 层 |
| 通信 | QWebChannel | Qt ↔ Web 双向 JS 桥接 |
| UI 来源 | jellyfin-web-jmp | 官方 Web 客户端的定制分支 |

### 1.2 视觉设计特征

**配色方案（暗黑主题）**
- 背景: `#101010` (纯黑灰)
- 卡片: 半透明暗色，带 `backdrop-filter: blur()`
- 主色调: `#00a4dc` (Jellyfin 蓝)
- 辅助色: `#ff9800` (亮度橙)
- 文字: `#ffffff` / `#eeeeee`

**布局模式**
- **电视模式 (TV Mode)**: 卡片网格，大尺寸，横向滚动
- **桌面模式 (Desktop Mode)**: 导航栏 + 内容区
- **移动端 (Mobile)**: 底部导航 + 垂直列表

**核心页面**

| 页面 | 布局 | 关键特征 |
|------|------|----------|
| 首页 | 横向卡片轮播 | 按分类分组 (继续观看/最近添加/推荐) |
| 媒体详情 | Hero 大图 + 信息面板 | 背景海报渐变遮罩，播放按钮突出 |
| 播放器 OSD | 底部渐变浮层 | 进度条 + 控制按钮，300ms 淡入淡出 |
| 导航 | 顶部水平菜单 | 图标 + 文字，高亮下划线 |
| 卡片组件 | 圆角矩形 | 150% 竖版 / 100% 正方形 / 56.25% 横版 |

**交互细节**
- OSD 显示/隐藏: `transition: opacity 0.3s ease-out`
- 播放条: `transform: translate3d` 滑入滑出
- 图标 OSD (音量/亮度): 固定右上角，毛玻璃背景 `rgba(0,0,0,0.8)` + `blur(5px)`
- 卡片无边框，`contain: layout style paint` 优化渲染

### 1.3 设计优缺点

| 优点 | 缺点 |
|------|------|
| 暗色主题沉浸感强 | 整体偏"标准 Jellyfin Web"，缺乏品牌辨识度 |
| OSD 渐变遮罩自然 | 无动态特效，界面静态 |
| 卡片分类清晰 | 科技感不足，更像"工具"而非"体验" |
| 跨平台一致性好 | 颜色系统单一，无层次感 |
| MPV 直通播放性能好 | 导航层级扁平，探索性弱 |

---

## 二、Aether Player UI 升级设计方案

### 2.1 设计理念

> **"Aether"** — 以太，古希腊哲学中充满宇宙的第五元素。
> 我们追求的不是"播放器"，而是一个 **沉浸式媒体宇宙入口**。

**三大设计支柱：**

1. **Celestial Glow** — 星辉光感：关键元素自带呼吸光效，模拟星辰微光
2. **Depth Layers** — 纵深层次：通过透明度、模糊、视差建立 Z 轴空间感
3. **Fluid Motion** — 流体动效：页面切换如水波流转，交互反馈有弹性

### 2.2 色彩系统 (Aether Palette)

#### 基础色板

```
┌─────────────────────────────────────────────────────────────┐
│  AETHER COLOR SYSTEM                                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ■ Deep Void     #0A0E14   主背景 — 深空黑                  │
│  ■ Nebula Dark   #111820   卡片/面板背景                    │
│  ■ Stardust      #1A2332   悬浮面板                         │
│  ■ Cosmic Gray   #2A3444   分割线/次级背景                   │
│                                                             │
│  ■ Celestial Cyan #00D4FF   主强调色 — 星辰青 (播放/主要CTA) │
│  ■ Aurora Green  #00E5A0   辅助强调 — 极光绿 (成功/在线)     │
│  ■ Supernova     #FF6B35   警示/热力 — 超新星橙              │
│  ■ Nova Purple   #8B5CF6   标签/分类 — 新星紫                │
│  ■ Plasma Pink   #EC4899   收藏/心标 — 等离子粉              │
│                                                             │
│  ■ Text Primary  #F0F4F8   主文字 — 冰白                     │
│  ■ Text Secondary#8892A4   次文字 — 雾灰                     │
│  ■ Text Tertiary #5A6577   辅助文字 — 暗雾                   │
│                                                             │
│  ■ Glow Cyan     #00D4FF40  星辰青辉光 (box-shadow)          │
│  ■ Glow Green    #00E5A030  极光绿辉光                       │
│  ■ Glow Purple   #8B5CF630  新星紫辉光                       │
└─────────────────────────────────────────────────────────────┘
```

#### 渐变系统

```
Hero Gradient:     linear-gradient(135deg, #0A0E14 0%, #111820 50%, #0D1520 100%)
Card Shimmer:      linear-gradient(145deg, rgba(0,212,255,0.08) 0%, transparent 60%)
Play Button Glow:  radial-gradient(circle, #00D4FF 0%, #00D4FF00 70%)
Page Transition:   linear-gradient(180deg, transparent 0%, #0A0E14 100%)
Accent Gradient:   linear-gradient(135deg, #00D4FF 0%, #8B5CF6 100%)
```

### 2.3 字体系统

```
标题 (H1):   Inter / 思源黑体 — 28sp, Weight 700, Letter Spacing -0.5
副标题 (H2): Inter / 思源黑体 — 22sp, Weight 600, Letter Spacing -0.3
正文 (Body):  Inter / 思源黑体 — 15sp, Weight 400, Line Height 1.5
标签 (Caption): Inter / 思源黑体 — 12sp, Weight 500, Letter Spacing 0.8, 全大写
数字 (Mono):   JetBrains Mono — 用于时长/时间码/比特率
```

### 2.4 核心组件设计

---

#### 🏠 首页 (Home)

**布局: 无边距沉浸式**

```
┌──────────────────────────────────────────────────────┐
│ [≡]  A E T H E R                    [🔍] [👤]       │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │         [Hero Banner — 全宽轮播]              │   │
│  │                                               │   │
│  │   ┌─────────┐                                 │   │
│  │   │  ▶ 播放  │  "流浪地球3"                    │   │
│  │   │  ◉ 继续  │  第7集 · 38:22 剩余             │   │
│  │   └─────────┘  科幻 · 2026                     │   │
│  │                                               │   │
│  │   ○ ● ○ ○    (圆点指示器，当前项发光)          │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ── 继 续 观 看 ──────────────────  查看全部 ›     │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐    │
│  │      │ │      │ │      │ │      │ │      │    │
│  │ 海报 │ │ 海报 │ │ 海报 │ │ 海报 │ │ 海报 │ ←  │
│  │      │ │      │ │      │ │      │ │      │    │
│  └──┬───┘ └──┬───┘ └──┬───┘ └──┬───┘ └──────┘    │
│  ▸ 剧名     ▸ 剧名    ▸ 剧名   ▸ 进度条            │
│  S2E5       S1E12     电影名    ████░░ 67%          │
│                                                      │
│  ── 最 近 新 增 ──────────────────  查看全部 ›     │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐    │
│  │      │ │      │ │      │ │      │ │      │    │
│  │ 横版 │ │ 竖版 │ │ 横版 │ │ 竖版 │ │ 横版 │ ←  │
│  │      │ │      │ │      │ │      │ │      │    │
│  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘    │
│                                                      │
│  ── 热 门 推 荐 ──────────────────  查看全部 ›     │
│  ...                                                 │
│                                                      │
│  ════════════════════════════════════════════════   │
│  Now Playing: 流浪地球3 S3E7  ▶  ████░░░  1:23:45  │
│  ════════════════════════════════════════════════   │
└──────────────────────────────────────────────────────┘
```

**设计要点:**

1. **Hero Banner**: 全宽无边距，背景图片模糊 + 渐变遮罩，卡片半透明悬浮在上面
2. **分类标题**: 间距拉开，用极细分割线 + 两端对齐，营造杂志感
3. **卡片**: 
   - 悬停态: 边框出现 `1px #00D4FF30` + 微弱发光 `box-shadow: 0 0 20px #00D4FF20`
   - 进度条: 渐变色 `#00D4FF → #8B5CF6`，圆角胶囊型
   - 新增/热门标签: 左上角 `#8B5CF6` 小角标
4. **底部播放条**: 毛玻璃背景 `backdrop-filter: blur(20px)` + 微光边框

---

#### 📺 媒体详情页 (Detail)

**电视剧详情页:**

```
┌──────────────────────────────────────────────────────┐
│ ← 返回                              [⋯] [❤] [+]   │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │         [Hero — 全宽背景图 + 深度模糊]         │   │
│  │                                               │   │
│  │   ┌───────┐                                   │   │
│  │   │ 海报  │   流浪地球3                        │   │
│  │   │ 竖版  │   ████████░░ 8.7                   │   │
│  │   │       │   科幻 · 冒险 · 2026               │   │
│  │   │       │   3 季 · 36 集 · 每集 45 分钟      │   │
│  │   └───────┘                                   │   │
│  │                                               │   │
│  │   [ ▶ 继续播放 ]   [ ↻ 从头播放 ]              │   │
│  │   按钮带脉动发光效果                            │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ── 剧 情 简 介 ─────────────────────────────────   │
│  在不远的未来，太阳即将毁灭...                        │
│  [展开 ▾]                                            │
│                                                      │
│  ── 演 职 人 员 ─────────────────────────────────   │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐    │
│  │ 圆形 │ │ 圆形 │ │ 圆形 │ │ 圆形 │ │ 圆形 │    │
│  │ 头像 │ │ 头像 │ │ 头像 │ │ 头像 │ │ 头像 │    │
│  │      │ │      │ │      │ │      │ │      │    │
│  │ 导演 │ │ 主演 │ │ 主演 │ │ 主演 │ │ 编剧 │    │
│  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘    │
│                                                      │
│  ── 音 轨 / 字 幕 ──────────────────────────────   │
│  ┌──────────────────────────────────────────────┐   │
│  │ 音轨:  [ FLAC 7.1 ✦ ] [ AAC 5.1 ] [ MP3 ]  │   │
│  │ 字幕:  [ 中文 ] [ English ] [ 禁用 ]          │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ── 第 1 季 ─────── [ 第 2 季 ▾ ] [ 第 3 季 ▾ ]   │
│  ┌──────────────────────────────────────────────┐   │
│  │ E01  ████████████████████░░░░  超载          │   │
│  │      45:00 · 已观看 · 2026-01-15              │   │
│  ├──────────────────────────────────────────────┤   │
│  │ E02  ░░░░░░░░░░░░░░░░░░░░░░░░  流浪          │   │
│  │      42:00 · 未观看 · 2026-01-22              │   │
│  ├──────────────────────────────────────────────┤   │
│  │ E03  ████████░░░░░░░░░░░░░░░░  离别          │   │
│  │      44:00 · 部分观看 · 2026-01-29            │   │
│  └──────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────┘
```

**设计要点:**

1. **Hero 区域**: 海报浮在背景上，背景图高度模糊(20px)，底部渐变过渡到页面背景
2. **评分星**: 用菱形徽章包裹数字评分，星辰青边框 + 发光
3. **播放按钮**: 渐变填充 `#00D4FF → #8B5CF6`，hover 时脉动发光
4. **音轨/字幕选择器**: 胶囊按钮组，选中态带星辰青边框 + 微光
5. **集数列表**: 进度条与集数标题同行，紧凑高效

---

#### 🎬 播放器 OSD

```
┌──────────────────────────────────────────────────────┐
│ ◀ 返回          流浪地球3 · S3E7 · 超载              │
│                        [⚙] [ CC ] [🔊]              │
├──────────────────────────────────────────────────────┤
│                                                      │
│                                                      │
│              [         视 频 画 面         ]          │
│                                                      │
│                                                      │
│                                                      │
│                                                      │
├──────────────────────────────────────────────────────┤
│                                                      │
│  1:23:45 ████████████░░░░░░░░░░░ 2:15:30            │
│         ↑ 进度条: 渐变 #00D4FF→#8B5CF6              │
│         ↑ 悬停时显示章节缩略图预览                    │
│                                                      │
│  [⏪] [◀◀] [ ▶ ] [▶▶] [⏩]      🔊 ═══════ ○      │
│                                  ↑ 音量滑块          │
│  [🔀]  [🔁]         1.0x        [🖼 全屏]           │
│                                                      │
└──────────────────────────────────────────────────────┘
```

**OSD 动效规格:**

```css
/* 顶部栏 — 从上方滑入 */
.osd-header {
  background: linear-gradient(180deg, rgba(10,14,20,0.9) 0%, transparent 100%);
  backdrop-filter: blur(12px);
  transform: translateY(-100%);
  transition: transform 0.35s cubic-bezier(0.4, 0, 0.2, 1),
              opacity 0.3s ease-out;
}
.osd-header.visible {
  transform: translateY(0);
  opacity: 1;
}

/* 底部控制栏 — 从下方滑入 */
.osd-controls {
  background: linear-gradient(0deg, rgba(10,14,20,0.95) 0%, transparent 100%);
  backdrop-filter: blur(16px);
  transform: translateY(100%);
  transition: transform 0.35s cubic-bezier(0.4, 0, 0.2, 1),
              opacity 0.3s ease-out;
}
.osd-controls.visible {
  transform: translateY(0);
  opacity: 1;
}

/* 进度条 hover 态 */
.progress-bar {
  height: 4px;                    /* 默认 */
  transition: height 0.2s ease;
}
.progress-bar:hover {
  height: 6px;
  box-shadow: 0 0 12px #00D4FF80;
}
.progress-bar::after {
  /* 拖拽圆点 */
  content: '';
  width: 14px;
  height: 14px;
  border-radius: 50%;
  background: #00D4FF;
  box-shadow: 0 0 16px #00D4FF;
  opacity: 0;
  transition: opacity 0.2s ease;
}
.progress-bar:hover::after {
  opacity: 1;
}
```

---

#### 🎵 音频播放器

```
┌──────────────────────────────────────────────────────┐
│                                                      │
│              ┌─────────────┐                         │
│              │             │                         │
│              │   专辑封面   │   ← 圆角 + 微光边框     │
│              │   (旋转动画) │   ← 播放时缓慢旋转      │
│              │             │                         │
│              └─────────────┘                         │
│                                                      │
│              歌曲名称                                 │
│              专辑名 · 艺术家                          │
│                                                      │
│         0:45 ████████████░░░░░ 3:22                  │
│                                                      │
│              [⏮] [ ▶ ] [⏭]                          │
│                                                      │
│         🔀     🔁     📋     📥                      │
│                                                      │
└──────────────────────────────────────────────────────┘
```

**音频特色:**
- 专辑封面: `border-radius: 12px`，播放时 `rotation: 360deg` 缓慢循环
- 封面背后: 径向渐变发光，颜色从封面主色调提取
- 进度条: 与视频 OSD 同风格

---

#### ⚙️ 设置页

```
┌──────────────────────────────────────────────────────┐
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │  👤 Altair                                    │   │
│  │  Altair-EMBY · 192.168.31.66:8012            │   │
│  │  ● 已连接                                     │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ── 播 放 器 ─────────────────────────────────────   │
│  ┌──────────────────────────────────────────────┐   │
│  │  音频直通          [═══●] ON                   │   │
│  │  默认音轨          FLAC 7.1 ▾                 │   │
│  │  默认字幕          中文 ▾                      │   │
│  │  渲染器            MPV ▾                       │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ── 外 观 ─────────────────────────────────────────   │
│  ┌──────────────────────────────────────────────┐   │
│  │  主题                [深空] [星云] [极光]     │   │
│  │  强调色              [青] [紫] [粉] [绿]      │   │
│  │  动效强度            ○━━━━●━━━○  中等         │   │
│  │  字体大小            ○━━●━━━━━━━  标准         │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ── 网 络 ─────────────────────────────────────────   │
│  ┌──────────────────────────────────────────────┐   │
│  │  代理地址          192.168.31.66:7890         │   │
│  │  缓存大小          500 MB ▾                   │   │
│  │  画质限制          无限制 ▾                    │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ── 关 于 ─────────────────────────────────────────   │
│  ┌──────────────────────────────────────────────┐   │
│  │  版本              v1.0.0-dev                 │   │
│  │  架构              Flutter + Go + MPV         │   │
│  │  服务器            Altair-EMBY                │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

#### 📱 登录 / 服务器选择

**服务器选择页:**

```
┌──────────────────────────────────────────────────────┐
│                                                      │
│                                                      │
│                    ✦ AETHER ✦                        │
│                 MEDIA  PLAYER                        │
│                                                      │
│              "连接你的媒体宇宙"                        │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │  🏠 Altair-EMBY                              │   │
│  │  192.168.31.66:8012                          │   │
│  │  ● 在线 · 2048 部影片                         │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │  + 添加新服务器                               │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│                                                      │
│  背景: 星空粒子动画 (Canvas/WebGL)                    │
│  整体: 居中布局，卡片带毛玻璃效果                      │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

### 2.5 动效系统

#### 页面转场

```dart
// 页面切换 — 水平滑入 + 淡入
PageRouteBuilder(
  transitionDuration: Duration(milliseconds: 350),
  reverseTransitionDuration: Duration(milliseconds: 300),
  pageBuilder: (_, __, ___) => targetPage,
  transitionsBuilder: (_, animation, __, child) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: Offset(0.05, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  },
)
```

#### 微交互动效

| 触发 | 动效 | 参数 |
|------|------|------|
| 卡片 hover | 缩放 + 发光 | scale: 1.03, box-shadow: 0 0 20px #00D4FF20 |
| 卡片点击 | 按压缩放 | scale: 0.97, duration: 100ms |
| 播放按钮 hover | 脉动发光 | boxShadow 循环 0.6s |
| 开关切换 | 滑动 + 颜色 | duration: 250ms, curve: easeOutCubic |
| 页面加载 | 骨架屏闪烁 | 渐变动画 1.5s 循环 |
| 列表项出现 | 交错淡入 | 每项延迟 50ms, 从下方 12px 滑入 |
| Toast 通知 | 顶部滑入 | translateY(-100%) → 0, duration: 300ms |

#### 骨架屏设计

```
加载态使用与内容同形状的占位块:
- 卡片: 圆角矩形 + 微光脉动
- 文字: 80% 宽度矩形
- 头像: 圆形
- 颜色: rgba(255,255,255,0.04) → rgba(255,255,255,0.08) 渐变
```

### 2.6 响应式布局

| 断点 | 布局 | 导航 |
|------|------|------|
| < 600px (手机) | 单列，全宽卡片 | 底部 Tab Bar |
| 600-900px (平板) | 双列网格 | 侧边 Rail (收缩态) |
| 900-1200px (小桌面) | 3-4 列网格 | 侧边 Rail (展开态) |
| > 1200px (大桌面) | 5-6 列网格 | 侧边 Rail + 分组 |

**手机端特别处理:**
- Hero Banner 缩小高度为 200px (桌面 360px)
- 卡片改为 2 列
- 音轨/字幕选择器改为底部弹出 ActionSheet
- 设置页改为分组列表

### 2.7 对比: JMP vs Aether

| 维度 | Jellyfin Media Player | Aether Player (新) |
|------|----------------------|-------------------|
| 背景 | `#101010` 纯色 | `#0A0E14` 深空渐变 + 粒子 |
| 主色 | `#00a4dc` 单一蓝 | `#00D4FF` 星辰青 + 多色系 |
| 卡片 | 扁平无特效 | 毛玻璃 + 悬停发光 |
| 动效 | 基础 CSS transition | 弹性曲线 + 交错动画 |
| 进度条 | 单色直线 | 渐变 + hover 扩展 + 发光 |
| 字体 | 系统默认 | Inter + JetBrains Mono |
| 品牌感 | 弱 (Web 客户端外观) | 强 (星系主题完整体系) |
| 科技感 | ⭐⭐ | ⭐⭐⭐⭐⭐ |

### 2.8 Flutter 实现参考

#### AppColors 扩展

```dart
/// Aether Player 色彩系统 V2
class AppColors {
  AppColors._();

  // ── 深空背景 ──
  static const Color deepVoid = Color(0xFF0A0E14);
  static const Color nebulaDark = Color(0xFF111820);
  static const Color stardust = Color(0xFF1A2332);
  static const Color cosmicGray = Color(0xFF2A3444);

  // ── 星辰强调色 ──
  static const Color celestialCyan = Color(0xFF00D4FF);
  static const Color auroraGreen = Color(0xFF00E5A0);
  static const Color supernova = Color(0xFFFF6B35);
  static const Color novaPurple = Color(0xFF8B5CF6);
  static const Color plasmaPink = Color(0xFFEC4899);

  // ── 文字 ──
  static const Color textPrimary = Color(0xFFF0F4F8);
  static const Color textSecondary = Color(0xFF8892A4);
  static const Color textTertiary = Color(0xFF5A6577);

  // ── 功能色 ──
  static const Color success = Color(0xFF00E5A0);
  static const Color warning = Color(0xFFFF6B35);
  static const Color error = Color(0xFFEF4444);

  // ── 边框 ──
  static const Color borderSubtle = Color(0x1AFFFFFF);   // 10%
  static const Color borderFocus = Color(0x4D00D4FF);    // 30%

  // ── 发光 ──
  static BoxShadow glowCyan({double blur = 20}) => BoxShadow(
    color: celestialCyan.withValues(alpha: 0.25),
    blurRadius: blur,
    spreadRadius: 2,
  );

  static BoxShadow glowPurple({double blur = 20}) => BoxShadow(
    color: novaPurple.withValues(alpha: 0.25),
    blurRadius: blur,
    spreadRadius: 2,
  );

  // ── 渐变 ──
  static const LinearGradient accentGradient = LinearGradient(
    colors: [celestialCyan, novaPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, deepVoid],
    stops: [0.4, 1.0],
  );

  static const LinearGradient progressGradient = LinearGradient(
    colors: [celestialCyan, novaPurple],
  );
}
```

---

## 三、设计文件清单

| 文件 | 说明 |
|------|------|
| `docs/ui-design-proposal.md` | 本文档 — 完整设计方案 |
| `app/lib/theme/app_colors_v2.dart` | 色彩系统 V2 实现 |
| `app/lib/theme/app_theme_v2.dart` | Material 3 主题 V2 |
| `app/lib/widgets/aether_card.dart` | 通用卡片组件 (毛玻璃 + 发光) |
| `app/lib/widgets/aether_button.dart` | 发光按钮组件 |
| `app/lib/widgets/aether_progress.dart` | 渐变进度条组件 |
| `app/lib/widgets/skeleton_loader.dart` | 骨架屏组件 |
| `app/lib/widgets/glass_panel.dart` | 毛玻璃面板组件 |
| `app/lib/screens/home_tab.dart` | 首页 (重设计) |
| `app/lib/screens/series_detail_screen.dart` | 剧集详情 (重设计) |
| `app/lib/screens/player_osd.dart` | 播放器 OSD (新建) |

---

## 四、实施优先级

### Phase 1 — 视觉基座 (Week 1)
- [ ] 色彩系统 V2 (`app_colors_v2.dart`)
- [ ] Material 3 主题升级 (`app_theme_v2.dart`)
- [ ] 骨架屏组件
- [ ] 响应式断点系统

### Phase 2 — 核心组件 (Week 2)
- [ ] Aether Card (毛玻璃 + 发光)
- [ ] Aether Button (渐变 + 脉动)
- [ ] Aether Progress (渐变进度条)
- [ ] Glass Panel (毛玻璃面板)

### Phase 3 — 页面重设计 (Week 3)
- [ ] 首页 Hero Banner + 卡片轮播
- [ ] 媒体详情页 Hero + 信息布局
- [ ] 设置页卡片化重设计
- [ ] 登录/服务器选择页

### Phase 4 — 播放器 (Week 4)
- [ ] 视频 OSD 控制栏
- [ ] 音频播放器页面
- [ ] 转场动效
- [ ] 微交互完善

---

*Design by Hermes Agent · Based on analysis of Jellyfin Media Player (Terminus-Media)*
*Aether Player — 连接你的媒体宇宙*
