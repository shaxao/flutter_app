# 萨莉亚智能排班助手 - 开发指南

## 快速开始

### 1. 环境准备

```bash
# 检查 Flutter 环境
flutter doctor

# 如果未安装 Flutter，访问：https://flutter.dev/docs/get-started/install
```

### 2. 安装依赖

```bash
cd flutter_app
flutter pub get
```

### 3. 运行应用

```bash
# iOS 模拟器
flutter run

# 真机调试（需要 Apple Developer 账号）
flutter run --release
```

## GitHub Actions 自动构建

### 配置步骤

1. **生成个人证书**
   - 打开 Xcode
   - Preferences → Accounts → 添加 Apple ID
   - Manage Certificates → + → Apple Development
   - 导出证书为 `.p12` 文件

2. **配置 GitHub Secrets**
   
   在仓库 Settings → Secrets and variables → Actions 添加：
   
   - `P12_BASE64`: 证书的 Base64 编码
     ```bash
     base64 -i certificate.p12 | pbcopy
     ```
   
   - `P12_PASSWORD`: 证书密码

3. **触发构建**
   
   ```bash
   git push origin main
   ```
   
   或手动触发：Actions → iOS Build & Sign → Run workflow

4. **下载 IPA**
   
   - 构建完成后，在 Actions → 对应的 workflow run
   - 下载 Artifacts 中的 `SaizeriYa-Scheduler-IPA`

## Sideloadly 安装

### 方式1: 使用 Sideloadly (推荐)

1. **下载 Sideloadly**
   - 官网：https://sideloadly.io/
   - 支持 Windows 和 macOS

2. **安装步骤**
   - 连接 iPhone 到电脑
   - 打开 Sideloadly
   - 拖入 `.ipa` 文件
   - 输入 Apple ID（免费账号即可）
   - 点击 Start

3. **信任证书**
   - iPhone: 设置 → 通用 → VPN与设备管理
   - 点击开发者应用 → 信任

### 方式2: 使用 AltStore

1. 下载 AltStore: https://altstore.io/
2. 安装 AltServer 到电脑
3. 通过 AltStore 安装 `.ipa`

### 方式3: Xcode 直接安装

```bash
# 连接设备后
flutter install
```

## 功能特性

### ✅ iOS 原生优势

| 功能 | PWA | iOS Native |
|------|-----|-----------|
| 锁屏语音播报 | ❌ | ✅ |
| 后台运行 | ❌ | ✅ |
| 本地通知 | ⚠️ | ✅ |
| 系统集成 | ❌ | ✅ |

### 核心功能

1. **智能排班**
   - 日历视图
   - 班次管理
   - 冲突检测

2. **语音提醒**
   - 锁屏播报
   - 后台运行
   - 自定义提醒

3. **考勤统计**
   - 出勤记录
   - 工时统计
   - 数据导出

4. **数据同步**
   - 与后端 API 同步
   - 离线缓存
   - 自动备份

## 项目结构

```
flutter_app/
├── lib/
│   ├── core/
│   │   ├── theme/          # 主题配置
│   │   └── services/       # 核心服务
│   │       ├── notification_service.dart  # 通知
│   │       └── voice_service.dart         # 语音
│   ├── features/
│   │   ├── home/           # 首页
│   │   ├── schedule/       # 排班
│   │   ├── reminder/       # 提醒
│   │   └── settings/       # 设置
│   └── main.dart
├── ios/                    # iOS 配置
├── pubspec.yaml           # 依赖配置
└── .github/workflows/     # CI/CD
```

## 设计系统

基于 **ui-ux-pro-max** 生成：

- **风格**: Exaggerated Minimalism
- **配色**: Fresh Blue (#3B82F6) + Orange CTA (#F97316)
- **字体**: Playfair Display SC / Karla
- **布局**: Minimal Single Column

详见：`design-system/萨莉亚智能排班助手/MASTER.md`

## 常见问题

### Q: 为什么选择 Flutter？
A: 
- 跨平台支持（未来可扩展 Android）
- 原生性能
- 丰富的 UI 组件
- 活跃的社区

### Q: 免费 Apple ID 可以安装吗？
A: 可以，但有限制：
- 每 7 天需重新签名
- 最多 3 个应用
- 建议使用 Sideloadly 自动续签

### Q: 如何实现后台语音？
A: 
- 使用 `flutter_tts` + iOS Audio Session
- 配置 `UIBackgroundModes` 为 `audio`
- 使用 `workmanager` 定时检查提醒

### Q: 数据如何同步？
A: 
- 使用 `dio` 调用现有后端 API
- `hive` 本地缓存
- 离线优先策略

## 下一步

1. ✅ 项目初始化
2. ⏳ 实现排班页面
3. ⏳ 实现提醒页面
4. ⏳ 集成后端 API
5. ⏳ 测试语音功能
6. ⏳ 发布第一个版本

## 参考资源

- [Flutter 官方文档](https://flutter.dev/docs)
- [flutter_tts 文档](https://pub.dev/packages/flutter_tts)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- [Sideloadly 教程](https://sideloadly.io/#faq)
