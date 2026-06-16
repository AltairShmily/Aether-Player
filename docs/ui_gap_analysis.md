# UI 差距清单 — Flutter 实现 vs HTML 设计规范

> 生成日期: 2026-06-16
> 设计规范: `docs/design_spec_celestial_glow.md`
> Flutter 项目: `app/lib/`

---

## 1. 侧边栏 (`screens/shell_screen.dart`)

| # | 差距 | 当前 Flutter 值 | HTML 规范值 | 文件:行号 |
|---|------|----------------|------------|----------|
| 1.1 | Logo 容器尺寸 | `32×32` | `40×40` | shell_screen.dart:273-276 |
| 1.2 | 导航按钮圆角 | `AppColors.radiusSm` (8px) | `radius-md` (12px) | shell_screen.dart:379 |
| 1.3 | 侧边栏顶部内边距 | `SizedBox(height: 16)` | `padding: 20px 0 16px` (top 20px) | shell_screen.dart:202 |
| 1.4 | 导航按钮间距 | 无明确 gap（使用 SizedBox 手动间隔） | `gap: 2px`（flex column） | shell_screen.dart:199-268 |
| 1.5 | 分隔线宽度 | 全宽（padding horizontal 16） | `width: 28px` 居中 | shell_screen.dart:216-219 |
| 1.6 | 分隔线外边距 | `padding: horizontal 16, vertical 4` | `margin: 8px 0` | shell_screen.dart:217 |
| 1.7 | 底部区域间距 | `SizedBox(height: 12)` | `gap: 4px` | shell_screen.dart:257 |

---

## 2. 媒体卡片 (`widgets/media_card.dart`)

| # | 差距 | 当前 Flutter 值 | HTML 规范值 | 文件:行号 |
|---|------|----------------|------------|----------|
| 2.1 | 卡片宽度 | 无固定宽度（由父容器决定） | `152px` | media_card.dart:45-147 |
| 2.2 | Hover 阴影 | 仅 `glowCyan(blur:18, spread:1)` | 复合阴影: `0 12px 32px rgba(0,0,0,0.5), 0 0 0 1px rgba(0,212,255,0.15), 0 0 20px rgba(0,212,255,0.08)` | media_card.dart:56 |
| 2.3 | Hover 动画时长 | `220ms` | `350ms` (0.35s) | media_card.dart:47,50 |
| 2.4 | Hover 缓动曲线 | `Curves.easeOutCubic` | `cubic-bezier(0.4, 0, 0.2, 1)` | media_card.dart:48 |
| 2.5 | 海报底部渐变 | `[transparent, 0xCC0A0E14]` stops `[0.5, 1.0]` | `to top, rgba(10,14,20,0.75) 0%, transparent 60%` | media_card.dart:206-211 |
| 2.6 | 播放覆盖层背景 | `deepVoid alpha:0.45` (0x73) | `rgba(10,14,20,0.35)` | media_card.dart:221 |
| 2.7 | 播放按钮尺寸 | `48×48` | `40×40` | media_card.dart:224-225 |
| 2.8 | 播放按钮背景 | 完全不透明 `celestialCyan` | `rgba(0,212,255,0.9)` | media_card.dart:227 |
| 2.9 | 播放按钮阴影 | `alpha:0.4, blur:16, spread:2` | `0 4px 20px rgba(0,212,255,0.3)` | media_card.dart:230-234 |
| 2.10 | 播放按钮缩放动画 | 无缩放（仅 opacity 切换） | `scale(0.8)→scale(1)` + 弹性缓动 | media_card.dart:216-245 |
| 2.11 | 播放图标尺寸 | `28` | `20` | media_card.dart:239 |
| 2.12 | 元信息区内边距 | `fromLTRB(10, 8, 10, 4)` | `padding: 8px 2px 0` | media_card.dart:89,103-104 |
| 2.13 | 标题字号 | `13px` | `0.78rem` (≈10.9px) | media_card.dart:97 |
| 2.14 | 标题字重 | `w600` | `w500` | media_card.dart:98 |
| 2.15 | 年份字号 | `11px` | `DM Mono, 0.68rem` (≈9.5px) | media_card.dart:112 |
| 2.16 | 年份字体 | 未指定 `DM Mono` | `font-family: 'DM Mono'` | media_card.dart:112 |
| 2.17 | 海报内标题样式 | 无海报内标题 | `0.7rem, fw600, color rgba(240,244,248,0.9), padding 14px` | — |

---

## 3. Hero Banner (`widgets/aether_hero.dart` + `screens/home_tab.dart`)

| # | 差距 | 当前 Flutter 值 | HTML 规范值 | 文件:行号 |
|---|------|----------------|------------|----------|
| 3.1 | 轮播指示器 | 无轮播指示器（仅 PageView） | 底部圆点指示器 | home_tab.dart:139-171 |
| 3.2 | Hero 高度（Desktop） | `320px` | 3:1 比例（需根据宽度计算） | app_breakpoints.dart:83 |
| 3.3 | PageView viewport | `0.92`（两侧露出） | 无此规格（应全宽） | home_tab.dart:31 |

---

## 4. 系列详情 (`screens/series_detail_screen.dart`)

| # | 差距 | 当前 Flutter 值 | HTML 规范值 | 文件:行号 |
|---|------|----------------|------------|----------|
| 4.1 | Backdrop 高度 | `280px` | `300px` | series_detail_screen.dart:213,222 |
| 4.2 | Backdrop 渐变遮罩 | 仅一个 `transparent→seriesBg` | 双层: `to top, bg-primary 5%, transparent 50%` + `to right, rgba(10,14,20,0.7), transparent 60%` | series_detail_screen.dart:244-252 |
| 4.3 | 海报圆角 | `radiusMd` (12px) | `radiusLg` (16px) | series_detail_screen.dart:150,165 |
| 4.4 | 海报边框颜色 | `borderSubtle` (10% white) | `rgba(0,212,255,0.12)` (12% cyan) | series_detail_screen.dart:149 |
| 4.5 | 标题字号 | `22px` | `1.85rem` (≈26px) | series_detail_screen.dart:323 |
| 4.6 | 标题字重 | `bold` (700) | `700` ✓ | — |
| 4.7 | 标题 letter-spacing | 无 | `-0.03em` | series_detail_screen.dart:321 |
| 4.8 | Meta 标签颜色 | `textPrimary` | `text-secondary` | series_detail_screen.dart:365 |
| 4.9 | 评分徽章背景 | `cardBg` | `accent-soft` (10% cyan) | series_detail_screen.dart:370-374 |
| 4.10 | 描述行高 | `1.6` | `1.7` | series_detail_screen.dart:437 |
| 4.11 | 演员容器宽度 | `64px` | `74px` | series_detail_screen.dart:903 |
| 4.12 | 演员头像尺寸 | `CircleAvatar radius 26` (52px) | `58×58` | series_detail_screen.dart:907 |
| 4.13 | 演员名字号 | `11px` | `0.68rem` (≈9.5px) | series_detail_screen.dart:929 |
| 4.14 | 演员角色字号 | `10px` | `0.62rem` (≈8.7px) | series_detail_screen.dart:937 |
| 4.15 | 季选择器间距 | `padding right 24` (固定间距) | `gap: 4px` | series_detail_screen.dart:478 |
| 4.16 | 季 Tab 字号 | `14px` | `0.82rem` (≈11.5px) | series_detail_screen.dart:489 |
| 4.17 | 季 Tab 内边距 | 无显式 padding（使用 SizedBox） | `padding: 10px 18px` | series_detail_screen.dart:477-508 |
| 4.18 | 集列表间距 | `Container margin vertical 4` | `gap: 2px` | series_detail_screen.dart:708 |

---

## 5. 集详情 (`screens/episode_detail_screen.dart`)

| # | 差距 | 当前 Flutter 值 | HTML 规范值 | 文件:行号 |
|---|------|----------------|------------|----------|
| 5.1 | 双栏间距 | 无显式 gap（Row 直接排列） | `gap: 32px` | episode_detail_screen.dart:164-211 |
| 5.2 | 大播放按钮 hover 阴影 | `alpha:0.4, blur:24, spread:4` | `0 4px 32px rgba(0,212,255,0.45)` | episode_detail_screen.dart:1138-1145 |
| 5.3 | 控制面板定位 | 非 sticky（在 Column 中固定位置） | `sticky top: 32px` | episode_detail_screen.dart:203-209 |
| 5.4 | 控制标签 letter-spacing | `0.8` | `0.06em` (≈0.84) | aether_dropdown.dart:95 |
| 5.5 | 播放全宽按钮内边距 | `height: 48` | `padding: 13px` (高度≈46px) | episode_detail_screen.dart:860 |
| 5.6 | 播放全宽按钮字号 | `15px` | `0.92rem` (≈12.9px) | episode_detail_screen.dart:891 |
| 5.7 | 播放全宽按钮 hover 阴影 | 仅单个 `alpha:0.25` | `0 4px 24px rgba(0,212,255,0.35), 0 0 0 1px rgba(0,212,255,0.2)` | episode_detail_screen.dart:867-873 |
| 5.8 | 集详情标题字号 | `26px` | `1.4rem` (≈19.6px) | episode_detail_screen.dart:499 |
| 5.9 | 描述行高 | `1.65` | `1.8` | episode_detail_screen.dart:711 |
| 5.10 | 面包屑字号 | `13px` | `0.78rem` (≈10.9px) | episode_detail_screen.dart:469 |
| 5.11 | 面包屑间距 | `SizedBox(width: 8)` | `gap: 7px` | episode_detail_screen.dart:452-453 |
| 5.12 | 背景色 | `AppColors.episodeBg` (stardust) | `var(--bg-primary)` (#0D1520) | episode_detail_screen.dart:144 |

---

## 6. 搜索弹窗 (`widgets/search_overlay.dart`)

| # | 差距 | 当前 Flutter 值 | HTML 规范值 | 文件:行号 |
|---|------|----------------|------------|----------|
| 6.1 | 入场动画 translateY | 无（仅 scale） | `translateY(-12px)→translateY(0)` | search_overlay.dart:122-127 |
| 6.2 | 输入区内边距 | `contentPadding: h12, v18` | `padding: 16px 20px` | search_overlay.dart:315-317 |
| 6.3 | 输入框字号 | `16px` | `1rem` (14px) | search_overlay.dart:292 |
| 6.4 | 提示文字 padding | `h20, v12` | `16px 20px` | search_overlay.dart:330 |
| 6.5 | 提示文字字号 | `13px` | `0.8rem` (≈11.2px) | search_overlay.dart:338 |
| 6.6 | 搜索框阴影 | 两个自定义阴影 | `0 24px 64px rgba(0,0,0,0.5)` | search_overlay.dart:244-257 |
| 6.7 | padding-top（距顶部） | 无固定 padding-top（居中） | `padding-top: 120px` | search_overlay.dart:216 |

---

## 7. 媒体库网格 (`screens/phone_library_screen.dart`)

| # | 差距 | 当前 Flutter 值 | HTML 规范值 | 文件:行号 |
|---|------|----------------|------------|----------|
| 7.1 | 桌面库卡片圆角 | `radiusMd` (12px) | `radiusLg` (16px) | phone_library_screen.dart:154 |
| 7.2 | 库卡片 Hover 效果 | 无 hover 效果 | `translateY(-4px) scale(1.02)` + 阴影 | phone_library_screen.dart:133-215 |
| 7.3 | 库卡片右侧光晕 | 无 | `radial-gradient(circle, rgba(255,255,255,0.06), transparent 70%)` | — |
| 7.4 | 库卡片内边距 | `14px` | `18px` | phone_library_screen.dart:185 |
| 7.5 | 库图标尺寸 | `22px` | `26px` | phone_library_screen.dart:190 |
| 7.6 | 库数量显示 | 显示"点击查看" | 应显示实际数量，`DM Mono, 0.72rem` | phone_library_screen.dart:201-207 |
| 7.7 | 网格间距 | `crossAxisSpacing: 12, mainAxisSpacing: 12` | `gap: 14px` | phone_library_screen.dart:94-95 |
| 7.8 | 底部渐变 | `transparent→0.6 alpha` stops `[0.35, 1.0]` | `to top, rgba(10,14,20,0.65), transparent 70%` | phone_library_screen.dart:171-180 |

---

## 8. 分类行 (`screens/home_tab.dart`)

| # | 差距 | 当前 Flutter 值 | HTML 规范值 | 文件:行号 |
|---|------|----------------|------------|----------|
| 8.1 | 标题字号 | `16px` | `1rem` (14px) | home_tab.dart:400 |
| 8.2 | 标题字重 | `w700` | `w600` | home_tab.dart:403 |
| 8.3 | 标题图标 | 渐变竖线 3×14 | Material icon 20px accent色 + text | home_tab.dart:389-396 |
| 8.4 | 查看全部字号 | `13px` | `0.78rem` (≈10.9px) | home_tab.dart:767 |
| 8.5 | 卡片间距 | `cardSpacing()` 返回 16px (desktop) | `gap: 14px` | home_tab.dart:431, app_breakpoints.dart:67 |
| 8.6 | Section margin-bottom | 无（Sliver 布局） | `36px` | home_tab.dart:381 |
| 8.7 | 标题行 margin-bottom | `padding bottom: 14` | `margin-bottom: 14px` ✓ | — |
| 8.8 | 滚动箭头毛玻璃 | 仅颜色 alpha 0.90 | `backdrop-filter: blur(8px)` | scroll_arrows.dart:248 |

---

## 9. 设置弹窗 (`widgets/settings_modal.dart`)

| # | 差距 | 当前 Flutter 值 | HTML 规范值 | 文件:行号 |
|---|------|----------------|------------|----------|
| 9.1 | 标题字号 | `18px` | `1.15rem` (≈16.1px) | settings_modal.dart:232 |
| 9.2 | 开关滑块尺寸 | `18×18` | `16×16` | settings_modal.dart:398 |
| 9.3 | 开关过渡时长 | `250ms` | `300ms` (0.3s) | settings_modal.dart:380,394 |
| 9.4 | 分组标题字号 | `11px` | `0.75rem` (≈10.5px) | settings_modal.dart:282 |
| 9.5 | 分组间距 | `SizedBox(height: 24)` | `margin-bottom: 28px` | settings_modal.dart:150,184 |
| 9.6 | 设置标签字号 | `14px` | `0.9rem` (≈12.6px) | settings_modal.dart:330 |
| 9.7 | 内容区顶部内边距 | `fromLTRB(28, 0, 28, 24)` | `padding: 24px 28px` | settings_modal.dart:113 |
| 9.8 | 遮罩层颜色 | `Colors.black54` | `rgba(0,0,0,0.6)` + `blur(6px)` | settings_modal.dart:18 |
| 9.9 | 入场动画缓动 | `Curves.easeOutCubic` | `cubic-bezier(0.34,1.56,0.64,1)` (弹性) | settings_modal.dart:26 |

---

## 10. TV 端

### 10.1 顶部导航 (`tv_home_screen.dart`)

| # | 差距 | 当前 Flutter 值 | HTML 规范值 | 文件:行号 |
|---|------|----------------|------------|----------|
| 10.1.1 | 顶部 padding | `top:24, left:56, right:56` (无 bottom) | `padding: 24px 56px 16px` | tv_home_screen.dart:488 |
| 10.1.2 | Logo 字号 | `24px` | `1.4rem` (≈19.6px) | tv_home_screen.dart:499 |
| 10.1.3 | 导航间距 | `SizedBox(horizontal: 4)` = gap 8px | `gap: 6px` | tv_home_screen.dart:515 |
| 10.1.4 | 导航按钮 padding | `h16, v8` | `8px 20px` | tv_home_screen.dart:525-526 |
| 10.1.5 | 导航按钮字号 | `14px` | `0.88rem` (≈12.3px) | tv_home_screen.dart:536 |
| 10.1.6 | 导航按钮圆角 | `20px` | `24px` | tv_home_screen.dart:531 |
| 10.1.7 | 时钟字号 | `14px` | `0.85rem` (≈11.9px) | tv_home_screen.dart:586 |

### 10.2 TV Featured Banner (`tv_home_screen.dart`)

| # | 差距 | 当前 Flutter 值 | HTML 规范值 | 文件:行号 |
|---|------|----------------|------------|----------|
| 10.2.1 | 圆角 | `16px` | `24px` (radiusXl) | tv_home_screen.dart:618,639 |
| 10.2.2 | 内容区 right 定位 | `right: 200` | `max-width: 45%` | tv_home_screen.dart:689 |
| 10.2.3 | 推荐标签圆角 | `6px` | `12px` | tv_home_screen.dart:702 |
| 10.2.4 | 推荐标签字号 | `12px` | `0.72rem` (≈10.1px) | tv_home_screen.dart:712 |

### 10.3 TV 媒体卡片 (`tv_home_screen.dart`)

| # | 差距 | 当前 Flutter 值 | HTML 规范值 | 文件:行号 |
|---|------|----------------|------------|----------|
| 10.3.1 | 焦点缩放时长 | `200ms` | `300ms` | tv_home_screen.dart:968 |
| 10.3.2 | 名称字号 | `14px` | `0.92rem` (≈12.9px) | tv_home_screen.dart:1073 |
| 10.3.3 | 年份字号 | `12px` | `0.75rem` (≈10.5px) | tv_home_screen.dart:1088 |
| 10.3.4 | 海报内边距 | 无 | `padding: 16px` | tv_home_screen.dart:997-1064 |
| 10.3.5 | 卡片间距 | `16px` | `18px` | tv_home_screen.dart:912 |

### 10.4 TV 滚动区

| # | 差距 | 当前 Flutter 值 | HTML 规范值 | 文件:行号 |
|---|------|----------------|------------|----------|
| 10.4.1 | Section 标题字号 | `20px` | `1.2rem` (≈16.8px) | tv_home_screen.dart:870 |
| 10.4.2 | Section 标题间距 | `SizedBox(width: 12)` | `gap: 10px` | tv_home_screen.dart:866 |
| 10.4.3 | Section 标题图标 | 渐变竖线 3×18 | Material icon 20px accent色 | tv_home_screen.dart:858-865 |

### 10.5 TV 媒体库卡片

| # | 差距 | 当前 Flutter 值 | HTML 规范值 | 文件:行号 |
|---|------|----------------|------------|----------|
| 10.5.1 | 图标尺寸 | `22px` | `28px` | tv_home_screen.dart:1298 |
| 10.5.2 | 库名字号/字重 | `15px, w600` | `1.15rem (≈16.1px), w700` | tv_home_screen.dart:1313-1314 |
| 10.5.3 | 数量字号 | `12px` | `0.75rem` (≈10.5px) | tv_home_screen.dart:1324 |
| 10.5.4 | 间距 | `16px` | `18px` | tv_home_screen.dart:1145 |

### 10.6 TV Toast

| # | 差距 | 当前 Flutter 值 | HTML 规范值 | 文件:行号 |
|---|------|----------------|------------|----------|
| 10.6.1 | TV Toast 组件 | **未实现** | 毛玻璃 toast，底部 60px，圆角 24px | — |

---

## 11. 全局性问题

| # | 差距 | 当前 Flutter 值 | HTML 规范值 | 涉及文件 |
|---|------|----------------|------------|----------|
| G.1 | 字体系统 | 未全局设置 Sora 字体 | 主字体 Sora，代码字体 DM Mono | app_theme.dart |
| G.2 | 基础字号 | 未定义基准（直接使用 px） | `html { font-size: 14px }` (rem 换算基准) | — |
| G.3 | 径向光晕背景 | 无 | Desktop 主内容区双层径向渐变 | home_tab.dart |
| G.4 | 滚动条样式 | 未自定义 | 宽度 5px，thumb rgba(255,255,255,0.07)，圆角 3px | — |
| G.5 | 毛玻璃效果不一致 | 部分组件使用 BackdropFilter，部分仅用颜色 alpha | 统一使用 backdrop-filter: blur() | scroll_arrows.dart, home_tab.dart |
| G.6 | 动画缓动不一致 | 多处使用 easeOutCubic | 弹性缓动 `cubic-bezier(0.34,1.56,0.64,1)` 应用于搜索/设置/播放按钮 | 多处 |
| G.7 | Card 组件使用 | 使用 Flutter Card widget（自带 margin/elevation） | 应使用 Container + 自定义样式 | media_card.dart |

---

## 优先级建议

### 🔴 高优先级（视觉差异明显）
1. 媒体卡片播放按钮尺寸 48→40（#2.7）
2. 媒体卡片元信息区 padding（#2.12）
3. 系列详情标题字号 22→26（#4.5）
4. 系列详情演员头像 52→58px（#4.12）
5. 侧边栏按钮圆角 8→12px（#1.2）
6. TV Featured 圆角 16→24px（#10.2.1）
7. 设置弹窗开关滑块 18→16px（#9.2）
8. 分类行标题图标风格（竖线→图标）（#8.3）

### 🟡 中优先级（细节偏差）
1. 媒体卡片 hover 阴影复合效果（#2.2）
2. 媒体卡片播放按钮缩放动画（#2.10）
3. 海报底部渐变方向/色值（#2.5, #7.8）
4. 搜索弹窗 translateY 动画（#6.1）
5. 设置弹窗弹性缓动（#9.9）
6. TV 导航字号/圆角（#10.1.5, #10.1.6）
7. 集详情标题 26→20px（#5.8）

### 🟢 低优先级（微调）
1. 各处字号 rem→px 换算偏差
2. letter-spacing 微调
3. 间距 gap 精确值
4. 毛玻璃 backdrop-filter 补全
5. 自定义滚动条
6. 全局字体设置
