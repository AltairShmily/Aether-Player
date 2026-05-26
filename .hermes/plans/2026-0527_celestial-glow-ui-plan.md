# Aether Celestial Glow UI 开发计划

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** 严格按照 `docs/aether_celestial_glow_ui.html` 设计稿，完成 Aether Emby 客户端 Desktop / Phone / Android TV 三平台的 UI 实现。

**Architecture:** 项目基于 Flutter + Riverpod + Material 3，已有完整的 Celestial Glow 色彩系统 (AppColors) 和 20+ 组件。本计划聚焦于：补全缺失页面、修复不符合设计稿的组件、实现交互细节。

**Tech Stack:** Flutter 3.x, Dart, Riverpod, Google Fonts (Sora, DM Mono), Material Symbols Rounded

---

## 现状分析

### 已完成（符合设计稿）
| 组件/页面 | 文件 | 状态 |
|-----------|------|------|
| 色彩系统 | `theme/app_colors.dart` | ✅ 完全匹配 |
| 主题数据 | `theme/app_theme.dart` | ✅ 完全匹配 |
| 响应式断点 | `theme/app_breakpoints.dart` | ✅ 完全匹配 |
| MediaCard | `widgets/media_card.dart` | ✅ 完全匹配 |
| ScrollArrows | `widgets/scroll_arrows.dart` | ✅ 完全匹配 |
| SearchOverlay | `widgets/search_overlay.dart` | ✅ 完全匹配 |
| GlassPanel | `widgets/glass_panel.dart` | ✅ 完全匹配 |
| AetherHero | `widgets/aether_hero.dart` | ✅ 完全匹配 |
| AetherBadge | `widgets/aether_badge.dart` | ✅ 完全匹配 |
| AetherProgress | `widgets/aether_progress.dart` | ✅ 完全匹配 |
| VideoOSD | `widgets/video_osd.dart` | ✅ 完全匹配 |
| AetherButton | `widgets/aether_button.dart` | ✅ 完全匹配 |
| AetherCard | `widgets/aether_card.dart` | ✅ 完全匹配 |
| AetherChip | `widgets/aether_chip.dart` | ✅ 完全匹配 |
| AetherPageRoute | `widgets/aether_page_route.dart` | ✅ 完全匹配 |
| AetherSplash | `widgets/aether_splash.dart` | ✅ 完全匹配 |
| ShellScreen | `screens/shell_screen.dart` | ✅ 基本匹配 |
| HomeTab | `screens/home_tab.dart` | ✅ 基本匹配 |
| LoginScreen | `screens/login_screen.dart` | ✅ 完全匹配 |
| ServerSelectionScreen | `screens/server_selection_screen.dart` | ✅ 完全匹配 |

### 需要修复（部分匹配）
| 组件/页面 | 文件 | 问题 |
|-----------|------|------|
| EpisodeCard | `widgets/episode_card.dart` | 硬编码 radius 10，无 hover 效果，用 legacy cardBg |
| SkeletonLoader | `widgets/skeleton_loader.dart` | 硬编码颜色，未用 AppColors tokens |
| TrackSelector | `widgets/track_selector.dart` | radius 14 不是 token，无 hover |
| PillButton | `widgets/pill_button.dart` | radius 28 硬编码，无 hover/动画 |
| MediaInfoCard | `widgets/media_info_card.dart` | radius 14，无 hover |
| DiamondBadge | `widgets/diamond_badge.dart` | 背景色略偏，无 glow 效果 |
| GenreChip | `widgets/genre_chip.dart` | 与 AetherChip.genre 重复，缺 border |
| SeriesDetailScreen | `screens/series_detail_screen.dart` | Play 按钮是 TODO |
| EpisodeDetailScreen | `screens/episode_detail_screen.dart` | Play 按钮是 TODO，control panel 用 bottom sheet 而非 inline dropdown |
| TvHomeScreen | `screens/tv_home_screen.dart` | Tab 切换未实现内容切换，搜索/库导航是 TODO |
| SettingsTab | `screens/settings_tab.dart` | 应为弹窗模式（设计稿），toggle 无持久化 |

### 缺失（设计稿有但未实现）
| 功能 | 设计稿描述 | 优先级 |
|------|-----------|--------|
| 服务器/账号切换器 | 侧边栏底部下拉菜单，支持多服务器+多账号 | P0 |
| 自定义下拉选择器 | 剧集详情页的媒体源/音频/字幕选择（inline，非 bottom sheet） | P0 |
| 剧集详情双栏布局 | Desktop ≥1200px 时左内容+右控制面板 | P0 |
| 噪点纹理叠加 | SVG feTurbulence 噪点背景 | P1 |
| Phone Mini 播放条 | 底部悬浮迷你播放器 | P1 |
| Phone 底部导航 | 4 个 Tab（主页/媒体库/搜索/设置） | P1 |
| TV Featured 大图 | 21:9 推荐横幅 | P1 |
| TV 焦点导航系统 | D-Pad + focus ring + scale 动画 | P1 |
| 剧集详情面包屑 | Series · S01 · E05 导航 | P2 |
| 演员横滑列表优化 | 圆形头像 + 名字 + 角色名 | P2 |

---

## 开发阶段

### Phase 1: Widget 修复与统一（基础层）
> 修复所有不合规组件，确保设计系统一致性

### Phase 2: Desktop 核心页面
> 侧边栏增强、首页优化、详情页重构

### Phase 3: Phone 响应式布局
> 底部导航、Mini 播放条、Phone 适配

### Phase 4: Android TV
> Featured 大图、焦点系统、D-Pad 导航

### Phase 5: 交互细节与打磨
> 噪点纹理、动画、设置弹窗、搜索增强

---

## Phase 1: Widget 修复与统一

### Task 1.1: 修复 EpisodeCard 圆角和颜色

**Objective:** 将 EpisodeCard 的硬编码 radius 10 改为 AppColors tokens，添加 hover 效果，替换 legacy 颜色。

**Files:**
- Modify: `app/lib/widgets/episode_card.dart`

**Steps:**
1. 将硬编码 `BorderRadius.circular(10)` 改为 `BorderRadius.circular(AppColors.radiusMd)`
2. 将 `AppColors.cardBg` 替换为 `AppColors.nebulaDark`
3. 将 `AppColors.textWarmGray` 替换为 `AppColors.textSecondary`
4. 添加 `MouseRegion` 包装，hover 时 `translateY(-4px)` + `boxShadow` 发光效果
5. 运行 `flutter analyze` 确认无错误

**Commit:** `🎨 fix: EpisodeCard 使用 design tokens 并添加 hover 效果`

---

### Task 1.2: 修复 SkeletonLoader 颜色

**Objective:** 将 SkeletonLoader 的硬编码颜色替换为 AppColors tokens。

**Files:**
- Modify: `app/lib/widgets/skeleton_loader.dart`

**Steps:**
1. 将 `#0E1319` 替换为 `AppColors.deepVoid`
2. 将 `#1A2332` 替换为 `AppColors.stardust`
3. shimmer 渐变使用 `AppColors.nebulaDark` → `AppColors.stardust` → `AppColors.nebulaDark`
4. 运行 `flutter analyze` 确认无错误

**Commit:** `🎨 fix: SkeletonLoader 使用 AppColors tokens`

---

### Task 1.3: 修复 TrackSelector 圆角和交互

**Objective:** 将 TrackSelector 的 radius 14 改为 token，添加 hover 效果。

**Files:**
- Modify: `app/lib/widgets/track_selector.dart`

**Steps:**
1. 将 `BorderRadius.circular(14)` 改为 `BorderRadius.circular(AppColors.radiusLg)`
2. 将 `AppColors.cardBg` 替换为 `AppColors.nebulaDark`
3. 为每个 TrackOption 添加 `MouseRegion` hover 效果（背景变为 `AppColors.surfaceHover`）
4. 选中状态使用 `AppColors.celestialCyan` 而非 `AppColors.playGold`
5. 运行 `flutter analyze` 确认无错误

**Commit:** `🎨 fix: TrackSelector 使用 design tokens 并添加 hover 效果`

---

### Task 1.4: 修复 PillButton 圆角和动画

**Objective:** 将 PillButton 的 radius 28 改为 token，添加 hover 动画。

**Files:**
- Modify: `app/lib/widgets/pill_button.dart`

**Steps:**
1. 将 `BorderRadius.circular(28)` 改为 `BorderRadius.circular(AppColors.radiusXl)`
2. 添加 `MouseRegion` hover：`scale(1.02)` + `boxShadow` 发光
3. 添加 `GestureDetector` press：`scale(0.98)`
4. 使用 `AppColors.accentGradient` 作为背景渐变
5. 运行 `flutter analyze` 确认无错误

**Commit:** `🎨 fix: PillButton 使用 design tokens 并添加 hover/press 动画`

---

### Task 1.5: 修复 MediaInfoCard 圆角

**Objective:** 将 MediaInfoCard 的 radius 14 改为 token。

**Files:**
- Modify: `app/lib/widgets/media_info_card.dart`

**Steps:**
1. 将 `BorderRadius.circular(14)` 改为 `BorderRadius.circular(AppColors.radiusLg)`
2. 将 `AppColors.cardBg` 替换为 `AppColors.nebulaDark`
3. 运行 `flutter analyze` 确认无错误

**Commit:** `🎨 fix: MediaInfoCard 使用 design tokens`

---

### Task 1.6: 修复 DiamondBadge 背景和 glow

**Objective:** 修正 DiamondBadge 背景色并添加 glow 效果。

**Files:**
- Modify: `app/lib/widgets/diamond_badge.dart`

**Steps:**
1. 将背景色 `0xFF1A1A1A` 改为 `AppColors.deepVoid`
2. 边框色使用 `AppColors.celestialCyan` 70% alpha
3. 添加 `boxShadow` glow：`AppColors.glowCyan(alpha: 0.2)`
4. 运行 `flutter analyze` 确认无错误

**Commit:** `🎨 fix: DiamondBadge 背景色和 glow 效果`

---

### Task 1.7: 合并 GenreChip 到 AetherChip

**Objective:** 移除冗余的 GenreChip，统一使用 AetherChip.genre。

**Files:**
- Delete: `app/lib/widgets/genre_chip.dart`
- Modify: 所有引用 GenreChip 的文件 → 改用 `AetherChip.genre()`

**Steps:**
1. 搜索所有 `GenreChip` 引用
2. 替换为 `AetherChip.genre(label: ...)`
3. 删除 `genre_chip.dart`
4. 运行 `flutter analyze` 确认无错误

**Commit:** `♻️ refactor: 移除冗余 GenreChip，统一使用 AetherChip.genre`

---

### Task 1.8: 添加噪点纹理组件

**Objective:** 创建 NoiseTexture 组件，用于全局背景噪点叠加。

**Files:**
- Create: `app/lib/widgets/noise_texture.dart`

**Steps:**
1. 创建 `NoiseTexture` StatelessWidget
2. 使用 `CustomPaint` + `CustomPainter` 绘制噪点（模拟 SVG feTurbulence）
3. 提供 `opacity` 参数（默认 0.025）
4. 使用 `AppColors.deepVoid` 作为基色
5. 在 `ShellScreen` 的 `Scaffold` body 中叠加此组件
6. 运行 `flutter analyze` 确认无错误

**Commit:** `✨ feat: 添加 NoiseTexture 噪点纹理组件`

---

## Phase 2: Desktop 核心页面

### Task 2.1: 服务器/账号切换器

**Objective:** 在侧边栏底部实现服务器/账号切换下拉菜单。

**Files:**
- Create: `app/lib/widgets/server_switcher.dart`
- Modify: `app/lib/screens/shell_screen.dart` (侧边栏底部)

**Steps:**
1. 创建 `ServerSwitcher` StatefulWidget
2. 实现下拉菜单 UI：
   - 服务器列表（status dot + 名称 + IP）
   - 分割线
   - 账号列表（avatar + 名称 + 角色）
   - "添加账号" 按钮
3. 使用 `AppColors.stardust` 背景 + `AppColors.borderLight` 边框
4. 动画：`opacity` + `translateX(-8px)` → `translateX(0)` 过渡
5. 点击外部区域自动关闭
6. 集成到 `ShellScreen` 侧边栏底部
7. 运行 `flutter analyze` 确认无错误

**Commit:** `✨ feat: 实现服务器/账号切换器下拉菜单`

---

### Task 2.2: 重构 EpisodeDetailScreen 双栏布局

**Objective:** 严格按照设计稿实现 Desktop 双栏布局（左内容 + 右控制面板）。

**Files:**
- Modify: `app/lib/screens/episode_detail_screen.dart`
- Create: `app/lib/widgets/media_source_selector.dart`

**Steps:**
1. 使用 `LayoutBuilder` 检测宽度 ≥1200px 时切换双栏
2. 左栏（可滚动）：
   - 返回按钮
   - 16:9 封面图（`aspectRatio: 16/9`，圆角 `radiusXl`）
   - 面包屑导航（剧名 · 季 · 集号）
   - 标题 + 元信息 + 描述
   - 剧集信息卡片
   - 演员横滑列表
3. 右栏（360px，sticky）：
   - 控制面板背景：`AppColors.nebulaDark` + `borderLight` 边框 + `radiusLg` 圆角
   - 媒体源下拉选择器（inline dropdown，非 bottom sheet）
   - 音频下拉选择器
   - 字幕下拉选择器
   - 渐变播放按钮
4. 创建 `MediaSourceSelector` 自定义下拉组件
5. 运行 `flutter analyze` 确认无错误

**Commit:** `✨ feat: EpisodeDetailScreen 双栏布局 + inline 下拉选择器`

---

### Task 2.3: 创建自定义下拉选择器组件

**Objective:** 创建设计稿中的自定义下拉选择器（用于媒体源/音频/字幕）。

**Files:**
- Create: `app/lib/widgets/aether_dropdown.dart`

**Steps:**
1. 创建 `AetherDropdown` StatefulWidget
2. Props: `label`（标题）, `options`（选项列表）, `selectedIndex`, `onChanged`
3. UI 结构：
   - 触发器：`AppColors.stardust` 背景 + `borderLight` 边框 + 右侧箭头图标
   - 菜单：`AppColors.stardust` 背景 + `borderLight` 边框 + `boxShadow`
   - 选项：hover 变 `surfaceHover`，选中变 `accentSoft` + 蓝色文字 + check 图标
4. 动画：菜单 `opacity` + `translateY(-4px)` → `translateY(0)`
5. 点击外部自动关闭
6. 运行 `flutter analyze` 确认无错误

**Commit:** `✨ feat: 创建 AetherDropdown 自定义下拉选择器`

---

### Task 2.4: 优化 SeriesDetailScreen 剧集列表

**Objective:** 按设计稿优化剧集列表样式，添加面包屑和播放按钮功能。

**Files:**
- Modify: `app/lib/screens/series_detail_screen.dart`

**Steps:**
1. 确保剧集列表项样式匹配设计稿：
   - 编号：DM Mono 字体，`textTertiary` 色
   - 缩略图：130px 宽，16:9，圆角 `radiusSm`
   - hover 时显示播放图标 overlay
   - 标题 + 描述（2 行截断）+ 时长
2. 实现播放按钮功能（替代 TODO）
3. 确保季节 Tab 下划线渐变动画匹配设计稿
4. 运行 `flutter analyze` 确认无错误

**Commit:** `🎨 style: 优化 SeriesDetailScreen 剧集列表样式`

---

### Task 2.5: 优化 HomeTab 分区标题和卡片

**Objective:** 确保首页分区标题和卡片样式严格匹配设计稿。

**Files:**
- Modify: `app/lib/screens/home_tab.dart`

**Steps:**
1. 分区标题：左侧图标（Material Symbols，accent 色）+ 标题文字 + 右侧 "查看全部 →"
2. 卡片 hover 效果：`translateY(-6px)` + `scale(1.03)` + 蓝色发光阴影
3. 卡片底部渐变叠加：`linear-gradient(to top, deepVoid 0%, transparent 60%)`
4. 卡片标题：`textPrimary`，年份：DM Mono + `textTertiary`
5. 媒体库网格：16:9 比例，渐变背景 + 图标 + 名称 + 部数
6. 运行 `flutter analyze` 确认无错误

**Commit:** `🎨 style: 优化 HomeTab 分区标题和卡片样式`

---

### Task 2.6: 实现设置弹窗模式

**Objective:** 将设置从全屏页面改为设计稿中的弹窗覆盖层模式。

**Files:**
- Modify: `app/lib/screens/settings_tab.dart` → 改为 `app/lib/widgets/settings_modal.dart`
- Modify: `app/lib/screens/shell_screen.dart` (触发方式)

**Steps:**
1. 创建 `SettingsModal` StatelessWidget（从 SettingsTab 重构）
2. UI 结构（设计稿）：
   - 覆盖层：`Colors.black54` + `BackdropFilter(blur: 6)`
   - 弹窗：520px 宽，`AppColors.bgSecondary` 背景，`radiusXl` 圆角
   - 头部：标题 + 关闭按钮
   - 内容：分组设置（播放/外观/网络）
   - 每组：标题（accent 色）+ 设置行（标签 + 描述 + toggle/值）
3. 动画：`scale(0.95) → scale(1)` + `translateY(12px) → translateY(0)`
4. 点击覆盖层关闭
5. 在 ShellScreen 中，设置按钮改为弹出 SettingsModal
6. 运行 `flutter analyze` 确认无错误

**Commit:** `✨ feat: 设置改为弹窗模式`

---

### Task 2.7: 实现搜索弹窗增强

**Objective:** 确保搜索弹窗严格匹配设计稿（居中弹窗 + 毛玻璃）。

**Files:**
- Modify: `app/lib/widgets/search_overlay.dart`

**Steps:**
1. 确认 backdrop 使用 `Colors.black54` + `BackdropFilter(blur: 8)`
2. 搜索框：560px 宽，`AppColors.stardust` 背景，`borderLight` 边框，`radiusLg` 圆角
3. 搜索图标：`AppColors.celestialCyan`
4. 输入框：`textPrimary` 文字，`textTertiary` placeholder
5. 提示文字："输入关键词开始搜索，或按 Esc 关闭"
6. 动画：`translateY(-12px) + scale(0.97)` → `translateY(0) + scale(1)`
7. 运行 `flutter analyze` 确认无错误

**Commit:** `🎨 style: 优化搜索弹窗匹配设计稿`

---

## Phase 3: Phone 响应式布局

### Task 3.1: Phone 底部导航栏

**Objective:** 实现设计稿中的 Phone 底部导航栏（4 个 Tab）。

**Files:**
- Modify: `app/lib/screens/shell_screen.dart`

**Steps:**
1. 在 compact 模式（<720px）下使用底部导航栏
2. 4 个 Tab：主页 / 媒体库 / 搜索 / 设置
3. 图标：Material Symbols Rounded，active 状态 FILL=1
4. active 颜色：`AppColors.celestialCyan`
5. 背景：`AppColors.nebulaDark` + `backdropFilter: blur(12)` + 顶部 border
6. safe-area 适配：`env(safe-area-inset-bottom)`
7. 搜索 Tab 点击弹出 SearchOverlay
8. 运行 `flutter analyze` 确认无错误

**Commit:** `✨ feat: Phone 底部导航栏（4 Tab）`

---

### Task 3.2: Phone Mini 播放条

**Objective:** 实现设计稿中的 Phone 底部悬浮迷你播放器。

**Files:**
- Create: `app/lib/widgets/mini_play_bar.dart`
- Modify: `app/lib/screens/shell_screen.dart` (集成)

**Steps:**
1. 创建 `MiniPlayBar` StatefulWidget
2. UI 结构（设计稿）：
   - 位置：底部导航栏上方，左右 margin 12px
   - 背景：`AppColors.stardust` + `borderLight` 边框 + `radiusMd` 圆角
   - 内容：小海报（36px）+ 标题 + 集信息 + 播放/关闭按钮
   - 阴影：`boxShadow` + 蓝色微光
3. 动画：从底部滑入
4. 播放按钮：`AppColors.celestialCyan` 图标
5. 关闭按钮：隐藏播放条
6. 集成到 ShellScreen，当有播放内容时显示
7. 运行 `flutter analyze` 确认无错误

**Commit:** `✨ feat: Phone Mini 播放条`

---

### Task 3.3: Phone 媒体库页面

**Objective:** 实现设计稿中的 Phone 媒体库页面（网格布局）。

**Files:**
- Create: `app/lib/screens/phone_library_screen.dart`

**Steps:**
1. 创建 `PhoneLibraryScreen` StatelessWidget
2. 顶部：返回按钮 + 库名称
3. 内容：3 列网格，每项 120px 宽的媒体卡片
4. 卡片样式匹配设计稿：2:3 海报 + 底部渐变 + 标题 + 年份
5. 点击进入详情页
6. 在 ShellScreen 的 "媒体库" Tab 中显示
7. 运行 `flutter analyze` 确认无错误

**Commit:** `✨ feat: Phone 媒体库页面`

---

### Task 3.4: Phone 详情页适配

**Objective:** 确保详情页在 Phone 上的布局匹配设计稿。

**Files:**
- Modify: `app/lib/screens/series_detail_screen.dart`
- Modify: `app/lib/screens/episode_detail_screen.dart`

**Steps:**
1. Phone 详情页布局（设计稿）：
   - 全宽封面图（16:9）+ 底部渐变
   - 海报（100px，2:3）+ 信息区
   - 描述文字
   - 剧集列表（紧凑样式）
2. 确保 `< 1200px` 时使用单栏布局
3. 海报边框：`2px solid rgba(0,212,255,0.12)`
4. 运行 `flutter analyze` 确认无错误

**Commit:** `🎨 style: Phone 详情页布局适配`

---

## Phase 4: Android TV

### Task 4.1: TV Featured 大图

**Objective:** 实现设计稿中的 TV Featured 推荐横幅。

**Files:**
- Modify: `app/lib/screens/tv_home_screen.dart`

**Steps:**
1. Featured 横幅样式（设计稿）：
   - 比例：21:9
   - 圆角：`radiusXl`
   - 背景：媒体渐变
   - 左侧渐变遮罩（从左到右 88%→40%→透明）
   - 内容：推荐标签 + 标题 + 描述 + 播放按钮
2. 播放按钮：`accentGradient` 背景 + 圆角 28px
3. hover/focus 效果：`scale(1.01)` + 蓝色边框 + 发光
4. 运行 `flutter analyze` 确认无错误

**Commit:** `✨ feat: TV Featured 推荐横幅`

---

### Task 4.2: TV 焦点导航系统

**Objective:** 实现完整的 TV D-Pad 焦点导航系统。

**Files:**
- Modify: `app/lib/screens/tv_home_screen.dart`
- Create: `app/lib/widgets/tv_focusable_card.dart`

**Steps:**
1. 创建 `TvFocusableCard` 组件：
   - `FocusNode` 管理
   - focus 状态：`scale(1.08)` + `border: 3px solid celestialCyan` + 发光阴影
   - D-Pad 方向键导航
2. TV 卡片样式（设计稿）：
   - 190px 宽，2:3 海报
   - hover/focus：`scale(1.08)` + 蓝色边框 + 发光
3. TV 媒体库卡片：
   - 260px 宽，16:9
   - hover/focus：`scale(1.05)` + 蓝色边框 + 发光
4. 实现 `FocusTraversalGroup` 确保焦点在行内正确移动
5. 实现跨行焦点导航
6. 运行 `flutter analyze` 确认无错误

**Commit:** `✨ feat: TV D-Pad 焦点导航系统`

---

### Task 4.3: TV Tab 内容切换

**Objective:** 实现 TV 顶部 Tab 的内容切换功能。

**Files:**
- Modify: `app/lib/screens/tv_home_screen.dart`

**Steps:**
1. 主页 Tab：Featured + 最近更新 + 媒体库 + 热门动漫
2. 电影 Tab：仅显示电影库内容
3. 剧集 Tab：仅显示剧集库内容
4. 动漫 Tab：仅显示动漫库内容
5. 设置 Tab：显示设置页面
6. Tab 切换时内容区域有 fadeIn 动画
7. 运行 `flutter analyze` 确认无错误

**Commit:** `✨ feat: TV Tab 内容切换`

---

### Task 4.4: TV 搜索功能

**Objective:** 实现 TV 搜索界面。

**Files:**
- Modify: `app/lib/screens/tv_home_screen.dart`
- Create: `app/lib/widgets/tv_search_overlay.dart`

**Steps:**
1. 创建 `TvSearchOverlay` 全屏覆盖层
2. 顶部搜索输入框（支持 D-Pad 虚拟键盘或外接键盘）
3. 搜索结果网格（匹配 TV 卡片样式）
4. 焦点导航支持
5. ESC 键关闭
6. 运行 `flutter analyze` 确认无错误

**Commit:** `✨ feat: TV 搜索界面`

---

## Phase 5: 交互细节与打磨

### Task 5.1: 鼠标拖拽滚动

**Objective:** 为所有横向滚动区域添加鼠标拖拽滚动支持。

**Files:**
- Modify: `app/lib/widgets/scroll_arrows.dart` (增强)

**Steps:**
1. 在 `ScrollArrows` 中添加拖拽滚动逻辑：
   - `onMouseDown`：记录起始位置
   - `onMouseMove`：计算偏移量，更新 scrollOffset
   - `onMouseUp`：结束拖拽
2. 拖拽时鼠标变为 `grabbing`
3. 拖拽时禁用 scroll-snap
4. 适用于所有使用 `ScrollArrows` 的地方
5. 运行 `flutter analyze` 确认无错误

**Commit:** `✨ feat: 横向滚动区域支持鼠标拖拽`

---

### Task 5.2: 动画效果增强

**Objective:** 为页面切换和交互动画添加设计稿中的效果。

**Files:**
- Modify: `app/lib/widgets/aether_page_route.dart`
- Modify: 各 screen 文件

**Steps:**
1. 页面切换动画（设计稿 `vIn` keyframe）：
   - `opacity: 0 → 1`
   - `translateY(10px) → translateY(0)`
   - duration: 400ms
2. 列表项逐个出现（stagger animation）：
   - 每项延迟 50ms
   - 使用 `AnimationController` + `Interval`
3. 卡片 hover 动画：
   - `cubic-bezier(0.4, 0, 0.2, 1)` 缓动
   - duration: 350ms
4. 运行 `flutter analyze` 确认无错误

**Commit:** `✨ feat: 页面切换和交互动画增强`

---

### Task 5.3: 全局毛玻璃效果

**Objective:** 确保所有需要毛玻璃效果的组件使用 backdropFilter。

**Files:**
- Modify: `app/lib/widgets/glass_panel.dart` (检查)
- Modify: 各 screen 中的 AppBar/BottomNav

**Steps:**
1. 检查所有 AppBar 是否使用透明背景 + 毛玻璃
2. 检查底部导航栏是否使用 `backdropFilter: blur(24)`
3. 检查弹窗覆盖层是否使用 `backdropFilter: blur(6-8)`
4. 确保 `GlassPanel` 的 `navBar` 变体用于所有导航栏
5. 运行 `flutter analyze` 确认无错误

**Commit:** `🎨 style: 全局毛玻璃效果统一`

---

### Task 5.4: Settings 持久化

**Objective:** 为设置项添加 SharedPreferences 持久化。

**Files:**
- Modify: `app/lib/screens/settings_tab.dart` (或 `settings_modal.dart`)
- Create: `app/lib/services/settings_service.dart`

**Steps:**
1. 创建 `SettingsService`：
   - `autoPlayNext`: bool (默认 true)
   - `hardwareAcceleration`: bool (默认 true)
   - `noiseTexture`: bool (默认 true)
   - `animations`: bool (默认 true)
   - `remoteAccess`: bool (默认 false)
   - `bandwidthLimit`: String (默认 'auto')
2. 使用 `shared_preferences` 包
3. 在 SettingsTab/Modal 中读取和写入设置
4. 在 App 启动时读取设置并应用（如噪声纹理开关）
5. 运行 `flutter analyze` 确认无错误

**Commit:** `✨ feat: 设置项 SharedPreferences 持久化`

---

### Task 5.5: i18n 国际化补充

**Objective:** 将所有硬编码中文替换为 i18n 翻译。

**Files:**
- Modify: 所有 screen 和 widget 文件中的硬编码中文字符串
- Modify: `app/lib/i18n/strings_zh_CN.g.dart`
- Modify: `app/lib/i18n/strings_en.g.dart`

**Steps:**
1. 搜索所有硬编码中文字符串
2. 在 i18n 文件中添加翻译条目
3. 替换所有硬编码为 `t.xxx` 调用
4. 确保中英文翻译完整
5. 运行 `flutter analyze` 确认无错误

**Commit:** `🌐 i18n: 补充所有硬编码中文的国际化翻译`

---

## 验证清单

每个 Phase 完成后执行：

```bash
# 1. 静态分析
cd /home/altair/workspace/Aether/app && flutter analyze

# 2. 构建测试
flutter build linux

# 3. 视觉对比
# 打开 aether_celestial_glow_ui.html 设计稿
# 逐页对比 Flutter 应用的每个页面
# 确认：颜色、间距、圆角、字体、动画、交互
```

## 风险与注意事项

1. **Phone 布局**：设计稿中 Phone 是独立布局，但当前 ShellScreen 用 compact 模式处理。可能需要为 Phone 创建独立的 ShellScreen 变体。

2. **TV 焦点系统**：Flutter 的焦点系统在 TV 上较复杂，需要充分测试 D-Pad 导航的焦点陷阱和焦点回环。

3. **性能**：毛玻璃效果 (`BackdropFilter`) 在低端设备上可能有性能问题。GlassPanel 已有 blur enable/disable 开关，确保在设置中可关闭。

4. **i18n 工具**：项目使用 slang 包生成 i18n，修改翻译文件后需要运行 `dart run slang` 重新生成。

5. **图片代理**：多个屏幕硬编码了 `localhost:19800`，应统一从 `StorageService` 读取。

---

## 时间估算

| Phase | Tasks | 预估时间 |
|-------|-------|---------|
| Phase 1: Widget 修复 | 8 tasks | 2-3 小时 |
| Phase 2: Desktop 核心 | 7 tasks | 4-5 小时 |
| Phase 3: Phone 布局 | 4 tasks | 3-4 小时 |
| Phase 4: Android TV | 4 tasks | 3-4 小时 |
| Phase 5: 交互打磨 | 5 tasks | 2-3 小时 |
| **总计** | **28 tasks** | **14-19 小时** |
