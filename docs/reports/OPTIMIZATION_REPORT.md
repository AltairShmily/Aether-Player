# Aether Player — 功能与 UI 界面优化报告

> 配套文档：`BUG_REPORT.md`、`FIX_PLAN.md`
> 本报告聚焦**功能完整度**与**用户体验**，不重复 `docs/ui_gap_analysis.md` 已覆盖的像素级设计规范偏差（该文档已详列 260 行 `Celestial Glow` 规范对齐项），而是补充架构级、交互级与可访问性层面的优化。
> 与 `docs/TODO_UI_ISSUES.md`（2026-05-27）的 3 项已知问题做了交叉核对，状态见 §5。

---

## 一、功能完整度：宣称特性 vs 实际实现

`README.md:28-36` 的特性表与代码实际状态存在落差，这是当前最需要弥合的部分：

| 宣称特性 | 实际状态 | 证据 | 缺口 |
|:--|:--|:--|:--|
| 🎥 智能播放（Direct/Transcode 自动切换） | ⚠️ 部分可用 | `playback_strategy.dart` 已实现决策逻辑 | 播放器 UI 不刷新（BUG-001），画质回退取错地址（BUG-019） |
| 📚 媒体库浏览 — 海报墙 | ✅ 桌面端可用 / ❌ 手机端图片全挂 | `home_tab.dart` 正常，`phone_library_screen.dart:288,478` 地址错误 | BUG-009 |
| 📚 媒体库浏览 — **搜索** | ❌ 空壳 | `shell_screen.dart:47` 未传回调、`home_tab.dart:932` 仅占位文本、`api_client.dart:233` 的 `search()` 零调用 | BUG-010 |
| 📚 媒体库浏览 — 分类筛选 | ⚠️ 仅固定 15 条、无分页 | `home_provider.dart:85-89` | BUG-044 |
| 📚 媒体库浏览 — 续播列表 | ⚠️ 依赖自动登录，令牌过期时静默空白 | `auth_provider.dart:120-138` | BUG-014 |
| 🎨 Celestial Glow UI | ✅ 基本落地 | `theme/`、`widgets/` 组件齐备 | 像素级偏差见 `ui_gap_analysis.md` |
| 📺 TV 模式 | ⚠️ 存在 TODO | `tv_home_screen.dart:521,1223` | BUG-012 |
| 🌐 跨平台 Linux/Windows/macOS/Android | ❌ Android 构建缺 AAR；macOS 未纳入 CMake | `build.gradle.kts:42`、`CMakeLists.txt:28-36` | BUG-033、BUG-046 |
| 🔒 安全代理（Token 不暴露给前端） | ❌ 与宣称相反 | 令牌明文存 prefs（BUG-002）、`api_key=<token>` 拼进 URL（BUG-038）、CORS `*` + `0.0.0.0`（BUG-004） | 需修正宣称或修正实现 |

**建议**：README 的"🔒 安全代理 | Token 不暴露给前端"这一行当前**与实际实现相反**（令牌不仅暴露给前端，还明文落盘）。在 BUG-002/038 修复前，这是文档层面的诚信问题，应优先修正实现。

### 连续播放能力（最高价值补强）

`BUG-012` 导致自动播放下一集完全断裂。对媒体播放器而言，**连续追剧是核心使用场景**，建议本轮优先打通：

1. 3 个调用点补传 `seriesId` / `seasonId` / `episodeIndex`。
2. `_nextEpisodeId` 从"播放完成后填充"改为**播放开始时预取**，使"下一集"按钮全程可点。
3. 播放结束前 ~15 秒展示"即将播放下一集"倒计时卡片（UI 文案已存在于 `player_page.dart`，仅缺触发）。

---

## 二、播放器体验优化

播放器是本产品的核心界面，当前问题最集中。

### 2.1 进度条拖拽（BUG-025，高频操作）

**现状**：`player_page.dart:891-894` 的 `Slider` 只实现 `onChanged`，拖动过程中**每移动一像素就触发一次 `seek`**，而 `player_provider.dart:438` 的 `seek` 未 await、无节流 → 一次拖动可能产生数十次 seek 请求，播放器抖动、服务端压力骤增。

**优化**：
```dart
Slider(
  value: _isDragging ? _dragValue : state.position,
  onChangeStart: (v) => setState(() { _isDragging = true; _dragValue = v; }),
  onChanged: (v) => setState(() => _dragValue = v),       // 只更新本地
  onChangeEnd: (v) {                                        // 松手才真正 seek
    setState(() => _isDragging = false);
    controller.seek(v);
  },
)
```
顺带启用已定义但从未使用的 `PlayerUiState.isSeeking`，拖动时在进度条上方显示目标时间气泡。

### 2.2 缓冲与错误反馈（BUG-023）

`cache-buffering-state` 属性名错误导致网络卡顿时**界面毫无反应**，用户无法区分"卡住了"和"在缓冲"。修正后应在缓冲时显示半透明遮罩 + 进度指示，并在缓冲超过 5 秒时提示"网络较慢，可尝试降低画质"（与已有的画质选择器联动）。

### 2.3 返回手势与退出确认（BUG-042）

`player_page` 无 `PopScope`，Android 返回手势直接退出播放。建议：
- 播放中按返回 → 弹出"退出播放？"确认，或直接最小化到 `MiniPlayBar`（该组件已存在但零引用，属现成资产）。
- 退出前确保 `reportStopped()` 完成上报（当前 `player_page.dart:176-194` 未 await，进度可能丢失）。

### 2.4 音量记忆（BUG-045）

`player_provider.dart:474` 的 `toggleMute` 取消静音时写死恢复 `1.0`，应恢复静音前的实际音量。

### 2.5 原生引擎渲染占位（BUG-028）

`player_page.dart:431-456` 在选择原生引擎时显示占位文案而非真实视频。结合 BUG-006（FFI 回调机制错误），建议**在原生引擎修复完成前，于设置页将其标注为"实验性，暂不可用"**，避免用户选中后看到空白播放页。这是低成本高收益的诚实性改进。

---

## 三、导航架构优化

### 3.1 侧边栏在详情页消失（对应 TODO_UI_ISSUES 问题 3）

**现状**：桌面端从侧边栏进入媒体库 / 剧集详情时使用 `Navigator.push`，侧边栏随之消失，用户失去全局导航锚点。

**推荐方案**：`TODO_UI_ISSUES.md` 已列出 A/B/C 三方案并推荐 B/C。结合 `shell_screen.dart:142-151` 现存的另一个缺陷 —— 嵌套 Navigator 使用 `ValueKey(_selectedIndex)` 导致**每次切 tab 整树重建、`HomeTab` 状态丢失并重新发起请求** —— 建议一次性解决：

```dart
// 用 IndexedStack 保留各 tab 状态，避免重建与重复请求
IndexedStack(
  index: _selectedIndex,
  children: const [HomeTab(), PhoneLibraryScreen(), SettingsTab()],
)
```

详情页则改为在 ShellScreen 的**内容区内**维护页面栈，侧边栏始终渲染。

**注意权衡**：`IndexedStack` 会同时保有所有 tab 的 state（内存换体验）。对当前 3 个 tab 的规模完全可接受；若后续 tab 增多，可改用 `AutomaticKeepAliveClientMixin` + `TabBarView`。

### 3.2 媒体库选择参数丢失（BUG-043）

`shell_screen.dart:134-138` 的 `onLibrarySelected` 忽略 `libId` 参数，导致 `PhoneLibraryScreen.selectedLibId` 永远收不到值，点击侧边栏特定媒体库无法定位到对应内容。

### 3.3 `_LibraryContentPage` 非响应式（BUG-033 in Flutter 层）

`phone_library_screen.dart:140` 用 `ref.read` 取快照传 `items`，数据更新后界面不会跟随刷新。应改为 `ref.watch`。

---

## 四、性能优化

| 项 | 现状 | 优化 | 预期收益 |
|:--|:--|:--|:--|
| **星空动画**（BUG-026） | `server_selection_screen.dart:75-83` 每帧重建 80 个 `Random` 星星 + 80 个 `MaskFilter.blur` | 星星列表构造时生成一次并复用；painter 实现 `shouldRepaint`；外层包 `RepaintBoundary` | 登录/选服页 CPU/GPU 占用显著下降，低端设备掉帧改善 |
| **图片解码**（BUG-041） | 全站 `Image.network` 无磁盘缓存、未设 `cacheWidth`，海报按原始尺寸（可能 1000px+）解码 | 补 `cacheWidth: 300`（海报）/ `800`（背景图）；或引入 `cached_network_image` | 内存占用大幅下降，滚动更流畅，重复浏览免二次请求 |
| **代理连接复用**（BUG-020） | `proxy.go:101` 每请求新建 `http.Client` | 包级共享 Client + Transport | 减少 TCP/TLS 握手，代理延迟下降 |
| **首页并发竞态**（BUG-044） | `home_provider.dart:85-89` 循环内不 await，多个 `copyWith` 以旧 map 为基底互相覆盖 | 收集结果后一次性合并写入，或串行 await | 消除媒体库随机丢失行的竞态 |
| **tab 切换重建**（见 §3.1） | `ValueKey` 导致整树重建 + 重新请求 | `IndexedStack` | 切 tab 瞬时响应，消除重复网络请求 |

---

## 五、与已知 UI 问题的交叉核对

`docs/TODO_UI_ISSUES.md`（2026-05-27）记录的 3 项问题，经本轮审查确认**均仍未修复**：

| 原问题 | 优先级 | 本轮状态 | 备注 |
|:--|:--|:--|:--|
| 1. 剧集详情页返回按钮被 hero 图片遮挡 | P0（预估 15 分钟） | ❌ 仍存在 | `series_detail_screen.dart:461` 另有 TODO；属 Stack 层级问题，低成本高收益，建议本轮一并修 |
| 2. 单集版本/音频/字幕下拉切换无效 | P1 | ❌ 仍存在，且**根因更深** | 除 UI 未接线外，还叠加 BUG-013（字幕强制选第一条）与 BUG-007（引擎设置不生效）；且原生引擎侧音轨列表恒为空（`flutter_bridge.h` 未导出 tracks 回调），需分层修复 |
| 3. 侧边栏在详情页消失 | P1 | ❌ 仍存在 | 见本报告 §3.1，并发现其与 tab 重建缺陷同源，建议合并解决 |

**结论**：该待办清单已 3 个月未推进，其中问题 1 预估仅 15 分钟。建议将本报告 §3.1 与该清单合并为统一的"导航与详情页体验"专项。

---

## 六、可访问性（当前完全缺失）

全工程 **`Semantics` 零命中**，无障碍支持为空白。建议分阶段补齐：

**第一阶段（低成本）**：
- 所有纯图标按钮补 `tooltip` + `Semantics(label:)`（播放/暂停/静音/全屏/返回等播放器控件优先）。
- 触控目标尺寸：`home_tab.dart:1059` 的 `_SeeAllButton` 字号 10.9px 偏小；`settings_tab.dart` 自绘开关触控区 44×24 低于 Material 推荐的 48×48，建议用透明 padding 扩大命中区。
- 图片类卡片补 `excludeFromSemantics` 或明确的语义标签，避免读屏器朗读无意义内容。

**第二阶段**：
- 对比度审查：`Celestial Glow` 深色主题下的次要文字（如 `home_tab` 中 10.9px 的辅助信息）需确认满足 WCAG AA 4.5:1。
- 支持系统字体缩放（`textScaleFactor`）：当前多处使用固定 `fontSize`，大字号模式下可能溢出。
- 焦点遍历顺序：TV 模式（`tv_home_screen.dart`）依赖遥控器焦点，需确认 `FocusTraversalGroup` 合理。

---

## 七、i18n 完整度

`README.md:170` 声明技术栈含 `slang (i18n)`，框架已正确接入（`app/lib/i18n/` 三文件齐备，CI 中 `dart run slang` 生成），但**实际翻译覆盖极低**（BUG-029）：

- `app.dart:68,77,92`（错误页文案）、`player_page.dart`（"即将播放下一集"/"取消"/"立即播放"/"设置"/"倍速"/"音轨"/"字幕"）、`settings_tab.dart` 全部、`home_tab.dart:204,378,412,738` 等大量中文硬编码。
- 结果：设置页可切 English，但切换后界面**基本仍是中文**，该设置项形同虚设。

**建议**：本轮不做全量补齐（工作量大，宜独立专项），但应：
1. 优先迁移**播放器与错误提示**这两类高频文案。
2. 建立约束防回归：在 `analysis_options.yaml` 中启用自定义 lint 或 CI 检查，禁止新增裸中文字符串。

---

## 八、设置页：让死配置生效或诚实标注

`settings_tab.dart` 与 `settings_modal.dart` 中大量设置项**只写 SharedPreferences、无任何消费方**（BUG-027）：硬件加速、音频直通、字幕大小、默认音轨/字幕语言、带宽限制、噪点/动画开关。

两种处理方式，按成本排序：

| 设置项 | 建议接线方式 | 成本 |
|:--|:--|:--|
| 硬件加速 | → `MpvEngine` 的 `hwdec` 参数（`auto`/`no`） | 低 |
| 字幕大小 | → mpv `sub-font-size` | 低 |
| 默认音轨/字幕语言 | → mpv `alang` / `slang` | 低 |
| 噪点/动画开关 | → `NoiseTexture`、`AetherPageRoute` 的动画开关 | 低 |
| 带宽限制 | → `PlaybackStrategy` 的画质决策输入 | 中 |
| 音频直通 | → mpv `audio-exclusive` / `audio-channels` | 中 |

**短期方案**：无法立即接线的项，在 UI 上标注"实验性"或移至"高级"折叠区，避免用户调整后无效果的困惑。同时统一改用已有的 `settingsServiceProvider`，而非每次 `SettingsService()` 新建实例（`settings_tab.dart:43`、`:224`）。

---

## 九、可诊断性

当前排障能力几乎为零，直接影响后续维护效率：

1. **异常被吞**（BUG-008）：`FlutterError.onError` 故意不调 `presentError`，`runZonedGuarded` 仅 `debugPrint`，release 下所有崩溃静默。
2. **后端日志丢失 + 内存泄漏**（BUG-022）：Go 子进程 stdout/stderr 从不消费，而 `middleware.go` 每请求写两条日志 → 日志全部丢失且 Dart 侧缓冲无限增长。
3. **`catch (_)` 空吞**：`home_provider.dart:117`、`player_provider.dart:580,605`、`episode_detail_screen.dart:75` 等多处。
4. **错误直接展示 `e.toString()`**：`login_screen.dart:328`、`home_tab.dart:269`、`player_page.dart:538`，既泄漏内部实现又未本地化。

**建议**：
- 恢复 `FlutterError.presentError`，release 下将错误写入 `getApplicationSupportDirectory()` 的日志文件。
- `backend_service` 消费子进程管道并转发到统一日志（带行数上限）。
- 设置页增加"导出诊断日志"入口 —— 这对开源项目收集 issue 尤其有价值。
- 用户可见错误改为本地化友好文案，技术细节仅进日志。

---

## 十、测试策略

`app/test/widget_test.dart` 仅 1 个用例（只测错误页文案），核心纯逻辑零覆盖。CI 中 `flutter test` 与 `go test ./...` 均因此几乎空转。

**优先补测（投入产出比最高的纯函数）**：

| 目标 | 理由 | 关键用例 |
|:--|:--|:--|
| `utils/episode_utils.dart` | 有已知键冲突 bug（BUG-017），无测试则回归无法防护 | `indexNumber` 与列表位置冲突、无编号集、空列表、乱序输入 |
| `services/playback_strategy.dart` | 承载"智能播放"核心决策，宣称特性之一 | Direct/Transcode 判定边界、画质回退、带宽不足场景 |
| `providers/*` 状态转换 | `copyWith` 丢 error（BUG-015）等状态 bug 的根源 | error 保留语义、loading 转换、失败路径 |
| Go `validateServerURL` | 安全边界，绕过手法多样（BUG-003） | 十进制 IP、IPv6、重定向、私网、scheme 白名单 |

**建议**：把"`episode_utils` 键冲突"作为第一个回归测试落地 —— 它同时验证 BUG-017 的修复，并建立起该项目的测试基线。

---

## 十一、优化优先级汇总

```
本轮执行（高价值 + 低风险 + 可本地验证）
  ✅ 播放器状态刷新（BUG-001）        — 核心功能，改动极小
  ✅ 设置持久化恢复（BUG-007）        — 一行调用，收益大
  ✅ 手机端图片地址（BUG-009）        — 两行修改
  ✅ 进度条拖拽节流（BUG-025）        — 高频操作体验
  ✅ 星空动画性能（BUG-026）          — 首屏印象
  ✅ 切换账户 / 字幕选择（BUG-011/013）— 功能可用性
  ✅ 搜索功能落地（BUG-010）          — 宣称特性补全
  ✅ 自动下一集链路（BUG-012）        — 核心使用场景
  ✅ 返回按钮遮挡（TODO_UI 问题 1）    — 预估 15 分钟
  ✅ 错误提示与状态三态（BUG-030）     — 可诊断性基础

单独专项（需决策或高风险）
  ⏸ 导航架构重构（§3.1 + TODO_UI 问题 3）— 涉及 ShellScreen 页面栈重设计
  ⏸ i18n 全量补齐（§7）                 — 涉及全部界面文案
  ⏸ 可访问性体系（§6）                   — 需设计规范配合
  ⏸ 原生引擎 FFI 重构（BUG-006）         — 无法本地编译验证
  ⏸ 设置项全量接线（§8）                 — 依赖 mpv 参数联调
```
