# UI 问题待办清单

> 创建时间：2026-05-27
> 最近更新：2026-09-05
> 状态：问题 1 已修复；问题 2 部分推进；问题 3 待处理
> 更完整的缺陷清单与修复状态见 [`reports/BUG_REPORT.md`](reports/BUG_REPORT.md)

---

## 问题 1: 剧集详情页返回按钮被遮挡 ✅ 已修复

**描述：** SeriesDetailScreen 的返回按钮在 hero 图片区域，但被最上层的图片遮挡住了，用户看不到也点不到。

**影响范围：** Desktop + Phone 的剧集详情页

**预期行为：** 返回按钮应始终可见且可点击，位于 hero 图片左上角

**实际根因（与原推测不同）：**
排查发现返回按钮在 Stack 中已是最后一个子节点、z 序正确，并未被图片遮挡。
真正原因是整个 `Scaffold.body` 没有 `SafeArea`，hero 区从屏幕最顶端开始，
而按钮固定在 `top: 12`，因此落在状态栏 / 刘海下方被**系统 UI** 遮挡。

**修复方式：**
按钮纵向位置叠加状态栏高度（`top: 12 + MediaQuery.paddingOf(context).top`），
既保留 hero 背景边到边的视觉效果，又保证按钮始终处于可点击区域。

**文件：** `app/lib/screens/series_detail_screen.dart`

---

## 问题 2: 剧集单集版本/音频/字幕下拉栏切换无效 ⚠️ 部分修复

**描述：** EpisodeDetailScreen 控制面板中的 AetherDropdown（媒体源/音频/字幕）切换选项后没有实际效果。

**影响范围：** Desktop 的剧集单集详情页

**预期行为：**
- 选择不同的媒体源 → 应切换播放源
- 选择不同的音频轨道 → 应切换音频
- 选择不同的字幕 → 应切换字幕

**本轮已修复（音频 / 字幕链路）：**
- 音轨与字幕的选中索引默认为 `0`，而下拉选项与真实轨道 1:1 映射，
  导致"用户从未选择"与"用户选了第一条"无法区分：字幕被强制启用第一条，
  音轨又因 `> 0` 过滤把用户显式选中的第一条丢弃。已改为可空、以 `null` 表示未选择
- C++ 引擎以 `MPV_FORMAT_INT64` 设置 `aid` / `sid` 时传入的是 4 字节 `int`
  地址，属未定义行为，轨道切换静默失败。已改为 `int64_t`
- 播放器 UI 此前完全不随状态刷新，切换后也看不到反馈。已补状态监听

**仍未解决：**
- **媒体源下拉**：`_selectedSourceIndex` 从未传给 `PlayerPage`，切换播放源确实无效
- **原生引擎轨道列表恒为空**：`flutter_bridge.h` 未导出 tracks 回调，
  `_audioTracks` 永不填充，因此原生引擎下无从选择轨道
- 上述两项与「原生引擎 FFI 回调重构」相关，见
  [`reports/BUG_REPORT.md`](reports/BUG_REPORT.md) 的 BUG-006

**文件：**
- `app/lib/screens/episode_detail_screen.dart`
- `app/lib/widgets/aether_dropdown.dart`
- `engine/src/ffi/flutter_bridge.h`

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
