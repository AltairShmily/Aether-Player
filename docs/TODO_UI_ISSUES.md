# UI 问题待办清单

> 更新时间：2026-05-27
> 状态：待修复

---

## 问题 1: 剧集详情页返回按钮被遮挡

**描述：** SeriesDetailScreen 的返回按钮在 hero 图片区域，但被最上层的图片遮挡住了，用户看不到也点不到。

**影响范围：** Desktop + Phone 的剧集详情页

**预期行为：** 返回按钮应始终可见且可点击，位于 hero 图片左上角

**可能原因：**
- Stack 层级问题：返回按钮的 Positioned 没有设置较高的 z-index
- hero 图片的 ClipRRect 或 Stack 可能覆盖了按钮

**修复方向：**
- 将返回按钮移到 Stack 的最顶层
- 或使用 Stack 的 `clipBehavior: Clip.none` 确保按钮不被裁剪
- 或将返回按钮放在 SliverAppBar 的 leading 属性中（如果使用 SliverAppBar）

**文件：** `app/lib/screens/series_detail_screen.dart` (约 line 232)

---

## 问题 2: 剧集单集版本/音频/字幕下拉栏切换无效

**描述：** EpisodeDetailScreen 控制面板中的 AetherDropdown（媒体源/音频/字幕）切换选项后没有实际效果。

**影响范围：** Desktop 的剧集单集详情页

**预期行为：**
- 选择不同的媒体源 → 应切换播放源
- 选择不同的音频轨道 → 应切换音频
- 选择不同的字幕 → 应切换字幕

**可能原因：**
- AetherDropdown 的 onChanged 回调只是 setState 更新了 selectedIndex，但没有实际调用播放器 API
- 播放器引擎（MPV）的轨道切换逻辑未集成到 UI

**修复方向：**
- 在 onChanged 回调中调用播放器 API 切换轨道
- 需要集成 `playerProvider` 或 `PlayerEngine` 的轨道切换方法
- 临时方案：至少确保选中状态正确保存和显示

**文件：**
- `app/lib/screens/episode_detail_screen.dart` (约 line 811)
- `app/lib/widgets/aether_dropdown.dart`

---

## 问题 3: 媒体库/剧集/单集界面应保留左侧侧边栏

**描述：** 当用户从侧边栏点击媒体库图标进入媒体库界面，或点击内容进入剧集详情/单集详情时，左侧侧边栏应该始终显示（Desktop 模式下）。

**影响范围：** Desktop 模式（≥720px 宽度）

**预期行为：**
- Desktop 模式下，侧边栏始终可见
- 媒体库界面：左侧侧边栏 + 右侧媒体库内容
- 剧集详情页：左侧侧边栏 + 右侧详情内容
- 单集详情页：左侧侧边栏 + 右侧详情内容

**当前行为：**
- 点击媒体库卡片 → Navigator.push 打开新页面 → 侧边栏消失
- 点击媒体项 → Navigator.push 打开详情页 → 侧边栏消失

**修复方向：**
- 方案 A：使用 Navigator.pushReplacement 替换右侧内容区，保持侧边栏不变
- 方案 B：将侧边栏和内容区都放在 ShellScreen 中，通过状态管理切换内容
- 方案 C：使用 IndexedStack 或类似的 widget 在 ShellScreen 内管理所有页面层级
- 推荐方案 B/C：ShellScreen 维护页面栈，侧边栏始终渲染

**文件：**
- `app/lib/screens/shell_screen.dart`
- `app/lib/screens/phone_library_screen.dart`
- `app/lib/screens/series_detail_screen.dart`
- `app/lib/screens/episode_detail_screen.dart`
- `app/lib/screens/media_detail_screen.dart`

---

## 优先级

| 问题 | 优先级 | 复杂度 | 预估时间 |
|------|--------|--------|---------|
| 1. 返回按钮遮挡 | P0 | 低 | 15 分钟 |
| 2. 下拉栏切换无效 | P1 | 中 | 1-2 小时 |
| 3. 侧边栏保留 | P1 | 高 | 3-4 小时 |

## 备注

- 问题 3 涉及导航架构调整，可能需要重构 ShellScreen 的页面管理方式
- 问题 2 需要播放器引擎的轨道切换 API 支持
- 问题 1 可能是简单的 CSS/布局问题，快速修复
