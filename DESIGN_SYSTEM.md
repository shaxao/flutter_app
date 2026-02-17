# VoiceFlow Premium Design System

## 1. 核心理念
**"Void & Pulse" (虚空与脉动)**
- **极简 (Minimalism)**: 剥离一切非必要装饰，还原功能本质。
- **高级 (Premium)**: 通过极致的黑白对比与克制的红色点缀，营造专业感。
- **几何 (Geometric)**: 强调线条与块面的构成感，摒弃圆润的“亲和力”，追求冷静的秩序感。

## 2. 色彩系统 (Color Palette)

### 基础色 (Foundation)
| Token | Hex | 说明 |
|-------|-----|------|
| **Background** | `#000000` | 纯黑，用于应用背景，提供无限深邃感 |
| **Surface** | `#1A1A1A` | 深灰，用于卡片、弹窗背景 |
| **Surface Highlight** | `#2A2A2A` | 稍亮灰色，用于Hover或选中状态 |

### 强调色 (Accent)
| Token | Hex | 说明 |
|-------|-----|------|
| **Primary** | `#FF0000` | 正红，用于核心操作、重要状态、品牌标识 |
| **Primary Dark** | `#8B0000` | 深红，用于按下状态或渐变深部 |
| **Primary Light** | `#FF3333` | 亮红，用于Hover发光效果 |

### 文字色 (Typography)
| Token | Hex | 说明 |
|-------|-----|------|
| **Text Primary** | `#FFFFFF` | 纯白，用于标题、正文 |
| **Text Secondary** | `#A0A0A0` | 中灰，用于辅助说明、次级信息 |
| **Text Disabled** | `#404040` | 暗灰，用于不可用状态 |

### 边框与分割 (Borders)
| Token | Hex | 说明 |
|-------|-----|------|
| **Border** | `#333333` | 深灰，用于细微边界界定 |
| **Border Focus** | `#FF0000` | 红色，用于聚焦或激活状态 |

## 3. 字体系统 (Typography)

**Font Family**: `Inter` (无衬线现代字体)

| 样式 (Style) | 字号 (Size) | 字重 (Weight) | 行高 (Height) | 字间距 (Spacing) | 用途 |
|-------------|------------|--------------|--------------|----------------|------|
| **Display XL** | 48px | 700 (Bold) | 1.1 | -1.5px | 首页大标题 |
| **Display L** | 36px | 600 (SemiBold)| 1.2 | -1.0px | 模块标题 |
| **Title M** | 24px | 500 (Medium) | 1.3 | -0.5px | 卡片标题 |
| **Body L** | 16px | 400 (Regular) | 1.6 | 0px | 正文内容 |
| **Body M** | 14px | 400 (Regular) | 1.5 | 0px | 列表项、辅助文案 |
| **Label S** | 12px | 500 (Medium) | 1.4 | 0.5px | 标签、元数据 |

## 4. 组件规范 (Components)

### 按钮 (Buttons)
- **造型**: 纯几何矩形，极小圆角 (2px) 或 直角 (0px)。
- **Primary Button**: 纯白文字 + 红色背景。Hover时亮度提升，Scale 1.02。
- **Secondary Button**: 纯白文字 + 深灰背景 (#333333)。Hover时边框变白。
- **Outline Button**: 红色边框 + 红色文字 + 透明背景。

### 卡片 (Cards)
- **背景**: `#1A1A1A`
- **边框**: 1px Solid `#333333`
- **阴影**: 无阴影 (Flat) 或 极微弱辉光 (Glow)。
- **交互**: Hover时边框颜色变为 `#666666`，背景轻微变亮。

### 弹窗 (Dialogs)
- **遮罩**: 背景模糊 `BackdropFilter` (Blur 10px) + 黑色半透明层 (Opacity 0.5)。
- **容器**: `#1A1A1A` 背景，红色顶部线条装饰 (Top Border 2px solid Red)。
- **动画**: 缩放淡入 (Scale + Fade In)。

### 输入框 (Inputs)
- **背景**: `#111111`
- **边框**: 底部边框 (Underline) 或 全边框 `#333333`。
- **Focus**: 边框变为红色 `#FF0000`，光标红色。

## 5. 布局与间距 (Layout & Spacing)
- **网格基数**: 8px
- **常见间距**:
  - XS: 4px
  - S: 8px
  - M: 16px
  - L: 24px
  - XL: 32px
  - XXL: 48px (6 * 8)
  - XXXL: 64px (8 * 8)
- **黄金比例**: 在大布局划分时参考 1.618 比例（例如侧边栏与主内容的宽度比）。

## 6. 微交互 (Micro-interactions)
- **Hover**: 200ms `easeInOut` 过渡。
- **Press**: 100ms `easeInOut` 缩放 (Scale 0.98)。
- **Switch**: 红色滑块，无阴影，纯色填充。
