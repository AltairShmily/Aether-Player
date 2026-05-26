# Aether (StreamVault) Celestial Glow UI 设计详细分析报告

> 分析对象：`docs/aether_celestial_glow_ui.html`
> 分析时间：2026-05-27
> 设计主题：Celestial Glow（天体光辉）

---

## 目录

1. [设计系统总览](#1-设计系统总览)
2. [Desktop 桌面端](#2-desktop-桌面端)
3. [Phone 手机端](#3-phone-手机端)
4. [Android TV 电视端](#4-android-tv-电视端)
5. [交互规范](#5-交互规范)
6. [配色系统详解](#6-配色系统详解)
7. [字体与排版](#7-字体与排版)
8. [动画与过渡](#8-动画与过渡)

---

## 1. 设计系统总览

### 1.1 设计理念

Celestial Glow 是一个以深空为灵感的暗色主题设计系统，核心理念是：

- **深邃感**：多层深色背景营造宇宙深空的层次感
- **光辉感**：青蓝色 (#00D4FF) 作为主强调色，如同天体发出的光芒
- **质感**：噪点纹理 + 毛玻璃效果，增加视觉层次
- **沉浸**：全屏暗色设计，减少视觉干扰

### 1.2 三平台适配策略

| 平台 | 布局方式 | 导航方式 | 交互特点 |
|------|---------|---------|---------|
| Desktop | 侧边栏 + 主内容区 | 侧边栏图标 + 鼠标 | Hover 效果、拖拽滚动 |
| Phone | 顶部栏 + 内容区 + 底部导航 | 底部 Tab | 触摸、滑动、点击 |
| Android TV | 顶部导航 + 内容区 | D-Pad 焦点 | 焦点放大、键盘导航 |

---

## 2. Desktop 桌面端

### 2.1 整体布局

```
┌──────────────────────────────────────────────────────┐
│                    Platform Bar (44px)                │
├──────┬───────────────────────────────────────────────┤
│      │              Top Bar (搜索触发器)               │
│  72px│───────────────────────────────────────────────│
│      │                                               │
│ 侧边栏│              Main Content                     │
│      │         (可滚动，含噪点纹理背景)                  │
│      │                                               │
│      │                                               │
│      │                                               │
└──────┴───────────────────────────────────────────────┘
```

### 2.2 Platform Bar（平台切换栏）

**位置**：固定在顶部，z-index: 9999
**高度**：44px
**背景**：`rgba(10,14,20,0.85)` + `backdrop-filter: blur(12px)`
**边框**：底部 1px solid `var(--border)`

**元素**：
- 左侧：Logo "StreamVault"（accent 色，font-weight: 700）
- 中间：三个平台切换按钮（Desktop / Phone / Android TV）

**交互**：
- 按钮 hover：背景变为 `var(--bg-surface)`，文字变为 `var(--text-secondary)`
- 按钮 active：文字变为 `var(--accent)`，背景变为 `var(--accent-soft)`

### 2.3 侧边栏 (Sidebar)

**宽度**：72px（固定）
**背景**：`var(--bg-surface)` (#111820)
**边框**：右侧 1px solid `var(--border)`

**布局结构**（从上到下）：

```
┌─────────┐
│  Logo   │ ← 40x40 SVG，渐变色
│ (40x40) │
├─────────┤
│  🏠 主页 │ ← 导航按钮
│  ─────  │ ← 分割线
│  🎬 动漫 │ ← 媒体库按钮（彩色图标）
│  📺 国产剧│
│  🎉 综艺  │
│  🎬 电影  │
│  🌿 纪录片│
│  🔍 搜索 │
│  📺 TV模式│
├─────────┤
│  Spacer │ ← 弹性空间
├─────────┤
│ 👤 服务器│ ← 服务器/账号切换器
│ ⚙️ 设置  │ ← 设置按钮
└─────────┘
```

**导航按钮 (nav-btn)**：
- 尺寸：44x44px
- 圆角：`var(--radius-md)` (12px)
- 默认：透明背景，`var(--text-muted)` 图标色
- Hover：背景 `var(--bg-surface-hover)`，图标色 `var(--text-secondary)`
- Active：背景 `var(--accent-soft)`，图标色 `var(--accent)`，图标填充模式

**Tooltip**：
- 位置：按钮右侧 14px
- 背景：`var(--bg-elevated)`
- 边框：1px solid `var(--border-light)`
- 阴影：`0 4px 12px rgba(0,0,0,0.4)`
- 动画：opacity + translateX 过渡

### 2.4 服务器/账号切换器

**头像**：
- 尺寸：36x36px 圆形
- 背景：`linear-gradient(135deg, #00D4FF, #8B5CF6)`
- Hover：`box-shadow: 0 0 0 3px var(--accent-soft)` + `scale(1.08)`

**下拉菜单**：
- 位置：头像右侧 12px，底部对齐
- 宽度：280px
- 背景：`var(--bg-elevated)`
- 边框：1px solid `var(--border-light)`
- 圆角：`var(--radius-lg)` (16px)
- 阴影：`0 12px 40px rgba(0,0,0,0.5)`
- 动画：opacity + translateX(-8px) scale(0.96) → 正常

**菜单内容**：
1. **服务器标签**：大写，11px，`var(--text-muted)`，letter-spacing 0.08em
2. **服务器列表**：
   - 在线状态点：8px 圆形，绿色 `#00E5A0` + 发光阴影
   - 离线状态点：灰色 `var(--text-muted)`
   - 当前服务器：`var(--accent-soft)` 背景，`var(--accent)` 文字
3. **分割线**：1px，`var(--border)`
4. **账号标签**：同服务器标签样式
5. **账号列表**：
   - 头像：28x28px 圆形，渐变背景
   - 名称 + 角色（管理员/受限）
6. **添加账号按钮**：虚线边框，hover 变 accent 色

### 2.5 主内容区 (Main Content)

**背景**：
```css
background:
  radial-gradient(ellipse at 10% 0%, rgba(0,212,255,0.04), transparent 50%),
  radial-gradient(ellipse at 80% 100%, rgba(139,92,246,0.03), transparent 50%),
  var(--bg-primary);
```

**噪点纹理**：SVG feTurbulence，opacity: 0.025

### 2.6 Top Bar（顶部搜索栏）

**位置**：sticky，z-index: 10
**背景**：`linear-gradient(to bottom, var(--bg-primary) 60%, transparent)`
**布局**：flex-end（搜索触发器靠右）

**搜索触发器**：
- 背景：`var(--bg-surface)`
- 边框：1px solid `var(--border-light)`
- 圆角：24px（胶囊形）
- 最小宽度：220px
- 内容：搜索图标 + "搜索媒体库..." + 快捷键 "Ctrl+K"
- Hover：边框变 accent 色

### 2.7 首页 (Home View)

**分区标题 (sec-hdr)**：
- 左侧：图标（accent 色，20px）+ 标题（16px，font-weight: 600）
- 右侧："查看全部 →" 按钮
  - Hover：文字变 accent 色，背景变 accent-soft

**横向滚动区 (h-scroll)**：
- 隐藏滚动条
- 支持鼠标拖拽滚动（cursor: grab → grabbing）
- 左右箭头按钮：
  - 36x36px 圆形
  - 背景：`rgba(17,24,32,0.92)` + `backdrop-filter: blur(8px)`
  - Hover：背景 accent-soft，边框 accent 色
  - 默认隐藏，hover 容器时显示

**媒体卡片 (media-card)**：
- 宽度：152px
- 海报比例：2:3
- 圆角：`var(--radius-md)` (12px)
- 底部渐变遮罩：`linear-gradient(to top, rgba(10,14,20,0.75), transparent 60%)`
- Hover 效果：
  - `translateY(-6px) scale(1.03)`
  - 阴影：`0 12px 32px rgba(0,0,0,0.5)` + 蓝色发光
  - 播放按钮 overlay 渐显

**媒体库网格 (lib-grid)**：
- 响应式：`repeat(auto-fill, minmax(210px, 1fr))`
- 卡片比例：16:9
- 圆角：`var(--radius-lg)` (16px)
- 内容：渐变背景 + 图标 + 名称 + 部数
- Hover：`translateY(-4px) scale(1.02)` + 蓝色发光

### 2.8 媒体库页面 (Library View)

**头部 (lib-header)**：
- 返回按钮：38x38px，边框 + 背景，hover 变 accent
- 标题：24px，font-weight: 700
- 信息：DM Mono 字体，右对齐

**媒体网格 (media-grid)**：
- 响应式：`repeat(auto-fill, minmax(148px, 1fr))`
- 间距：18px
- 卡片出现动画：stagger，每项延迟 50ms

### 2.9 详情页 (Detail View)

**背景图 (detail-backdrop)**：
- 高度：300px
- 圆角：`var(--radius-xl)` (24px)
- 底部偏移：-70px（与海报重叠）
- 渐变遮罩：
  - 底部：`linear-gradient(to top, var(--bg-primary) 5%, transparent 50%)`
  - 右侧：`linear-gradient(to right, rgba(10,14,20,0.7), transparent 60%)`

**海报 (detail-poster)**：
- 宽度：170px
- 比例：2:3
- 圆角：`var(--radius-lg)` (16px)
- 边框：2px solid `rgba(0,212,255,0.12)`
- 阴影：`0 8px 32px rgba(0,0,0,0.5)`

**信息区 (detail-info)**：
- 标题：29.6px (1.85rem)，font-weight: 700，letter-spacing: -0.03em
- 元信息行：
  - 评分徽章：accent-soft 背景，accent 文字
  - 分隔点：3px 圆形
  - 标签：图标 + 文字
- 类型标签：surface 背景，border 边框
- 描述：14px，line-height: 1.7，最大宽度 580px

**演员列表 (cast-scroll)**：
- 横向滚动，隐藏滚动条
- 演员卡片：74px 宽
- 头像：58x58px 圆形，渐变背景
- 名字：10.9px，`var(--text-secondary)`
- 角色：9.9px，`var(--text-muted)`

**季度切换 (season-tabs)**：
- 底部边框分割
- Tab 样式：无背景，`var(--text-muted)` 文字
- Active：`var(--accent)` 文字 + 底部渐变线（accent → purple）
- Hover：`var(--text-secondary)` 文字

**剧集列表 (ep-list)**：
- 垂直列表，间距 2px
- 剧集项 (ep-item)：
  - 编号：DM Mono 字体，28px 宽，居中
  - 缩略图：130px 宽，16:9，圆角 `var(--radius-sm)`
  - Hover：背景 `var(--bg-surface-hover)`，播放图标渐显
  - 信息：标题 + 描述（2 行截断）+ 时长

### 2.10 剧集详情页 (Episode Detail View)

**双栏布局 (epd-layout)**：
```css
grid-template-columns: 1fr 360px;
gap: 32px;
```
响应式：< 1100px 时变为单栏

**左栏 - 内容区**：
- 封面图：16:9，圆角 `var(--radius-lg)`
- 大播放按钮：60x60px 圆形，渐变背景，hover scale(1.1)
- 面包屑导航：13px，`var(--text-muted)`，当前项 accent 色
- 标题：22.4px (1.4rem)
- 元信息 + 描述

**右栏 - 控制面板 (ctrl-panel)**：
- 背景：`var(--bg-surface)`
- 边框：1px solid `var(--border)`
- 圆角：`var(--radius-lg)` (16px)
- 内边距：22px
- sticky 定位：`top: 32px`

**自定义下拉选择器 (custom-select)**：
- 触发器：stardust 背景，border-light 边框，圆角 `var(--radius-sm)`
- Hover：边框变白色 15%
- Active：边框 accent 色 + 3px accent-soft 光环
- 箭头：旋转 180° 动画
- 菜单：stardust 背景，translateY(-4px) → 0 动画
- 选项：hover 变 surface-hover，选中变 accent-soft + accent 文字 + check 图标

**播放按钮 (play-full-btn)**：
- 渐变背景：`linear-gradient(135deg, #00D4FF, #8B5CF6)`
- 文字色：`var(--bg-deep)`（深色）
- 圆角：`var(--radius-md)` (12px)
- Hover：`translateY(-1px)` + 蓝色发光阴影

### 2.11 搜索弹窗 (Search Modal)

**覆盖层**：
- 背景：`rgba(0,0,0,0.55)`
- 毛玻璃：`backdrop-filter: blur(8px)`
- z-index: 600

**搜索框**：
- 宽度：560px
- 背景：`var(--bg-elevated)`
- 圆角：`var(--radius-lg)` (16px)
- 阴影：`0 24px 64px rgba(0,0,0,0.5)`
- 动画：`translateY(-12px) scale(0.97)` → 正常（弹性缓动）

**输入区域**：
- 图标：accent 色，22px
- 输入框：无边框，16px，`var(--text-primary)`
- 占位符：`var(--text-muted)`

### 2.12 设置弹窗 (Settings Modal)

**覆盖层**：
- 背景：`rgba(0,0,0,0.6)`
- 毛玻璃：`backdrop-filter: blur(6px)`
- z-index: 500

**弹窗**：
- 宽度：520px
- 最大高度：80vh
- 背景：`var(--bg-secondary)`
- 圆角：`var(--radius-xl)` (24px)
- 动画：`scale(0.95) translateY(12px)` → 正常

**头部**：
- 标题：18.4px (1.15rem)
- 关闭按钮：36x36px，surface 背景

**设置分组**：
- 分组标题：大写，12px，accent 色，letter-spacing 0.06em
- 设置行：flex 布局，底部边框分割
- Toggle 开关：44x24px，圆角 12px
  - Off：stardust 背景，border-light 边框，灰色滑块
  - On：accent 背景，accent 边框，深色滑块

---

## 3. Phone 手机端

### 3.1 整体布局

```
┌────────────────────────────┐
│  Logo    🔍 搜索...        │ ← p-top
├────────────────────────────┤
│                            │
│        Content Area        │ ← p-content (可滚动)
│      (内容区，可滚动)        │
│                            │
├────────────────────────────┤
│ 🏠主页 📺媒体库 🔍搜索 ⚙设置│ ← p-bottom (底部导航)
└────────────────────────────┘
```

**噪点纹理**：opacity 0.02（比 Desktop 更淡）

### 3.2 顶部栏 (p-top)

- 内边距：12px 16px 8px
- Logo：渐变色文字（accent → purple），font-weight: 700
- 搜索栏：flex:1，38px 高，圆角 20px，surface 背景

### 3.3 底部导航栏 (p-bottom)

- 背景：`rgba(13,21,32,0.92)` + `backdrop-filter: blur(12px)`
- 顶部边框：1px solid `var(--border)`
- safe-area 适配：`env(safe-area-inset-bottom, 8px)`

**导航按钮 (p-nav-btn)**：
- 布局：垂直排列（图标 + 文字）
- 图标：24px
- 文字：10px (0.6rem)
- Active：accent 色，图标填充模式

### 3.4 迷你播放条 (p-play-bar)

- 位置：底部导航栏上方，左右 12px
- 背景：`var(--bg-elevated)`
- 边框：1px solid `rgba(0,212,255,0.1)`
- 圆角：`var(--radius-md)` (12px)
- 阴影：`0 4px 20px rgba(0,0,0,0.4)` + 蓝色微光

**内容**：
- 小海报：36x36px，圆角 `var(--radius-xs)`
- 信息：标题 + 集信息
- 控制：播放/关闭按钮（32x32px 圆形）

### 3.5 手机媒体卡片 (p-card)

- 宽度：120px
- 比例：2:3
- 圆角：`var(--radius-md)` (12px)
- 点击反馈：`scale(0.96)`
- 海报底部渐变：`linear-gradient(to top, rgba(10,14,20,0.65), transparent 55%)`

### 3.6 手机媒体库网格 (p-lib-grid)

- 2 列网格，间距 10px
- 卡片比例：16:10
- 内容：渐变背景 + 图标 + 名称 + 部数

### 3.7 手机详情页 (p-detail)

- 封面图：全宽，16:9
- 底部渐变：`linear-gradient(to top, var(--bg-primary), transparent 60%)`
- 海报：100px，2:3，圆角 `var(--radius-md)`，蓝色边框
- 信息区：标题 + 元信息 + 描述 + 剧集列表

### 3.8 手机剧集项 (p-ep-item)

- 编号：DM Mono，24px 宽
- 缩略图：100px，16:9，圆角 `var(--radius-xs)`
- 信息：标题 + 描述（1 行截断）+ 时长

---

## 4. Android TV 电视端

### 4.1 整体布局

```
┌──────────────────────────────────────────────────────┐
│ AETHER  主页 电影 剧集 动漫 设置    🔍  20:30        │ ← tv-top
├──────────────────────────────────────────────────────┤
│                                                      │
│            Featured Banner (21:9)                     │
│                                                      │
├──────────────────────────────────────────────────────┤
│ 📅 最近更新                                          │
│ [Card] [Card] [Card] [Card] [Card] ...               │
├──────────────────────────────────────────────────────┤
│ 📺 媒体库                                            │
│ [LibCard] [LibCard] [LibCard] ...                    │
├──────────────────────────────────────────────────────┤
│ 🎬 热门动漫                                          │
│ [Card] [Card] [Card] [Card] [Card] ...               │
└──────────────────────────────────────────────────────┘
```

### 4.2 顶部导航栏 (tv-top)

- 内边距：24px 56px 16px
- Logo：渐变色文字，22.4px (1.4rem)，font-weight: 800
- 导航按钮：圆角 24px，active 时渐变背景（accent → purple）+ 深色文字
- 右侧：搜索按钮（40x40px 圆形）+ 时钟（DM Mono）

### 4.3 Featured 推荐横幅 (tv-featured)

- 比例：21:9
- 圆角：`var(--radius-xl)` (24px)
- 外边距：0 56px 36px

**渐变遮罩**：
```css
background:
  linear-gradient(to right, rgba(10,14,20,0.88), rgba(10,14,20,0.4) 40%, transparent 70%),
  linear-gradient(to top, rgba(10,14,20,0.6), transparent 40%);
```

**内容区**：
- 位置：左下角，left: 48px，bottom: 36px
- 推荐标签：accent-soft 背景，accent 文字，圆角 12px
- 标题：32px (2rem)，font-weight: 800
- 描述：14px，2 行截断
- 播放按钮：渐变背景，圆角 28px

**Focus 效果**：
- `scale(1.01)`
- `box-shadow: 0 0 0 3px var(--accent)` + 蓝色发光

### 4.4 TV 媒体卡片 (tv-card)

- 宽度：190px
- 比例：2:3
- 圆角：`var(--radius-lg)` (16px)

**Focus 效果**：
- `scale(1.08)`
- `box-shadow: 0 0 0 3px var(--accent)` + 蓝色发光

### 4.5 TV 媒体库卡片 (tv-lib-card)

- 宽度：260px
- 比例：16:9
- 圆角：`var(--radius-lg)` (16px)

**Focus 效果**：
- `scale(1.05)`
- 蓝色边框 + 发光

### 4.6 TV Toast 提示

- 位置：底部 60px，水平居中
- 背景：`var(--bg-elevated)` + `backdrop-filter: blur(12px)`
- 边框：1px solid `var(--accent)`
- 文字：accent 色
- 圆角：24px（胶囊形）
- 动画：translateY(20px) → 0

---

## 5. 交互规范

### 5.1 Hover 效果汇总

| 元素 | 效果 |
|------|------|
| 媒体卡片 | translateY(-6px) scale(1.03) + 蓝色发光 |
| 媒体库卡片 | translateY(-4px) scale(1.02) + 蓝色发光 |
| TV 卡片 | scale(1.08) + 蓝色边框 + 发光 |
| TV Featured | scale(1.01) + 蓝色边框 + 发光 |
| 播放按钮 | translateY(-1px) + 蓝色发光 |
| 滚动箭头 | 背景 accent-soft，边框 accent 色 |
| 服务器头像 | scale(1.08) + accent 光环 |
| 导航按钮 | 背景 surface-hover，文字 secondary |

### 5.2 点击/触摸效果

| 元素 | 效果 |
|------|------|
| 手机卡片 | scale(0.96) |
| 播放按钮 | scale(0.98) |
| Toggle 开关 | 滑块位移 + 颜色变化 |

### 5.3 拖拽滚动

- 鼠标按下：cursor: grab → grabbing
- 拖拽时：禁用 scroll-snap
- 滚动速度：1.5x 鼠标移动距离

### 5.4 键盘快捷键

| 快捷键 | 功能 |
|--------|------|
| Ctrl+K / Cmd+K | 打开搜索 |
| Esc | 关闭搜索/设置弹窗 |
| 方向键 | D-Pad 导航（TV） |

### 5.5 动画时长

| 类型 | 时长 | 缓动函数 |
|------|------|---------|
| 页面切换 | 400ms | ease |
| Hover 效果 | 300ms | cubic-bezier(0.4, 0, 0.2, 1) |
| 弹窗出现 | 300-350ms | cubic-bezier(0.34, 1.56, 0.64, 1) |
| 下拉菜单 | 200-250ms | ease-out |
| 卡片出现 | 500ms | ease（stagger 50ms） |

---

## 6. 配色系统详解

### 6.1 背景色层级

| 变量 | 色值 | 用途 |
|------|------|------|
| `--bg-deep` | #0A0E14 | 最深背景（Scaffold） |
| `--bg-primary` | #0D1520 | 主内容区背景 |
| `--bg-secondary` | #0F1722 | 弹窗背景 |
| `--bg-surface` | #111820 | 卡片、侧边栏背景 |
| `--bg-surface-hover` | #1A2332 | Hover 状态背景 |
| `--bg-elevated` | #1A2332 | 悬浮层、下拉菜单背景 |
| `--bg-card` | #111820 | 卡片背景（同 surface） |

### 6.2 强调色

| 变量 | 色值 | 用途 |
|------|------|------|
| `--accent` | #00D4FF | 主强调色（青蓝色） |
| `--accent-soft` | rgba(0,212,255,0.10) | 强调色背景（10% 透明度） |
| `--accent-medium` | rgba(0,212,255,0.20) | 强调色背景（20% 透明度） |
| `--accent-hover` | #33DDFF | 强调色悬停态 |
| `--accent-glow` | rgba(0,212,255,0.25) | 强调色发光效果 |

**辅助强调色**：
- `#8B5CF6` (紫色)：渐变终止色，TV 导航 active 背景
- `#00E5A0` (绿色)：在线状态、进度条
- `#FF6B35` (橙色)：警告、评分
- `#EC4899` (粉色)：通知徽章

### 6.3 文字色

| 变量 | 色值 | 用途 |
|------|------|------|
| `--text-primary` | #F0F4F8 | 主文字（标题、重要信息） |
| `--text-secondary` | #8892A4 | 次要文字（描述、副标题） |
| `--text-muted` | #5A6577 | 弱化文字（时间、标签、占位符） |

### 6.4 边框色

| 变量 | 色值 | 用途 |
|------|------|------|
| `--border` | rgba(255,255,255,0.06) | 默认边框（6% 白色） |
| `--border-light` | rgba(255,255,255,0.10) | 轻边框（10% 白色） |

### 6.5 渐变组合

**主渐变（accentGradient）**：
```css
linear-gradient(135deg, #00D4FF, #8B5CF6)
```
用途：播放按钮、Logo、服务器头像

**媒体海报渐变（12 种）**：
```css
linear-gradient(135deg, #0A0E14, #1A2332, #111820)  // 深空
linear-gradient(135deg, #0D1520, #1A2332, #8B5CF6)  // 紫色星云
linear-gradient(135deg, #1A0A0A, #8B2020, #FF6B35)  // 红色火焰
linear-gradient(135deg, #051A12, #00E5A0, #0A0E14)  // 绿色极光
linear-gradient(135deg, #0A1628, #00D4FF, #0D1520)  // 青色海洋
...（共 12 种）
```

---

## 7. 字体与排版

### 7.1 字体家族

| 字体 | 用途 |
|------|------|
| Sora | 主字体（标题、正文、按钮） |
| DM Mono | 等宽字体（数字、时间、代码、版本号） |
| PingFang SC | 中文回退字体 |
| Material Symbols Rounded | 图标字体 |

### 7.2 字号规范

| 级别 | Desktop | Phone | TV |
|------|---------|-------|-----|
| 大标题 | 29.6px (1.85rem) | 19.2px (1.2rem) | 32px (2rem) |
| 标题 | 22.4px (1.4rem) | 14.4px (0.9rem) | 19.2px (1.2rem) |
| 正文 | 14px (1rem) | 12.5px (0.89rem) | 14px (1rem) |
| 小字 | 12px (0.85rem) | 10.9px (0.78rem) | 12px (0.85rem) |
| 标签 | 11px (0.78rem) | 10px (0.72rem) | 11.5px (0.82rem) |

### 7.3 字重规范

| 场景 | 字重 |
|------|------|
| 大标题 | 800 (Extra Bold) |
| 标题 | 700 (Bold) |
| 副标题 | 600 (Semi Bold) |
| 正文 | 500 (Medium) |
| 弱化文字 | 400 (Regular) |

### 7.4 行高规范

| 场景 | 行高 |
|------|------|
| 标题 | 1.1 - 1.2 |
| 正文 | 1.5 - 1.7 |
| 小字 | 1.3 |

---

## 8. 动画与过渡

### 8.1 过渡曲线

**标准过渡**：
```css
transition: 0.3s cubic-bezier(0.4, 0, 0.2, 1);
```
用途：大多数 Hover 效果、颜色变化

**弹性过渡**：
```css
transition: 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
```
用途：弹窗出现、播放按钮缩放

**平滑过渡**：
```css
transition: 0.2s ease-out;
```
用途：下拉菜单、Tooltip

### 8.2 关键帧动画

**页面切入 (vIn)**：
```css
@keyframes vIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}
```

**卡片出现 (cfu)**：
```css
@keyframes cfu {
  from { opacity: 0; transform: translateY(14px); }
  to { opacity: 1; transform: translateY(0); }
}
```

### 8.3 毛玻璃效果

| 场景 | 模糊值 | 背景色 |
|------|--------|--------|
| Platform Bar | blur(12px) | rgba(10,14,20,0.85) |
| 搜索弹窗 | blur(8px) | rgba(0,0,0,0.55) |
| 设置弹窗 | blur(6px) | rgba(0,0,0,0.6) |
| 底部导航 | blur(12px) | rgba(13,21,32,0.92) |
| 滚动箭头 | blur(8px) | rgba(17,24,32,0.92) |
| Toast | blur(12px) | var(--bg-elevated) |

---

## 附录：设计 Token 完整列表

```css
:root {
  /* 圆角 */
  --radius-xs: 6px;
  --radius-sm: 8px;
  --radius-md: 12px;
  --radius-lg: 16px;
  --radius-xl: 24px;

  /* 间距 */
  --sidebar-w: 72px;

  /* 过渡 */
  --transition: 0.3s cubic-bezier(0.4, 0, 0.2, 1);

  /* 滚动条 */
  /* 宽度：5px，透明轨道，半透明滑块 */
}
```
