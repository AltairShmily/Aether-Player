# Aether Player — UI 改造实施计划

> 依据：`docs/ui_prototypes/` 下三份原型文档
> 基准：`dev` 分支 commit `08a8fde`（本文所有行号均已在该 commit 上核准）
> 编制日期：2026-09-11
> 配套：`docs/reports/BUG_REPORT.md`、`docs/ui_gap_analysis.md`、`docs/design_spec_celestial_glow.md`

---

## 一、文档定位

`docs/ui_prototypes/` 下三份文档各有分工，本文不重复其内容，只做**落地前的核查与施工编排**：

| 文档 | 性质 | 本文如何使用 |
|:--|:--|:--|
| `aether_ui_prototypes.html` | 12 页原型（几乎全为 happy path） | 视觉目标参照 |
| `aether_ui_prototypes_v2_sample.html` | 对上者的**结构批评** + 组件图例建议 | 提取 OPT-01「先建词典再画页面」作为 Phase 0 依据 |
| `aether_ui_fix_lib_series_player.html` | 媒体库/剧集/播放三页的**可落地改造规格**，含 P0–P2 与源码锚点 | 主要施工蓝本 |

**核查结论：规格可信。** 其引用的四处源码锚点在当前 `dev`（已含前两轮修复）上**逐一精确命中**：

| 规格锚点 | 当前代码 | 状态 |
|:--|:--|:--|
| `phone_library_screen.dart:200` 库卡副文案写死 | `'点击查看',` | ✅ 行号一致 |
| `series_detail_screen.dart:499` 主按钮播第一集 | `_onEpisodeTap(_episodes.first.primary);` | ✅ 行号一致 |
| `series_detail_screen.dart:683–722` 横向预览重复 | `:690` `itemCount: _episodes.length.clamp(0, 10)` | ✅ 落在区间内 |
| `player_page.dart:1106–1109` 倍速点击循环 | `:1106` `final speeds = state.speedOptions;` | ✅ 行号一致 |

---

## 二、现状核查：组件漂移的真实规模

规格提到「组件收敛」「避免两套并行漂移」，v2_sample 的 OPT-01 要求「先建词典，再画页面」。实测数据比文档描述的更严重：

### 2.1 共享组件存在，但全部是死代码

| 组件 | 被导入次数 | 说明 |
|:--|:--|:--|
| `widgets/media_card.dart` | **0** | 含 `MediaCard` 与 `SearchHintCard` |
| `widgets/video_osd.dart` | **0** | 桌面 OSD，规格要求把手机 OSD 下沉至此 |
| `widgets/skeleton_loader.dart` | **0** | 已提供 `AetherSkeleton` / `AetherHomeSkeleton` / `AetherDetailSkeleton` |
| `widgets/genre_chip.dart` | **0** | — |
| `widgets/mini_play_bar.dart` | **0** | — |

对照之下，`aether_progress.dart`（3）、`pill_button.dart`（2）、`meta_chip.dart`（3）、`diamond_badge.dart`（2）是**在用**的——说明问题不在"没人写组件"，而在特定几个组件不可用。

### 2.2 根因：共享卡片组件的图片请求是坏的

`MediaCard._PosterSection`（`media_card.dart:204`）与 `SearchHintCard`（`:344` 附近）的图片请求：

```dart
headers: const {'Accept': 'image/*'},   // ← 只有 Accept
```

而 Go 侧 `library.go:117` 的 `HandleGetItemImage` 依赖 `X-Emby-Server` 定位上游：

```go
serverURL := r.Header.Get("X-Emby-Server")   // 缺失 → 空串
body, contentType, err := h.EmbyClient.GetItemImage(serverURL, token, ...)
```

`serverURL` 为空时上游 URL 退化为相对路径 `/Items/{id}/Images/Primary`，`http.NewRequest` 直接失败 → **502**。

**因此这两个组件从诞生起就无法显示任何图片**，被各页放弃、转为内联实现，最终沦为死代码。这是"组件漂移"的真正起点，而非设计规范分歧。

### 2.3 内联实现的规模

`app/lib/screens/` 下共 **20 处** `Image.network`，**8 个文件**各自实现海报卡（`home_tab`、`series_detail_screen`、`media_detail_screen`、`episode_detail_screen`、`audio_player_page`、`phone_library_screen`、`tv_search_overlay`、`tv_home_screen`）。

### 2.4 核查中新发现：TV 模式图片全部损坏

排查内联实现时，发现 3 处图片请求**完全没有 headers**：

| 位置 | 内容 | 后果 |
|:--|:--|:--|
| `tv_home_screen.dart:750` | featured 横幅背景图 | 502，回退到渐变占位 |
| `tv_home_screen.dart:1111` | 媒体行海报 | 502，回退到占位图标 |
| `tv_search_overlay.dart:281` | TV 搜索结果海报 | 502，回退到占位 |

即 **TV 模式下所有图片都不显示**，用户只会看到占位块。此前三轮修复均未覆盖（第二轮修的是 `tv_home_screen` 的 URL base 被覆盖问题，未查 headers）。

**正确范式已存在于代码库中**：`audio_player_page.dart:221` 通过 `widget.imageHeaders` 由调用方注入。共享组件应采用同一模式。

### 2.5 一个必须写进组件契约的约束

第二轮修复发现：`NetworkImage` 的 `operator==` **只比较 `url` 与 `scale`，不比较 `headers`**。因此若组件在 headers 就绪前先渲染图片，请求失败后即使 headers 补上，widget 也认为 provider 未变化、不会重新解析，图片将**永久停留在失败态**。

已在 `series_detail_screen` / `episode_detail_screen` 用 build 入口门控修复。共享组件必须把这一约束固化进契约，否则每个调用方都要重复踩坑。

---

## 三、施工顺序

规格给出的 P0/P1/P2 是按**页面**划分的。但基于 §2 的核查，若按页面推进，评分角标、骨架、四态、hover 播放钮等会在 8 个文件里各写一遍，且 TV 图片损坏这类问题会继续遗漏。

**因此调整为：Phase 0 组件收敛前置，其余阶段在其之上施工。**

```
Phase 0  组件收敛（前置）      ← 新增，规格 OPT-01 / 组件收敛要求
   ↓     修好共享卡片 → 补齐缺失原子 → 各页改用共享组件
Phase 1  P0 三项（规格原序）
   ↓     剧集「接着看」· 播放器字幕一级入口 · 库卡数量文案
Phase 2  P1 四项
   ↓     剧集列表去重 · OSD 两行化 · 库筛选排序 · 三页四态
Phase 3  P2 两项
         跳过片头/缓冲段/错误卡片 · OSD 下沉 video_osd
```

---

## 四、Phase 0 — 组件收敛（前置，必须最先做）

### 0.1 修复共享卡片的图片头缺陷

**文件**：`app/lib/widgets/media_card.dart`

**改法**：为 `MediaCard` 与 `SearchHintCard` 增加 `imageHeaders` 参数，由调用方注入，与 `audio_player_page.dart:221` 的既有范式一致。

```dart
class MediaCard extends StatefulWidget {
  final MediaItem item;
  final VoidCallback onTap;
  final String Function(String, {String type, int? maxWidth}) imageUrlBuilder;

  /// 代理转发所需的头（X-Emby-Server / X-Emby-Token）。
  /// 缺失时图片请求会被本地代理拒绝（502）——这正是本组件此前沦为死代码的原因。
  final Map<String, String> imageHeaders;
  ...
}
```

**契约约束（写进文档注释）**：调用方必须保证 `imageHeaders` 在首次渲染时即已就绪。因 `NetworkImage` 的相等性不含 headers，事后补头不会触发重新解析（见 §2.5）。

**验证**：`flutter analyze`；在 `phone_library_screen` 接入后实机确认海报显示。

### 0.2 新增缺失原子：评分角标 + 海报进度条

**文件**：`app/lib/widgets/media_card.dart`（或新建 `widgets/rating_badge.dart`）

规格要求「海报卡右上评分角标（有 Rating 时）」。当前 8 处内联实现均无此元素。

```dart
/// 海报右上角评分角标 —— 仅在评分有效时渲染
class RatingBadge extends StatelessWidget {
  final double rating;
  const RatingBadge({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    if (rating <= 0) return const SizedBox.shrink();   // 无评分不占位
    ...
  }
}
```

同时给 `MediaCard` 增加可选 `progress`（0–1），用于「继续观看」卡片的底部进度条；数据源为 `MediaItem.userData.playbackPositionTicks` / `runTimeTicks`。

**复用而非新建**：进度条应调用已在用的 `aether_progress.dart`（3 处导入，是活组件），不要再写一份。

### 0.3 各页改用共享卡片

按「本次已要改动的页面优先」原则分批接入，避免一次性重构 8 个文件带来的视觉回归风险：

| 批次 | 文件 | 理由 |
|:--|:--|:--|
| 第 1 批 | `phone_library_screen.dart`（2 处内联卡） | Phase 1 的库卡文案与 Phase 2 的筛选/评分角标都要改这里 |
| 第 1 批 | `tv_search_overlay.dart:281`、`tv_home_screen.dart:750,1111` | 修复 §2.4 的图片损坏 |
| 第 2 批 | `home_tab.dart`（2 处） | 首页是主入口，改动需单独回归 |
| 第 3 批 | `series_detail_screen.dart`、`media_detail_screen.dart`、`episode_detail_screen.dart` | 详情页布局特殊（海报与 hero 重叠），风险最高，最后动 |

**同时清理我自己引入的重复**：第二轮实现搜索时在 `home_tab.dart` 内联写了 `_SearchResultTile`，而 `SearchHintCard` 就在同一组件库里无人使用。两者布局不同（列表行 vs 海报卡），需判断是合并还是各自保留——若保留，应抽出共享的缩略图与类型标签原子，而不是各写一份。

### 0.4 四态复用既有骨架组件

`skeleton_loader.dart` 已提供 `AetherSkeleton` / `AetherHomeSkeleton` / `AetherDetailSkeleton`，**Phase 2 的四态补齐必须复用它们**，不得新写。这是 OPT-01「先建词典」的直接体现。

---

## 五、Phase 1 — P0 三项

### 1.1 剧集页主按钮改为「接着看」

**文件**：`series_detail_screen.dart:491–502`（当前 `_buildTitleSection` 内的 `PillButton`）

**现状**：`:499` 无条件播 `_episodes.first.primary`，注释还留着 `// TODO: Start playing first unwatched episode or first episode`。

**算法（照抄规格备注）**：
1. 取当前季 `episodes` 中 `userData.playbackPositionTicks > 0` 且 `!played` 的**最后一集**
2. 若无 → 第一个未看完的集
3. 再无 → 当前季 E01

**按钮文案**：有进度 → `继续播放 S01E03`；无进度 → `播放 S01E01`。集号用 `MediaItem.episodeLabel`（已存在）。

**成本**：低。数据全部已在 `_episodes`（`MergedEpisode.primary.userData`）中，无需新请求。

### 1.2 播放器字幕一级入口 + 语言角标

**文件**：`player_page.dart` 的 `_PlayerControlsOverlay`（底栏右侧，`:1070` 附近）

**现状**：字幕藏在设置弹窗列表里，底栏看不到当前字幕语言。

**改法**：底栏加字幕按钮，旁边显示当前语言短标签（中 / 英 / 关）。

**数据已就绪**：`state.subtitleTracks`（`TrackInfo.language`）与 `state.currentSubtitleTrack` 均已在 `PlayerUiState` 中；第二轮已修好轨道列表为空的问题（新增 `tracksStream`），因此这里能拿到真实数据。

**关联**：第二轮修复的是字幕**链路**（外挂字幕 `DeliveryUrl` 接通），本项修的是**可发现性**——用户此前根本看不到入口。两者互补，缺一则字幕功能仍不可用。

### 1.3 库卡数量文案

**文件**：`phone_library_screen.dart:200`（`_buildLibCard`）

**现状**：副文案写死 `'点击查看'`，不传达任何信息。

**改法**：改为「N 部」。

**数据来源（零额外请求）**：`home_provider._loadLibraryItems` 已在为每个库调用 `getItems`，而 `ItemListResponse` **本身就带 `totalRecordCount`**。只需在 `HomeState` 增加 `libraryCounts` 映射并顺手记录，无需新增请求或后端端点。

**与规格的偏差**：规格要求「128 部 · 12 未看」。**「未看」数本轮不做** —— 需要按库发 `IsPlayed=false` 查询，而 Go 侧 `GetItems` 的参数白名单（`client.go` 的 `GetItems` 字段映射表）不含该过滤条件，须先改后端并新增 N 次请求。建议作为独立决策项（见 §8）。

---

## 六、Phase 2 — P1 四项

### 2.1 剧集列表去重：横向预览 → 继续观看条

**文件**：`series_detail_screen.dart:683–722`（`:690` `clamp(0, 10)`）

**现状**：横向 10 张预览卡 + 纵向全量列表，同一批剧集展示两遍，首屏被横向行吃掉。

**改法**：
- 横向行改为「继续观看条」：仅取有进度的 1–3 集，卡片带进度
- 纵向列表保留全量，加已看勾 + 当前集左侧 2px 青色高亮
- 复用 Phase 0.2 的 `progress` 能力，不另写进度条

### 2.2 播放 OSD 两行化 + 倍速直选

**文件**：`player_page.dart` `_PlayerControlsOverlay`（`:980–1110`）、`_ProgressBar`

**现状**：底栏所有控件挤在一行（`:980–1110`）；倍速是点击循环（`:1106`），无法直选 1.5x；音量滑条固定宽 70。

**改法**（照规格）：
- 行 1：进度条（h4 + 缓冲段 + 拖动预览时间）
- 行 2：左 = 退10 / 播放52 / 进30 / 下一集；右 = 字幕 / 音量 / 倍速 / 画质 / 更多
- 倍速改为 Chip 直选菜单（0.5–2.0），当前值常显
- 音量滑条宽度 `min(120, 20%)`，点图标切静音

**注意**：第二轮已把进度条抽成独立的 `_ProgressBar` 并实现拖动节流（松手才 seek），本项在其基础上加缓冲段与 h4，**不要推翻重做**。

### 2.3 库内容页筛选 Chip + 排序

**文件**：`phone_library_screen.dart` 的 `_LibraryContentPage`

**改法**：顶栏加类型 Chip（全部 / 电影 / 剧集 / 4K / 未看）+ 排序（最近添加 / 名称 / 年份）。

**依赖（已核实）**：排序与筛选所需的参数链路**已经打通**，无需改动前后端接口——
`ApiClient.getItems` 已透出 `sortBy`（默认 `DateCreated`）、`sortOrder`（默认 `Descending`）、`includeItemTypes`、`parentId` 四个参数，Go 侧 `GetItems` 的字段映射表也含对应的 `SortBy` / `SortOrder` / `IncludeItemTypes` / `ParentId`。因此本项是纯前端工作。

**已知问题**：`_LibraryContentPage`（`:140` 附近）用 `ref.read` 取快照传 items，非响应式；本次改造应一并改为 `ref.watch`。

### 2.4 三页四态补齐

**范围**：媒体库 / 剧集 / 播放三页的 骨架 / 空 / 错误 / 正常。

**现状锚点**：
- `series_detail_screen.dart:554`（空季）与 `:639`（空集）均为 `SizedBox.shrink()`，用户无法区分"没数据"与"没请求到"
- `series_detail_screen.dart:631` 加载态只有一个居中转圈

**改法**：一律复用 `skeleton_loader.dart` 的既有组件（Phase 0.4），空态给文案 + 刷新，错误态给原因 + 重试（并提示检查 `aether-server`）。

---

## 七、Phase 3 — P2 两项

| 项 | 内容 | 文件 |
|:--|:--|:--|
| 跳过片头 / 缓冲段 / 错误卡片 | 有 `IntroMarker` 时进度条上方出现「跳过片头」胶囊（8s 自动淡出）；缓冲显示百分比；错误改**居中卡片** + 重试/切换画质/返回三动作（当前是底部提示条，与 OSD 抢层） | `player_page.dart` |
| OSD 下沉到 `video_osd.dart` | 把稳定后的 `_PlayerControlsOverlay` 下沉到 `widgets/video_osd.dart`，桌面与手机共用、只换布局密度，消除两套并行实现 | `video_osd.dart`（当前 0 导入） |

**顺序理由**：必须先做 Phase 2.2 把 OSD 改稳定，再下沉。若先下沉再改，会在两个文件间来回搬运。

**跳过片头的前置条件**：Emby 的 `IntroMarkers` 需要 `getPlaybackInfo` 或独立 `/Items/{id}/IntroTimestamps` 端点，当前 Go 侧**没有**对应 handler，需先加后端支持。若不做后端，此项应降级或搁置。

---

## 八、待决策项

| 项 | 问题 | 建议 |
|:--|:--|:--|
| **「未看」计数** | 需 Go 侧 `GetItems` 支持 `IsPlayed` 过滤，并为每个库多发一次请求（N 库 = N 请求），拖慢首屏 | 本轮只做总数；若确需未看数，建议新增 Go 批量端点一次返回各库计数，而非 N 次请求 |
| **`SearchHintCard` vs `_SearchResultTile`** | 一个是海报卡、一个是列表行，布局确实不同 | 倾向保留两者但抽出共享的缩略图/类型标签原子；若统一为一种布局则删掉另一个 |
| **详情页接入共享卡片的时机** | `series_detail` / `media_detail` / `episode_detail` 的海报与 hero 存在重叠定位，接入共享卡片风险最高 | 放第 3 批，且每批单独提交 + 实机回归 |
| **`mini_play_bar.dart` / `genre_chip.dart`** | 均为 0 导入死代码 | 需产品决策：补入口还是删除。`mini_play_bar` 与「退出播放最小化」体验相关，倾向补入口；`genre_chip` 已有 `AetherChip.genre` 在用，倾向删除 |

---

## 九、提交划分

遵循 Conventional Commits + 中文 + emoji，与仓库既有风格一致：

| # | Commit | 阶段 |
|:--|:--|:--|
| 1 | `🐛 fix: 修复共享卡片组件图片头缺失导致的 502` | 0.1 |
| 2 | `✨ feat: 新增评分角标与海报进度条原子组件` | 0.2 |
| 3 | `♻️ refactor: 媒体库与 TV 页改用共享 MediaCard` | 0.3 第 1 批 |
| 4 | `🐛 fix: 修复 TV 模式图片全部无法加载` | 0.3（§2.4） |
| 5 | `✨ feat: 剧集主按钮改为按进度续播` | 1.1 |
| 6 | `✨ feat: 播放器底栏新增字幕一级入口与语言角标` | 1.2 |
| 7 | `✨ feat: 媒体库卡片显示条目数量` | 1.3 |
| 8 | `♻️ refactor: 剧集列表去重为继续观看条` | 2.1 |
| 9 | `🎨 style: 播放 OSD 两行化与倍速直选` | 2.2 |
| 10 | `✨ feat: 媒体库内容页筛选与排序` | 2.3 |
| 11 | `✨ feat: 三页补齐骨架/空/错误四态` | 2.4 |
| 12 | `✨ feat: 播放器跳过片头与错误卡片` | 3 |
| 13 | `♻️ refactor: OSD 下沉到 video_osd 供桌面复用` | 3 |
| 14 | `♻️ refactor: 首页与详情页接入共享卡片` | 0.3 第 2–3 批 |

提交 3/4 与 14 的顺序可与 Phase 1/2 交错，以「每次提交后 `flutter analyze` + `flutter test` 必须通过」为约束。

---

## 十、验证方式

| 层级 | 手段 | 说明 |
|:--|:--|:--|
| 静态 | `flutter analyze` | 当前基线为 0 issues，每个提交后必须保持 |
| 单测 | `flutter test` | 当前 21 个用例；Phase 1.1 的「接着看」算法应补纯函数单测（进度选集是易错逻辑） |
| 后端 | `go vet` / `go test` / 三平台交叉编译 | 若 §8 决定加 `IsPlayed` 或批量计数端点则需跑 |
| 实机 | 图片加载、hover 微交互、TV 焦点环、四态切换 | **无法自动化**，需人工验证；TV 模式图片修复（提交 4）尤其需要实机确认 |

**风险提示**：Phase 0 触碰 8 个文件的图片渲染路径，属高可见度改动。务必分批提交并在每批后实机检查，不要一次性替换全部内联卡片。

---

## 十一、明确不做（本轮范围外）

| 项 | 原因 |
|:--|:--|
| 像素级对齐 `design_spec_celestial_glow.md` | `ui_gap_analysis.md` 已详列 260 行偏差，属独立专项；本文只处理结构性与可用性问题 |
| i18n 文案迁移 | 新增文案（如「继续播放 SxxExx」「暂无演职人员信息」）会沿用现有硬编码中文风格，全量 i18n 仍是独立专项 |
| 无障碍（Semantics） | `reports/OPTIMIZATION_REPORT.md` §6 已列，需设计规范配合 |
| 侧栏导航架构重构 | 即 `TODO_UI_ISSUES.md` 问题 3，需重构 `ShellScreen` 页面栈，风险独立 |
| 原生 C++ 引擎 FFI 重构 | 见 `reports/BUG_REPORT.md` BUG-006，本机无 libmpv 无法验证 |
