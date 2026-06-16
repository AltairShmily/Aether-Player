# Aether Player · Celestial Glow UI 设计规范文档

> 基于 `aether_celestial_glow_ui.html` 原型完整提取  
> 主题: Celestial Glow  
> 生成日期: 2026-06-16

---

## 1. 全局设计系统

### 1.1 色彩系统 (CSS Variables)
| 变量名 | 值 | 用途 |
|---|---|---|
| `--bg-deep` | `#0A0E14` | 最深层背景 |
| `--bg-primary` | `#0D1520` | 主背景 |
| `--bg-secondary` | `#0F1722` | 次级背景 |
| `--bg-surface` | `#111820` | 面板/卡片面 |
| `--bg-surface-hover` | `#1A2332` | Hover 状态面 |
| `--bg-elevated` | `#1A2332` | 弹出层/浮层 |
| `--bg-card` | `#111820` | 卡片背景 |
| `--accent` | `#00D4FF` | 主强调色 (青色) |
| `--accent-soft` | `rgba(0,212,255,0.10)` | 柔和强调底色 |
| `--accent-medium` | `rgba(0,212,255,0.20)` | 中等强调底色 |
| `--accent-hover` | `#33DDFF` | 强调色 Hover |
| `--accent-glow` | `rgba(0,212,255,0.25)` | 发光效果 |
| `--text-primary` | `#F0F4F8` | 主文字 |
| `--text-secondary` | `#8892A4` | 次要文字 |
| `--text-muted` | `#5A6577` | 弱化文字 |
| `--border` | `rgba(255,255,255,0.06)` | 默认边框 |
| `--border-light` | `rgba(255,255,255,0.10)` | 亮边框 |

### 1.2 圆角系统
| 变量 | 值 | 常见用途 |
|---|---|---|
| `--radius-xs` | `6px` | 评分徽章、标签 |
| `--radius-sm` | `8px` | 小按钮、缩略图、下拉选项 |
| `--radius-md` | `12px` | 导航按钮、媒体卡片海报、控制触发器 |
| `--radius-lg` | `16px` | 搜索框、详情海报、库卡片、控制面板、Ep封面 |
| `--radius-xl` | `24px` | Backdrop、设置模态框、Featured Banner |

### 1.3 动画缓动
- 全局过渡: `0.3s cubic-bezier(0.4, 0, 0.2, 1)` (变量 `--transition`)
- 弹性缓动: `cubic-bezier(0.34, 1.56, 0.64, 1)` — 用于搜索框弹出、设置弹窗、播放按钮、选项菜单
- 快速过渡: `0.2s` / `0.15s` — 用于 hover 颜色变化、tooltip

### 1.4 字体系统
| 字体 | 权重 | 用途 |
|---|---|---|
| **Sora** (主字体) | 300, 400, 500, 600, 700, 800 | 全局 body 字体，标题、按钮 |
| **DM Mono** | 400, 500 | 年份、集编号、快捷键标签、版本号、时钟 |
| **Material Symbols Rounded** | 100-700 (可变) | 图标字体 |
| 回退字体 | `'PingFang SC', sans-serif` | 中文回退 |

- 基础字号: `html { font-size: 14px }`

### 1.5 滚动条样式
- 宽度: `5px`
- Track: `transparent`
- Thumb: `rgba(255,255,255,0.07)`，圆角 `3px`
- Thumb hover: `rgba(255,255,255,0.14)`

### 1.6 噪点纹理
- SVG fractalNoise 覆盖层，`opacity: 0.025` (Desktop) / `0.02` (Phone)
- `baseFrequency: 0.9`, `numOctaves: 4`

### 1.7 径向光晕背景 (Desktop Main)
```css
radial-gradient(ellipse at 10% 0%, rgba(0,212,255,0.04), transparent 50%),
radial-gradient(ellipse at 80% 100%, rgba(139,92,246,0.03), transparent 50%),
var(--bg-primary)
```

---

## 2. 顶部平台选择栏 (Platform Bar)
- 高度: `44px`
- 背景: `rgba(10,14,20,0.85)` + `backdrop-filter: blur(12px)`
- 边框: `border-bottom: 1px solid var(--border)`
- 布局: `flex`, 居中, `gap: 4px`, `padding: 0 20px`
- Logo: `font-weight: 700`, `font-size: 0.85rem`, `color: var(--accent)`, `letter-spacing: -0.02em`
- 按钮样式:
  - `padding: 6px 16px`, `border-radius: 20px`
  - 字号: `0.78rem`, `font-weight: 500`
  - 默认: `color: var(--text-muted)`
  - Hover: `color: var(--text-secondary)`, `background: var(--bg-surface)`
  - Active: `color: var(--accent)`, `background: var(--accent-soft)`
  - 图标: `font-size: 16px`

---

## 3. 侧边栏 (Sidebar)
- **宽度**: `72px` (变量 `--sidebar-w`)
- **背景**: `var(--bg-surface)` = `#111820`
- **右边框**: `1px solid var(--border)`
- **布局**: `flex-direction: column`, `align-items: center`
- **内边距**: `padding: 20px 0 16px`

### 3.1 Logo 区域
- 容器: `40px × 40px`, 居中, `margin-bottom: 24px`
- SVG: `30px × 30px`，渐变色 `#00D4FF → #8B5CF6`

### 3.2 导航按钮
- **尺寸**: `44px × 44px`
- **圆角**: `var(--radius-md)` = `12px`
- **间距**: `gap: 2px` (纵向 flex)
- **默认态**: `color: var(--text-muted)`, `background: transparent`
- **Hover 态**: `color: var(--text-secondary)`, `background: var(--bg-surface-hover)`
- **Active 态**: `color: var(--accent)`, `background: var(--accent-soft)`, 图标 FILL=1
- **图标**: `font-size: 22px`
- **过渡**: `color var(--transition), background var(--transition)`

### 3.3 Tooltip
- 位置: 左侧 `left: calc(100% + 14px)`, 垂直居中
- 背景: `var(--bg-elevated)`
- 内边距: `6px 12px`
- 圆角: `var(--radius-sm)` = `8px`
- 字号: `0.75rem`
- 阴影: `0 4px 12px rgba(0,0,0,0.4)`
- 边框: `1px solid var(--border-light)`
- 动画: `opacity 0.2s, transform 0.2s`，从 `translateX(-4px)` 到 `translateX(0)`

### 3.4 分隔线
- 宽度: `28px`, 高度: `1px`
- 颜色: `var(--border)`
- 外边距: `8px 0`

### 3.5 底部区域
- 布局: `flex-direction: column`, `align-items: center`, `gap: 4px`

### 3.6 服务器切换器
- **头像**: `36px × 36px`, 圆形
- **头像渐变**: `linear-gradient(135deg, #00D4FF, #8B5CF6)`
- **Hover**: `box-shadow: 0 0 0 3px var(--accent-soft)`, `transform: scale(1.08)`
- **边框**: `2px solid transparent`
- **下拉菜单**:
  - 宽度: `280px`
  - 圆角: `var(--radius-lg)` = `16px`
  - 内边距: `12px`
  - 阴影: `0 12px 40px rgba(0,0,0,0.5)`
  - 入场动画: 从 `translateX(-8px) scale(0.96)` 到 `translateX(0) scale(1)`, `0.25s`
- **状态点**: `8px × 8px` 圆形
  - 在线: `background: #00E5A0`, `box-shadow: 0 0 6px rgba(0,229,160,0.4)`
  - 离线: `background: var(--text-muted)`
- **小账号头像**: `28px × 28px` 圆形
- **添加账号按钮**: 虚线边框 `1px dashed var(--border-light)`, Hover 变强调色

---

## 4. 主内容区 (Desktop Main)
- **布局**: `flex: 1`, `overflow-y: auto`
- **背景**: 径向光晕 + 主背景色 (见 1.7)
- **噪点覆盖**: opacity 0.025

### 4.1 顶部搜索栏 (Top Bar)
- **内边距**: `16px 36px`
- **定位**: `sticky top: 0`, `z-index: 10`
- **背景渐变**: `linear-gradient(to bottom, var(--bg-primary) 60%, transparent)`

### 4.2 搜索触发器
- **内边距**: `8px 16px`
- **圆角**: `24px`
- **最小宽度**: `220px`
- **边框**: `1px solid var(--border-light)`
- **字号**: `0.82rem`
- **快捷键标签**: `font-family: 'DM Mono'`, `font-size: 0.68rem`, `padding: 2px 8px`, `border-radius: 4px`
- **Hover**: `border-color: var(--accent)`, `color: var(--text-secondary)`

---

## 5. 视图切换动画
- **入场动画** (`vIn`): `0.4s ease`
  - From: `opacity: 0; transform: translateY(10px)`
  - To: `opacity: 1; transform: translateY(0)`
- **卡片渐现** (`cfu`): `0.5s ease`, 逐项延迟 `0.05s`
  - From: `opacity: 0; transform: translateY(14px)`
  - To: `opacity: 1; transform: translateY(0)`

---

## 6. 分类行 (Section)
- **外边距**: `margin-bottom: 36px`
- **标题行**: `flex`, `justify-content: space-between`, `margin-bottom: 14px`
- **标题**: `font-size: 1rem`, `font-weight: 600`, `gap: 8px` (图标+文字)
- **标题图标**: `font-size: 20px`, `color: var(--accent)`
- **查看全部按钮**: `font-size: 0.78rem`, `padding: 5px 12px`, `border-radius: var(--radius-sm)`
  - Hover: `color: var(--accent)`, `background: var(--accent-soft)`

### 6.1 水平滚动区 (H-Scroll)
- **间距**: `gap: 14px`
- **内边距**: `padding: 4px 2px 12px`
- **滚动行为**: `scroll-snap-type: x proximity`
- **拖拽**: cursor `grab` → `grabbing`
- **滚动箭头**:
  - 尺寸: `36px × 36px` 圆形
  - 背景: `rgba(17,24,32,0.92)` + `backdrop-filter: blur(8px)`
  - 边框: `1px solid var(--border-light)`
  - 默认: `opacity: 0`, hover 父容器时 `opacity: 1`
  - Hover: `background: var(--accent-soft)`, `color: var(--accent)`, `border-color: var(--accent)`
  - 图标: `font-size: 20px`
  - 滚动量: `350px`

---

## 7. 媒体卡片 (Media Card)
- **宽度**: `152px`
- **海报比例**: `aspect-ratio: 2/3`
- **海报圆角**: `var(--radius-md)` = `12px`
- **海报 Hover 动画**:
  - `transform: translateY(-6px) scale(1.03)`
  - `box-shadow: 0 12px 32px rgba(0,0,0,0.5), 0 0 0 1px rgba(0,212,255,0.15), 0 0 20px rgba(0,212,255,0.08)`
  - 过渡: `0.35s cubic-bezier(0.4, 0, 0.2, 1)`
- **海报底部渐变遮罩**: `linear-gradient(to top, rgba(10,14,20,0.75) 0%, transparent 60%)`
- **海报内标题**: `font-size: 0.7rem`, `font-weight: 600`, `color: rgba(240,244,248,0.9)`, `line-height: 1.3`, 内边距 `14px`

### 7.1 播放覆盖层
- **背景**: `rgba(10,14,20,0.35)`
- **默认**: `opacity: 0`, Hover 时 `opacity: 1`
- **播放按钮**:
  - 尺寸: `40px × 40px` 圆形
  - 背景: `rgba(0,212,255,0.9)`
  - 阴影: `0 4px 20px rgba(0,212,255,0.3)`
  - 默认: `transform: scale(0.8)`, Hover: `transform: scale(1)`
  - 缓动: `cubic-bezier(0.34, 1.56, 0.64, 1)`
  - 图标: `color: #0A0E14`, `font-size: 20px`, `margin-left: 2px`

### 7.2 卡片元信息
- **内边距**: `padding: 8px 2px 0`
- **标题**: `font-size: 0.78rem`, `font-weight: 500`, `max-width: 95px`
- **年份**: `font-family: 'DM Mono'`, `font-size: 0.68rem`, `color: var(--text-muted)`

---

## 8. 媒体库网格 (Library Grid)
- **布局**: `grid`, `grid-template-columns: repeat(auto-fill, minmax(210px, 1fr))`
- **间距**: `gap: 14px`

### 8.1 库卡片
- **比例**: `aspect-ratio: 16/9`
- **圆角**: `var(--radius-lg)` = `16px`
- **Hover 动画**:
  - `transform: translateY(-4px) scale(1.02)`
  - `box-shadow: 0 12px 36px rgba(0,0,0,0.5), 0 0 0 1px rgba(0,212,255,0.1)`
- **底部渐变**: `linear-gradient(to top, rgba(10,14,20,0.65), transparent 70%)`
- **右侧光晕**: `radial-gradient(circle, rgba(255,255,255,0.06), transparent 70%)`, 位于 `top: -30%; right: -20%; width: 60%; height: 130%`
- **图标**: `font-size: 26px`, `opacity: 0.8`, `margin-bottom: 6px`
- **库名**: `font-size: 1.05rem`, `font-weight: 700`, `color: #F0F4F8`
- **数量**: `font-family: 'DM Mono'`, `font-size: 0.72rem`, `color: rgba(240,244,248,0.6)`, `margin-top: 3px`
- **内边距**: `18px`

### 8.2 媒体网格 (Grid 视图)
- **布局**: `grid`, `grid-template-columns: repeat(auto-fill, minmax(148px, 1fr))`
- **间距**: `gap: 18px`
- **卡片入场**: `cfu` 动画, 逐项延迟 `0.05s`

---

## 9. 系列详情页

### 9.1 Backdrop
- **高度**: `300px`
- **圆角**: `var(--radius-xl)` = `24px`
- **外边距**: `margin-bottom: -70px` (与 header 重叠)
- **渐变遮罩**:
  ```css
  linear-gradient(to top, var(--bg-primary) 5%, transparent 50%),
  linear-gradient(to right, rgba(10,14,20,0.7), transparent 60%)
  ```

### 9.2 详情头部
- **布局**: `flex`, `gap: 24px`, `padding: 0 24px`
- **海报**:
  - 宽度: `170px`
  - 比例: `2/3`
  - 圆角: `var(--radius-lg)` = `16px`
  - 阴影: `0 8px 32px rgba(0,0,0,0.5)`
  - 边框: `2px solid rgba(0,212,255,0.12)`
- **信息区**: `flex: 1`, `padding-top: 70px`
- **标题**: `font-size: 1.85rem`, `font-weight: 700`, `letter-spacing: -0.03em`, `line-height: 1.2`

### 9.3 Meta 行
- **布局**: `flex`, `gap: 10px`, `flex-wrap: wrap`, `margin-bottom: 12px`
- **Meta 标签**: `font-size: 0.78rem`, `color: var(--text-secondary)`, 图标 `15px`
- **Meta 分隔点**: `3px × 3px` 圆形, `background: var(--text-muted)`
- **评分徽章**:
  - `background: var(--accent-soft)`, `color: var(--accent)`
  - `padding: 3px 9px`, `border-radius: var(--radius-xs)` = `6px`
  - `font-size: 0.78rem`, `font-weight: 600`
- **类型标签**:
  - `padding: 3px 9px`, `border-radius: var(--radius-xs)` = `6px`
  - `font-size: 0.72rem`
  - `background: var(--bg-surface)`, `border: 1px solid var(--border)`
- **描述文字**: `font-size: 0.85rem`, `color: var(--text-secondary)`, `line-height: 1.7`, `max-width: 580px`

### 9.4 演员区
- **滚动容器**: `flex`, `gap: 14px`, 横向滚动
- **演员项**: `width: 74px`, 居中文字
- **头像**: `58px × 58px` 圆形, 居中, `margin-bottom: 6px`, 字号 `1.1rem`, `font-weight: 600`
- **名字**: `font-size: 0.68rem`, `color: var(--text-secondary)`, `line-height: 1.3`
- **角色**: `font-size: 0.62rem`, `color: var(--text-muted)`

### 9.5 季选择器 (Season Tabs)
- **布局**: `flex`, `gap: 4px`, `margin-bottom: 18px`
- **底部边框**: `1px solid var(--border)`
- **Tab 按钮**: `padding: 10px 18px`, `font-size: 0.82rem`, `font-weight: 500`
- **Active 指示器**:
  - 位置: `bottom: -1px`
  - 高度: `2px`
  - 渐变: `linear-gradient(90deg, #00D4FF, #8B5CF6)`
  - 动画: `transform: scaleX(0) → scaleX(1)`, `0.25s`
- **Hover**: `color: var(--text-secondary)`
- **Active**: `color: var(--accent)`

### 9.6 集列表 (Episode List)
- **布局**: `flex-direction: column`, `gap: 2px`
- **集项**: `flex`, `gap: 14px`, `padding: 12px 14px`, `border-radius: var(--radius-md)` = `12px`
- **Hover**: `background: var(--bg-surface-hover)`
- **集编号**: `font-family: 'DM Mono'`, `font-size: 0.78rem`, `width: 28px`
- **缩略图**: `width: 130px`, `aspect-ratio: 16/9`, `border-radius: var(--radius-sm)` = `8px`
- **缩略图播放覆盖**: Hover 时 `opacity: 1`, 背景 `rgba(10,14,20,0.4)`, 图标 `color: var(--accent)`, `font-size: 26px`
- **集标题**: `font-size: 0.85rem`, `font-weight: 500`, `margin-bottom: 3px`
- **集描述**: `font-size: 0.75rem`, `color: var(--text-muted)`, 最多2行, `line-height: 1.5`
- **时长**: `font-family: 'DM Mono'`, `font-size: 0.75rem`
- **入场动画**: `cfu`, `0.4s ease`, 逐项 `0.05s` 延迟

---

## 10. 集详情页 (Episode Detail)

### 10.1 双栏布局
- **Grid**: `grid-template-columns: 1fr 360px`, `gap: 32px`, `align-items: start`
- **响应式**: `@media(max-width: 1100px)` 切为单栏, 控制面板 `position: static`

### 10.2 封面
- **比例**: `16/9`, `border-radius: var(--radius-lg)` = `16px`
- **大播放按钮**:
  - 尺寸: `60px × 60px` 圆形
  - 渐变: `linear-gradient(135deg, #00D4FF, #8B5CF6)`
  - 阴影: `0 4px 24px rgba(0,212,255,0.3)`
  - Hover: `transform: scale(1.1)`, 阴影增强 `0 4px 32px rgba(0,212,255,0.45)`
  - 缓动: `cubic-bezier(0.34, 1.56, 0.64, 1)`
  - 图标: `color: #0A0E14`, `font-size: 30px`
- **覆盖层**: `rgba(10,14,20,0.25)`, Hover 加深到 `0.4`

### 10.3 面包屑
- `font-size: 0.78rem`, `color: var(--text-muted)`, `gap: 7px`, `margin-bottom: 10px`

### 10.4 集标题
- `font-size: 1.4rem`, `font-weight: 700`, `margin-bottom: 8px`

### 10.5 描述
- `font-size: 0.85rem`, `color: var(--text-secondary)`, `line-height: 1.8`, `margin-bottom: 28px`

### 10.6 控制面板 (Ctrl Panel)
- **背景**: `var(--bg-surface)`
- **边框**: `1px solid var(--border)`
- **圆角**: `var(--radius-lg)` = `16px`
- **内边距**: `22px`
- **定位**: `sticky top: 32px`
- **标签**: `font-size: 0.72rem`, `font-weight: 600`, `text-transform: uppercase`, `letter-spacing: 0.06em`, `color: var(--text-muted)`, `margin-bottom: 7px`
- **控件组间距**: `margin-bottom: 18px`, 最后一组 `22px`

### 10.7 自定义下拉选择器
- **触发器**:
  - `padding: 11px 13px`, `background: var(--bg-elevated)`
  - `border: 1px solid var(--border-light)`, `border-radius: var(--radius-sm)` = `8px`
  - `font-size: 0.82rem`
  - Hover: `border-color: rgba(255,255,255,0.15)`
  - Open: `border-color: var(--accent)`, `box-shadow: 0 0 0 3px var(--accent-soft)`
  - 箭头: `font-size: 17px`, Open 时旋转 `180deg`
- **下拉菜单**:
  - `top: calc(100% + 4px)`, `padding: 4px`
  - `border-radius: var(--radius-sm)`, `box-shadow: 0 8px 24px rgba(0,0,0,0.4)`
  - 入场: `translateY(-4px) → translateY(0)`, `0.2s`
- **选项**: `padding: 9px 12px`, `border-radius: var(--radius-xs)`, `font-size: 0.82rem`
  - Selected: `background: var(--accent-soft)`, `color: var(--accent)`
  - 子标签: `font-size: 0.7rem`, `color: var(--text-muted)`

### 10.8 播放按钮 (全宽)
- **内边距**: `13px`
- **渐变**: `linear-gradient(135deg, #00D4FF, #8B5CF6)`
- **文字**: `color: #0A0E14`, `font-size: 0.92rem`, `font-weight: 600`
- **圆角**: `var(--radius-md)` = `12px`
- **Hover**:
  - `box-shadow: 0 4px 24px rgba(0,212,255,0.35), 0 0 0 1px rgba(0,212,255,0.2)`
  - `transform: translateY(-1px)`
- **过渡**: `0.3s cubic-bezier(0.4, 0, 0.2, 1)`

---

## 11. 搜索弹窗 (Search Modal)
- **覆盖层**: `position: fixed; inset: 0`, `z-index: 600`
- **背景**: `rgba(0,0,0,0.55)` + `backdrop-filter: blur(8px)`
- **Padding-top**: `120px`
- **入场**: `opacity: 0 → 1`, `0.25s`

### 11.1 搜索框
- **宽度**: `560px`
- **背景**: `var(--bg-elevated)`
- **边框**: `1px solid var(--border-light)`
- **圆角**: `var(--radius-lg)` = `16px`
- **阴影**: `0 24px 64px rgba(0,0,0,0.5)`
- **入场动画**: `translateY(-12px) scale(0.97) → translateY(0) scale(1)`, `0.3s cubic-bezier(0.34,1.56,0.64,1)`
- **输入区**: `padding: 16px 20px`, `gap: 12px`, 底部边框 `var(--border)`
- **搜索图标**: `color: var(--accent)`, `font-size: 22px`
- **输入框**: `font-size: 1rem`, placeholder `color: var(--text-muted)`
- **提示文字**: `padding: 16px 20px`, `font-size: 0.8rem`, `color: var(--text-muted)`

---

## 12. 设置弹窗 (Settings Modal)
- **覆盖层**: `rgba(0,0,0,0.6)` + `backdrop-filter: blur(6px)`, `z-index: 500`
- **弹窗**: `width: 520px`, `max-height: 80vh`
- **背景**: `var(--bg-secondary)` = `#0F1722`
- **圆角**: `var(--radius-xl)` = `24px`
- **入场动画**: `scale(0.95) translateY(12px) → scale(1) translateY(0)`, `0.35s cubic-bezier(0.34,1.56,0.64,1)`

### 12.1 设置头部
- **内边距**: `24px 28px`, 底部边框 `var(--border)`
- **标题**: `font-size: 1.15rem`, `font-weight: 600`
- **关闭按钮**: `36px × 36px`, `border-radius: var(--radius-sm)` = `8px`

### 12.2 设置内容
- **内边距**: `24px 28px`, `max-height: calc(80vh - 80px)`
- **分组间距**: `margin-bottom: 28px`
- **分组标题**: `font-size: 0.75rem`, `font-weight: 600`, `text-transform: uppercase`, `letter-spacing: 0.06em`, `color: var(--accent)`, `margin-bottom: 16px`
- **设置行**: `padding: 12px 0`, 底部边框 `var(--border)`, `flex justify-content: space-between`
- **标签**: `font-size: 0.9rem`
- **描述**: `font-size: 0.75rem`, `color: var(--text-muted)`, `margin-top: 2px`

### 12.3 开关 (Toggle)
- **尺寸**: `44px × 24px`, `border-radius: 12px`
- **Off 态**: `background: var(--bg-elevated)`, `border: 2px solid var(--border-light)`
- **On 态**: `background: var(--accent)`, `border-color: var(--accent)`
- **滑块**: `16px × 16px` 圆形
  - Off: `background: var(--text-muted)`, `left: 2px`
  - On: `background: var(--bg-deep)`, `left: 22px`
- **过渡**: `0.3s`

### 12.4 关于区块
- 居中文字, `padding: 20px`
- Logo: `48px × 48px`
- 应用名: `font-size: 1.1rem`, `font-weight: 700`
- 版本: `font-family: 'DM Mono'`, `font-size: 0.78rem`, `color: var(--text-muted)`

---

## 13. Phone 端

### 13.1 顶部栏
- **内边距**: `padding: 12px 16px 8px`
- **Logo**: `font-size: 1.1rem`, `font-weight: 700`, `letter-spacing: -0.03em`
  - 渐变文字: `linear-gradient(135deg, #00D4FF, #8B5CF6)`, `-webkit-background-clip: text`
- **搜索栏**: `height: 38px`, `border-radius: 20px`, `gap: 8px`, `padding: 0 14px`

### 13.2 分类行 (Phone)
- **外边距**: `margin-bottom: 22px`
- **标题行**: `padding: 0 16px`, `margin-bottom: 10px`
- **标题**: `font-size: 0.92rem`, `font-weight: 600`, `gap: 6px`
- **图标**: `font-size: 18px`, `color: var(--accent)`
- **查看全部**: `font-size: 0.72rem`, `padding: 4px 10px`, `border-radius: 12px`

### 13.3 Phone 水平滚动
- **间距**: `gap: 10px`, `padding: 2px 16px 10px`

### 13.4 Phone 卡片
- **宽度**: `120px`
- **海报**: `2/3`, `border-radius: var(--radius-md)` = `12px`
- **Active 态**: `transform: scale(0.96)` (按压缩放)
- **海报渐变**: `linear-gradient(to top, rgba(10,14,20,0.65) 0%, transparent 55%)`
- **海报内标题**: `font-size: 0.62rem`, `font-weight: 600`
- **名称**: `font-size: 0.72rem`, `font-weight: 500`
- **年份**: `font-family: 'DM Mono'`, `font-size: 0.62rem`

### 13.5 Phone 媒体库网格
- **布局**: `grid`, `1fr 1fr`, `gap: 10px`, `padding: 0 16px`
- **卡片比例**: `16/10`
- **卡片圆角**: `var(--radius-md)` = `12px`
- **内边距**: `14px`
- **图标**: `font-size: 22px`, `opacity: 0.8`
- **库名**: `font-size: 0.9rem`, `font-weight: 700`
- **数量**: `font-family: 'DM Mono'`, `font-size: 0.65rem`, `color: rgba(240,244,248,0.55)`

### 13.6 Phone 详情页
- **封面**: `16/9`, 底部渐变 `linear-gradient(to top, var(--bg-primary) 0%, transparent 60%)`
- **内容体**: `padding: 0 16px`, `margin-top: -60px`
- **海报**: `width: 100px`, `border-radius: var(--radius-md)`, `shadow: 0 4px 16px`, `border: 2px solid rgba(0,212,255,0.12)`
- **标题**: `font-size: 1.2rem`, `font-weight: 700`
- **描述**: `font-size: 0.78rem`, `line-height: 1.6`
- **集项**: `padding: 10px 16px`, `border-radius: var(--radius-sm)`
  - 缩略图: `width: 100px`, `16/9`, `border-radius: var(--radius-xs)`
  - 标题: `font-size: 0.78rem`
  - 描述: `font-size: 0.68rem`, 最多1行

### 13.7 底部导航栏
- **背景**: `rgba(13,21,32,0.92)` + `backdrop-filter: blur(12px)`
- **边框**: `border-top: 1px solid var(--border)`
- **布局**: `justify-content: space-around`, `padding: 8px 0 env(safe-area-inset-bottom, 8px)`
- **按钮**: `padding: 6px 16px`, `font-size: 0.6rem`
- **图标**: `font-size: 24px`
- **Active**: `color: var(--accent)`, 图标 FILL=1

### 13.8 迷你播放条
- **位置**: `bottom: 60px`, `left: 12px`, `right: 12px`
- **背景**: `var(--bg-elevated)`
- **边框**: `1px solid rgba(0,212,255,0.1)`
- **圆角**: `var(--radius-md)` = `12px`
- **内边距**: `10px 14px`
- **阴影**: `0 4px 20px rgba(0,0,0,0.4), 0 0 30px rgba(0,212,255,0.05)`
- **迷你海报**: `36px × 36px`, `border-radius: var(--radius-xs)`
- **迷你标题**: `font-size: 0.75rem`, `font-weight: 500`
- **迷你集信息**: `font-size: 0.62rem`, `color: var(--text-muted)`
- **控制按钮**: `32px × 32px` 圆形

---

## 14. TV 端

### 14.1 顶部导航
- **内边距**: `padding: 24px 56px 16px`
- **Logo**: `font-size: 1.4rem`, `font-weight: 800`, `letter-spacing: -0.03em`
  - 渐变文字: `linear-gradient(135deg, #00D4FF, #8B5CF6)`
- **导航间距**: `margin-left: 40px`, `gap: 6px`
- **导航按钮**: `padding: 8px 20px`, `font-size: 0.88rem`, `font-weight: 500`, `border-radius: 24px`
  - Active: `color: #0A0E14`, `background: linear-gradient(135deg, #00D4FF, #8B5CF6)`, `font-weight: 600`
- **搜索按钮**: `40px × 40px` 圆形
  - Hover/Focus: `border-color: var(--accent)`, `color: var(--accent)`, `background: var(--accent-soft)`
- **时钟**: `font-family: 'DM Mono'`, `font-size: 0.85rem`

### 14.2 TV Featured Banner
- **外边距**: `0 56px 36px`
- **比例**: `aspect-ratio: 21/9`
- **圆角**: `var(--radius-xl)` = `24px`
- **Hover/Focus 动画**:
  - `transform: scale(1.01)`
  - `box-shadow: 0 0 0 3px var(--accent), 0 20px 60px rgba(0,0,0,0.5), 0 0 40px rgba(0,212,255,0.1)`
- **渐变遮罩**:
  ```css
  linear-gradient(to right, rgba(10,14,20,0.88) 0%, rgba(10,14,20,0.4) 40%, transparent 70%),
  linear-gradient(to top, rgba(10,14,20,0.6) 0%, transparent 40%)
  ```
- **内容区**: `left: 48px`, `bottom: 36px`, `max-width: 45%`
- **推荐标签**: `padding: 4px 12px`, `border-radius: 12px`, `font-size: 0.72rem`, `font-weight: 600`
  - 背景: `var(--accent-soft)`, 颜色: `var(--accent)`
- **标题**: `font-size: 2rem`, `font-weight: 800`, `letter-spacing: -0.03em`, `line-height: 1.1`
- **描述**: `font-size: 0.85rem`, `line-height: 1.5`, 最多2行
- **播放按钮**: `padding: 10px 28px`, `border-radius: 28px`, `font-size: 0.88rem`, `font-weight: 600`
  - 渐变: `linear-gradient(135deg, #00D4FF, #8B5CF6)`, `color: #0A0E14`
  - Hover: `box-shadow: 0 4px 20px rgba(0,212,255,0.35)`

### 14.3 TV 媒体卡片
- **宽度**: `190px`
- **圆角**: `var(--radius-lg)` = `16px`
- **Hover/Focus 动画**:
  - `transform: scale(1.08)`
  - `box-shadow: 0 0 0 3px var(--accent), 0 16px 40px rgba(0,0,0,0.5), 0 0 24px rgba(0,212,255,0.12)`
- **海报**: `2/3`, `border-radius: var(--radius-lg)`, `padding: 16px`
- **海报渐变**: `linear-gradient(to top, rgba(10,14,20,0.7) 0%, transparent 55%)`
- **海报标题**: `font-size: 0.82rem`, `font-weight: 600`
- **名称**: `font-size: 0.92rem`, `font-weight: 500`
- **年份**: `font-family: 'DM Mono'`, `font-size: 0.75rem`

### 14.4 TV 滚动区
- **间距**: `gap: 18px`, `padding: 4px 56px 14px`
- **分节**: `margin-bottom: 36px`
- **节标题**: `padding: 0 56px`, `font-size: 1.2rem`, `font-weight: 700`, `gap: 10px`
- **图标**: `font-size: 24px`, `color: var(--accent)`

### 14.5 TV 媒体库卡片
- **宽度**: `260px`, `aspect-ratio: 16/9`, `border-radius: var(--radius-lg)`
- **Hover/Focus**:
  - `transform: scale(1.05)`
  - `box-shadow: 0 0 0 3px var(--accent), 0 12px 36px rgba(0,0,0,0.5), 0 0 20px rgba(0,212,255,0.1)`
- **内边距**: `20px`
- **图标**: `font-size: 28px`, `opacity: 0.8`
- **库名**: `font-size: 1.15rem`, `font-weight: 700`
- **数量**: `font-family: 'DM Mono'`, `font-size: 0.75rem`, `color: rgba(240,244,248,0.55)`

### 14.6 TV Toast 提示
- **位置**: `fixed bottom: 60px`, 水平居中
- **背景**: `var(--bg-elevated)`
- **边框**: `1px solid var(--accent)`, `border-radius: 24px`
- **内边距**: `10px 24px`
- **字号**: `0.88rem`, `font-weight: 500`
- **毛玻璃**: `backdrop-filter: blur(12px)`
- **动画**: `opacity 0 → 1`, `translateY(20px) → 0`, `0.3s`, 自动消失 2.5s

---

## 15. 渐变色汇总

### 15.1 品牌渐变
| 用途 | 值 |
|---|---|
| 主品牌渐变 | `linear-gradient(135deg, #00D4FF, #8B5CF6)` |
| 播放按钮渐变 | `linear-gradient(135deg, #00D4FF, #8B5CF6)` |
| 季指示器 | `linear-gradient(90deg, #00D4FF, #8B5CF6)` |

### 15.2 海报背景渐变 (GRADS 数组)
| 索引 | 渐变值 |
|---|---|
| 0 | `linear-gradient(135deg, #0A0E14, #1A2332, #111820)` |
| 1 | `linear-gradient(135deg, #0D1520, #1A2332, #8B5CF6)` |
| 2 | `linear-gradient(135deg, #1A0A0A, #8B2020, #FF6B35)` |
| 3 | `linear-gradient(135deg, #051A12, #00E5A0, #0A0E14)` |
| 4 | `linear-gradient(135deg, #0A1628, #00D4FF, #0D1520)` |
| 5 | `linear-gradient(135deg, #1A1508, #FF6B35, #FF6B35)` |
| 6 | `linear-gradient(135deg, #1A0A2E, #8B5CF6, #EC4899)` |
| 7 | `linear-gradient(135deg, #0D1520, #00D4FF, #8B5CF6)` |
| 8 | `linear-gradient(135deg, #1A0A33, #8B5CF6, #00D4FF)` |
| 9 | `linear-gradient(135deg, #051A18, #00E5A0, #00D4FF)` |
| 10 | `linear-gradient(135deg, #141820, #2A3444, #5A6577)` |
| 11 | `linear-gradient(135deg, #1A1818, #2A3444, #5A6577)` |

### 15.3 演员头像渐变
| 角色 | 渐变 |
|---|---|
| 艾伦 | `linear-gradient(135deg, #00D4FF, #8B5CF6)` |
| 三笠 | `linear-gradient(135deg, #EC4899, #8B5CF6)` |
| 阿尔敏 | `linear-gradient(135deg, #00E5A0, #00D4FF)` |
| 利威尔 | `linear-gradient(135deg, #1A2332, #2A3444)` |
| 埃尔文 | `linear-gradient(135deg, #FF6B35, #FF6B35)` |
| 韩吉 | `linear-gradient(135deg, #8B5CF6, #EC4899)` |
| 柯尼 | `linear-gradient(135deg, #FF6B35, #00E5A0)` |

### 15.4 媒体库配色
| 库名 | 主色 |
|---|---|
| 动漫 | `#8B5CF6` (紫色) |
| 动漫电影 | `#00D4FF` (青色) |
| 国产剧 | `#FF6B35` (橙色) |
| 综艺 | `#EC4899` (粉色) |
| 电影 | `#00E5A0` (绿色) |
| 纪录片 | `#00D4FF` (青色) |

### 15.5 其他渐变
| 用途 | 值 |
|---|---|
| 主内容径向光晕 1 | `radial-gradient(ellipse at 10% 0%, rgba(0,212,255,0.04), transparent 50%)` |
| 主内容径向光晕 2 | `radial-gradient(ellipse at 80% 100%, rgba(139,92,246,0.03), transparent 50%)` |
| TV 背景径向光晕 1 | `radial-gradient(ellipse at 15% 10%, rgba(0,212,255,0.05), transparent 55%)` |
| TV 背景径向光晕 2 | `radial-gradient(ellipse at 85% 80%, rgba(139,92,246,0.03), transparent 50%)` |
| 库卡片右侧光晕 | `radial-gradient(circle, rgba(255,255,255,0.06), transparent 70%)` |
| Backdrop 底部 | `linear-gradient(to top, var(--bg-primary) 5%, transparent 50%)` |
| Backdrop 左侧 | `linear-gradient(to right, rgba(10,14,20,0.7), transparent 60%)` |
| Top Bar | `linear-gradient(to bottom, var(--bg-primary) 60%, transparent)` |

---

## 16. 阴影汇总

| 组件 | box-shadow 值 |
|---|---|
| Tooltip | `0 4px 12px rgba(0,0,0,0.4)` |
| 服务器下拉 | `0 12px 40px rgba(0,0,0,0.5)` |
| 搜索弹窗 | `0 24px 64px rgba(0,0,0,0.5)` |
| 下拉菜单 | `0 8px 24px rgba(0,0,0,0.4)` |
| Media Card Hover | `0 12px 32px rgba(0,0,0,0.5), 0 0 0 1px rgba(0,212,255,0.15), 0 0 20px rgba(0,212,255,0.08)` |
| 播放圆按钮 | `0 4px 20px rgba(0,212,255,0.3)` |
| Library Card Hover | `0 12px 36px rgba(0,0,0,0.5), 0 0 0 1px rgba(0,212,255,0.1)` |
| 详情海报 | `0 8px 32px rgba(0,0,0,0.5)` |
| 大播放按钮 | `0 4px 24px rgba(0,212,255,0.3)` |
| 大播放按钮 Hover | `0 4px 32px rgba(0,212,255,0.45)` |
| 播放全宽按钮 Hover | `0 4px 24px rgba(0,212,255,0.35), 0 0 0 1px rgba(0,212,255,0.2)` |
| 在线状态点 | `0 0 6px rgba(0,229,160,0.4)` |
| TV Card Hover | `0 0 0 3px var(--accent), 0 16px 40px rgba(0,0,0,0.5), 0 0 24px rgba(0,212,255,0.12)` |
| TV Featured Hover | `0 0 0 3px var(--accent), 0 20px 60px rgba(0,0,0,0.5), 0 0 40px rgba(0,212,255,0.1)` |
| TV Library Card Hover | `0 0 0 3px var(--accent), 0 12px 36px rgba(0,0,0,0.5), 0 0 20px rgba(0,212,255,0.1)` |
| 迷你播放条 | `0 4px 20px rgba(0,0,0,0.4), 0 0 30px rgba(0,212,255,0.05)` |
| Phone 详情海报 | `0 4px 16px rgba(0,0,0,0.5)` |
| TV 播放按钮 Hover | `0 4px 20px rgba(0,212,255,0.35)` |
| 设置弹窗 | (无额外 shadow，靠 border) |

---

## 17. 动画/过渡汇总

| 动画名/效果 | 属性 | 值 | 缓动函数 |
|---|---|---|---|
| 全局过渡 `--transition` | 所有 | `0.3s` | `cubic-bezier(0.4,0,0.2,1)` |
| 视图入场 `vIn` | opacity+transform | `0.4s` | `ease` |
| 卡片渐现 `cfu` | opacity+transform | `0.5s` (逐项+0.05s) | `ease` |
| 搜索框弹出 | transform | `0.3s` | `cubic-bezier(0.34,1.56,0.64,1)` |
| 设置弹窗弹出 | transform | `0.35s` | `cubic-bezier(0.34,1.56,0.64,1)` |
| 服务器下拉 | opacity+transform | `0.25s` | default |
| 下拉菜单 | opacity+transform | `0.2s` | default |
| 选择器下拉 | opacity+transform | `0.2s` | default |
| Tooltip | opacity+transform | `0.2s` | default |
| 季指示器 | transform scaleX | `0.25s` | default |
| 搜索弹窗遮罩 | opacity | `0.25s` | default |
| 设置遮罩 | opacity | `0.3s` | default |
| Media Card 海报 Hover | transform+box-shadow | `0.35s` | `cubic-bezier(0.4,0,0.2,1)` |
| 播放覆盖层 | opacity | `0.3s` | default |
| 播放圆按钮 | transform | `0.3s` | `cubic-bezier(0.34,1.56,0.64,1)` |
| Library Card Hover | transform+box-shadow | `0.35s` | default |
| 大播放按钮 | transform | `0.3s` | `cubic-bezier(0.34,1.56,0.64,1)` |
| 播放全宽按钮 | all | `0.3s` | `cubic-bezier(0.4,0,0.2,1)` |
| Toggle | all | `0.3s` | default |
| 箭头旋转 | transform | `0.2s` | default |
| Phone 按压 | transform | `0.3s` | default |
| TV Card Hover | transform+box-shadow | `0.3s` | default |
| TV Featured Hover | transform+box-shadow | `0.3s` | default |
| TV Lib Card Hover | transform+box-shadow | `0.3s` | default |
| TV Toast | opacity+transform | `0.3s` | default |

---

## 18. 所有 font-size 使用汇总

| 值 (rem) | 值 (px @14) | 用途 |
|---|---|---|
| `0.60rem` | 8.4px | Phone 底部导航文字 |
| `0.62rem` | 8.7px | 演员角色名, Phone 海报内标题, Phone 年份, 迷你集信息 |
| `0.65rem` | 9.1px | Phone 库数量 |
| `0.68rem` | 9.5px | 演员名, 快捷键标签, 卡片年份, TV 年份 (部分) |
| `0.70rem` | 9.8px | Tooltip, 海报内标题 |
| `0.72rem` | 10.1px | 库数量, 类型标签, Phone 查看全部, 控制标签, TV推荐标签 |
| `0.75rem` | 10.5px | 设置描述, 集描述, 时长, TV 年份 |
| `0.78rem` | 10.9px | 平台按钮, 查看全部, Meta 标签, 评分徽章, 集编号, 版本号, 面包屑, 搜索触发器 |
| `0.80rem` | 11.2px | 搜索提示, 添加账号按钮 |
| `0.82rem` | 11.5px | 搜索触发器, 季Tab, 选择器, 搜索输入 placeholder |
| `0.85rem` | 11.9px | 平台Logo, 集标题, 服务器项, 设置标签, Featured 描述, 控制值 |
| `0.88rem` | 12.3px | TV 导航, TV 播放按钮, TV Toast |
| `0.90rem` | 12.6px | 设置标签, Phone 库名 |
| `0.92rem` | 12.9px | 播放全宽按钮, Phone 节标题, TV 卡片名称 |
| `1.00rem` | 14px | 节标题 (Desktop), 搜索输入 |
| `1.05rem` | 14.7px | 库卡片名称 |
| `1.10rem` | 15.4px | Phone Logo, 关于应用名 |
| `1.15rem` | 16.1px | 设置标题, Phone 库标题, TV 库名 |
| `1.20rem` | 16.8px | Phone 详情标题 |
| `1.40rem` | 19.6px | TV Logo, 集详情标题 |
| `1.50rem` | 21px | 库页标题 |
| `1.85rem` | 25.9px | 详情大标题 |
| `2.00rem` | 28px | TV Featured 标题 |

---

## 19. 所有 font-weight 使用汇总

| 值 | 用途 |
|---|---|
| 300 | Sora 字体可选 (未直接使用) |
| 400 | Material Symbols 默认, DM Mono 默认 |
| 500 | 次要按钮、卡片标题、导航文字、Meta 标签、TV 导航 |
| 600 | 节标题、评分徽章、海报内标题、播放按钮、设置分组标题、TV Active 导航、推荐标签 |
| 700 | Logo、库名、详情大标题、TV 节标题、TV Logo |
| 800 | TV Logo |

---

## 20. 所有 padding/margin/gap 关键值汇总

### 20.1 外边距 (margin)
| 组件 | 值 |
|---|---|
| Section | `margin-bottom: 36px` |
| Phone Section | `margin-bottom: 22px` |
| 标题行 | `margin-bottom: 14px` |
| Backdrop | `margin-bottom: -70px` (重叠) |
| 控件组 | `margin-bottom: 18px` / 最后 `22px` |
| 设置分组 | `margin-bottom: 28px` |
| 集详情描述 | `margin-bottom: 28px` |

### 20.2 内边距 (padding)
| 组件 | 值 |
|---|---|
| 侧边栏 | `20px 0 16px` |
| 海报内容区 | `14px` (Desktop) / `10px` (Phone) / `16px` (TV) |
| 库卡片 | `18px` (Desktop) / `14px` (Phone) / `20px` (TV) |
| 详情头部 | `0 24px` |
| 控制面板 | `22px` |
| 设置弹窗头部 | `24px 28px` |
| 设置弹窗内容 | `24px 28px` |
| 集项 | `12px 14px` (Desktop) / `10px 16px` (Phone) |
| Top Bar | `16px 36px` |
| 视图 | `8px 36px 60px` |
| TV Top | `24px 56px 16px` |
| TV 内容滚动 | `4px 56px 14px` |

### 20.3 Gap
| 组件 | 值 |
|---|---|
| 平台按钮 | `4px` |
| 侧边栏导航 | `2px` |
| 水平滚动 (Desktop) | `14px` |
| 水平滚动 (Phone) | `10px` |
| 水平滚动 (TV) | `18px` |
| 媒体网格 | `18px` |
| 库网格 | `14px` |
| 演员滚动 | `14px` |
| Meta 行 | `10px` |
| 详情布局 | `24px` / `32px` (Ep详情) |
| TV 导航 | `6px` |
| Phone 底部导航 | (space-around) |

---

## 21. 关键设计模式总结

### 21.1 发光边框 (Focus Ring) — TV 端
```
box-shadow: 0 0 0 3px var(--accent), ...
```
TV 端所有可聚焦元素使用 `3px` 青色边框发光作为焦点态。

### 21.2 卡片 Hover 提升模式
Desktop: `translateY(-6px) scale(1.03)` + 青色辉光阴影  
TV: `scale(1.08)` + 青色边框 + 阴影  
Phone: `scale(0.96)` 按压效果 (Active 态)

### 21.3 毛玻璃效果
- 搜索模态: `backdrop-filter: blur(8px)`
- 设置模态: `backdrop-filter: blur(6px)`
- 平台栏: `backdrop-filter: blur(12px)`
- Phone 底部导航: `backdrop-filter: blur(12px)`
- 滚动箭头: `backdrop-filter: blur(8px)`
- Toast: `backdrop-filter: blur(12px)`

### 21.4 渐变文字
Logo 文字 (Phone/TV): `background-clip: text` + `linear-gradient(135deg, #00D4FF, #8B5CF6)`

### 21.5 Material Symbols 使用
- 默认: `FILL 0, wght 400, GRAD 0, opsz 24`
- 填充态 (`.icon-filled`): `FILL 1, wght 500, GRAD 0, opsz 24`
